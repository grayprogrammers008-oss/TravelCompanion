-- =====================================================
-- Trip Templates System
-- =====================================================
-- This migration creates the trip templates system that allows:
-- 1. Pre-built trip templates for popular destinations
-- 2. Template itineraries with day-by-day activities
-- 3. Template checklists with packing items
-- 4. AI usage tracking for freemium model
-- =====================================================

-- =====================================================
-- TRIP TEMPLATES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.trip_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  destination TEXT NOT NULL,
  destination_state TEXT, -- For Indian states
  duration_days INTEGER NOT NULL,
  budget_min DECIMAL(12, 2),
  budget_max DECIMAL(12, 2),
  currency TEXT DEFAULT 'INR',
  cover_image_url TEXT,
  category TEXT NOT NULL DEFAULT 'adventure', -- adventure, pilgrimage, beach, hill_station, heritage, wildlife, honeymoon, family
  tags TEXT[] DEFAULT '{}', -- Array of tags for filtering
  best_season TEXT[], -- Array of months: ['October', 'November', 'December']
  difficulty_level TEXT DEFAULT 'easy', -- easy, moderate, difficult
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  use_count INTEGER DEFAULT 0, -- Track popularity
  rating DECIMAL(2, 1) DEFAULT 0, -- Average rating from users
  rating_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX idx_trip_templates_destination ON public.trip_templates(destination);
CREATE INDEX idx_trip_templates_category ON public.trip_templates(category);
CREATE INDEX idx_trip_templates_duration ON public.trip_templates(duration_days);
CREATE INDEX idx_trip_templates_active ON public.trip_templates(is_active);
CREATE INDEX idx_trip_templates_featured ON public.trip_templates(is_featured);

-- =====================================================
-- TEMPLATE ITINERARY ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.template_itinerary_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id UUID REFERENCES public.trip_templates(id) ON DELETE CASCADE NOT NULL,
  day_number INTEGER NOT NULL,
  order_index INTEGER NOT NULL DEFAULT 0,
  title TEXT NOT NULL,
  description TEXT,
  location TEXT,
  location_url TEXT, -- Google Maps URL
  start_time TIME, -- Suggested start time
  end_time TIME,
  duration_minutes INTEGER,
  category TEXT DEFAULT 'activity', -- activity, transport, food, accommodation, sightseeing
  estimated_cost DECIMAL(10, 2),
  tips TEXT, -- Local tips for this activity
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_template_itinerary_template ON public.template_itinerary_items(template_id);
CREATE INDEX idx_template_itinerary_day ON public.template_itinerary_items(template_id, day_number);

-- =====================================================
-- TEMPLATE CHECKLISTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.template_checklists (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id UUID REFERENCES public.trip_templates(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  icon TEXT DEFAULT 'checklist', -- Icon identifier
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_template_checklists_template ON public.template_checklists(template_id);

-- =====================================================
-- TEMPLATE CHECKLIST ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.template_checklist_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  checklist_id UUID REFERENCES public.template_checklists(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  order_index INTEGER NOT NULL DEFAULT 0,
  is_essential BOOLEAN DEFAULT false, -- Mark must-have items
  category TEXT, -- clothing, documents, electronics, toiletries, medicines, misc
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_template_checklist_items_checklist ON public.template_checklist_items(checklist_id);

-- =====================================================
-- AI USAGE TRACKING TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.user_ai_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  ai_generations_used INTEGER DEFAULT 0,
  ai_generations_limit INTEGER DEFAULT 5, -- Free tier limit
  is_premium BOOLEAN DEFAULT false,
  premium_plan TEXT, -- 'monthly', 'annual', null for free
  premium_started_at TIMESTAMPTZ,
  premium_expires_at TIMESTAMPTZ,
  lifetime_generations INTEGER DEFAULT 0, -- Total ever generated
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

CREATE INDEX idx_user_ai_usage_user ON public.user_ai_usage(user_id);
CREATE INDEX idx_user_ai_usage_premium ON public.user_ai_usage(is_premium);

-- =====================================================
-- AI GENERATION LOGS TABLE (For analytics)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.ai_generation_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  destination TEXT NOT NULL,
  duration_days INTEGER NOT NULL,
  budget DECIMAL(12, 2),
  interests TEXT[], -- User selected interests
  trip_id UUID REFERENCES public.trips(id) ON DELETE SET NULL, -- If applied to a trip
  generation_time_ms INTEGER, -- How long it took
  was_successful BOOLEAN DEFAULT true,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ai_generation_logs_user ON public.ai_generation_logs(user_id);
CREATE INDEX idx_ai_generation_logs_destination ON public.ai_generation_logs(destination);
CREATE INDEX idx_ai_generation_logs_date ON public.ai_generation_logs(created_at);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.trip_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_itinerary_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_ai_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_generation_logs ENABLE ROW LEVEL SECURITY;

-- Trip templates are public read
CREATE POLICY "Anyone can view active templates"
ON public.trip_templates FOR SELECT
USING (is_active = true);

-- Template itinerary items are public read
CREATE POLICY "Anyone can view template itinerary items"
ON public.template_itinerary_items FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.trip_templates
    WHERE trip_templates.id = template_itinerary_items.template_id
    AND trip_templates.is_active = true
  )
);

-- Template checklists are public read
CREATE POLICY "Anyone can view template checklists"
ON public.template_checklists FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.trip_templates
    WHERE trip_templates.id = template_checklists.template_id
    AND trip_templates.is_active = true
  )
);

-- Template checklist items are public read
CREATE POLICY "Anyone can view template checklist items"
ON public.template_checklist_items FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.template_checklists tc
    JOIN public.trip_templates t ON t.id = tc.template_id
    WHERE tc.id = template_checklist_items.checklist_id
    AND t.is_active = true
  )
);

-- Users can only see their own AI usage
CREATE POLICY "Users can view own AI usage"
ON public.user_ai_usage FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can insert own AI usage"
ON public.user_ai_usage FOR INSERT
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own AI usage"
ON public.user_ai_usage FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can only see their own generation logs
CREATE POLICY "Users can view own generation logs"
ON public.ai_generation_logs FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can insert own generation logs"
ON public.ai_generation_logs FOR INSERT
WITH CHECK (user_id = auth.uid());

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to get or create user AI usage record
CREATE OR REPLACE FUNCTION public.get_or_create_ai_usage(p_user_id UUID)
RETURNS public.user_ai_usage AS $$
DECLARE
  v_usage public.user_ai_usage;
BEGIN
  -- Try to get existing record
  SELECT * INTO v_usage
  FROM public.user_ai_usage
  WHERE user_id = p_user_id;

  -- If not found, create new record
  IF NOT FOUND THEN
    INSERT INTO public.user_ai_usage (user_id)
    VALUES (p_user_id)
    RETURNING * INTO v_usage;
  END IF;

  RETURN v_usage;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment AI usage
CREATE OR REPLACE FUNCTION public.increment_ai_usage(p_user_id UUID)
RETURNS public.user_ai_usage AS $$
DECLARE
  v_usage public.user_ai_usage;
BEGIN
  -- Get or create usage record
  SELECT * INTO v_usage FROM public.get_or_create_ai_usage(p_user_id);

  -- Update the usage count
  UPDATE public.user_ai_usage
  SET
    ai_generations_used = ai_generations_used + 1,
    lifetime_generations = lifetime_generations + 1,
    updated_at = NOW()
  WHERE user_id = p_user_id
  RETURNING * INTO v_usage;

  RETURN v_usage;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can generate AI itinerary
CREATE OR REPLACE FUNCTION public.can_generate_ai_itinerary(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_usage public.user_ai_usage;
BEGIN
  -- Get or create usage record
  SELECT * INTO v_usage FROM public.get_or_create_ai_usage(p_user_id);

  -- Premium users with valid subscription can always generate
  IF v_usage.is_premium AND v_usage.premium_expires_at > NOW() THEN
    RETURN true;
  END IF;

  -- Free users check against limit
  RETURN v_usage.ai_generations_used < v_usage.ai_generations_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get remaining AI generations
CREATE OR REPLACE FUNCTION public.get_remaining_ai_generations(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_usage public.user_ai_usage;
BEGIN
  -- Get or create usage record
  SELECT * INTO v_usage FROM public.get_or_create_ai_usage(p_user_id);

  -- Premium users get -1 (unlimited)
  IF v_usage.is_premium AND v_usage.premium_expires_at > NOW() THEN
    RETURN -1;
  END IF;

  -- Free users get remaining count
  RETURN GREATEST(0, v_usage.ai_generations_limit - v_usage.ai_generations_used);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment template use count
CREATE OR REPLACE FUNCTION public.increment_template_use_count(p_template_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.trip_templates
  SET use_count = use_count + 1
  WHERE id = p_template_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to apply template to trip
CREATE OR REPLACE FUNCTION public.apply_template_to_trip(
  p_template_id UUID,
  p_trip_id UUID,
  p_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_template public.trip_templates;
  v_itinerary_item RECORD;
  v_checklist RECORD;
  v_checklist_item RECORD;
  v_new_checklist_id UUID;
  v_trip_start_date DATE;
BEGIN
  -- Get template
  SELECT * INTO v_template
  FROM public.trip_templates
  WHERE id = p_template_id AND is_active = true;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  -- Get trip start date
  SELECT start_date::DATE INTO v_trip_start_date
  FROM public.trips
  WHERE id = p_trip_id;

  -- Copy itinerary items
  FOR v_itinerary_item IN
    SELECT * FROM public.template_itinerary_items
    WHERE template_id = p_template_id
    ORDER BY day_number, order_index
  LOOP
    INSERT INTO public.itinerary_items (
      trip_id,
      day_number,
      order_index,
      title,
      description,
      location,
      start_time,
      end_time,
      created_by
    ) VALUES (
      p_trip_id,
      v_itinerary_item.day_number,
      v_itinerary_item.order_index,
      v_itinerary_item.title,
      v_itinerary_item.description,
      v_itinerary_item.location,
      -- Convert time to timestamp using trip start date + day offset
      CASE WHEN v_itinerary_item.start_time IS NOT NULL
        THEN (v_trip_start_date + (v_itinerary_item.day_number - 1) * INTERVAL '1 day' + v_itinerary_item.start_time)::TIMESTAMPTZ
        ELSE NULL
      END,
      CASE WHEN v_itinerary_item.end_time IS NOT NULL
        THEN (v_trip_start_date + (v_itinerary_item.day_number - 1) * INTERVAL '1 day' + v_itinerary_item.end_time)::TIMESTAMPTZ
        ELSE NULL
      END,
      p_user_id
    );
  END LOOP;

  -- Copy checklists
  FOR v_checklist IN
    SELECT * FROM public.template_checklists
    WHERE template_id = p_template_id
    ORDER BY order_index
  LOOP
    INSERT INTO public.checklists (trip_id, name, created_by)
    VALUES (p_trip_id, v_checklist.name, p_user_id)
    RETURNING id INTO v_new_checklist_id;

    -- Copy checklist items
    FOR v_checklist_item IN
      SELECT * FROM public.template_checklist_items
      WHERE checklist_id = v_checklist.id
      ORDER BY order_index
    LOOP
      INSERT INTO public.checklist_items (checklist_id, content, is_completed)
      VALUES (v_new_checklist_id, v_checklist_item.content, false);
    END LOOP;
  END LOOP;

  -- Increment template use count
  PERFORM public.increment_template_use_count(p_template_id);

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.get_or_create_ai_usage TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_ai_usage TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_generate_ai_itinerary TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_remaining_ai_generations TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_template_use_count TO authenticated;
GRANT EXECUTE ON FUNCTION public.apply_template_to_trip TO authenticated;

-- =====================================================
-- SUMMARY
-- =====================================================
-- Tables created:
-- - trip_templates: Pre-built trip templates
-- - template_itinerary_items: Day-by-day activities for templates
-- - template_checklists: Packing lists for templates
-- - template_checklist_items: Items in template checklists
-- - user_ai_usage: Track AI generation usage per user
-- - ai_generation_logs: Log each AI generation for analytics
--
-- Functions created:
-- - get_or_create_ai_usage: Get/create user AI usage record
-- - increment_ai_usage: Increment user's AI usage count
-- - can_generate_ai_itinerary: Check if user can generate
-- - get_remaining_ai_generations: Get remaining free generations
-- - increment_template_use_count: Track template popularity
-- - apply_template_to_trip: Copy template to user's trip
-- =====================================================
