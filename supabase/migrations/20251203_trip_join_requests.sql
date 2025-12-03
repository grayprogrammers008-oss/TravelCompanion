-- Migration: Trip Join Requests
-- Date: 2025-12-03
-- Description: Create trip_join_requests table for managing join requests to public trips

-- Create enum type for request status
DO $$ BEGIN
    CREATE TYPE public.join_request_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create trip_join_requests table
CREATE TABLE IF NOT EXISTS public.trip_join_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status public.join_request_status NOT NULL DEFAULT 'pending',
    message TEXT, -- Optional message from requester
    response_message TEXT, -- Optional response from trip owner
    responded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    responded_at TIMESTAMPTZ,

    -- Ensure a user can only have one pending request per trip
    CONSTRAINT unique_pending_request UNIQUE (trip_id, user_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_join_requests_trip_id ON public.trip_join_requests(trip_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_user_id ON public.trip_join_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_status ON public.trip_join_requests(status);
CREATE INDEX IF NOT EXISTS idx_join_requests_created_at ON public.trip_join_requests(created_at DESC);

-- Add comments
COMMENT ON TABLE public.trip_join_requests IS 'Stores join requests for public trips';
COMMENT ON COLUMN public.trip_join_requests.message IS 'Optional message from the user requesting to join';
COMMENT ON COLUMN public.trip_join_requests.response_message IS 'Optional response from the trip owner/admin';
COMMENT ON COLUMN public.trip_join_requests.responded_by IS 'User ID of the person who approved/rejected the request';

-- Enable RLS
ALTER TABLE public.trip_join_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users can view their own requests
CREATE POLICY "Users can view own join requests"
ON public.trip_join_requests
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Trip owners/admins can view requests for their trips
CREATE POLICY "Trip owners can view requests for their trips"
ON public.trip_join_requests
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.trips t
        WHERE t.id = trip_join_requests.trip_id
        AND t.created_by = auth.uid()
    )
    OR
    EXISTS (
        SELECT 1 FROM public.trip_members tm
        WHERE tm.trip_id = trip_join_requests.trip_id
        AND tm.user_id = auth.uid()
        AND tm.role = 'admin'
    )
);

-- Users can create join requests for public trips they're not members of
CREATE POLICY "Users can request to join public trips"
ON public.trip_join_requests
FOR INSERT
TO authenticated
WITH CHECK (
    user_id = auth.uid()
    AND
    -- Trip must be public
    EXISTS (
        SELECT 1 FROM public.trips t
        WHERE t.id = trip_join_requests.trip_id
        AND t.is_public = true
    )
    AND
    -- User must not already be a member
    NOT EXISTS (
        SELECT 1 FROM public.trip_members tm
        WHERE tm.trip_id = trip_join_requests.trip_id
        AND tm.user_id = auth.uid()
    )
);

-- Users can cancel their own pending requests
CREATE POLICY "Users can cancel own pending requests"
ON public.trip_join_requests
FOR UPDATE
TO authenticated
USING (
    user_id = auth.uid()
    AND status = 'pending'
)
WITH CHECK (
    user_id = auth.uid()
    AND status = 'cancelled'
);

-- Trip owners/admins can approve or reject requests
CREATE POLICY "Trip owners can respond to requests"
ON public.trip_join_requests
FOR UPDATE
TO authenticated
USING (
    status = 'pending'
    AND
    (
        EXISTS (
            SELECT 1 FROM public.trips t
            WHERE t.id = trip_join_requests.trip_id
            AND t.created_by = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM public.trip_members tm
            WHERE tm.trip_id = trip_join_requests.trip_id
            AND tm.user_id = auth.uid()
            AND tm.role = 'admin'
        )
    )
)
WITH CHECK (
    status IN ('approved', 'rejected')
);

-- Users can delete their own cancelled/rejected requests
CREATE POLICY "Users can delete own non-pending requests"
ON public.trip_join_requests
FOR DELETE
TO authenticated
USING (
    user_id = auth.uid()
    AND status IN ('cancelled', 'rejected')
);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.trip_join_requests TO authenticated;

-- Function to get public trips with join status
CREATE OR REPLACE FUNCTION public.get_public_trips(
    p_search TEXT DEFAULT NULL,
    p_destination TEXT DEFAULT NULL,
    p_min_budget DOUBLE PRECISION DEFAULT NULL,
    p_max_budget DOUBLE PRECISION DEFAULT NULL,
    p_start_after DATE DEFAULT NULL,
    p_start_before DATE DEFAULT NULL,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    destination TEXT,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    cover_image_url TEXT,
    created_by UUID,
    creator_name TEXT,
    creator_avatar TEXT,
    created_at TIMESTAMPTZ,
    budget DOUBLE PRECISION,
    currency TEXT,
    member_count BIGINT,
    is_member BOOLEAN,
    join_request_status public.join_request_status
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.id,
        t.name,
        t.description,
        t.destination,
        t.start_date,
        t.end_date,
        t.cover_image_url,
        t.created_by,
        p.full_name as creator_name,
        p.avatar_url as creator_avatar,
        t.created_at,
        t.budget,
        t.currency,
        (SELECT COUNT(*) FROM public.trip_members WHERE trip_id = t.id) as member_count,
        EXISTS (
            SELECT 1 FROM public.trip_members tm
            WHERE tm.trip_id = t.id AND tm.user_id = auth.uid()
        ) as is_member,
        (
            SELECT jr.status FROM public.trip_join_requests jr
            WHERE jr.trip_id = t.id AND jr.user_id = auth.uid()
            ORDER BY jr.created_at DESC
            LIMIT 1
        ) as join_request_status
    FROM public.trips t
    JOIN public.profiles p ON t.created_by = p.id
    WHERE t.is_public = true
        AND t.is_completed = false -- Only show active trips
        AND (p_search IS NULL OR
             t.name ILIKE '%' || p_search || '%' OR
             t.destination ILIKE '%' || p_search || '%' OR
             t.description ILIKE '%' || p_search || '%')
        AND (p_destination IS NULL OR t.destination ILIKE '%' || p_destination || '%')
        AND (p_min_budget IS NULL OR t.budget >= p_min_budget)
        AND (p_max_budget IS NULL OR t.budget <= p_max_budget)
        AND (p_start_after IS NULL OR t.start_date >= p_start_after)
        AND (p_start_before IS NULL OR t.start_date <= p_start_before)
    ORDER BY t.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_public_trips TO authenticated;

-- Function to create a join request
CREATE OR REPLACE FUNCTION public.create_join_request(
    p_trip_id UUID,
    p_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_request_id UUID;
BEGIN
    -- Check if trip is public
    IF NOT EXISTS (SELECT 1 FROM public.trips WHERE id = p_trip_id AND is_public = true) THEN
        RAISE EXCEPTION 'Trip is not public';
    END IF;

    -- Check if user is already a member
    IF EXISTS (SELECT 1 FROM public.trip_members WHERE trip_id = p_trip_id AND user_id = auth.uid()) THEN
        RAISE EXCEPTION 'You are already a member of this trip';
    END IF;

    -- Check if there's already a pending request
    IF EXISTS (SELECT 1 FROM public.trip_join_requests WHERE trip_id = p_trip_id AND user_id = auth.uid() AND status = 'pending') THEN
        RAISE EXCEPTION 'You already have a pending request for this trip';
    END IF;

    -- Create the request
    INSERT INTO public.trip_join_requests (trip_id, user_id, message)
    VALUES (p_trip_id, auth.uid(), p_message)
    RETURNING id INTO v_request_id;

    RETURN v_request_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.create_join_request TO authenticated;

-- Function to respond to a join request (approve/reject)
CREATE OR REPLACE FUNCTION public.respond_to_join_request(
    p_request_id UUID,
    p_approved BOOLEAN,
    p_response_message TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_trip_id UUID;
    v_user_id UUID;
    v_status public.join_request_status;
BEGIN
    -- Get the request details
    SELECT trip_id, user_id, status INTO v_trip_id, v_user_id, v_status
    FROM public.trip_join_requests
    WHERE id = p_request_id;

    IF v_trip_id IS NULL THEN
        RAISE EXCEPTION 'Request not found';
    END IF;

    IF v_status != 'pending' THEN
        RAISE EXCEPTION 'Request has already been processed';
    END IF;

    -- Check if current user is trip owner or admin
    IF NOT EXISTS (
        SELECT 1 FROM public.trips t
        WHERE t.id = v_trip_id AND t.created_by = auth.uid()
    ) AND NOT EXISTS (
        SELECT 1 FROM public.trip_members tm
        WHERE tm.trip_id = v_trip_id AND tm.user_id = auth.uid() AND tm.role = 'admin'
    ) THEN
        RAISE EXCEPTION 'You do not have permission to respond to this request';
    END IF;

    -- Update the request
    UPDATE public.trip_join_requests
    SET
        status = CASE WHEN p_approved THEN 'approved'::public.join_request_status ELSE 'rejected'::public.join_request_status END,
        response_message = p_response_message,
        responded_by = auth.uid(),
        responded_at = now(),
        updated_at = now()
    WHERE id = p_request_id;

    -- If approved, add user as member
    IF p_approved THEN
        INSERT INTO public.trip_members (trip_id, user_id, role)
        VALUES (v_trip_id, v_user_id, 'member');
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.respond_to_join_request TO authenticated;

-- Function to get pending join requests for a trip (for trip owners)
CREATE OR REPLACE FUNCTION public.get_trip_join_requests(p_trip_id UUID)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    user_name TEXT,
    user_email CITEXT,
    user_avatar TEXT,
    message TEXT,
    status public.join_request_status,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    -- Check if current user is trip owner or admin
    IF NOT EXISTS (
        SELECT 1 FROM public.trips t
        WHERE t.id = p_trip_id AND t.created_by = auth.uid()
    ) AND NOT EXISTS (
        SELECT 1 FROM public.trip_members tm
        WHERE tm.trip_id = p_trip_id AND tm.user_id = auth.uid() AND tm.role = 'admin'
    ) THEN
        RAISE EXCEPTION 'You do not have permission to view requests for this trip';
    END IF;

    RETURN QUERY
    SELECT
        jr.id,
        jr.user_id,
        p.full_name as user_name,
        p.email as user_email,
        p.avatar_url as user_avatar,
        jr.message,
        jr.status,
        jr.created_at
    FROM public.trip_join_requests jr
    JOIN public.profiles p ON jr.user_id = p.id
    WHERE jr.trip_id = p_trip_id
    ORDER BY
        CASE WHEN jr.status = 'pending' THEN 0 ELSE 1 END,
        jr.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_trip_join_requests TO authenticated;

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_join_request_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_join_request_updated_at ON public.trip_join_requests;
CREATE TRIGGER trigger_update_join_request_updated_at
    BEFORE UPDATE ON public.trip_join_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.update_join_request_updated_at();
