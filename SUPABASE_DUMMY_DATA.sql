-- =====================================================
-- TRAVEL CREW APP - DUMMY DATA FOR TESTING
-- =====================================================
-- Run this AFTER deploying SUPABASE_SCHEMA.sql
-- This creates test trips, expenses, and itinerary items
-- =====================================================

-- IMPORTANT: You must sign up in the app first to create a real user!
-- Then run this script to populate data for that user.

DO $$
DECLARE
    user1_id UUID;
    user2_id UUID;
    user3_id UUID;
    trip1_id UUID;
    trip2_id UUID;
    expense1_id UUID;
    checklist1_id UUID;
BEGIN
    -- =====================================================
    -- STEP 1: Get existing auth users
    -- =====================================================

    -- Get the most recent user from auth.users (you who just signed up)
    SELECT id INTO user1_id FROM auth.users ORDER BY created_at DESC LIMIT 1;

    IF user1_id IS NULL THEN
        RAISE EXCEPTION '❌ No users found! Please sign up in the app first, then run this script.';
    END IF;

    -- Use the same user for all test data (you can add more users later)
    user2_id := user1_id;
    user3_id := user1_id;

    RAISE NOTICE '✓ Found user: %', user1_id;
    RAISE NOTICE '  Using this user for all test data';

    -- =====================================================
    -- STEP 2: Create Test Trips
    -- =====================================================

    -- Trip 1: Bali Adventure (upcoming)
    INSERT INTO trips (name, description, destination, start_date, end_date, created_by, created_at, updated_at)
    VALUES (
        'Bali Adventure 2025',
        'Epic trip to explore beautiful Bali - beaches, temples, and amazing food!',
        'Bali, Indonesia',
        CURRENT_DATE + INTERVAL '30 days',
        CURRENT_DATE + INTERVAL '40 days',
        user1_id,
        NOW(),
        NOW()
    )
    RETURNING id INTO trip1_id;

    RAISE NOTICE '✓ Created Trip 1: Bali Adventure';
    RAISE NOTICE '  - ID: %', trip1_id;

    -- Trip 2: Tokyo Food Tour (ongoing)
    INSERT INTO trips (name, description, destination, start_date, end_date, created_by, created_at, updated_at)
    VALUES (
        'Tokyo Food Tour',
        'Exploring the amazing culinary scene in Tokyo - sushi, ramen, and more!',
        'Tokyo, Japan',
        CURRENT_DATE - INTERVAL '3 days',
        CURRENT_DATE + INTERVAL '4 days',
        user1_id,
        NOW(),
        NOW()
    )
    RETURNING id INTO trip2_id;

    RAISE NOTICE '✓ Created Trip 2: Tokyo Food Tour';
    RAISE NOTICE '  - ID: %', trip2_id;

    -- =====================================================
    -- STEP 3: Create Itinerary Items
    -- =====================================================

    -- Bali itinerary items
    INSERT INTO itinerary_items (trip_id, title, description, location, start_time, end_time, day_number, order_index, created_by, created_at, updated_at)
    VALUES
        -- Day 1
        (trip1_id, 'Arrival & Check-in', 'Arrive at Ngurah Rai Airport, transfer to hotel in Seminyak', 'Seminyak, Bali',
         (CURRENT_DATE + INTERVAL '30 days')::timestamp + TIME '14:00',
         (CURRENT_DATE + INTERVAL '30 days')::timestamp + TIME '16:00',
         1, 1, user1_id, NOW(), NOW()),

        (trip1_id, 'Sunset at Tanah Lot Temple', 'Visit the iconic sea temple and watch sunset', 'Tanah Lot, Bali',
         (CURRENT_DATE + INTERVAL '30 days')::timestamp + TIME '17:00',
         (CURRENT_DATE + INTERVAL '30 days')::timestamp + TIME '19:30',
         1, 2, user1_id, NOW(), NOW()),

        -- Day 2
        (trip1_id, 'Ubud Rice Terraces', 'Explore Tegalalang Rice Terraces, coffee plantation visit', 'Ubud, Bali',
         (CURRENT_DATE + INTERVAL '31 days')::timestamp + TIME '09:00',
         (CURRENT_DATE + INTERVAL '31 days')::timestamp + TIME '13:00',
         2, 1, user1_id, NOW(), NOW()),

        (trip1_id, 'Ubud Monkey Forest', 'Visit the sacred monkey sanctuary', 'Ubud, Bali',
         (CURRENT_DATE + INTERVAL '31 days')::timestamp + TIME '14:00',
         (CURRENT_DATE + INTERVAL '31 days')::timestamp + TIME '16:00',
         2, 2, user1_id, NOW(), NOW()),

        -- Day 3
        (trip1_id, 'Snorkeling at Blue Lagoon', 'Snorkeling adventure at Blue Lagoon Beach', 'Padang Bai, Bali',
         (CURRENT_DATE + INTERVAL '32 days')::timestamp + TIME '08:00',
         (CURRENT_DATE + INTERVAL '32 days')::timestamp + TIME '14:00',
         3, 1, user1_id, NOW(), NOW());

    -- Tokyo itinerary items
    INSERT INTO itinerary_items (trip_id, title, description, location, start_time, end_time, day_number, order_index, created_by, created_at, updated_at)
    VALUES
        (trip2_id, 'Tsukiji Fish Market', 'Early morning visit to the famous fish market', 'Tsukiji, Tokyo',
         (CURRENT_DATE - INTERVAL '2 days')::timestamp + TIME '05:00',
         (CURRENT_DATE - INTERVAL '2 days')::timestamp + TIME '09:00',
         2, 1, user1_id, NOW(), NOW()),

        (trip2_id, 'Ramen Tasting Tour', 'Visit 3 famous ramen shops in Shinjuku', 'Shinjuku, Tokyo',
         (CURRENT_DATE - INTERVAL '1 day')::timestamp + TIME '12:00',
         (CURRENT_DATE - INTERVAL '1 day')::timestamp + TIME '15:00',
         3, 1, user1_id, NOW(), NOW());

    RAISE NOTICE '✓ Created 7 itinerary items';
    RAISE NOTICE '  - Bali: 5 activities across 3 days';
    RAISE NOTICE '  - Tokyo: 2 food experiences';

    -- =====================================================
    -- STEP 4: Create Expenses
    -- =====================================================

    -- Bali expenses
    INSERT INTO expenses (trip_id, title, description, amount, currency, category, paid_by, split_type, transaction_date, created_at, updated_at)
    VALUES
        (trip1_id, 'Hotel Booking - Seminyak', 'Luxury villa with pool for 10 nights', 1500.00, 'USD', 'accommodation', user1_id, 'equal', NOW(), NOW(), NOW()),
        (trip1_id, 'Airport Transfer', 'Private car from airport to hotel', 35.00, 'USD', 'transport', user1_id, 'equal', NOW(), NOW(), NOW());

    -- Insert dinner expense separately to get its ID
    INSERT INTO expenses (trip_id, title, description, amount, currency, category, paid_by, split_type, transaction_date, created_at, updated_at)
    VALUES
        (trip1_id, 'Dinner at Tanah Lot', 'Seafood dinner with sunset view', 120.00, 'USD', 'food', user1_id, 'equal', NOW(), NOW(), NOW())
    RETURNING id INTO expense1_id;

    -- Create expense splits for the last expense
    INSERT INTO expense_splits (expense_id, user_id, amount, is_settled, created_at)
    VALUES
        (expense1_id, user1_id, 120.00, FALSE, NOW());

    -- Tokyo expenses
    INSERT INTO expenses (trip_id, title, description, amount, currency, category, paid_by, split_type, transaction_date, created_at, updated_at)
    VALUES
        (trip2_id, 'Tsukiji Market Breakfast', 'Fresh sushi breakfast at the market', 45.00, 'USD', 'food', user1_id, 'equal', NOW() - INTERVAL '2 days', NOW(), NOW()),
        (trip2_id, 'Ramen Tour', 'Three bowls of amazing ramen', 30.00, 'USD', 'food', user1_id, 'equal', NOW() - INTERVAL '1 day', NOW(), NOW());

    -- Standalone expense (no trip)
    INSERT INTO expenses (trip_id, title, description, amount, currency, category, paid_by, split_type, transaction_date, created_at, updated_at)
    VALUES
        (NULL, 'Coffee with Friends', 'Starbucks meetup', 25.00, 'USD', 'food', user1_id, 'equal', NOW(), NOW(), NOW());

    RAISE NOTICE '✓ Created 6 expenses';
    RAISE NOTICE '  - Bali: 3 expenses ($1,655 total)';
    RAISE NOTICE '  - Tokyo: 2 expenses ($75 total)';
    RAISE NOTICE '  - Standalone: 1 expense ($25)';

    -- =====================================================
    -- STEP 5: Create Checklists
    -- =====================================================

    -- Bali packing checklist
    INSERT INTO checklists (trip_id, name, created_by, created_at, updated_at)
    VALUES (trip1_id, 'Bali Packing List', user1_id, NOW(), NOW())
    RETURNING id INTO checklist1_id;

    INSERT INTO checklist_items (checklist_id, title, is_completed, assigned_to, order_index, created_at, updated_at)
    VALUES
        (checklist1_id, 'Passport & visa documents', TRUE, user1_id, 1, NOW(), NOW()),
        (checklist1_id, 'Sunscreen SPF 50+', TRUE, user1_id, 2, NOW(), NOW()),
        (checklist1_id, 'Swimwear', FALSE, user1_id, 3, NOW(), NOW()),
        (checklist1_id, 'Beach towels', FALSE, user1_id, 4, NOW(), NOW()),
        (checklist1_id, 'Camera & SD cards', FALSE, user1_id, 5, NOW(), NOW()),
        (checklist1_id, 'Medications', FALSE, user1_id, 6, NOW(), NOW()),
        (checklist1_id, 'Power adapter (UK plug)', TRUE, user1_id, 7, NOW(), NOW());

    RAISE NOTICE '✓ Created 1 checklist with 7 items';
    RAISE NOTICE '  - 3 items completed, 4 pending';

    -- =====================================================
    -- STEP 6: Create Notifications
    -- =====================================================

    INSERT INTO notifications (user_id, trip_id, title, message, type, is_read, created_at)
    VALUES
        (user1_id, trip1_id, 'Welcome to Bali!', 'Your Bali Adventure trip is coming up soon!', 'trip_updated', FALSE, NOW()),
        (user1_id, trip2_id, 'Tokyo Food Tour', 'Your Tokyo Food Tour is currently ongoing', 'trip_updated', FALSE, NOW() - INTERVAL '2 days'),
        (user1_id, trip1_id, 'Checklist reminder', 'Don''t forget to pack for your Bali trip!', 'checklist_update', TRUE, NOW() - INTERVAL '1 day'),
        (user1_id, trip1_id, 'Expense added', 'Hotel booking expense added ($1,500)', 'expense_added', FALSE, NOW());

    RAISE NOTICE '✓ Created 4 notifications';

    -- =====================================================
    -- COMPLETION MESSAGE
    -- =====================================================

    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ✅ DUMMY DATA INSERTED SUCCESSFULLY!                      ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Summary:';
    RAISE NOTICE '   ✓ Using your user account: %', user1_id;
    RAISE NOTICE '   ✓ 2 trips (Bali Adventure, Tokyo Food Tour)';
    RAISE NOTICE '   ✓ 7 itinerary items';
    RAISE NOTICE '   ✓ 6 expenses ($1,755 total)';
    RAISE NOTICE '   ✓ 3 expense splits';
    RAISE NOTICE '   ✓ 1 checklist with 7 items';
    RAISE NOTICE '   ✓ 4 notifications';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Next Steps:';
    RAISE NOTICE '   1. Log out and log back into your app';
    RAISE NOTICE '   2. You should see 2 trips on the home page!';
    RAISE NOTICE '   3. Tap on a trip to see itinerary, expenses, and checklists';
    RAISE NOTICE '';
    RAISE NOTICE '📱 Test in your app:';
    RAISE NOTICE '   - Home: See Bali & Tokyo trips';
    RAISE NOTICE '   - Tap Bali: See 5 itinerary items';
    RAISE NOTICE '   - Expenses: See $1,755 in expenses';
    RAISE NOTICE '   - Checklist: See 7 packing items';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Enjoy testing your app!';
    RAISE NOTICE '';
END $$;
