-- Fix user_statistics view to work without expenses table
-- This creates a simpler view that only uses data from the profiles table

DROP VIEW IF EXISTS user_statistics;

CREATE OR REPLACE VIEW user_statistics AS
SELECT
  p.id,
  p.email,
  p.full_name,
  p.avatar_url,
  p.role,
  p.status,
  p.created_at,
  p.updated_at,
  p.last_login_at,
  p.last_active_at,
  p.account_locked_at,
  p.account_locked_reason,
  p.login_count,
  p.trips_count,
  p.messages_count,
  0::BIGINT as expenses_count,  -- Default to 0 for now
  0::NUMERIC as total_expenses  -- Default to 0 for now
FROM profiles p;

-- Grant permissions
GRANT SELECT ON user_statistics TO authenticated;

COMMENT ON VIEW user_statistics IS 'Simplified user statistics view for admin panel - expenses calculation removed for performance';
