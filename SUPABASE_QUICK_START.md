# Supabase Quick Start Guide

## ✅ Integration Status: COMPLETE

Your Travel Crew app is now integrated with Supabase!

---

## 🎯 What You Need to Do Next

### **CRITICAL: Deploy Database Schema** ⚠️

Before the app can store data in Supabase, you must deploy the schema:

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard/project/ckgaoxajvonazdwpsmai
   - Login with your Supabase account

2. **Run the SQL Schema**
   - Click **SQL Editor** in the left sidebar
   - Click **New Query**
   - Open `SUPABASE_SCHEMA.sql` from your project
   - Copy all contents (789 lines) and paste into the editor
   - Click **Run** or press `Cmd+Enter`
   - Wait for success message (should take 5-10 seconds)

3. **Verify Tables Created**
   - Click **Table Editor** in the left sidebar
   - You should see 12 tables:
     - profiles, trips, trip_members, trip_invites
     - itinerary_items, checklists, checklist_items
     - expenses, expense_splits, settlements
     - autopilot_suggestions, notifications

**Note**: The schema is idempotent - you can run it multiple times safely. It will drop and recreate all objects.

---

## 🚀 Run the App

```bash
# Run on iOS Simulator
flutter run

# Run on Android Emulator
flutter run

# Run on Chrome (for testing)
flutter run -d chrome
```

When the app starts, you should see in the console:
```
✅ Supabase initialized successfully
```

---

## 🔐 Test Authentication

1. **Launch the app**
2. **Sign up** with a new account:
   - Email: your-email@example.com
   - Password: (minimum 6 characters)
3. **Check Supabase Dashboard**:
   - Go to **Authentication** → **Users**
   - You should see your new user!

---

## 📊 Your Supabase Credentials

```
Project URL: https://ckgaoxajvonazdwpsmai.supabase.co
Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Location in code**: `lib/core/config/supabase_config.dart`

---

## 💡 Quick Tips

### **Check if Supabase is Working**

```dart
import 'package:travel_crew/core/network/supabase_client.dart';

// Check initialization
if (SupabaseClientWrapper.isAuthenticated) {
  print('User is logged in!');
  print('User ID: ${SupabaseClientWrapper.currentUserId}');
}
```

### **Common Issues & Solutions**

**Issue**: "Supabase not initialized" error
- **Solution**: Make sure app calls `SupabaseClientWrapper.initialize()` in `main.dart`

**Issue**: "Table does not exist" error
- **Solution**: Deploy the `SUPABASE_SCHEMA.sql` to your Supabase project

**Issue**: "Invalid API key" error
- **Solution**: Verify credentials in `supabase_config.dart` match your dashboard

---

## 📚 Documentation Files

- **Full Guide**: [SUPABASE_INTEGRATION.md](SUPABASE_INTEGRATION.md)
- **Database Schema**: [SUPABASE_SCHEMA.sql](SUPABASE_SCHEMA.sql)
- **App Setup**: [SETUP.md](SETUP.md)

---

## 🎉 What's Enabled

✅ **Supabase Client**: Fully configured and initialized
✅ **Authentication**: Sign up, login, logout ready
✅ **Database**: Ready to use (after schema deployment)
✅ **Real-time**: Subscriptions enabled
✅ **Storage**: File upload ready
✅ **Hybrid Mode**: Works with both Supabase and SQLite

---

## ⚡ Quick Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Check for errors
flutter analyze

# Run tests
flutter test

# Build for production
flutter build apk  # Android
flutter build ios  # iOS
```

---

**Need Help?** Check the full guide at [SUPABASE_INTEGRATION.md](SUPABASE_INTEGRATION.md)
