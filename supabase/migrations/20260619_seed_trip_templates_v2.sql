-- =====================================================
-- SEED: Trip Templates v2 (idempotent)
-- Run this in Supabase Dashboard → SQL Editor
-- Safe to re-run: uses ON CONFLICT (id) DO NOTHING
-- Explicit UUIDs match HardcodedTemplates in the app
-- =====================================================

INSERT INTO public.trip_templates (
  id, name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured, use_count, rating
) VALUES
  (
    '550e8400-e29b-41d4-a716-446655440001',
    'Goa Beach Getaway',
    'Experience the perfect beach vacation in Goa with stunning beaches, vibrant nightlife, and delicious seafood. Visit iconic churches, enjoy water sports, and relax by the Arabian Sea.',
    'Goa', 'Goa', 3, 15000, 35000, 'INR', 'beach',
    ARRAY['beach','party','seafood','water-sports','nightlife'],
    ARRAY['October','November','December','January','February','March'],
    'easy', true, true, 250, 4.8
  ),
  (
    '550e8400-e29b-41d4-a716-446655440002',
    'Royal Rajasthan Heritage Tour',
    'Explore the magnificent forts, palaces, and rich culture of Rajasthan. From the Pink City of Jaipur to the Blue City of Jodhpur, experience royal India.',
    'Jaipur - Jodhpur - Udaipur', 'Rajasthan', 5, 25000, 60000, 'INR', 'heritage',
    ARRAY['forts','palaces','culture','history','photography'],
    ARRAY['October','November','December','January','February','March'],
    'easy', true, true, 380, 4.9
  ),
  (
    '550e8400-e29b-41d4-a716-446655440003',
    'Kerala Backwaters & Hills',
    'Experience God''s Own Country with serene backwaters, lush tea gardens, and pristine beaches. A perfect blend of relaxation and natural beauty.',
    'Kochi - Alleppey - Munnar', 'Kerala', 4, 20000, 45000, 'INR', 'family',
    ARRAY['backwaters','houseboat','tea-gardens','nature','ayurveda'],
    ARRAY['September','October','November','December','January','February','March'],
    'easy', true, true, 310, 4.7
  ),
  (
    '550e8400-e29b-41d4-a716-446655440004',
    'Himachal Mountains Adventure',
    'From Shimla''s colonial charm to Manali''s adventure sports, experience the majestic Himalayas. Perfect for adventure seekers and nature lovers.',
    'Shimla - Manali', 'Himachal Pradesh', 5, 20000, 50000, 'INR', 'adventure',
    ARRAY['mountains','trekking','snow','adventure','paragliding'],
    ARRAY['March','April','May','June','September','October'],
    'moderate', true, true, 290, 4.6
  ),
  (
    '550e8400-e29b-41d4-a716-446655440005',
    'Varanasi Spiritual Journey',
    'Experience the spiritual heart of India. Witness the mesmerizing Ganga Aarti, explore ancient temples, and discover the city''s timeless traditions.',
    'Varanasi', 'Uttar Pradesh', 3, 10000, 25000, 'INR', 'pilgrimage',
    ARRAY['spiritual','temples','ganga','culture','photography'],
    ARRAY['October','November','December','January','February','March'],
    'easy', true, false, 180, 4.5
  ),
  (
    '550e8400-e29b-41d4-a716-446655440006',
    'Andaman Island Paradise',
    'Discover pristine beaches, crystal-clear waters, and vibrant coral reefs. Perfect for beach lovers, snorkeling enthusiasts, and history buffs.',
    'Port Blair - Havelock - Neil Island', 'Andaman & Nicobar', 5, 35000, 80000, 'INR', 'beach',
    ARRAY['island','snorkeling','scuba','beaches','coral-reefs'],
    ARRAY['October','November','December','January','February','March','April','May'],
    'easy', true, true, 220, 4.8
  ),
  (
    '550e8400-e29b-41d4-a716-446655440007',
    'Ladakh - The Ultimate Road Trip',
    'Conquer the world''s highest motorable passes, witness stunning landscapes, and experience the unique Ladakhi culture. An adventure of a lifetime.',
    'Leh - Nubra - Pangong', 'Ladakh', 7, 40000, 100000, 'INR', 'roadTrip',
    ARRAY['road-trip','high-altitude','monasteries','lakes','adventure'],
    ARRAY['June','July','August','September'],
    'difficult', true, true, 340, 4.9
  ),
  (
    '550e8400-e29b-41d4-a716-446655440008',
    'Darjeeling & Sikkim Hills',
    'From world-famous tea gardens to views of Kanchenjunga, explore the enchanting hill stations of the Eastern Himalayas.',
    'Darjeeling - Gangtok', 'West Bengal & Sikkim', 5, 25000, 55000, 'INR', 'hillStation',
    ARRAY['tea-gardens','mountains','toy-train','monasteries','nature'],
    ARRAY['March','April','May','September','October','November'],
    'moderate', true, false, 150, 4.6
  ),
  (
    '550e8400-e29b-41d4-a716-446655440009',
    'Karnataka Wildlife Safari',
    'Experience India''s rich wildlife at Bandipur and Nagarhole. Spot tigers, elephants, leopards, and diverse bird species in their natural habitat.',
    'Mysore - Bandipur - Nagarhole', 'Karnataka', 4, 30000, 70000, 'INR', 'wildlife',
    ARRAY['safari','tigers','elephants','birds','nature'],
    ARRAY['October','November','December','January','February','March','April','May','June'],
    'easy', true, false, 130, 4.5
  ),
  (
    '550e8400-e29b-41d4-a716-446655440010',
    'Pondicherry French Escape',
    'A perfect weekend getaway to India''s French Quarter. Explore colorful streets, pristine beaches, spiritual ashrams, and delightful cafes.',
    'Pondicherry', 'Puducherry', 2, 8000, 20000, 'INR', 'weekend',
    ARRAY['french-quarter','beaches','cafes','ashram','cycling'],
    ARRAY['October','November','December','January','February','March'],
    'easy', true, false, 200, 4.4
  ),
  (
    '550e8400-e29b-41d4-a716-446655440011',
    'Maldives Honeymoon Escape',
    'The ultimate romantic getaway with overwater villas, pristine turquoise lagoons, and breathtaking sunsets. Perfect for newlyweds.',
    'Malé - Maafushi', NULL, 5, 100000, 300000, 'INR', 'honeymoon',
    ARRAY['romantic','overwater-villa','snorkeling','luxury','sunset'],
    ARRAY['November','December','January','February','March','April'],
    'easy', true, true, 175, 4.9
  ),
  (
    '550e8400-e29b-41d4-a716-446655440012',
    'Coorg Coffee Estate Retreat',
    'Escape to the Scotland of India — rolling coffee plantations, misty hills, and cascading waterfalls. Ideal for a relaxed family weekend.',
    'Coorg', 'Karnataka', 3, 15000, 40000, 'INR', 'family',
    ARRAY['coffee','plantation','waterfall','trekking','nature'],
    ARRAY['October','November','December','January','February','March','April'],
    'easy', true, false, 140, 4.6
  )
ON CONFLICT (id) DO NOTHING;
