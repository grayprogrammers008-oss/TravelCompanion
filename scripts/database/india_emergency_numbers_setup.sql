-- ============================================
-- INDIA EMERGENCY NUMBERS SETUP
-- ============================================
-- This script creates the emergency_numbers table
-- and populates it with India-specific emergency services
--
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. DROP EXISTING TABLE (if exists)
-- ============================================
DROP TABLE IF EXISTS emergency_numbers CASCADE;

-- ============================================
-- 2. CREATE EMERGENCY NUMBERS TABLE
-- ============================================
CREATE TABLE emergency_numbers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Basic Information
  service_name VARCHAR(100) NOT NULL,
  service_type VARCHAR(50) NOT NULL, -- 'police', 'fire', 'ambulance', 'helpline', 'disaster', 'other'
  phone_number VARCHAR(20) NOT NULL,
  alternate_number VARCHAR(20),

  -- Location Information
  country VARCHAR(2) NOT NULL DEFAULT 'IN', -- ISO country code
  state VARCHAR(100), -- Specific state if applicable (NULL for national)
  city VARCHAR(100), -- Specific city if applicable (NULL for national/state)

  -- Service Details
  description TEXT,
  is_toll_free BOOLEAN DEFAULT FALSE,
  is_24_7 BOOLEAN DEFAULT TRUE,
  languages JSON, -- ['en', 'hi', 'ta', etc.]

  -- Display Information
  icon VARCHAR(50), -- Icon name for UI
  color VARCHAR(7), -- Hex color code for UI
  display_order INTEGER DEFAULT 0, -- For sorting in UI
  is_active BOOLEAN DEFAULT TRUE,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. CREATE INDEXES
-- ============================================
CREATE INDEX idx_emergency_numbers_country ON emergency_numbers(country);
CREATE INDEX idx_emergency_numbers_service_type ON emergency_numbers(service_type);
CREATE INDEX idx_emergency_numbers_state ON emergency_numbers(state);
CREATE INDEX idx_emergency_numbers_city ON emergency_numbers(city);
CREATE INDEX idx_emergency_numbers_is_active ON emergency_numbers(is_active);
CREATE INDEX idx_emergency_numbers_display_order ON emergency_numbers(display_order);

-- ============================================
-- 4. ENABLE ROW LEVEL SECURITY
-- ============================================
ALTER TABLE emergency_numbers ENABLE ROW LEVEL SECURITY;

-- Allow public read access to emergency numbers
CREATE POLICY "Emergency numbers are viewable by everyone"
  ON emergency_numbers FOR SELECT
  USING (is_active = TRUE);

-- ============================================
-- 5. INSERT INDIA EMERGENCY NUMBERS
-- ============================================

-- National Emergency Services
INSERT INTO emergency_numbers (
  service_name, service_type, phone_number, alternate_number,
  country, description, is_toll_free, is_24_7, languages,
  icon, color, display_order
) VALUES
  -- Primary Emergency Services
  (
    'Police',
    'police',
    '100',
    '112',
    'IN',
    'National police emergency helpline for reporting crimes, accidents, and requesting immediate police assistance.',
    TRUE,
    TRUE,
    '["en", "hi", "ta", "te", "kn", "ml", "mr", "gu", "bn", "or"]'::JSON,
    'local_police',
    '#1976D2',
    1
  ),
  (
    'Fire Brigade',
    'fire',
    '101',
    '112',
    'IN',
    'National fire emergency service for reporting fires, building collapses, and requesting fire rescue assistance.',
    TRUE,
    TRUE,
    '["en", "hi", "ta", "te", "kn", "ml", "mr", "gu", "bn", "or"]'::JSON,
    'local_fire_department',
    '#D32F2F',
    2
  ),
  (
    'Ambulance',
    'ambulance',
    '102',
    '112',
    'IN',
    'National ambulance service for medical emergencies, accidents, and urgent patient transport.',
    TRUE,
    TRUE,
    '["en", "hi", "ta", "te", "kn", "ml", "mr", "gu", "bn", "or"]'::JSON,
    'local_hospital',
    '#E53935',
    3
  ),
  (
    'Emergency (Unified)',
    'emergency',
    '112',
    NULL,
    'IN',
    'Unified emergency number for police, fire, ambulance, and other emergency services. Works even without SIM card.',
    TRUE,
    TRUE,
    '["en", "hi", "ta", "te", "kn", "ml", "mr", "gu", "bn", "or"]'::JSON,
    'emergency',
    '#C62828',
    0
  ),

  -- Medical Emergency Services
  (
    'Disaster Management',
    'disaster',
    '108',
    '112',
    'IN',
    'National Disaster Management helpline for natural disasters, accidents, and mass casualty incidents.',
    TRUE,
    TRUE,
    '["en", "hi", "ta", "te", "kn", "ml", "mr", "gu", "bn", "or"]'::JSON,
    'warning',
    '#F57C00',
    4
  ),

  -- Women & Child Safety
  (
    'Women Helpline',
    'helpline',
    '1091',
    '112',
    'IN',
    'National helpline for women in distress, domestic violence, harassment, and women safety issues.',
    TRUE,
    TRUE,
    '["en", "hi", "ta", "te", "kn", "ml", "mr", "gu", "bn", "or"]'::JSON,
    'support',
    '#AD1457',
    5
  ),
  (
    'Women Helpline (Domestic Abuse)',
    'helpline',
    '181',
    '1091',
    'IN',
    'Helpline for women facing domestic abuse, violence, and harassment. Provides counseling and support.',
    TRUE,
    TRUE,
    '["en", "hi", "ta", "te", "kn", "ml", "mr", "gu", "bn", "or"]'::JSON,
    'support',
    '#C2185B',
    6
  ),
  (
    'Child Helpline',
    'helpline',
    '1098',
    NULL,
    'IN',
    'National helpline for children in need of care and protection, child abuse, missing children.',
    TRUE,
    TRUE,
    '["en", "hi", "ta", "te", "kn", "ml", "mr", "gu", "bn", "or"]'::JSON,
    'child_care',
    '#7B1FA2',
    7
  ),

  -- Mental Health & Crisis
  (
    'Mental Health Helpline',
    'helpline',
    '9152987821',
    NULL,
    'IN',
    'Vandrevala Foundation mental health helpline for depression, anxiety, suicide prevention, and emotional support.',
    FALSE,
    TRUE,
    '["en", "hi", "ta", "te", "kn", "ml", "mr", "gu", "bn", "or"]'::JSON,
    'psychology',
    '#512DA8',
    8
  ),
  (
    'Senior Citizens Helpline',
    'helpline',
    '14567',
    '1291',
    'IN',
    'Elder helpline for senior citizens in distress, abuse, health emergencies, and support services.',
    TRUE,
    TRUE,
    '["en", "hi", "ta", "te", "kn", "ml", "mr", "gu", "bn", "or"]'::JSON,
    'elderly',
    '#5E35B1',
    9
  ),

  -- Railway & Transport
  (
    'Railway Police',
    'police',
    '182',
    '112',
    'IN',
    'Railway Protection Force helpline for railway-related emergencies, crimes, and passenger safety.',
    TRUE,
    TRUE,
    '["en", "hi", "ta", "te", "kn", "ml", "mr", "gu", "bn", "or"]'::JSON,
    'train',
    '#303F9F',
    10
  ),
  (
    'Road Accident Emergency',
    'emergency',
    '1073',
    '112',
    'IN',
    'National highway authority helpline for road accidents, breakdowns, and highway emergencies.',
    TRUE,
    TRUE,
    '["en", "hi"]'::JSON,
    'car_crash',
    '#F57F17',
    11
  ),

  -- Consumer & Utility Services
  (
    'Tourist Helpline',
    'helpline',
    '1363',
    NULL,
    'IN',
    'Ministry of Tourism helpline for tourist assistance, complaints, and emergency support for travelers.',
    TRUE,
    TRUE,
    '["en", "hi"]'::JSON,
    'travel_explore',
    '#00796B',
    12
  ),
  (
    'Cyber Crime Helpline',
    'police',
    '1930',
    NULL,
    'IN',
    'National cyber crime helpline for reporting cyber fraud, online harassment, and digital crimes.',
    TRUE,
    TRUE,
    '["en", "hi"]'::JSON,
    'security',
    '#0288D1',
    13
  ),
  (
    'Anti-Corruption Helpline',
    'helpline',
    '1031',
    NULL,
    'IN',
    'Central Vigilance Commission helpline for reporting corruption, bribery, and government misconduct.',
    TRUE,
    FALSE,
    '["en", "hi"]'::JSON,
    'gavel',
    '#00695C',
    14
  ),
  (
    'Consumer Helpline',
    'helpline',
    '1800-11-4000',
    '14404',
    'IN',
    'National consumer helpline for complaints about products, services, and consumer rights.',
    TRUE,
    FALSE,
    '["en", "hi", "ta", "te", "kn", "ml"]'::JSON,
    'shopping_cart',
    '#0097A7',
    15
  );

-- ============================================
-- 6. CREATE HELPER FUNCTIONS
-- ============================================

-- Function to get emergency numbers by service type
CREATE OR REPLACE FUNCTION get_emergency_numbers_by_type(
  p_service_type VARCHAR,
  p_country VARCHAR DEFAULT 'IN'
)
RETURNS TABLE (
  id UUID,
  service_name VARCHAR,
  service_type VARCHAR,
  phone_number VARCHAR,
  alternate_number VARCHAR,
  description TEXT,
  icon VARCHAR,
  color VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    en.id,
    en.service_name,
    en.service_type,
    en.phone_number,
    en.alternate_number,
    en.description,
    en.icon,
    en.color
  FROM emergency_numbers en
  WHERE en.service_type = p_service_type
    AND en.country = p_country
    AND en.is_active = TRUE
  ORDER BY en.display_order ASC;
END;
$$ LANGUAGE plpgsql;

-- Function to get all active emergency numbers for a country
CREATE OR REPLACE FUNCTION get_all_emergency_numbers(
  p_country VARCHAR DEFAULT 'IN'
)
RETURNS TABLE (
  id UUID,
  service_name VARCHAR,
  service_type VARCHAR,
  phone_number VARCHAR,
  alternate_number VARCHAR,
  description TEXT,
  is_toll_free BOOLEAN,
  is_24_7 BOOLEAN,
  icon VARCHAR,
  color VARCHAR,
  display_order INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    en.id,
    en.service_name,
    en.service_type,
    en.phone_number,
    en.alternate_number,
    en.description,
    en.is_toll_free,
    en.is_24_7,
    en.icon,
    en.color,
    en.display_order
  FROM emergency_numbers en
  WHERE en.country = p_country
    AND en.is_active = TRUE
  ORDER BY en.display_order ASC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. CREATE UPDATE TRIGGER
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_emergency_numbers_updated_at
  BEFORE UPDATE ON emergency_numbers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 8. VERIFICATION QUERIES
-- ============================================

-- Count total emergency numbers
SELECT COUNT(*) as total_emergency_numbers FROM emergency_numbers;

-- Count by service type
SELECT service_type, COUNT(*) as count
FROM emergency_numbers
GROUP BY service_type
ORDER BY count DESC;

-- List all emergency numbers
SELECT service_name, service_type, phone_number, is_24_7, is_toll_free
FROM emergency_numbers
ORDER BY display_order;

-- Test helper functions
SELECT * FROM get_all_emergency_numbers('IN');
SELECT * FROM get_emergency_numbers_by_type('police', 'IN');

-- ============================================
-- SETUP COMPLETE
-- ============================================
-- ✓ Table created: emergency_numbers
-- ✓ Indexes created for performance
-- ✓ RLS policies enabled
-- ✓ 15 India emergency numbers inserted
-- ✓ Helper functions created
-- ✓ Update triggers enabled
-- ============================================
