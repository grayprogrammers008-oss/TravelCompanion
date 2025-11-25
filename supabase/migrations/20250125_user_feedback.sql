-- User Feedback Feature
-- Allows users to submit feedback and admins to review/manage it
-- Created: January 25, 2025

-- Create feedback_type enum
CREATE TYPE feedback_type AS ENUM (
  'bug_report',
  'feature_request',
  'general_feedback',
  'improvement_suggestion',
  'complaint'
);

-- Create feedback_status enum
CREATE TYPE feedback_status AS ENUM (
  'pending',
  'in_review',
  'resolved',
  'dismissed'
);

-- Create user_feedback table
CREATE TABLE IF NOT EXISTS public.user_feedback (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type feedback_type NOT NULL DEFAULT 'general_feedback',
  subject TEXT,
  message TEXT NOT NULL,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  status feedback_status NOT NULL DEFAULT 'pending',
  admin_notes TEXT,
  resolved_by UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT message_length CHECK (char_length(message) >= 10 AND char_length(message) <= 2000),
  CONSTRAINT subject_length CHECK (subject IS NULL OR (char_length(subject) >= 3 AND char_length(subject) <= 200))
);

-- Create indexes for better performance
CREATE INDEX idx_user_feedback_user_id ON public.user_feedback(user_id);
CREATE INDEX idx_user_feedback_status ON public.user_feedback(status);
CREATE INDEX idx_user_feedback_type ON public.user_feedback(type);
CREATE INDEX idx_user_feedback_created_at ON public.user_feedback(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.user_feedback ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users can view their own feedback
CREATE POLICY "Users can view their own feedback"
  ON public.user_feedback
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Users can insert their own feedback
CREATE POLICY "Users can insert their own feedback"
  ON public.user_feedback
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own pending feedback
CREATE POLICY "Users can update their own pending feedback"
  ON public.user_feedback
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id AND status = 'pending')
  WITH CHECK (auth.uid() = user_id AND status = 'pending');

-- Admins can view all feedback
CREATE POLICY "Admins can view all feedback"
  ON public.user_feedback
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'super_admin')
    )
  );

-- Admins can update all feedback
CREATE POLICY "Admins can update all feedback"
  ON public.user_feedback
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'super_admin')
    )
  );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_user_feedback_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_user_feedback_updated_at
  BEFORE UPDATE ON public.user_feedback
  FOR EACH ROW
  EXECUTE FUNCTION public.update_user_feedback_updated_at();

-- Create view for admin feedback dashboard
CREATE OR REPLACE VIEW public.admin_feedback_stats AS
SELECT
  COUNT(*) as total_feedback,
  COUNT(*) FILTER (WHERE status = 'pending') as pending_count,
  COUNT(*) FILTER (WHERE status = 'in_review') as in_review_count,
  COUNT(*) FILTER (WHERE status = 'resolved') as resolved_count,
  COUNT(*) FILTER (WHERE status = 'dismissed') as dismissed_count,
  COUNT(*) FILTER (WHERE type = 'bug_report') as bug_reports_count,
  COUNT(*) FILTER (WHERE type = 'feature_request') as feature_requests_count,
  AVG(rating) FILTER (WHERE rating IS NOT NULL) as average_rating,
  COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days') as feedback_this_week,
  COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') as feedback_this_month
FROM public.user_feedback;

-- Grant permissions
GRANT SELECT ON public.admin_feedback_stats TO authenticated;

-- Function to get user feedback with user details (for admin)
CREATE OR REPLACE FUNCTION public.get_all_feedback_admin(
  p_status feedback_status DEFAULT NULL,
  p_type feedback_type DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  user_name TEXT,
  user_email TEXT,
  user_avatar_url TEXT,
  type feedback_type,
  subject TEXT,
  message TEXT,
  rating INTEGER,
  status feedback_status,
  admin_notes TEXT,
  resolved_by UUID,
  resolved_by_name TEXT,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    f.id,
    f.user_id,
    p.full_name as user_name,
    p.email as user_email,
    p.avatar_url as user_avatar_url,
    f.type,
    f.subject,
    f.message,
    f.rating,
    f.status,
    f.admin_notes,
    f.resolved_by,
    rp.full_name as resolved_by_name,
    f.resolved_at,
    f.created_at,
    f.updated_at
  FROM public.user_feedback f
  JOIN public.profiles p ON f.user_id = p.id
  LEFT JOIN public.profiles rp ON f.resolved_by = rp.id
  WHERE (p_status IS NULL OR f.status = p_status)
    AND (p_type IS NULL OR f.type = p_type)
  ORDER BY f.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_all_feedback_admin TO authenticated;

-- Function to submit feedback (for users)
CREATE OR REPLACE FUNCTION public.submit_feedback(
  p_type feedback_type,
  p_subject TEXT,
  p_message TEXT,
  p_rating INTEGER DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_feedback_id UUID;
BEGIN
  INSERT INTO public.user_feedback (
    user_id,
    type,
    subject,
    message,
    rating,
    status
  ) VALUES (
    auth.uid(),
    p_type,
    p_subject,
    p_message,
    p_rating,
    'pending'
  )
  RETURNING id INTO v_feedback_id;

  RETURN v_feedback_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.submit_feedback TO authenticated;

-- Function to update feedback status (admin only)
CREATE OR REPLACE FUNCTION public.update_feedback_status(
  p_feedback_id UUID,
  p_status feedback_status,
  p_admin_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  -- Check if user is admin
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role IN ('admin', 'super_admin')
  ) INTO v_is_admin;

  IF NOT v_is_admin THEN
    RAISE EXCEPTION 'Only admins can update feedback status';
  END IF;

  UPDATE public.user_feedback
  SET
    status = p_status,
    admin_notes = COALESCE(p_admin_notes, admin_notes),
    resolved_by = CASE WHEN p_status IN ('resolved', 'dismissed') THEN auth.uid() ELSE resolved_by END,
    resolved_at = CASE WHEN p_status IN ('resolved', 'dismissed') THEN NOW() ELSE resolved_at END
  WHERE id = p_feedback_id;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.update_feedback_status TO authenticated;

-- Insert some sample feedback for testing (optional - remove in production)
-- INSERT INTO public.user_feedback (user_id, type, subject, message, rating, status)
-- SELECT
--   id as user_id,
--   'feature_request' as type,
--   'Sample Feedback' as subject,
--   'This is a sample feedback for testing purposes.' as message,
--   5 as rating,
--   'pending' as status
-- FROM auth.users
-- LIMIT 1;

-- Add comment
COMMENT ON TABLE public.user_feedback IS 'Stores user feedback, bug reports, and feature requests';
COMMENT ON COLUMN public.user_feedback.type IS 'Type of feedback: bug_report, feature_request, general_feedback, improvement_suggestion, complaint';
COMMENT ON COLUMN public.user_feedback.status IS 'Current status: pending, in_review, resolved, dismissed';
COMMENT ON COLUMN public.user_feedback.rating IS 'Optional rating from 1-5 stars';
