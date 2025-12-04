-- =====================================================
-- SEED DATA: Trip Templates
-- =====================================================
-- This file contains 10 pre-built trip templates for
-- popular Indian destinations with detailed itineraries
-- and packing checklists.
-- =====================================================

-- =====================================================
-- 1. GOA BEACH VACATION (3 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Goa Beach Getaway',
  'Experience the perfect beach vacation in Goa with stunning beaches, vibrant nightlife, and delicious seafood. Visit iconic churches, enjoy water sports, and relax by the Arabian Sea.',
  'Goa',
  'Goa',
  3,
  15000,
  35000,
  'INR',
  'beach',
  ARRAY['beach', 'party', 'seafood', 'water-sports', 'nightlife'],
  ARRAY['October', 'November', 'December', 'January', 'February', 'March'],
  'easy',
  true,
  true
);

-- Get the template ID for Goa
DO $$
DECLARE
  goa_template_id UUID;
BEGIN
  SELECT id INTO goa_template_id FROM public.trip_templates WHERE name = 'Goa Beach Getaway';

  -- Day 1 Itinerary
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (goa_template_id, 1, 1, 'Arrive at Goa Airport', 'Land at Dabolim Airport and transfer to your hotel in North Goa', 'Dabolim Airport', 'transport', '10:00', 500, 'Pre-book airport transfer for better rates'),
  (goa_template_id, 1, 2, 'Check-in & Freshen Up', 'Check into your beach resort and freshen up', 'Calangute/Baga', 'accommodation', '12:00', 3000, 'Choose hotels near the beach for convenience'),
  (goa_template_id, 1, 3, 'Lunch at Beach Shack', 'Enjoy fresh seafood at a beach shack', 'Baga Beach', 'food', '13:30', 800, 'Try the fish curry rice - a Goan specialty'),
  (goa_template_id, 1, 4, 'Calangute Beach', 'Relax at Goa''s most popular beach, enjoy water sports', 'Calangute Beach', 'activity', '15:00', 1500, 'Best time for parasailing is afternoon'),
  (goa_template_id, 1, 5, 'Sunset at Baga Beach', 'Watch the beautiful sunset and enjoy beach activities', 'Baga Beach', 'sightseeing', '17:30', 0, 'Grab a beer and watch the sunset'),
  (goa_template_id, 1, 6, 'Dinner & Nightlife', 'Experience Goa''s famous nightlife at Tito''s Lane', 'Tito''s Lane, Baga', 'food', '20:00', 2000, 'Weekends are more crowded but more fun');

  -- Day 2 Itinerary
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (goa_template_id, 2, 1, 'Breakfast at Cafe', 'Start with a hearty breakfast at a beach cafe', 'Anjuna', 'food', '09:00', 400, 'Try the Goan pork sausage breakfast'),
  (goa_template_id, 2, 2, 'Old Goa Churches', 'Visit UNESCO heritage churches including Basilica of Bom Jesus', 'Old Goa', 'sightseeing', '10:30', 0, 'Dress modestly for church visits'),
  (goa_template_id, 2, 3, 'Lunch in Panjim', 'Authentic Goan thali at a local restaurant', 'Panjim', 'food', '13:00', 500, 'Try Ritz Classic for authentic Goan food'),
  (goa_template_id, 2, 4, 'Fontainhas Latin Quarter', 'Walk through the colorful Portuguese streets', 'Fontainhas, Panjim', 'sightseeing', '14:30', 0, 'Great for photography'),
  (goa_template_id, 2, 5, 'Anjuna Beach', 'Explore the famous flea market beach', 'Anjuna Beach', 'activity', '16:30', 500, 'Flea market is on Wednesdays'),
  (goa_template_id, 2, 6, 'Curlies Beach Club', 'Dinner and chill music at the iconic beach club', 'Anjuna', 'food', '19:00', 1500, 'Great for sunset and live music');

  -- Day 3 Itinerary
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (goa_template_id, 3, 1, 'Breakfast & Checkout', 'Pack up and checkout from hotel', 'Hotel', 'accommodation', '09:00', 400, 'Keep luggage at hotel if late flight'),
  (goa_template_id, 3, 2, 'Vagator Beach & Chapora Fort', 'Visit the Dil Chahta Hai fort and scenic beach', 'Vagator', 'sightseeing', '10:30', 0, 'Best views from the fort'),
  (goa_template_id, 3, 3, 'Lunch at Thalassa', 'Greek food with stunning cliff views', 'Vagator', 'food', '13:00', 1500, 'Book in advance for cliff-side table'),
  (goa_template_id, 3, 4, 'Souvenir Shopping', 'Buy cashews, feni, and local crafts', 'Mapusa Market', 'activity', '15:00', 2000, 'Bargain for better prices'),
  (goa_template_id, 3, 5, 'Depart from Airport', 'Transfer to airport for departure', 'Dabolim Airport', 'transport', '17:00', 500, 'Reach 2 hours before flight');

  -- Goa Packing Checklist
  INSERT INTO public.template_checklists (template_id, name, icon, order_index) VALUES
  (goa_template_id, 'Beach Essentials', 'beach_access', 1);

  INSERT INTO public.template_checklist_items (checklist_id, content, order_index, is_essential, category)
  SELECT c.id, item.content, item.order_index, item.is_essential, item.category
  FROM public.template_checklists c
  CROSS JOIN (VALUES
    ('Swimsuit/Beachwear', 1, true, 'clothing'),
    ('Sunscreen SPF 50+', 2, true, 'toiletries'),
    ('Sunglasses', 3, true, 'misc'),
    ('Beach towel', 4, false, 'misc'),
    ('Flip flops/Sandals', 5, true, 'clothing'),
    ('Light cotton clothes', 6, true, 'clothing'),
    ('Hat/Cap', 7, false, 'clothing'),
    ('Waterproof phone pouch', 8, false, 'electronics'),
    ('After-sun lotion', 9, false, 'toiletries'),
    ('Insect repellent', 10, false, 'toiletries')
  ) AS item(content, order_index, is_essential, category)
  WHERE c.template_id = goa_template_id AND c.name = 'Beach Essentials';

  INSERT INTO public.template_checklists (template_id, name, icon, order_index) VALUES
  (goa_template_id, 'Documents & Money', 'article', 2);

  INSERT INTO public.template_checklist_items (checklist_id, content, order_index, is_essential, category)
  SELECT c.id, item.content, item.order_index, item.is_essential, item.category
  FROM public.template_checklists c
  CROSS JOIN (VALUES
    ('ID Card (Aadhar/Passport)', 1, true, 'documents'),
    ('Flight tickets', 2, true, 'documents'),
    ('Hotel booking confirmation', 3, true, 'documents'),
    ('Debit/Credit cards', 4, true, 'documents'),
    ('Some cash for local shops', 5, true, 'documents'),
    ('Travel insurance details', 6, false, 'documents')
  ) AS item(content, order_index, is_essential, category)
  WHERE c.template_id = goa_template_id AND c.name = 'Documents & Money';
END $$;

-- =====================================================
-- 2. RAJASTHAN HERITAGE TOUR (5 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Royal Rajasthan Heritage Tour',
  'Explore the magnificent forts, palaces, and rich culture of Rajasthan. From the Pink City of Jaipur to the Blue City of Jodhpur, experience royal India.',
  'Jaipur - Jodhpur - Udaipur',
  'Rajasthan',
  5,
  25000,
  60000,
  'INR',
  'heritage',
  ARRAY['forts', 'palaces', 'culture', 'history', 'photography'],
  ARRAY['October', 'November', 'December', 'January', 'February', 'March'],
  'easy',
  true,
  true
);

DO $$
DECLARE
  rajasthan_template_id UUID;
BEGIN
  SELECT id INTO rajasthan_template_id FROM public.trip_templates WHERE name = 'Royal Rajasthan Heritage Tour';

  -- Day 1: Jaipur
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (rajasthan_template_id, 1, 1, 'Arrive in Jaipur', 'Land at Jaipur Airport, transfer to hotel', 'Jaipur Airport', 'transport', '10:00', 600, 'Book hotel near City Palace for convenience'),
  (rajasthan_template_id, 1, 2, 'Hawa Mahal', 'Visit the iconic Palace of Winds', 'Hawa Mahal', 'sightseeing', '14:00', 50, 'Best photos from the opposite cafe'),
  (rajasthan_template_id, 1, 3, 'City Palace', 'Explore the magnificent royal residence', 'City Palace, Jaipur', 'sightseeing', '15:30', 500, 'Hire a guide for detailed history'),
  (rajasthan_template_id, 1, 4, 'Jantar Mantar', 'UNESCO World Heritage astronomical site', 'Jantar Mantar', 'sightseeing', '17:00', 200, 'Amazing ancient scientific instruments'),
  (rajasthan_template_id, 1, 5, 'Dinner at Chokhi Dhani', 'Traditional Rajasthani village experience', 'Chokhi Dhani', 'food', '19:30', 1500, 'Book in advance, great cultural show');

  -- Day 2: Jaipur
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (rajasthan_template_id, 2, 1, 'Amber Fort', 'Explore the majestic fort with elephant ride option', 'Amber Fort', 'sightseeing', '09:00', 500, 'Go early to avoid crowds and heat'),
  (rajasthan_template_id, 2, 2, 'Jal Mahal (Photo Stop)', 'View the Water Palace from the shore', 'Jal Mahal', 'sightseeing', '12:00', 0, 'Entry not allowed, but great views'),
  (rajasthan_template_id, 2, 3, 'Lunch at 1135 AD', 'Royal dining inside Amber Fort', '1135 AD Restaurant', 'food', '13:00', 1200, 'Try the Laal Maas'),
  (rajasthan_template_id, 2, 4, 'Nahargarh Fort', 'Sunset point with city views', 'Nahargarh Fort', 'sightseeing', '16:00', 200, 'Perfect for sunset photography'),
  (rajasthan_template_id, 2, 5, 'Johari Bazaar Shopping', 'Shop for gems, jewelry, and textiles', 'Johari Bazaar', 'activity', '18:30', 2000, 'Bargain hard, fixed price shops available');

  -- Day 3: Jaipur to Jodhpur
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (rajasthan_template_id, 3, 1, 'Drive to Jodhpur', 'Scenic 5-hour drive through Rajasthan', 'Highway', 'transport', '07:00', 4000, 'Hire a driver, stop at Ajmer if time permits'),
  (rajasthan_template_id, 3, 2, 'Check-in Jodhpur', 'Rest at heritage haveli', 'Jodhpur', 'accommodation', '13:00', 3500, 'Stay in the old city for authentic experience'),
  (rajasthan_template_id, 3, 3, 'Mehrangarh Fort', 'One of India''s largest forts', 'Mehrangarh Fort', 'sightseeing', '15:00', 600, 'Audio guide highly recommended'),
  (rajasthan_template_id, 3, 4, 'Blue City Walk', 'Walk through blue-painted houses', 'Old Jodhpur', 'sightseeing', '17:30', 0, 'Best views from the fort'),
  (rajasthan_template_id, 3, 5, 'Dinner at Indique', 'Rooftop dining with fort views', 'Indique Restaurant', 'food', '19:30', 1500, 'Book rooftop table in advance');

  -- Day 4: Jodhpur to Udaipur
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (rajasthan_template_id, 4, 1, 'Jaswant Thada', 'Beautiful marble cenotaph', 'Jaswant Thada', 'sightseeing', '08:00', 50, 'Peaceful early morning visit'),
  (rajasthan_template_id, 4, 2, 'Drive to Udaipur', '5-hour scenic drive via Ranakpur', 'Highway', 'transport', '10:00', 4000, 'Stop at Ranakpur Jain Temple'),
  (rajasthan_template_id, 4, 3, 'Ranakpur Jain Temple', 'Intricate 1444-pillar marble temple', 'Ranakpur', 'sightseeing', '12:30', 0, 'Remove leather items before entry'),
  (rajasthan_template_id, 4, 4, 'Arrive Udaipur', 'Check-in to lakeside hotel', 'Udaipur', 'accommodation', '17:00', 4000, 'Stay near Lake Pichola'),
  (rajasthan_template_id, 4, 5, 'Lake Pichola Sunset', 'Boat ride during sunset', 'Lake Pichola', 'activity', '18:00', 800, 'Book through hotel for better rates');

  -- Day 5: Udaipur & Departure
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (rajasthan_template_id, 5, 1, 'City Palace Udaipur', 'Explore the largest palace complex in Rajasthan', 'City Palace, Udaipur', 'sightseeing', '09:00', 300, 'Start from museum section'),
  (rajasthan_template_id, 5, 2, 'Jagdish Temple', 'Beautiful Indo-Aryan temple', 'Jagdish Temple', 'sightseeing', '11:30', 0, 'Active temple, witness aarti'),
  (rajasthan_template_id, 5, 3, 'Lunch & Shopping', 'Local cuisine and handicrafts', 'Hathi Pol Bazaar', 'food', '12:30', 1500, 'Great for miniature paintings'),
  (rajasthan_template_id, 5, 4, 'Departure', 'Transfer to airport/station', 'Udaipur', 'transport', '15:00', 500, 'Udaipur airport is 25km from city');

  -- Rajasthan Packing Checklist
  INSERT INTO public.template_checklists (template_id, name, icon, order_index) VALUES
  (rajasthan_template_id, 'Heritage Tour Essentials', 'castle', 1);

  INSERT INTO public.template_checklist_items (checklist_id, content, order_index, is_essential, category)
  SELECT c.id, item.content, item.order_index, item.is_essential, item.category
  FROM public.template_checklists c
  CROSS JOIN (VALUES
    ('Comfortable walking shoes', 1, true, 'clothing'),
    ('Light cotton clothes', 2, true, 'clothing'),
    ('Scarf/Stole for temples', 3, true, 'clothing'),
    ('Sunscreen SPF 50+', 4, true, 'toiletries'),
    ('Sunglasses', 5, true, 'misc'),
    ('Hat/Cap', 6, true, 'clothing'),
    ('Water bottle', 7, true, 'misc'),
    ('Camera with extra batteries', 8, false, 'electronics'),
    ('Power bank', 9, true, 'electronics'),
    ('Light jacket (winter months)', 10, false, 'clothing'),
    ('Moisturizer (dry climate)', 11, false, 'toiletries')
  ) AS item(content, order_index, is_essential, category)
  WHERE c.template_id = rajasthan_template_id AND c.name = 'Heritage Tour Essentials';
END $$;

-- =====================================================
-- 3. KERALA BACKWATERS (4 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Kerala Backwaters & Hills',
  'Experience God''s Own Country with serene backwaters, lush tea gardens, and pristine beaches. A perfect blend of relaxation and natural beauty.',
  'Kochi - Alleppey - Munnar',
  'Kerala',
  4,
  20000,
  45000,
  'INR',
  'family',
  ARRAY['backwaters', 'houseboat', 'tea-gardens', 'nature', 'ayurveda'],
  ARRAY['September', 'October', 'November', 'December', 'January', 'February', 'March'],
  'easy',
  true,
  true
);

-- =====================================================
-- 4. HIMACHAL ADVENTURE (5 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Himachal Mountains Adventure',
  'From Shimla''s colonial charm to Manali''s adventure sports, experience the majestic Himalayas. Perfect for adventure seekers and nature lovers.',
  'Shimla - Manali',
  'Himachal Pradesh',
  5,
  20000,
  50000,
  'INR',
  'adventure',
  ARRAY['mountains', 'trekking', 'snow', 'adventure', 'paragliding'],
  ARRAY['March', 'April', 'May', 'June', 'September', 'October'],
  'moderate',
  true,
  true
);

-- =====================================================
-- 5. VARANASI SPIRITUAL (3 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Varanasi Spiritual Journey',
  'Experience the spiritual heart of India. Witness the mesmerizing Ganga Aarti, explore ancient temples, and discover the city''s timeless traditions.',
  'Varanasi',
  'Uttar Pradesh',
  3,
  10000,
  25000,
  'INR',
  'pilgrimage',
  ARRAY['spiritual', 'temples', 'ganga', 'culture', 'photography'],
  ARRAY['October', 'November', 'December', 'January', 'February', 'March'],
  'easy',
  true,
  false
);

-- =====================================================
-- 6. ANDAMAN ISLANDS (5 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Andaman Island Paradise',
  'Discover pristine beaches, crystal-clear waters, and vibrant coral reefs. Perfect for beach lovers, snorkeling enthusiasts, and history buffs.',
  'Port Blair - Havelock - Neil Island',
  'Andaman & Nicobar',
  5,
  35000,
  80000,
  'INR',
  'beach',
  ARRAY['island', 'snorkeling', 'scuba', 'beaches', 'coral-reefs'],
  ARRAY['October', 'November', 'December', 'January', 'February', 'March', 'April', 'May'],
  'easy',
  true,
  true
);

-- =====================================================
-- 7. LADAKH ROAD TRIP (7 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Ladakh - The Ultimate Road Trip',
  'Conquer the world''s highest motorable passes, witness stunning landscapes, and experience the unique Ladakhi culture. An adventure of a lifetime.',
  'Leh - Nubra - Pangong',
  'Ladakh',
  7,
  40000,
  100000,
  'INR',
  'roadTrip',
  ARRAY['road-trip', 'high-altitude', 'monasteries', 'lakes', 'adventure'],
  ARRAY['June', 'July', 'August', 'September'],
  'difficult',
  true,
  true
);

-- =====================================================
-- 8. DARJEELING & SIKKIM (5 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Darjeeling & Sikkim Hills',
  'From world-famous tea gardens to views of Kanchenjunga, explore the enchanting hill stations of Eastern Himalayas.',
  'Darjeeling - Gangtok',
  'West Bengal & Sikkim',
  5,
  25000,
  55000,
  'INR',
  'hillStation',
  ARRAY['tea-gardens', 'mountains', 'toy-train', 'monasteries', 'nature'],
  ARRAY['March', 'April', 'May', 'September', 'October', 'November'],
  'moderate',
  true,
  false
);

-- =====================================================
-- 9. KARNATAKA WILDLIFE (4 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Karnataka Wildlife Safari',
  'Experience India''s rich wildlife at Bandipur and Nagarhole. Spot tigers, elephants, leopards, and diverse bird species in their natural habitat.',
  'Mysore - Bandipur - Nagarhole',
  'Karnataka',
  4,
  30000,
  70000,
  'INR',
  'wildlife',
  ARRAY['safari', 'tigers', 'elephants', 'birds', 'nature'],
  ARRAY['October', 'November', 'December', 'January', 'February', 'March', 'April', 'May', 'June'],
  'easy',
  true,
  false
);

-- =====================================================
-- 10. PONDICHERRY WEEKEND (2 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Pondicherry French Escape',
  'A perfect weekend getaway to India''s French Quarter. Explore colorful streets, pristine beaches, spiritual ashrams, and delightful cafes.',
  'Pondicherry',
  'Puducherry',
  2,
  8000,
  20000,
  'INR',
  'weekend',
  ARRAY['french-quarter', 'beaches', 'cafes', 'ashram', 'cycling'],
  ARRAY['October', 'November', 'December', 'January', 'February', 'March'],
  'easy',
  true,
  false
);

-- =====================================================
-- SUMMARY
-- =====================================================
-- Created 10 trip templates:
-- 1. Goa Beach Getaway (3 days, Featured)
-- 2. Royal Rajasthan Heritage Tour (5 days, Featured)
-- 3. Kerala Backwaters & Hills (4 days, Featured)
-- 4. Himachal Mountains Adventure (5 days, Featured)
-- 5. Varanasi Spiritual Journey (3 days)
-- 6. Andaman Island Paradise (5 days, Featured)
-- 7. Ladakh - The Ultimate Road Trip (7 days, Featured)
-- 8. Darjeeling & Sikkim Hills (5 days)
-- 9. Karnataka Wildlife Safari (4 days)
-- 10. Pondicherry French Escape (2 days)
-- =====================================================
