-- ============================================================================
-- DUMMY DATA FOR NITHYA GANESAN (nithyaganesan53@gmail.com)
-- ============================================================================
-- This script creates sample trips, expenses, itinerary items, and checklists
-- for testing the Travel Companion app
-- ============================================================================

-- Get Nithya's user ID (replace with actual ID from your database)
-- You'll need to run: SELECT id FROM auth.users WHERE email = 'nithyaganesan53@gmail.com';
-- Then replace 'NITHYA_USER_ID' below with the actual UUID

-- For now, let's use a variable approach
DO $$
DECLARE
    nithya_user_id UUID;
    vinoth_user_id UUID;
    trip1_id UUID;
    trip2_id UUID;
    trip3_id UUID;
    expense1_id UUID;
    expense2_id UUID;
    expense3_id UUID;
    checklist1_id UUID;
    checklist2_id UUID;
BEGIN
    -- Get user IDs
    SELECT id INTO nithya_user_id FROM auth.users WHERE email = 'nithyaganesan53@gmail.com';
    SELECT id INTO vinoth_user_id FROM auth.users WHERE email = 'vinothvsbe@gmail.com';

    -- Check if Nithya's account exists
    IF nithya_user_id IS NULL THEN
        RAISE NOTICE 'User nithyaganesan53@gmail.com not found. Please create the account first.';
        RETURN;
    END IF;

    -- Auto-cleanup: Delete any existing data for Nithya to avoid duplicates
    RAISE NOTICE 'Checking for existing data...';

    -- Delete in order to respect foreign key constraints
    DELETE FROM checklist_items
    WHERE checklist_id IN (SELECT id FROM checklists WHERE created_by = nithya_user_id);

    DELETE FROM checklists WHERE created_by = nithya_user_id;
    DELETE FROM expense_splits WHERE user_id = nithya_user_id;
    DELETE FROM expenses WHERE paid_by = nithya_user_id;
    DELETE FROM itinerary_items WHERE created_by = nithya_user_id;
    DELETE FROM trip_members WHERE user_id = nithya_user_id;
    DELETE FROM trips WHERE created_by = nithya_user_id;

    RAISE NOTICE '✓ Cleaned up any existing data';
    RAISE NOTICE 'Creating dummy data for Nithya (User ID: %)', nithya_user_id;

    -- ========================================================================
    -- TRIP 1: Weekend Getaway to Goa (Upcoming)
    -- ========================================================================
    trip1_id := gen_random_uuid();

    INSERT INTO trips (
        id, created_by, name, destination, start_date, end_date,
        description, cover_image_url
    ) VALUES (
        trip1_id,
        nithya_user_id,
        'Weekend Getaway to Goa',
        'Goa, India',
        CURRENT_DATE + INTERVAL '15 days',
        CURRENT_DATE + INTERVAL '18 days',
        'Beach relaxation, water sports, and nightlife. Going to explore North Goa beaches!',
        'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=800'
    );

    -- Add Nithya as trip admin
    INSERT INTO trip_members (id, trip_id, user_id, role, joined_at)
    VALUES (gen_random_uuid(), trip1_id, nithya_user_id, 'admin', NOW())
    ON CONFLICT (trip_id, user_id) DO NOTHING;

    -- Add Vinoth as a member (if exists)
    IF vinoth_user_id IS NOT NULL THEN
        INSERT INTO trip_members (id, trip_id, user_id, role, joined_at)
        VALUES (gen_random_uuid(), trip1_id, vinoth_user_id, 'member', NOW())
        ON CONFLICT (trip_id, user_id) DO NOTHING;
    END IF;

    -- Itinerary for Goa Trip
    INSERT INTO itinerary_items (id, trip_id, title, description, location, start_time, end_time, day_number, order_index, created_by)
    VALUES
        (gen_random_uuid(), trip1_id, 'Arrive at Goa Airport', 'Pick up rental car', 'Goa Airport',
         CURRENT_DATE + INTERVAL '15 days' + TIME '10:00', CURRENT_DATE + INTERVAL '15 days' + TIME '11:00',
         1, 1, nithya_user_id),

        (gen_random_uuid(), trip1_id, 'Check-in at Beach Resort', 'Sea-facing room booked', 'Calangute Beach Resort',
         CURRENT_DATE + INTERVAL '15 days' + TIME '12:00', CURRENT_DATE + INTERVAL '15 days' + TIME '13:00',
         1, 2, nithya_user_id),

        (gen_random_uuid(), trip1_id, 'Lunch at Beach Shack', 'Try fresh seafood', 'Curlies Beach Shack',
         CURRENT_DATE + INTERVAL '15 days' + TIME '14:00', CURRENT_DATE + INTERVAL '15 days' + TIME '15:30',
         1, 3, nithya_user_id),

        (gen_random_uuid(), trip1_id, 'Beach Time & Sunset', 'Relax and enjoy sunset', 'Anjuna Beach',
         CURRENT_DATE + INTERVAL '15 days' + TIME '16:00', CURRENT_DATE + INTERVAL '15 days' + TIME '19:00',
         1, 4, nithya_user_id),

        (gen_random_uuid(), trip1_id, 'Water Sports', 'Parasailing and jet skiing', 'Baga Beach',
         CURRENT_DATE + INTERVAL '16 days' + TIME '09:00', CURRENT_DATE + INTERVAL '16 days' + TIME '12:00',
         2, 1, nithya_user_id),

        (gen_random_uuid(), trip1_id, 'Visit Fort Aguada', 'Historical fort with great views', 'Fort Aguada',
         CURRENT_DATE + INTERVAL '16 days' + TIME '15:00', CURRENT_DATE + INTERVAL '16 days' + TIME '17:00',
         2, 2, nithya_user_id);

    -- Checklist for Goa Trip
    checklist1_id := gen_random_uuid();
    INSERT INTO checklists (id, trip_id, name, created_by)
    VALUES (checklist1_id, trip1_id, 'Packing List', nithya_user_id);

    INSERT INTO checklist_items (id, checklist_id, title, is_completed, assigned_to)
    VALUES
        (gen_random_uuid(), checklist1_id, 'Swimwear', true, nithya_user_id),
        (gen_random_uuid(), checklist1_id, 'Sunscreen SPF 50+', true, nithya_user_id),
        (gen_random_uuid(), checklist1_id, 'Beach towels', false, nithya_user_id),
        (gen_random_uuid(), checklist1_id, 'Flip flops & sandals', true, nithya_user_id),
        (gen_random_uuid(), checklist1_id, 'Camera & charger', false, nithya_user_id),
        (gen_random_uuid(), checklist1_id, 'Light cotton clothes', false, nithya_user_id),
        (gen_random_uuid(), checklist1_id, 'Mosquito repellent', false, nithya_user_id),
        (gen_random_uuid(), checklist1_id, 'First aid kit', false, nithya_user_id);

    -- Expenses for Goa Trip
    expense1_id := gen_random_uuid();
    INSERT INTO expenses (id, trip_id, title, description, amount, category, paid_by, transaction_date)
    VALUES (
        expense1_id, trip1_id, 'Flight Tickets', 'Mumbai to Goa round trip', 8500.00,
        'transport', nithya_user_id, CURRENT_DATE - INTERVAL '5 days'
    );

    -- Split equally between Nithya and Vinoth (if exists)
    IF vinoth_user_id IS NOT NULL THEN
        INSERT INTO expense_splits (id, expense_id, user_id, amount)
        VALUES
            (gen_random_uuid(), expense1_id, nithya_user_id, 4250.00),
            (gen_random_uuid(), expense1_id, vinoth_user_id, 4250.00);
    ELSE
        INSERT INTO expense_splits (id, expense_id, user_id, amount)
        VALUES (gen_random_uuid(), expense1_id, nithya_user_id, 8500.00);
    END IF;

    expense2_id := gen_random_uuid();
    INSERT INTO expenses (id, trip_id, title, description, amount, category, paid_by, transaction_date)
    VALUES (
        expense2_id, trip1_id, 'Beach Resort Booking', '3 nights stay at Calangute', 12000.00,
        'accommodation', nithya_user_id, CURRENT_DATE - INTERVAL '3 days'
    );

    IF vinoth_user_id IS NOT NULL THEN
        INSERT INTO expense_splits (id, expense_id, user_id, amount)
        VALUES
            (gen_random_uuid(), expense2_id, nithya_user_id, 6000.00),
            (gen_random_uuid(), expense2_id, vinoth_user_id, 6000.00);
    ELSE
        INSERT INTO expense_splits (id, expense_id, user_id, amount)
        VALUES (gen_random_uuid(), expense2_id, nithya_user_id, 12000.00);
    END IF;

    -- ========================================================================
    -- TRIP 2: Ooty Hill Station Retreat (Past Trip)
    -- ========================================================================
    trip2_id := gen_random_uuid();

    INSERT INTO trips (
        id, created_by, name, destination, start_date, end_date,
        description, cover_image_url
    ) VALUES (
        trip2_id,
        nithya_user_id,
        'Ooty Hill Station Retreat',
        'Ooty, Tamil Nadu',
        CURRENT_DATE - INTERVAL '30 days',
        CURRENT_DATE - INTERVAL '27 days',
        'Peaceful hill station escape with tea gardens and botanical gardens',
        'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800'
    );

    INSERT INTO trip_members (id, trip_id, user_id, role, joined_at)
    VALUES (gen_random_uuid(), trip2_id, nithya_user_id, 'admin', CURRENT_DATE - INTERVAL '35 days')
    ON CONFLICT (trip_id, user_id) DO NOTHING;

    -- Some expenses from past trip
    expense3_id := gen_random_uuid();
    INSERT INTO expenses (id, trip_id, title, description, amount, category, paid_by, transaction_date)
    VALUES (
        expense3_id, trip2_id, 'Toy Train Ride', 'Nilgiri Mountain Railway', 2500.00,
        'activities', nithya_user_id, CURRENT_DATE - INTERVAL '29 days'
    );

    INSERT INTO expense_splits (id, expense_id, user_id, amount)
    VALUES (gen_random_uuid(), expense3_id, nithya_user_id, 2500.00);

    INSERT INTO expenses (id, trip_id, title, description, amount, category, paid_by, transaction_date)
    VALUES (
        gen_random_uuid(), trip2_id, 'Tea Garden Tour', 'Guided tour with tea tasting', 1200.00,
        'activities', nithya_user_id, CURRENT_DATE - INTERVAL '28 days'
    );

    -- ========================================================================
    -- TRIP 3: Kerala Backwaters (Planning)
    -- ========================================================================
    trip3_id := gen_random_uuid();

    INSERT INTO trips (
        id, created_by, name, destination, start_date, end_date,
        description, cover_image_url
    ) VALUES (
        trip3_id,
        nithya_user_id,
        'Kerala Backwaters Experience',
        'Alleppey, Kerala',
        CURRENT_DATE + INTERVAL '60 days',
        CURRENT_DATE + INTERVAL '65 days',
        'Houseboat cruise through serene backwaters with authentic Kerala cuisine',
        'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=800'
    );

    INSERT INTO trip_members (id, trip_id, user_id, role, joined_at)
    VALUES (gen_random_uuid(), trip3_id, nithya_user_id, 'admin', NOW())
    ON CONFLICT (trip_id, user_id) DO NOTHING;

    -- Checklist for Kerala Trip
    checklist2_id := gen_random_uuid();
    INSERT INTO checklists (id, trip_id, name, created_by)
    VALUES (checklist2_id, trip3_id, 'Pre-Trip To-Do', nithya_user_id);

    INSERT INTO checklist_items (id, checklist_id, title, is_completed, assigned_to)
    VALUES
        (gen_random_uuid(), checklist2_id, 'Book houseboat', false, nithya_user_id),
        (gen_random_uuid(), checklist2_id, 'Research Ayurvedic spas', false, nithya_user_id),
        (gen_random_uuid(), checklist2_id, 'Check visa requirements', true, nithya_user_id),
        (gen_random_uuid(), checklist2_id, 'Book flight tickets', false, nithya_user_id);

    -- ========================================================================
    -- STANDALONE EXPENSES (No trip association)
    -- ========================================================================
    INSERT INTO expenses (id, trip_id, title, description, amount, category, paid_by, transaction_date)
    VALUES
        (gen_random_uuid(), NULL, 'Travel Guide Books', 'Lonely Planet India', 1200.00,
         'shopping', nithya_user_id, CURRENT_DATE - INTERVAL '10 days'),

        (gen_random_uuid(), NULL, 'New Backpack', 'Travel backpack 60L', 3500.00,
         'shopping', nithya_user_id, CURRENT_DATE - INTERVAL '7 days'),

        (gen_random_uuid(), NULL, 'Travel Insurance', 'Annual policy', 4500.00,
         'other', nithya_user_id, CURRENT_DATE - INTERVAL '2 days');

    RAISE NOTICE '✅ Dummy data created successfully!';
    RAISE NOTICE '   - 3 Trips (1 completed, 2 upcoming)';
    RAISE NOTICE '   - 6 Expenses (3 trip, 3 standalone)';
    RAISE NOTICE '   - 6 Itinerary items';
    RAISE NOTICE '   - 2 Checklists with 12 items total';

END $$;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Run these to verify the data was created:

-- Check trips
-- SELECT id, name, destination, start_date, end_date
-- FROM trips
-- WHERE created_by = (SELECT id FROM auth.users WHERE email = 'nithyaganesan53@gmail.com')
-- ORDER BY start_date;

-- Check expenses
-- SELECT e.id, e.title, e.amount, e.category, t.name as trip_name
-- FROM expenses e
-- LEFT JOIN trips t ON e.trip_id = t.id
-- WHERE e.paid_by = (SELECT id FROM auth.users WHERE email = 'nithyaganesan53@gmail.com')
-- ORDER BY e.transaction_date DESC;

-- Check checklists
-- SELECT c.title, COUNT(ci.id) as items_count,
--        SUM(CASE WHEN ci.is_completed THEN 1 ELSE 0 END) as completed_count
-- FROM checklists c
-- LEFT JOIN checklist_items ci ON c.id = ci.checklist_id
-- WHERE c.created_by = (SELECT id FROM auth.users WHERE email = 'nithyaganesan53@gmail.com')
-- GROUP BY c.id, c.title;
