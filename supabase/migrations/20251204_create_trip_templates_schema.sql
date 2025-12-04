-- =====================================================
-- TRIP TEMPLATES DATABASE SCHEMA
-- =====================================================
-- Creates the tables for trip templates feature:
-- 1. trip_templates - Main template information
-- 2. template_itinerary_items - Day-by-day activities
-- 3. template_checklists - Packing list categories
-- 4. template_checklist_items - Individual checklist items
-- 5. ai_usage_tracking - Track AI itinerary generation usage
-- =====================================================

-- =====================================================
-- 1. TRIP TEMPLATES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.trip_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  destination TEXT NOT NULL,
  destination_state TEXT,
  duration_days INTEGER NOT NULL DEFAULT 1,
  budget_min DOUBLE PRECISION,
  budget_max DOUBLE PRECISION,
  currency TEXT NOT NULL DEFAULT 'INR',
  category TEXT NOT NULL DEFAULT 'adventure',
  tags TEXT[] DEFAULT '{}',
  best_season TEXT[] DEFAULT '{}',
  difficulty_level TEXT NOT NULL DEFAULT 'easy',
  cover_image_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_featured BOOLEAN NOT NULL DEFAULT false,
  use_count INTEGER NOT NULL DEFAULT 0,
  rating DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add comments
COMMENT ON TABLE public.trip_templates IS 'Pre-built trip templates that users can use as starting points';
COMMENT ON COLUMN public.trip_templates.category IS 'Template category: adventure, beach, heritage, family, pilgrimage, wildlife, hillStation, roadTrip, weekend';
COMMENT ON COLUMN public.trip_templates.difficulty_level IS 'Trip difficulty: easy, moderate, difficult';
COMMENT ON COLUMN public.trip_templates.best_season IS 'Array of months when this trip is best (e.g., October, November)';

-- Index for efficient queries
CREATE INDEX IF NOT EXISTS idx_trip_templates_category ON public.trip_templates(category);
CREATE INDEX IF NOT EXISTS idx_trip_templates_is_active ON public.trip_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_trip_templates_is_featured ON public.trip_templates(is_featured);
CREATE INDEX IF NOT EXISTS idx_trip_templates_destination ON public.trip_templates(destination);

-- =====================================================
-- 2. TEMPLATE ITINERARY ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.template_itinerary_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES public.trip_templates(id) ON DELETE CASCADE,
  day_number INTEGER NOT NULL,
  order_index INTEGER NOT NULL DEFAULT 0,
  title TEXT NOT NULL,
  description TEXT,
  location TEXT,
  location_url TEXT,
  start_time TEXT, -- HH:mm format
  end_time TEXT,
  duration_minutes INTEGER,
  category TEXT NOT NULL DEFAULT 'activity',
  estimated_cost DOUBLE PRECISION,
  tips TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.template_itinerary_items IS 'Day-by-day itinerary items for templates';
COMMENT ON COLUMN public.template_itinerary_items.category IS 'Item category: activity, transport, food, accommodation, sightseeing';

CREATE INDEX IF NOT EXISTS idx_template_itinerary_template_id ON public.template_itinerary_items(template_id);
CREATE INDEX IF NOT EXISTS idx_template_itinerary_day ON public.template_itinerary_items(template_id, day_number);

-- =====================================================
-- 3. TEMPLATE CHECKLISTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.template_checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES public.trip_templates(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.template_checklists IS 'Packing checklist categories for templates';

CREATE INDEX IF NOT EXISTS idx_template_checklists_template_id ON public.template_checklists(template_id);

-- =====================================================
-- 4. TEMPLATE CHECKLIST ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.template_checklist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_id UUID NOT NULL REFERENCES public.template_checklists(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  order_index INTEGER NOT NULL DEFAULT 0,
  is_essential BOOLEAN NOT NULL DEFAULT false,
  category TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.template_checklist_items IS 'Individual items in template checklists';
COMMENT ON COLUMN public.template_checklist_items.is_essential IS 'Whether this item is essential/must-have';
COMMENT ON COLUMN public.template_checklist_items.category IS 'Item category: clothing, toiletries, electronics, documents, misc';

CREATE INDEX IF NOT EXISTS idx_template_checklist_items_checklist_id ON public.template_checklist_items(checklist_id);

-- =====================================================
-- 5. AI USAGE TRACKING TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.ai_usage_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  feature TEXT NOT NULL DEFAULT 'itinerary_generation',
  usage_count INTEGER NOT NULL DEFAULT 0,
  last_used_at TIMESTAMPTZ,
  monthly_limit INTEGER NOT NULL DEFAULT 5,
  is_premium BOOLEAN NOT NULL DEFAULT false,
  premium_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, feature)
);

COMMENT ON TABLE public.ai_usage_tracking IS 'Tracks AI feature usage per user for freemium model';
COMMENT ON COLUMN public.ai_usage_tracking.monthly_limit IS 'Free tier monthly limit (default 5)';
COMMENT ON COLUMN public.ai_usage_tracking.is_premium IS 'Whether user has premium subscription';

CREATE INDEX IF NOT EXISTS idx_ai_usage_user_id ON public.ai_usage_tracking(user_id);

-- =====================================================
-- 6. AI GENERATION LOGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.ai_generation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  feature TEXT NOT NULL DEFAULT 'itinerary_generation',
  request_data JSONB,
  response_summary TEXT,
  tokens_used INTEGER,
  generation_time_ms INTEGER,
  was_successful BOOLEAN NOT NULL DEFAULT true,
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.ai_generation_logs IS 'Logs of AI generation requests for analytics and debugging';

CREATE INDEX IF NOT EXISTS idx_ai_logs_user_id ON public.ai_generation_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_logs_created_at ON public.ai_generation_logs(created_at);

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.trip_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_itinerary_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_usage_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_generation_logs ENABLE ROW LEVEL SECURITY;

-- Trip Templates: Everyone can read active templates
CREATE POLICY "Anyone can read active templates"
  ON public.trip_templates
  FOR SELECT
  USING (is_active = true);

-- Template Itinerary Items: Everyone can read
CREATE POLICY "Anyone can read template itinerary items"
  ON public.template_itinerary_items
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.trip_templates t
    WHERE t.id = template_id AND t.is_active = true
  ));

-- Template Checklists: Everyone can read
CREATE POLICY "Anyone can read template checklists"
  ON public.template_checklists
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.trip_templates t
    WHERE t.id = template_id AND t.is_active = true
  ));

-- Template Checklist Items: Everyone can read
CREATE POLICY "Anyone can read template checklist items"
  ON public.template_checklist_items
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.template_checklists c
    JOIN public.trip_templates t ON t.id = c.template_id
    WHERE c.id = checklist_id AND t.is_active = true
  ));

-- AI Usage Tracking: Users can only access their own data
CREATE POLICY "Users can read own AI usage"
  ON public.ai_usage_tracking
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own AI usage"
  ON public.ai_usage_tracking
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own AI usage"
  ON public.ai_usage_tracking
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- AI Generation Logs: Users can only access their own logs
CREATE POLICY "Users can read own AI logs"
  ON public.ai_generation_logs
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own AI logs"
  ON public.ai_generation_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to increment template use count
CREATE OR REPLACE FUNCTION public.increment_template_use_count(p_template_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.trip_templates
  SET use_count = use_count + 1,
      updated_at = NOW()
  WHERE id = p_template_id;
END;
$$;

-- Function to get or create AI usage record
CREATE OR REPLACE FUNCTION public.get_or_create_ai_usage(p_user_id UUID, p_feature TEXT DEFAULT 'itinerary_generation')
RETURNS public.ai_usage_tracking
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_usage public.ai_usage_tracking;
BEGIN
  -- Try to get existing record
  SELECT * INTO v_usage
  FROM public.ai_usage_tracking
  WHERE user_id = p_user_id AND feature = p_feature;

  -- If not found, create new record
  IF v_usage IS NULL THEN
    INSERT INTO public.ai_usage_tracking (user_id, feature, usage_count, monthly_limit)
    VALUES (p_user_id, p_feature, 0, 5)
    RETURNING * INTO v_usage;
  END IF;

  RETURN v_usage;
END;
$$;

-- Function to increment AI usage and check limit
CREATE OR REPLACE FUNCTION public.increment_ai_usage(p_user_id UUID, p_feature TEXT DEFAULT 'itinerary_generation')
RETURNS TABLE (
  can_use BOOLEAN,
  current_count INTEGER,
  monthly_limit INTEGER,
  is_premium BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_usage public.ai_usage_tracking;
  v_can_use BOOLEAN;
BEGIN
  -- Get or create usage record
  SELECT * INTO v_usage FROM public.get_or_create_ai_usage(p_user_id, p_feature);

  -- Reset count if new month (simple monthly reset)
  IF v_usage.last_used_at IS NOT NULL AND
     date_trunc('month', v_usage.last_used_at) < date_trunc('month', NOW()) THEN
    UPDATE public.ai_usage_tracking
    SET usage_count = 0
    WHERE id = v_usage.id;
    v_usage.usage_count := 0;
  END IF;

  -- Check if can use
  v_can_use := v_usage.is_premium OR (v_usage.usage_count < v_usage.monthly_limit);

  -- Increment if allowed
  IF v_can_use THEN
    UPDATE public.ai_usage_tracking
    SET usage_count = usage_count + 1,
        last_used_at = NOW(),
        updated_at = NOW()
    WHERE id = v_usage.id
    RETURNING usage_count INTO v_usage.usage_count;
  END IF;

  RETURN QUERY SELECT v_can_use, v_usage.usage_count, v_usage.monthly_limit, v_usage.is_premium;
END;
$$;

-- Function to log AI generation
CREATE OR REPLACE FUNCTION public.log_ai_generation(
  p_user_id UUID,
  p_feature TEXT,
  p_request_data JSONB,
  p_response_summary TEXT,
  p_tokens_used INTEGER DEFAULT NULL,
  p_generation_time_ms INTEGER DEFAULT NULL,
  p_was_successful BOOLEAN DEFAULT true,
  p_error_message TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO public.ai_generation_logs (
    user_id, feature, request_data, response_summary,
    tokens_used, generation_time_ms, was_successful, error_message
  ) VALUES (
    p_user_id, p_feature, p_request_data, p_response_summary,
    p_tokens_used, p_generation_time_ms, p_was_successful, p_error_message
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$;

-- Function to check if user can generate AI itinerary
CREATE OR REPLACE FUNCTION public.can_generate_ai_itinerary(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_usage public.ai_usage_tracking;
BEGIN
  -- Get or create usage record
  SELECT * INTO v_usage FROM public.get_or_create_ai_usage(p_user_id, 'itinerary_generation');

  -- Reset count if new month
  IF v_usage.last_used_at IS NOT NULL AND
     date_trunc('month', v_usage.last_used_at) < date_trunc('month', NOW()) THEN
    UPDATE public.ai_usage_tracking
    SET usage_count = 0
    WHERE id = v_usage.id;
    RETURN true;
  END IF;

  -- Premium users always can generate
  IF v_usage.is_premium THEN
    RETURN true;
  END IF;

  -- Free users check monthly limit
  RETURN v_usage.usage_count < v_usage.monthly_limit;
END;
$$;

-- Function to get remaining AI generations
CREATE OR REPLACE FUNCTION public.get_remaining_ai_generations(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_usage public.ai_usage_tracking;
BEGIN
  -- Get or create usage record
  SELECT * INTO v_usage FROM public.get_or_create_ai_usage(p_user_id, 'itinerary_generation');

  -- Reset count if new month
  IF v_usage.last_used_at IS NOT NULL AND
     date_trunc('month', v_usage.last_used_at) < date_trunc('month', NOW()) THEN
    UPDATE public.ai_usage_tracking
    SET usage_count = 0
    WHERE id = v_usage.id;
    v_usage.usage_count := 0;
  END IF;

  -- Premium users return -1 (unlimited)
  IF v_usage.is_premium THEN
    RETURN -1;
  END IF;

  -- Free users return remaining count
  RETURN GREATEST(0, v_usage.monthly_limit - v_usage.usage_count);
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.increment_template_use_count TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_ai_usage TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_ai_usage TO authenticated;
GRANT EXECUTE ON FUNCTION public.log_ai_generation TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_generate_ai_itinerary TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_remaining_ai_generations TO authenticated;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to trip_templates
DROP TRIGGER IF EXISTS update_trip_templates_updated_at ON public.trip_templates;
CREATE TRIGGER update_trip_templates_updated_at
  BEFORE UPDATE ON public.trip_templates
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Apply trigger to ai_usage_tracking
DROP TRIGGER IF EXISTS update_ai_usage_updated_at ON public.ai_usage_tracking;
CREATE TRIGGER update_ai_usage_updated_at
  BEFORE UPDATE ON public.ai_usage_tracking
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================================
-- SUMMARY
-- =====================================================
-- Created tables:
-- 1. trip_templates - Main template storage
-- 2. template_itinerary_items - Day activities
-- 3. template_checklists - Checklist categories
-- 4. template_checklist_items - Checklist items
-- 5. ai_usage_tracking - Freemium usage tracking
-- 6. ai_generation_logs - AI request logs
--
-- Created functions:
-- - increment_template_use_count
-- - get_or_create_ai_usage
-- - increment_ai_usage
-- - log_ai_generation
-- =====================================================
