-- Sample Itinerary for "Weekend Trip to Tamilnadu" (Nov 30 - Dec 8, 2025)
-- Trip ID: 6bcd60fa-768b-421b-89aa-43ff0127ca98
-- User ID: e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a
-- Total: 48 itinerary items across 9 days

-- Day 1 (Nov 30) - Arrival in Chennai
INSERT INTO itinerary_items (id, trip_id, title, description, location, start_time, end_time, day_number, order_index, created_by, created_at, updated_at) VALUES
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Arrive at Chennai Airport', 'Land at Chennai International Airport and collect luggage', 'Chennai International Airport', '2025-11-30 10:00:00', '2025-11-30 11:00:00', 1, 0, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Check-in at Hotel', 'Check into hotel and freshen up', 'Hotel in Chennai', '2025-11-30 12:00:00', '2025-11-30 13:00:00', 1, 1, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Lunch at Saravana Bhavan', 'Enjoy authentic South Indian lunch - try the thali', 'Saravana Bhavan, Chennai', '2025-11-30 13:30:00', '2025-11-30 14:30:00', 1, 2, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Visit Marina Beach', 'Evening walk at the longest urban beach in India (13 km)', 'Marina Beach, Chennai', '2025-11-30 16:00:00', '2025-11-30 18:30:00', 1, 3, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Dinner at Peshawri', 'North Indian dinner experience at ITC Grand Chola', 'ITC Grand Chola, Chennai', '2025-11-30 20:00:00', '2025-11-30 21:30:00', 1, 4, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),

-- Day 2 (Dec 1) - Chennai Exploration
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Breakfast at Hotel', 'South Indian breakfast buffet - idli, dosa, vada, pongal', 'Hotel', '2025-12-01 08:00:00', '2025-12-01 09:00:00', 2, 0, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Visit Kapaleeshwarar Temple', 'Ancient 7th century Shiva temple with stunning Dravidian architecture', 'Kapaleeshwarar Temple, Mylapore', '2025-12-01 09:30:00', '2025-12-01 11:30:00', 2, 1, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Explore San Thome Cathedral', 'Historic Catholic cathedral built over the tomb of St. Thomas the Apostle', 'San Thome Cathedral, Chennai', '2025-12-01 12:00:00', '2025-12-01 13:00:00', 2, 2, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Lunch at Murugan Idli Shop', 'Famous for soft idlis with 10+ varieties of chutneys', 'Murugan Idli Shop, T Nagar', '2025-12-01 13:30:00', '2025-12-01 14:30:00', 2, 3, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Government Museum Visit', 'Second oldest museum in India with Bronze gallery, Archaeological section', 'Government Museum, Egmore', '2025-12-01 15:00:00', '2025-12-01 17:30:00', 2, 4, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Shopping at T Nagar', 'Famous shopping district for Kanchipuram silk sarees and gold jewelry', 'T Nagar, Chennai', '2025-12-01 18:00:00', '2025-12-01 20:00:00', 2, 5, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),

-- Day 3 (Dec 2) - Mahabalipuram Day Trip
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Drive to Mahabalipuram', 'Scenic 2-hour drive along East Coast Road with beach views', 'ECR Highway', '2025-12-02 07:00:00', '2025-12-02 09:00:00', 3, 0, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Shore Temple Visit', 'UNESCO World Heritage Site - 8th century structural temple by the sea', 'Shore Temple, Mahabalipuram', '2025-12-02 09:30:00', '2025-12-02 11:00:00', 3, 1, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Pancha Rathas Exploration', 'Five monolithic rock-cut temples named after Pandavas', 'Pancha Rathas, Mahabalipuram', '2025-12-02 11:30:00', '2025-12-02 13:00:00', 3, 2, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Seafood Lunch', 'Fresh seafood - prawns, fish curry at beach-side restaurant', 'Moonrakers Restaurant, Mahabalipuram', '2025-12-02 13:30:00', '2025-12-02 14:30:00', 3, 3, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Arjunas Penance', 'Giant 27m x 9m open-air rock relief - largest in the world', 'Arjunas Penance, Mahabalipuram', '2025-12-02 15:00:00', '2025-12-02 16:30:00', 3, 4, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Return to Chennai', 'Drive back to Chennai hotel via ECR', 'ECR Highway', '2025-12-02 17:00:00', '2025-12-02 19:00:00', 3, 5, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),

-- Day 4 (Dec 3) - Travel to Pondicherry
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Check-out and Drive to Pondicherry', 'Scenic 3-hour coastal drive to French colony', 'Chennai to Pondicherry', '2025-12-03 08:00:00', '2025-12-03 11:00:00', 4, 0, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Check-in at French Quarter Hotel', 'Boutique heritage hotel in White Town with colonial charm', 'White Town, Pondicherry', '2025-12-03 11:30:00', '2025-12-03 12:30:00', 4, 1, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'French Lunch at Villa Shanti', 'French-Tamil fusion cuisine in a restored heritage mansion', 'Villa Shanti, Pondicherry', '2025-12-03 13:00:00', '2025-12-03 14:30:00', 4, 2, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Walk in French Quarter', 'Explore colorful colonial streets, yellow buildings, bougainvillea', 'White Town, Pondicherry', '2025-12-03 15:00:00', '2025-12-03 17:00:00', 4, 3, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Promenade Beach Sunset', 'Evening walk on 1.5 km promenade with Gandhi statue', 'Promenade Beach, Pondicherry', '2025-12-03 17:30:00', '2025-12-03 19:00:00', 4, 4, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Dinner at Le Cafe', 'Iconic beachfront cafe with sea breeze and French pastries', 'Le Cafe, Pondicherry', '2025-12-03 19:30:00', '2025-12-03 21:00:00', 4, 5, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),

-- Day 5 (Dec 4) - Auroville & Pondicherry
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Visit Auroville', 'Universal township - Matrimandir golden sphere meditation center', 'Auroville', '2025-12-04 08:00:00', '2025-12-04 12:00:00', 5, 0, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Lunch at Auroville Bakery', 'Organic vegetarian food, wood-fired pizzas, fresh salads', 'Auroville Bakery', '2025-12-04 12:30:00', '2025-12-04 13:30:00', 5, 1, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Sri Aurobindo Ashram', 'Spiritual center founded in 1926, meditation and samadhi', 'Sri Aurobindo Ashram, Pondicherry', '2025-12-04 15:00:00', '2025-12-04 16:30:00', 5, 2, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Paradise Beach Trip', 'Boat ride to secluded beach, swimming and relaxation', 'Paradise Beach, Pondicherry', '2025-12-04 17:00:00', '2025-12-04 19:00:00', 5, 3, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),

-- Day 6 (Dec 5) - Travel to Thanjavur
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Drive to Thanjavur', '4-hour drive through Tamil countryside and rice fields', 'Pondicherry to Thanjavur', '2025-12-05 07:00:00', '2025-12-05 11:00:00', 6, 0, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Check-in at Thanjavur Hotel', 'Heritage hotel with traditional Tamil architecture', 'Thanjavur', '2025-12-05 11:30:00', '2025-12-05 12:30:00', 6, 1, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Traditional Thanjavur Lunch', 'Authentic banana leaf meal with 12+ dishes', 'Local Restaurant, Thanjavur', '2025-12-05 13:00:00', '2025-12-05 14:00:00', 6, 2, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Brihadeeswarar Temple Visit', 'UNESCO World Heritage - 1000 year old Big Temple with 66m tower', 'Brihadeeswarar Temple, Thanjavur', '2025-12-05 15:00:00', '2025-12-05 18:00:00', 6, 3, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Thanjavur Palace & Museum', 'Royal palace with Saraswathi Mahal Library and art gallery', 'Thanjavur Palace', '2025-12-05 18:30:00', '2025-12-05 20:00:00', 6, 4, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),

-- Day 7 (Dec 6) - Madurai
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Drive to Madurai', '3-hour drive to the ancient temple city', 'Thanjavur to Madurai', '2025-12-06 07:00:00', '2025-12-06 10:00:00', 7, 0, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Check-in at Madurai Hotel', 'Hotel with rooftop view of Meenakshi Temple gopurams', 'Madurai', '2025-12-06 10:30:00', '2025-12-06 11:30:00', 7, 1, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Meenakshi Amman Temple Visit', 'Iconic 2500 year old temple with 14 gopurams and 1000 pillar hall', 'Meenakshi Temple, Madurai', '2025-12-06 12:00:00', '2025-12-06 15:00:00', 7, 2, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Lunch at Amma Mess', 'Famous non-veg Tamil cuisine - mutton chukka, chicken 65', 'Amma Mess, Madurai', '2025-12-06 15:30:00', '2025-12-06 16:30:00', 7, 3, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Thirumalai Nayak Palace', '17th century Indo-Saracenic palace with 248 pillars', 'Thirumalai Nayak Palace, Madurai', '2025-12-06 17:00:00', '2025-12-06 18:30:00', 7, 4, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Evening Temple Ceremony', 'Witness the spectacular night ceremony - Lord Sundareswarar procession', 'Meenakshi Temple, Madurai', '2025-12-06 20:30:00', '2025-12-06 21:30:00', 7, 5, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),

-- Day 8 (Dec 7) - Kodaikanal Hill Station
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Drive to Kodaikanal', 'Scenic 3.5 hour hill drive with 18 hairpin bends', 'Madurai to Kodaikanal', '2025-12-07 06:00:00', '2025-12-07 09:30:00', 8, 0, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Breakfast at Carlton Hotel', 'English breakfast with stunning valley views', 'Carlton Hotel, Kodaikanal', '2025-12-07 10:00:00', '2025-12-07 11:00:00', 8, 1, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Kodaikanal Lake Boating', 'Pedal boating or rowing in the star-shaped lake', 'Kodaikanal Lake', '2025-12-07 11:30:00', '2025-12-07 13:00:00', 8, 2, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Lunch and Homemade Chocolates', 'Try famous Kodai chocolates and eucalyptus products', 'Kodaikanal Market', '2025-12-07 13:30:00', '2025-12-07 15:00:00', 8, 3, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Coakers Walk', '1km scenic mountain walk with panoramic valley views', 'Coakers Walk, Kodaikanal', '2025-12-07 15:30:00', '2025-12-07 17:00:00', 8, 4, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Pillar Rocks Viewpoint', 'Three massive granite pillars rising 400 ft from the ground', 'Pillar Rocks, Kodaikanal', '2025-12-07 17:30:00', '2025-12-07 18:30:00', 8, 5, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Drive back to Madurai', 'Return journey for flight next day', 'Kodaikanal to Madurai', '2025-12-07 19:00:00', '2025-12-07 22:30:00', 8, 6, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),

-- Day 9 (Dec 8) - Departure
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Morning Temple Visit', 'Early morning darshan at Meenakshi Temple (less crowded)', 'Meenakshi Temple, Madurai', '2025-12-08 06:00:00', '2025-12-08 07:30:00', 9, 0, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Breakfast and Checkout', 'Pack and checkout from hotel', 'Hotel, Madurai', '2025-12-08 08:00:00', '2025-12-08 09:30:00', 9, 1, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Visit Gandhi Museum', 'Museum with blood-stained cloth Gandhi wore when assassinated', 'Gandhi Museum, Madurai', '2025-12-08 10:00:00', '2025-12-08 11:30:00', 9, 2, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Last Minute Shopping', 'Buy souvenirs - Madurai sungudi sarees, jasmine, Jigarthanda', 'Madurai Market', '2025-12-08 12:00:00', '2025-12-08 13:00:00', 9, 3, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW()),
(gen_random_uuid(), '6bcd60fa-768b-421b-89aa-43ff0127ca98', 'Depart from Madurai Airport', 'Flight back home with wonderful memories of Tamil Nadu!', 'Madurai Airport', '2025-12-08 15:00:00', '2025-12-08 16:00:00', 9, 4, 'e4a5a4ef-a5a3-4cff-83c6-c53d88ecba3a', NOW(), NOW());

-- Verify insertion
SELECT day_number, COUNT(*) as items, MIN(title) as first_item
FROM itinerary_items
WHERE trip_id = '6bcd60fa-768b-421b-89aa-43ff0127ca98'
GROUP BY day_number
ORDER BY day_number;
