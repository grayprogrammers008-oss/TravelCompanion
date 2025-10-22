# Travel Crew App - Setup Guide

## Prerequisites

- Flutter SDK (3.35.5 or higher)
- Dart SDK (3.9.2 or higher)
- A Supabase account
- A Claude API key (for Autopilot feature)
- Firebase project (for push notifications)

## Step 1: Install Dependencies

```bash
flutter pub get
```

## Step 2: Set Up Supabase

### 2.1 Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in project details and create the project

### 2.2 Run the Database Schema

1. In your Supabase dashboard, navigate to **SQL Editor**
2. Click "New Query"
3. Copy the entire content from `SUPABASE_SCHEMA.sql`
4. Paste it into the SQL editor
5. Click "Run" to execute the schema

### 2.3 Configure Supabase Credentials

1. In Supabase dashboard, go to **Settings** → **API**
2. Copy your **Project URL**
3. Copy your **anon/public key**
4. Update `lib/core/config/supabase_config.dart` with these values

**Option A: Update the config file directly**
```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key-here';
```

**Option B: Use environment variables (Recommended)**
```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### 2.4 Enable Realtime

1. In Supabase dashboard, go to **Database** → **Replication**
2. Ensure the following tables are enabled for realtime:
   - trips
   - trip_members
   - itinerary_items
   - checklists
   - checklist_items
   - expenses
   - expense_splits
   - notifications

## Step 3: Set Up Firebase (for Push Notifications)

### 3.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Follow the setup wizard

### 3.2 Add Android App

1. In Firebase project, click "Add app" → Android
2. Package name: `com.travelcrew.travel_crew`
3. Download `google-services.json`
4. Place it in `android/app/`

### 3.3 Add iOS App

1. Click "Add app" → iOS
2. Bundle ID: `com.travelcrew.travelCrew`
3. Download `GoogleService-Info.plist`
4. Add it to `ios/Runner/` via Xcode

### 3.4 Enable Cloud Messaging

1. In Firebase Console, go to **Cloud Messaging**
2. Enable the API if not already enabled
3. Copy the Server Key (for backend notifications)

## Step 4: Configure Claude API (for Autopilot)

1. Get your Claude API key from [Anthropic Console](https://console.anthropic.com/)
2. Update `lib/core/config/supabase_config.dart`:

```dart
static const String claudeApiKey = 'your-claude-api-key';
```

Or use environment variables:
```bash
flutter run --dart-define=CLAUDE_API_KEY=your-api-key
```

## Step 5: Run the App

### Android
```bash
flutter run
```

### iOS
```bash
cd ios
pod install
cd ..
flutter run
```

### Web
```bash
flutter run -d chrome
```

## Project Structure

```
lib/
├── core/
│   ├── config/           # App configuration
│   ├── constants/        # Constants and enums
│   ├── network/          # Network utilities
│   ├── router/           # Navigation and routing
│   ├── theme/            # App theme
│   └── utils/            # Utility functions
├── features/
│   ├── auth/             # Authentication feature
│   ├── trips/            # Trip management
│   ├── itinerary/        # Itinerary builder
│   ├── checklists/       # Shared checklists
│   ├── expenses/         # Expense tracking
│   ├── autopilot/        # AI recommendations
│   └── notifications/    # Push notifications
└── shared/
    ├── models/           # Shared data models
    ├── widgets/          # Reusable widgets
    └── providers/        # Shared providers

Each feature follows clean architecture:
├── data/
│   ├── datasources/      # API and local data sources
│   ├── models/           # Data transfer objects
│   └── repositories/     # Repository implementations
├── domain/
│   ├── entities/         # Business entities
│   ├── repositories/     # Repository interfaces
│   └── usecases/         # Business logic
└── presentation/
    ├── pages/            # UI screens
    ├── widgets/          # Feature-specific widgets
    └── providers/        # State management
```

## Development Workflow

### Running Code Generation

For Freezed, JSON serialization, and Riverpod:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Watch mode (auto-generates on file changes):
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Testing

Run all tests:
```bash
flutter test
```

Run with coverage:
```bash
flutter test --coverage
```

## Environment Configuration

Create a `.env` file (not committed to git) for sensitive data:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
CLAUDE_API_KEY=your-claude-api-key
```

## Troubleshooting

### "Supabase credentials not configured"
- Update `lib/core/config/supabase_config.dart` with your actual credentials
- Or use `--dart-define` flags when running

### Firebase not working
- Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in the correct locations
- Rebuild the app after adding Firebase config files

### Realtime not syncing
- Check if tables are enabled in Supabase Replication settings
- Verify RLS policies are correctly set up

## Next Steps

1. Configure your Supabase project
2. Add Firebase configuration files
3. Update API keys in config
4. Run the app and start developing!

## Support

For issues and questions:
- Check the PRD.md for product requirements
- Review SUPABASE_SCHEMA.sql for database structure
- See inline code documentation

---

**Phase 1 MVP Features:**
- ✅ Trip creation and crew invites
- ✅ Daily itinerary builder
- ✅ Shared checklists
- ✅ Expense tracker with cost splitting
- ✅ UPI/Paytm payment integration
- ✅ Real-time sync
- ✅ Claude AI Autopilot v1
- ✅ Push notifications
