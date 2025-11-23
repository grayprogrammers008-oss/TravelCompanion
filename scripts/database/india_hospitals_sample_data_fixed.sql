-- ============================================
-- INDIA HOSPITALS SAMPLE DATA (FIXED)
-- ============================================
-- This script adds major hospitals across India
-- Compatible with hospitals_setup_no_postgis.sql schema
--
-- Prerequisites:
-- - Run hospitals_setup_no_postgis.sql first
--
-- Coverage: Delhi, Mumbai, Bangalore, Chennai, Kolkata,
--           Hyderabad, Pune, Ahmedabad, Jaipur, Lucknow
-- ============================================

-- Clear any existing India hospitals (optional)
-- DELETE FROM hospitals WHERE country = 'India';

-- ============================================
-- INSERT 20 MAJOR INDIA HOSPITALS
-- ============================================

-- 1. AIIMS - New Delhi
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'All India Institute of Medical Sciences (AIIMS)',
  'Ansari Nagar, Sri Aurobindo Marg',
  'New Delhi', 'Delhi', 'India', '110029',
  28.5672, 77.2100,
  '+91-11-26588500', '+91-11-26588700', 'https://www.aiims.edu',
  'trauma_center', 2478, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Orthopedics', 'Pediatrics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurosurgery', 'Oncology', 'Trauma Care', 'Cardiac Surgery', 'Organ Transplant'],
  4.8, TRUE
);

-- 2. Fortis Escorts Heart Institute - New Delhi
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Fortis Escorts Heart Institute',
  'Okhla Road, Okhla',
  'New Delhi', 'Delhi', 'India', '110025',
  28.5355, 77.2760,
  '+91-11-47135000', '+91-11-47135000', 'https://www.fortishealthcare.com',
  'specialized', 310, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Cardiac Surgery', 'ICU'],
  ARRAY['Cardiology', 'Cardiac Surgery', 'Interventional Cardiology'],
  4.7, TRUE
);

-- 3. Tata Memorial Hospital - Mumbai
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Tata Memorial Hospital',
  'Dr Ernest Borges Marg, Parel',
  'Mumbai', 'Maharashtra', 'India', '400012',
  19.0060, 72.8433,
  '+91-22-24177000', '+91-22-24177000', 'https://tmc.gov.in',
  'specialized', 629, TRUE, FALSE, TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Oncology', 'Surgery', 'Radiation Therapy', 'Chemotherapy', 'ICU'],
  ARRAY['Medical Oncology', 'Surgical Oncology', 'Radiation Oncology', 'Pediatric Oncology'],
  4.9, TRUE
);

-- 4. Lilavati Hospital - Mumbai
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Lilavati Hospital and Research Centre',
  'A-791, Bandra Reclamation, Bandra West',
  'Mumbai', 'Maharashtra', 'India', '400050',
  19.0596, 72.8295,
  '+91-22-26567891', '+91-22-26567891', 'https://www.lilavatihospital.com',
  'trauma_center', 323, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Orthopedics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurosurgery', 'Joint Replacement', 'Minimally Invasive Surgery'],
  4.6, TRUE
);

-- 5. Manipal Hospital - Bangalore
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Manipal Hospital',
  '98, HAL Airport Road, Kodihalli',
  'Bangalore', 'Karnataka', 'India', '560017',
  12.9634, 77.6545,
  '+91-80-25023456', '+91-80-25023456', 'https://www.manipalhospitals.com',
  'trauma_center', 650, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Orthopedics', 'Pediatrics', 'ICU'],
  ARRAY['Cardiology', 'Neurosurgery', 'Oncology', 'Organ Transplant', 'Robotic Surgery'],
  4.7, TRUE
);

-- 6. Apollo Hospital - Bangalore
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Apollo Hospital',
  '154/11, Opposite IIM, Bannerghatta Road',
  'Bangalore', 'Karnataka', 'India', '560076',
  12.8892, 77.6006,
  '+91-80-26304050', '+91-80-26304050', 'https://www.apollohospitals.com',
  'trauma_center', 250, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Orthopedics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurosurgery', 'Joint Replacement', 'Transplant Surgery'],
  4.8, TRUE
);

-- 7. Apollo Hospital - Chennai
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Apollo Hospital',
  '21, Greams Lane, Off Greams Road',
  'Chennai', 'Tamil Nadu', 'India', '600006',
  13.0569, 80.2509,
  '+91-44-28293333', '+91-44-28293333', 'https://www.apollohospitals.com',
  'trauma_center', 550, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Orthopedics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurosurgery', 'Oncology', 'Organ Transplant', 'Proton Therapy'],
  4.8, TRUE
);

-- 8. Fortis Malar Hospital - Chennai
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Fortis Malar Hospital',
  '52, 1st Main Road, Gandhi Nagar, Adyar',
  'Chennai', 'Tamil Nadu', 'India', '600020',
  13.0067, 80.2575,
  '+91-44-42895555', '+91-44-42895555', 'https://www.fortishealthcare.com',
  'general', 180, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Orthopedics', 'ICU'],
  ARRAY['Cardiology', 'Cardiac Surgery', 'Neurology'],
  4.6, TRUE
);

-- 9. AMRI Hospital - Kolkata
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'AMRI Hospital',
  'JC-16 & 17, Sector III, Salt Lake City',
  'Kolkata', 'West Bengal', 'India', '700098',
  22.5804, 88.4134,
  '+91-33-66063800', '+91-33-66063800', 'https://www.amrihospitals.in',
  'trauma_center', 400, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Orthopedics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurosurgery', 'Orthopedics', 'Oncology'],
  4.5, TRUE
);

-- 10. Apollo Gleneagles Hospital - Kolkata
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Apollo Gleneagles Hospital',
  '58, Canal Circular Road',
  'Kolkata', 'West Bengal', 'India', '700054',
  22.5431, 88.3840,
  '+91-33-23203040', '+91-33-23203040', 'https://www.apollogleneagles.in',
  'trauma_center', 500, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Orthopedics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurosurgery', 'Oncology', 'Organ Transplant'],
  4.7, TRUE
);

-- 11. Yashoda Hospital - Hyderabad
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Yashoda Hospital',
  'Behind Hari Hara Kala Bhavan, SP Road, Secunderabad',
  'Hyderabad', 'Telangana', 'India', '500003',
  17.4401, 78.4949,
  '+91-40-23443333', '+91-40-23443333', 'https://www.yashodahospitals.com',
  'trauma_center', 350, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Orthopedics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurosurgery', 'Orthopedics', 'Gastroenterology'],
  4.6, TRUE
);

-- 12. Apollo Hospital - Hyderabad
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Apollo Hospital',
  'Plot No. 251, Rd Number 3, Jubilee Hills',
  'Hyderabad', 'Telangana', 'India', '500033',
  17.4239, 78.4180,
  '+91-40-23607777', '+91-40-23607777', 'https://www.apollohospitals.com',
  'trauma_center', 500, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Orthopedics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurosurgery', 'Oncology', 'Organ Transplant'],
  4.8, TRUE
);

-- 13. Ruby Hall Clinic - Pune
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Ruby Hall Clinic',
  '40, Sassoon Road',
  'Pune', 'Maharashtra', 'India', '411001',
  18.5204, 73.8567,
  '+91-20-26163232', '+91-20-26163232', 'https://www.rubyhall.com',
  'trauma_center', 750, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Orthopedics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurosurgery', 'Joint Replacement', 'IVF'],
  4.7, TRUE
);

-- 14. Sahyadri Hospital - Pune
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Sahyadri Hospital',
  '30-C, Erandwane, Karve Road',
  'Pune', 'Maharashtra', 'India', '411004',
  18.5074, 73.8376,
  '+91-20-67061000', '+91-20-67061000', 'https://www.sahyadrihospital.com',
  'general', 200, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Orthopedics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurology', 'Orthopedics'],
  4.6, TRUE
);

-- 15. Sterling Hospital - Ahmedabad
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Sterling Hospital',
  'Sterling Hospital Road, Behind Drive-In Cinema, Off Gurukul Road',
  'Ahmedabad', 'Gujarat', 'India', '380052',
  23.0291, 72.5198,
  '+91-79-40001000', '+91-79-40001000', 'https://www.sterlinghospitals.com',
  'trauma_center', 200, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Orthopedics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurosurgery', 'Organ Transplant'],
  4.7, TRUE
);

-- 16. Apollo Hospital - Ahmedabad
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Apollo Hospital',
  'Plot No. 1A, GIDC Estate, Bhat Village',
  'Ahmedabad', 'Gujarat', 'India', '382428',
  23.1148, 72.6839,
  '+91-79-40087777', '+91-79-40087777', 'https://www.apollohospitals.com',
  'trauma_center', 250, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Orthopedics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurosurgery', 'Oncology'],
  4.7, TRUE
);

-- 17. Fortis Hospital - Jaipur
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Fortis Hospital',
  'Jawahar Lal Nehru Marg, Malviya Nagar',
  'Jaipur', 'Rajasthan', 'India', '302017',
  26.8515, 75.8131,
  '+91-141-2547000', '+91-141-2547000', 'https://www.fortishealthcare.com',
  'trauma_center', 355, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Orthopedics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurosurgery', 'Joint Replacement'],
  4.6, TRUE
);

-- 18. Eternal Hospital - Jaipur
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Eternal Hospital',
  'Jagatpura Road, Near Jawahar Circle',
  'Jaipur', 'Rajasthan', 'India', '302020',
  26.8420, 75.8340,
  '+91-141-2790000', '+91-141-2790000', 'https://www.eternalhospital.com',
  'general', 230, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Orthopedics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurology', 'Orthopedics'],
  4.5, TRUE
);

-- 19. Medanta Hospital - Lucknow
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Medanta Hospital',
  'Plot A-2, Sector B, Amar Shaheed Path',
  'Lucknow', 'Uttar Pradesh', 'India', '226028',
  26.9197, 80.9630,
  '+91-522-4585555', '+91-522-4585555', 'https://www.medanta.org',
  'trauma_center', 400, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Orthopedics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurosurgery', 'Oncology', 'Organ Transplant'],
  4.7, TRUE
);

-- 20. Max Super Speciality Hospital - New Delhi (Saket)
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7,
  services, specialties,
  rating, is_verified
) VALUES (
  'Max Super Speciality Hospital',
  '1, 2, Press Enclave Road, Saket',
  'New Delhi', 'Delhi', 'India', '110017',
  28.5244, 77.2066,
  '+91-11-26515050', '+91-11-26515050', 'https://www.maxhealthcare.in',
  'trauma_center', 500, TRUE, TRUE, 'I', TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Cardiology', 'Neurology', 'Oncology', 'Orthopedics', 'Pediatrics', 'Surgery', 'ICU'],
  ARRAY['Cardiology', 'Neurosurgery', 'Oncology', 'Organ Transplant', 'Robotic Surgery'],
  4.8, TRUE
);

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Count total India hospitals
SELECT COUNT(*) as total_india_hospitals
FROM hospitals
WHERE country = 'India';

-- Count by city
SELECT city, COUNT(*) as hospital_count
FROM hospitals
WHERE country = 'India'
GROUP BY city
ORDER BY hospital_count DESC;

-- List all India hospitals
SELECT name, city, state, phone_number, has_emergency_room, rating
FROM hospitals
WHERE country = 'India'
ORDER BY city, name;

-- ============================================
-- SETUP COMPLETE
-- ============================================
-- ✓ 20 major India hospitals inserted
-- ✓ Coverage across 10 major cities
-- ✓ All hospitals have emergency rooms
-- ✓ All are verified and active
-- ============================================
