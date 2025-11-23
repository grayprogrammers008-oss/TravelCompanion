-- ============================================
-- HOSPITALS SAMPLE DATA - 15 US HOSPITALS
-- ============================================
-- Run this AFTER hospitals_setup_no_postgis.sql
-- Inserts 15 realistic hospitals across major US cities
-- ============================================

-- Clear any existing test data (optional)
-- DELETE FROM hospitals WHERE is_verified = FALSE;

-- ============================================
-- INSERT 15 SAMPLE HOSPITALS
-- ============================================
-- 1. Mount Sinai Hospital - New York, NY
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website, email,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7, opening_hours,
  services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'Mount Sinai Hospital',
  '1468 Madison Avenue',
  'New York',
  'NY',
  'USA',
  '10029',
  40.7903,
  -73.9525,
  '+1-212-241-6500',
  '+1-212-241-7171',
  'https://www.mountsinai.org',
  'info@mountsinai.org',
  'trauma_center',
  1200,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  '{}',
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Pediatrics', 'Surgery'],
  ARRAY['Heart Disease', 'Cancer Treatment', 'Neurosurgery', 'Trauma Care'],
  4.5,
  3254,
  TRUE,
  TRUE
);

-- 2. NewYork-Presbyterian Hospital - New York, NY
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7, services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'NewYork-Presbyterian Hospital',
  '525 East 68th Street',
  'New York',
  'NY',
  'USA',
  '10065',
  40.7649,
  -73.9540,
  '+1-212-746-5454',
  '+1-212-746-0911',
  'https://www.nyp.org',
  'trauma_center',
  2600,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Orthopedics', 'Transplant'],
  ARRAY['Heart Surgery', 'Brain Surgery', 'Organ Transplant'],
  4.7,
  5821,
  TRUE,
  TRUE
);

-- 3. Cedars-Sinai Medical Center - Los Angeles, CA
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7, services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'Cedars-Sinai Medical Center',
  '8700 Beverly Boulevard',
  'Los Angeles',
  'CA',
  'USA',
  '90048',
  34.0755,
  -118.3775,
  '+1-310-423-3277',
  '+1-310-423-8780',
  'https://www.cedars-sinai.org',
  'trauma_center',
  900,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Gastroenterology'],
  ARRAY['Heart Disease', 'Cancer Treatment', 'Digestive Disorders'],
  4.6,
  4532,
  TRUE,
  TRUE
);

-- 4. UCLA Medical Center - Los Angeles, CA
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7, services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'UCLA Medical Center',
  '757 Westwood Plaza',
  'Los Angeles',
  'CA',
  'USA',
  '90095',
  34.0681,
  -118.4453,
  '+1-310-825-9111',
  '+1-310-825-2111',
  'https://www.uclahealth.org',
  'trauma_center',
  520,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Oncology', 'Neurology', 'Transplant', 'Pediatrics'],
  ARRAY['Cancer Treatment', 'Brain Surgery', 'Kidney Transplant'],
  4.8,
  6234,
  TRUE,
  TRUE
);

-- 5. Massachusetts General Hospital - Boston, MA
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7, services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'Massachusetts General Hospital',
  '55 Fruit Street',
  'Boston',
  'MA',
  'USA',
  '02114',
  42.3631,
  -71.0686,
  '+1-617-726-2000',
  '+1-617-726-5656',
  'https://www.massgeneral.org',
  'trauma_center',
  1050,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Orthopedics', 'Research'],
  ARRAY['Heart Disease', 'Cancer Research', 'Neurosurgery'],
  4.9,
  7421,
  TRUE,
  TRUE
);

-- 6. Mayo Clinic - Rochester, MN
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7, services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'Mayo Clinic',
  '200 First Street SW',
  'Rochester',
  'MN',
  'USA',
  '55905',
  44.0225,
  -92.4662,
  '+1-507-284-2511',
  '+1-507-255-2000',
  'https://www.mayoclinic.org',
  'specialized',
  2059,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Transplant', 'Research'],
  ARRAY['Heart Surgery', 'Cancer Treatment', 'Complex Diagnostics'],
  4.9,
  9876,
  TRUE,
  TRUE
);

-- 7. Cleveland Clinic - Cleveland, OH
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, accepts_ambulance,
  is_24_7, services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'Cleveland Clinic',
  '9500 Euclid Avenue',
  'Cleveland',
  'OH',
  'USA',
  '44195',
  41.5034,
  -81.6198,
  '+1-216-444-2200',
  '+1-216-444-6677',
  'https://www.clevelandclinic.org',
  'specialized',
  1400,
  TRUE,
  TRUE,
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Orthopedics', 'Urology'],
  ARRAY['Heart Surgery', 'Brain Surgery', 'Joint Replacement'],
  4.7,
  5643,
  TRUE,
  TRUE
);

-- 8. Johns Hopkins Hospital - Baltimore, MD
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7, services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'Johns Hopkins Hospital',
  '1800 Orleans Street',
  'Baltimore',
  'MD',
  'USA',
  '21287',
  39.2971,
  -76.5929,
  '+1-410-955-5000',
  '+1-410-955-5080',
  'https://www.hopkinsmedicine.org',
  'trauma_center',
  1154,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Oncology', 'Neurology', 'Cardiology', 'Pediatrics', 'Research'],
  ARRAY['Cancer Research', 'Neurosurgery', 'Children''s Hospital'],
  4.8,
  6754,
  TRUE,
  TRUE
);

-- 9. Northwestern Memorial Hospital - Chicago, IL
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7, services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'Northwestern Memorial Hospital',
  '251 East Huron Street',
  'Chicago',
  'IL',
  'USA',
  '60611',
  41.8956,
  -87.6209,
  '+1-312-926-2000',
  '+1-312-926-5188',
  'https://www.nm.org',
  'trauma_center',
  897,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Transplant'],
  ARRAY['Heart Disease', 'Cancer Treatment', 'Organ Transplant'],
  4.6,
  4321,
  TRUE,
  TRUE
);

-- 10. Houston Methodist Hospital - Houston, TX
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, accepts_ambulance,
  is_24_7, services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'Houston Methodist Hospital',
  '6565 Fannin Street',
  'Houston',
  'TX',
  'USA',
  '77030',
  29.7092,
  -95.4014,
  '+1-713-790-3311',
  '+1-713-790-2700',
  'https://www.houstonmethodist.org',
  'general',
  950,
  TRUE,
  TRUE,
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Orthopedics'],
  ARRAY['Heart Disease', 'Cancer Treatment', 'Sports Medicine'],
  4.5,
  3987,
  TRUE,
  TRUE
);

-- 11. UCSF Medical Center - San Francisco, CA
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7, services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'UCSF Medical Center',
  '505 Parnassus Avenue',
  'San Francisco',
  'CA',
  'USA',
  '94143',
  37.7625,
  -122.4582,
  '+1-415-476-1000',
  '+1-415-476-1037',
  'https://www.ucsfhealth.org',
  'trauma_center',
  790,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Neurology', 'Oncology', 'Transplant', 'Pediatrics'],
  ARRAY['Brain Surgery', 'Cancer Treatment', 'Children''s Hospital'],
  4.7,
  5234,
  TRUE,
  TRUE
);

-- 12. Stanford Health Care - Palo Alto, CA
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7, services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'Stanford Health Care',
  '300 Pasteur Drive',
  'Palo Alto',
  'CA',
  'USA',
  '94304',
  37.4419,
  -122.1740,
  '+1-650-723-4000',
  '+1-650-723-5300',
  'https://www.stanfordhealthcare.org',
  'trauma_center',
  613,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Transplant'],
  ARRAY['Heart Surgery', 'Cancer Research', 'Organ Transplant'],
  4.8,
  4876,
  TRUE,
  TRUE
);

-- 13. Seattle Children's Hospital - Seattle, WA
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7, services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'Seattle Children''s Hospital',
  '4800 Sand Point Way NE',
  'Seattle',
  'WA',
  'USA',
  '98105',
  47.6564,
  -122.2853,
  '+1-206-987-2000',
  '+1-206-987-2040',
  'https://www.seattlechildrens.org',
  'specialized',
  437,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Pediatrics', 'Neonatology', 'Pediatric Surgery', 'Cardiology'],
  ARRAY['Children''s Heart Surgery', 'Neonatal Care', 'Pediatric Cancer'],
  4.9,
  6543,
  TRUE,
  TRUE
);

-- 14. Tampa General Hospital - Tampa, FL
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7, services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'Tampa General Hospital',
  '1 Tampa General Circle',
  'Tampa',
  'FL',
  'USA',
  '33606',
  27.9447,
  -82.4614,
  '+1-813-844-7000',
  '+1-813-844-4444',
  'https://www.tgh.org',
  'trauma_center',
  1007,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Transplant', 'Burn Center'],
  ARRAY['Heart Disease', 'Trauma Care', 'Burn Treatment', 'Organ Transplant'],
  4.6,
  3765,
  TRUE,
  TRUE
);

-- 15. Phoenix Children's Hospital - Phoenix, AZ
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7, services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'Phoenix Children''s Hospital',
  '1919 East Thomas Road',
  'Phoenix',
  'AZ',
  'USA',
  '85016',
  33.4806,
  -112.0463,
  '+1-602-933-1000',
  '+1-602-933-0910',
  'https://www.phoenixchildrens.org',
  'specialized',
  433,
  TRUE,
  TRUE,
  'II',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Pediatrics', 'Neonatology', 'Pediatric Surgery', 'Cardiology'],
  ARRAY['Children''s Emergency', 'Neonatal ICU', 'Pediatric Trauma'],
  4.7,
  4234,
  TRUE,
  TRUE
);

-- ============================================
-- VERIFY THE DATA
-- ============================================

-- Count total hospitals
SELECT COUNT(*) AS total_hospitals FROM hospitals;

-- Show all hospitals with basic info
SELECT
  name,
  city,
  state,
  type,
  has_emergency_room,
  has_trauma_center,
  trauma_level,
  rating,
  ROUND(latitude::NUMERIC, 4) AS lat,
  ROUND(longitude::NUMERIC, 4) AS lng
FROM hospitals
ORDER BY state, city, name;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'SUCCESS: 15 sample hospitals inserted!';
  RAISE NOTICE '';
  RAISE NOTICE 'Distribution:';
  RAISE NOTICE '- New York: 2 hospitals';
  RAISE NOTICE '- Los Angeles: 2 hospitals';
  RAISE NOTICE '- California (other): 3 hospitals';
  RAISE NOTICE '- Boston: 1 hospital';
  RAISE NOTICE '- Chicago: 1 hospital';
  RAISE NOTICE '- Houston: 1 hospital';
  RAISE NOTICE '- Other cities: 5 hospitals';
  RAISE NOTICE '';
  RAISE NOTICE 'Types:';
  RAISE NOTICE '- Trauma Centers (Level I): 10';
  RAISE NOTICE '- Trauma Centers (Level II): 1';
  RAISE NOTICE '- Specialized: 3';
  RAISE NOTICE '- General: 1';
  RAISE NOTICE '';
  RAISE NOTICE 'You can now test the hospital finder!';
  RAISE NOTICE '========================================';
END $$;
