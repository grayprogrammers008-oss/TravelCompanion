#!/bin/bash

# GitHub Issues Creation Script for Travel Crew
# This script creates all 23 issues with proper labels and assignments

set -e

REPO="vinothvsbe/TravelCompanion"

echo "🚀 Creating GitHub Issues for Travel Crew"
echo "Repository: $REPO"
echo ""

# First, create all the necessary labels
echo "📝 Creating labels..."

# Priority labels
gh label create "priority-high" --color "d73a4a" --description "High priority issue" --repo "$REPO" 2>/dev/null || echo "Label priority-high already exists"
gh label create "priority-medium" --color "ff9800" --description "Medium priority issue" --repo "$REPO" 2>/dev/null || echo "Label priority-medium already exists"
gh label create "priority-low" --color "4caf50" --description "Low priority issue" --repo "$REPO" 2>/dev/null || echo "Label priority-low already exists"

# Type labels
gh label create "enhancement" --color "2196f3" --description "New feature or enhancement" --repo "$REPO" 2>/dev/null || echo "Label enhancement already exists"
gh label create "bug" --color "d73a4a" --description "Bug or error" --repo "$REPO" 2>/dev/null || echo "Label bug already exists"
gh label create "documentation" --color "9e9e9e" --description "Documentation improvement" --repo "$REPO" 2>/dev/null || echo "Label documentation already exists"

# Feature labels
gh label create "trip-management" --color "9c27b0" --description "Trip related features" --repo "$REPO" 2>/dev/null || echo "Label trip-management already exists"
gh label create "expenses" --color "ff6b9d" --description "Expense tracking features" --repo "$REPO" 2>/dev/null || echo "Label expenses already exists"
gh label create "itinerary" --color "00b8a9" --description "Itinerary features" --repo "$REPO" 2>/dev/null || echo "Label itinerary already exists"
gh label create "checklists" --color "4caf50" --description "Checklist features" --repo "$REPO" 2>/dev/null || echo "Label checklists already exists"
gh label create "ui-ux" --color "e91e63" --description "UI/UX improvements" --repo "$REPO" 2>/dev/null || echo "Label ui-ux already exists"
gh label create "notifications" --color "ffc145" --description "Push notifications" --repo "$REPO" 2>/dev/null || echo "Label notifications already exists"
gh label create "payments" --color "ffc107" --description "Payment integration" --repo "$REPO" 2>/dev/null || echo "Label payments already exists"
gh label create "testing" --color "607d8b" --description "Testing related" --repo "$REPO" 2>/dev/null || echo "Label testing already exists"
gh label create "performance" --color "00bcd4" --description "Performance optimization" --repo "$REPO" 2>/dev/null || echo "Label performance already exists"
gh label create "devops" --color "1565c0" --description "CI/CD and DevOps" --repo "$REPO" 2>/dev/null || echo "Label devops already exists"
gh label create "ai" --color "9b5de5" --description "AI features" --repo "$REPO" 2>/dev/null || echo "Label ai already exists"
gh label create "realtime" --color "00b8a9" --description "Real-time sync" --repo "$REPO" 2>/dev/null || echo "Label realtime already exists"
gh label create "firebase" --color "ff6f00" --description "Firebase integration" --repo "$REPO" 2>/dev/null || echo "Label firebase already exists"
gh label create "invites" --color "8e24aa" --description "Invite system" --repo "$REPO" 2>/dev/null || echo "Label invites already exists"
gh label create "images" --color "f06292" --description "Image handling" --repo "$REPO" 2>/dev/null || echo "Label images already exists"
gh label create "feature" --color "00897b" --description "New feature" --repo "$REPO" 2>/dev/null || echo "Label feature already exists"
gh label create "sync" --color "26c6da" --description "Synchronization" --repo "$REPO" 2>/dev/null || echo "Label sync already exists"
gh label create "claude" --color "a374f0" --description "Claude AI integration" --repo "$REPO" 2>/dev/null || echo "Label claude already exists"
gh label create "autopilot" --color "ce93d8" --description "AI Autopilot features" --repo "$REPO" 2>/dev/null || echo "Label autopilot already exists"
gh label create "deep-linking" --color "42a5f5" --description "Deep linking" --repo "$REPO" 2>/dev/null || echo "Label deep-linking already exists"
gh label create "dark-mode" --color "424242" --description "Dark mode theme" --repo "$REPO" 2>/dev/null || echo "Label dark-mode already exists"
gh label create "quality" --color "78909c" --description "Code quality" --repo "$REPO" 2>/dev/null || echo "Label quality already exists"
gh label create "optimization" --color "26a69a" --description "Optimization" --repo "$REPO" 2>/dev/null || echo "Label optimization already exists"
gh label create "profile" --color "ec407a" --description "User profile" --repo "$REPO" 2>/dev/null || echo "Label profile already exists"
gh label create "settings" --color "ab47bc" --description "App settings" --repo "$REPO" 2>/dev/null || echo "Label settings already exists"
gh label create "animations" --color "ff4081" --description "Animations" --repo "$REPO" 2>/dev/null || echo "Label animations already exists"
gh label create "onboarding" --color "7e57c2" --description "User onboarding" --repo "$REPO" 2>/dev/null || echo "Label onboarding already exists"
gh label create "validation" --color "ffa726" --description "Input validation" --repo "$REPO" 2>/dev/null || echo "Label validation already exists"
gh label create "backend" --color "5c6bc0" --description "Backend work" --repo "$REPO" 2>/dev/null || echo "Label backend already exists"
gh label create "deployment" --color "ef5350" --description "Deployment" --repo "$REPO" 2>/dev/null || echo "Label deployment already exists"
gh label create "marketing" --color "ec407a" --description "Marketing materials" --repo "$REPO" 2>/dev/null || echo "Label marketing already exists"

echo "✅ Labels created"
echo ""
echo "🎫 Creating issues..."
echo ""

# Issue #1: Edit Trip Functionality
gh issue create \
  --repo "$REPO" \
  --title "Implement Full Edit Trip Functionality" \
  --label "enhancement,priority-high,trip-management" \
  --body "Currently, the edit button on trip cards opens the CreateTripPage without pre-filling data. We need a complete edit experience.

## Tasks
- [ ] Modify CreateTripPage to accept optional tripId parameter
- [ ] Pre-fill form fields when editing existing trip
- [ ] Update trip data on save (PUT request instead of POST)
- [ ] Show \"Update Trip\" button text instead of \"Create Trip\"
- [ ] Add validation for edited data
- [ ] Handle errors during update
- [ ] Show success message after update
- [ ] Navigate back to trip detail page after successful update

## Files to Modify
- \`lib/features/trips/presentation/pages/create_trip_page.dart\`
- \`lib/features/trips/domain/usecases/update_trip_usecase.dart\` (new file)
- \`lib/features/trips/data/datasources/trip_local_datasource.dart\`
- \`lib/core/router/app_router.dart\`

## Acceptance Criteria
- Tapping edit shows pre-filled form
- All fields can be modified
- Save updates the trip correctly
- UI shows loading and error states
- Navigation works correctly

**Assigned to**: Vinoth"

echo "✅ Issue #1 created"

# Issue #2: Real Destination Images
gh issue create \
  --repo "$REPO" \
  --title "Replace Gradient Placeholders with Real Travel Destination Images" \
  --label "enhancement,priority-high,ui-ux,images" \
  --body "Currently, trip cards show gradient placeholders. We need beautiful, high-quality travel destination images to create emotional connection.

## Tasks
- [ ] Set up Unsplash API integration (free tier: 50 requests/hour)
- [ ] Create image download service
- [ ] Map common destinations to Unsplash search queries
- [ ] Cache downloaded images locally
- [ ] Implement image compression for performance
- [ ] Add fallback to gradients if API fails
- [ ] Add placeholder shimmer while loading
- [ ] Handle network errors gracefully

## Files to Create/Modify
- \`lib/core/services/image_service.dart\` (new)
- \`lib/core/constants/app_images.dart\` (modify)
- \`lib/core/widgets/destination_image.dart\` (modify)
- \`pubspec.yaml\` (add http package)

## API Setup
1. Create free Unsplash account: https://unsplash.com/developers
2. Get API access key
3. Add to environment variables

## Acceptance Criteria
- Beautiful images load for common destinations
- Images are cached to reduce API calls
- Graceful fallback to gradients
- Fast loading with shimmer effect
- No crashes if API is down

**Assigned to**: Nithya"

echo "✅ Issue #2 created"

# Issue #3: Trip Detail Page
gh issue create \
  --repo "$REPO" \
  --title "Design and Implement Trip Detail Page with Tabs" \
  --label "enhancement,priority-high,trip-management,ui-ux" \
  --body "Trip detail page needs to show comprehensive trip information with tabbed sections for Itinerary, Expenses, Crew, and Checklists.

## Tasks
- [ ] Create trip detail page scaffold
- [ ] Add hero image header with cover photo
- [ ] Implement tab navigation (Itinerary, Expenses, Crew, Checklists)
- [ ] Design trip info card (dates, location, description)
- [ ] Add edit/delete trip actions in app bar
- [ ] Implement share trip functionality
- [ ] Add member management (invite, remove)
- [ ] Create empty states for each tab
- [ ] Add loading states
- [ ] Implement pull-to-refresh

## Files to Modify
- \`lib/features/trips/presentation/pages/trip_detail_page.dart\` (redesign)
- \`lib/features/trips/presentation/widgets/trip_header.dart\` (new)
- \`lib/features/trips/presentation/widgets/trip_info_card.dart\` (new)
- \`lib/features/trips/presentation/widgets/member_list_widget.dart\` (new)

## Design Reference
Follow elite design system in CLAUDE.md:
- Hero image with gradient overlay
- Tab bar with teal indicator
- Card-based sections
- Premium spacing and shadows

## Acceptance Criteria
- Beautiful hero image section
- Smooth tab navigation
- All trip info displayed clearly
- Member management works
- Responsive on all screen sizes

**Assigned to**: Vinoth"

echo "✅ Issue #3 created"

# Issue #4: Trip Invite System
gh issue create \
  --repo "$REPO" \
  --title "Build Trip Invite Generation and Acceptance Flow" \
  --label "enhancement,priority-high,trip-management,invites" \
  --body "Users need to invite friends to trips via invite codes or deep links.

## Tasks
- [ ] Generate unique invite codes for trips
- [ ] Create invite link with deep link support
- [ ] Build invite acceptance flow
- [ ] Send invite via share sheet (SMS, WhatsApp, Email)
- [ ] Handle invite code validation
- [ ] Add user to trip members on acceptance
- [ ] Show pending invites in trip detail
- [ ] Implement invite expiration (optional)
- [ ] Add revoke invite functionality
- [ ] Create invite notification

## Files to Create
- \`lib/features/trip_invites/domain/repositories/invite_repository.dart\`
- \`lib/features/trip_invites/data/datasources/invite_remote_datasource.dart\`
- \`lib/features/trip_invites/presentation/pages/accept_invite_page.dart\`
- \`lib/features/trip_invites/domain/usecases/generate_invite_usecase.dart\`
- \`lib/features/trip_invites/domain/usecases/accept_invite_usecase.dart\`

## Database
Uses existing \`trip_invites\` table in Supabase schema

## Acceptance Criteria
- Unique invite codes generated
- Share sheet works on iOS/Android
- Invite links open app (deep link)
- Members added successfully
- Error handling for invalid codes
- UI shows pending invites

**Assigned to**: Nithya"

echo "✅ Issue #4 created"

# Issue #5: Itinerary Feature
gh issue create \
  --repo "$REPO" \
  --title "Implement Itinerary Builder with Day-wise Organization" \
  --label "enhancement,priority-high,itinerary,feature" \
  --body "Users need to plan daily activities for their trip with times, locations, and notes.

## Tasks

### Domain Layer
- [ ] Create itinerary repository interface
- [ ] Create use cases (add, update, delete, get itinerary)
- [ ] Implement business logic for day grouping

### Data Layer
- [ ] Implement itinerary local datasource (SQLite)
- [ ] Implement itinerary remote datasource (Supabase)
- [ ] Create repository implementation
- [ ] Add sync logic between local and remote

### Presentation Layer
- [ ] Create itinerary list page (day-wise grouping)
- [ ] Build add/edit itinerary item form
- [ ] Implement time picker for activities
- [ ] Add location picker with autocomplete
- [ ] Create itinerary item card widget
- [ ] Implement drag-to-reorder functionality
- [ ] Add delete with swipe gesture
- [ ] Create empty state for no activities

## Files to Create
- \`lib/features/itinerary/domain/repositories/itinerary_repository.dart\`
- \`lib/features/itinerary/domain/usecases/*.dart\` (4 files)
- \`lib/features/itinerary/data/datasources/*.dart\` (2 files)
- \`lib/features/itinerary/data/repositories/itinerary_repository_impl.dart\`
- \`lib/features/itinerary/presentation/pages/itinerary_page.dart\`
- \`lib/features/itinerary/presentation/pages/add_itinerary_item_page.dart\`
- \`lib/features/itinerary/presentation/widgets/*.dart\` (3-4 widgets)
- \`lib/features/itinerary/presentation/providers/itinerary_providers.dart\`

## Design Features
- Timeline view with day separators
- Activity cards with time, location, notes
- Category icons (Breakfast, Sightseeing, Travel, etc.)
- Drag handles for reordering
- Swipe-to-delete with undo

## Acceptance Criteria
- Activities grouped by day
- Add/edit/delete works
- Time picker is intuitive
- Reordering is smooth
- Syncs across devices
- Empty state guides users

**Assigned to**: Vinoth"

echo "✅ Issue #5 created"

# Issue #6: Checklist Feature
gh issue create \
  --repo "$REPO" \
  --title "Implement Collaborative Checklists for Packing and Tasks" \
  --label "enhancement,priority-high,checklists,feature" \
  --body "Users need to create shared checklists for packing, tasks, and reminders with assignment and completion tracking.

## Tasks

### Domain Layer
- [ ] Create checklist repository interface
- [ ] Create use cases (CRUD for checklists and items)
- [ ] Implement assignment logic
- [ ] Add completion tracking

### Data Layer
- [ ] Implement checklist local datasource
- [ ] Implement checklist remote datasource
- [ ] Create repository implementation
- [ ] Add real-time sync for collaborative editing

### Presentation Layer
- [ ] Create checklist list page
- [ ] Build add/edit checklist form
- [ ] Create checklist item widget with checkbox
- [ ] Implement add item inline
- [ ] Add assignment dropdown (assign to member)
- [ ] Show completion progress bar
- [ ] Implement filter (All, My Items, Completed)
- [ ] Add swipe-to-delete for items
- [ ] Create predefined templates (Packing, Documents, etc.)

## Files to Create
- \`lib/features/checklists/domain/repositories/checklist_repository.dart\`
- \`lib/features/checklists/domain/usecases/*.dart\` (6 files)
- \`lib/features/checklists/data/datasources/*.dart\` (2 files)
- \`lib/features/checklists/data/repositories/checklist_repository_impl.dart\`
- \`lib/features/checklists/presentation/pages/checklist_page.dart\`
- \`lib/features/checklists/presentation/pages/create_checklist_page.dart\`
- \`lib/features/checklists/presentation/widgets/*.dart\` (4-5 widgets)
- \`lib/features/checklists/presentation/providers/checklist_providers.dart\`

## Premium Features
- Predefined templates (Packing list, Documents, Pre-trip tasks)
- Assign items to specific members
- Completion percentage
- Filter and sort options
- Real-time collaboration

## Acceptance Criteria
- Checklists created and shared
- Items added/deleted/checked
- Assignment works correctly
- Progress percentage accurate
- Templates are helpful
- Real-time updates work
- UI is clean and intuitive

**Assigned to**: Nithya"

echo "✅ Issue #6 created"

# Issue #7: Payment Integration
gh issue create \
  --repo "$REPO" \
  --title "Add UPI Payment Integration for Settlements" \
  --label "enhancement,priority-medium,payments,expenses" \
  --body "Enable users to settle expenses via UPI with one-tap payment links for Paytm, PhonePe, GPay.

## Tasks
- [ ] Generate UPI deep links for payments
- [ ] Support Paytm, PhonePe, GPay, and generic UPI
- [ ] Show payment options in balance summary
- [ ] Implement \"Request Payment\" button
- [ ] Create payment proof upload (screenshot)
- [ ] Mark settlement as paid after confirmation
- [ ] Send payment notification to payer
- [ ] Handle payment link errors gracefully
- [ ] Add payment history view

## Files to Create/Modify
- \`lib/core/services/payment_service.dart\` (new)
- \`lib/features/expenses/presentation/widgets/payment_options_sheet.dart\` (new)
- \`lib/features/expenses/presentation/pages/settlement_page.dart\` (new)
- \`lib/features/expenses/domain/usecases/create_settlement_usecase.dart\` (modify)

## UPI Deep Link Format
\`\`\`
upi://pay?pa={UPI_ID}&pn={NAME}&am={AMOUNT}&cu=INR&tn={NOTE}
\`\`\`

## Acceptance Criteria
- UPI links open payment apps
- Multiple UPI apps supported
- Payment proof can be uploaded
- Settlements marked correctly
- Error handling for failed payments
- User-friendly payment flow

**Assigned to**: Vinoth"

echo "✅ Issue #7 created"

# Issue #8: Real-time Sync
gh issue create \
  --repo "$REPO" \
  --title "Add Real-time Synchronization Across Devices" \
  --label "enhancement,priority-medium,realtime,sync" \
  --body "Enable real-time updates for trips, expenses, itineraries, and checklists using Supabase Realtime.

## Tasks
- [ ] Set up Supabase Realtime channels
- [ ] Subscribe to trip updates
- [ ] Subscribe to expense updates
- [ ] Subscribe to itinerary changes
- [ ] Subscribe to checklist updates
- [ ] Handle conflict resolution (last-write-wins)
- [ ] Show live indicators (e.g., \"Nithya is typing...\")
- [ ] Implement optimistic updates
- [ ] Add offline queue for pending changes
- [ ] Sync when connection restored

## Files to Create/Modify
- \`lib/core/services/realtime_service.dart\` (new)
- \`lib/features/trips/data/datasources/trip_remote_datasource.dart\` (modify)
- \`lib/features/expenses/data/datasources/expense_remote_datasource.dart\` (modify)
- \`lib/features/itinerary/data/datasources/itinerary_remote_datasource.dart\` (modify)
- \`lib/features/checklists/data/datasources/checklist_remote_datasource.dart\` (modify)

## Realtime Events to Handle
- \`INSERT\` - New item added
- \`UPDATE\` - Item modified
- \`DELETE\` - Item removed

## Acceptance Criteria
- Changes appear instantly on all devices
- No data loss during conflicts
- Offline changes sync when online
- Live indicators work
- Performance is smooth
- No excessive database calls

**Assigned to**: Nithya"

echo "✅ Issue #8 created"

# Issue #9: Claude AI Autopilot
gh issue create \
  --repo "$REPO" \
  --title "Implement AI-Powered Travel Recommendations" \
  --label "enhancement,priority-medium,ai,claude,autopilot" \
  --body "Integrate Claude AI to provide personalized recommendations for restaurants, attractions, activities, and detours.

## Tasks
- [ ] Set up Claude API client
- [ ] Create prompt templates for recommendations
- [ ] Build context from trip data (destination, dates, members)
- [ ] Implement restaurant recommendation flow
- [ ] Add attraction suggestions
- [ ] Create activity ideas based on preferences
- [ ] Implement detour suggestions during travel
- [ ] Cache recommendations to reduce API costs
- [ ] Add \"Ask AI\" button in trip detail
- [ ] Create AI suggestions bottom sheet
- [ ] Handle API errors and rate limits
- [ ] Add loading states for AI responses

## Files to Create
- \`lib/core/services/claude_ai_service.dart\` (new)
- \`lib/features/autopilot/domain/repositories/autopilot_repository.dart\` (new)
- \`lib/features/autopilot/presentation/pages/ai_suggestions_page.dart\` (new)
- \`lib/features/autopilot/presentation/widgets/suggestion_card.dart\` (new)
- \`lib/features/autopilot/domain/usecases/get_recommendations_usecase.dart\` (new)

## Claude API Setup
1. Get API key from Anthropic Console
2. Add to environment variables
3. Implement caching strategy to reduce costs

## Prompt Context
- Destination
- Trip dates
- Number of travelers
- Existing itinerary items
- User preferences (budget, interests)

## Acceptance Criteria
- AI provides relevant recommendations
- Responses are fast (<3 seconds)
- Caching reduces API costs
- UI shows loading states
- Error handling for API failures
- Recommendations can be added to itinerary

**Assigned to**: Vinoth"

echo "✅ Issue #9 created"

# Issue #10: Push Notifications
gh issue create \
  --repo "$REPO" \
  --title "Implement Firebase Push Notifications for Trip Updates" \
  --label "enhancement,priority-medium,notifications,firebase" \
  --body "Send push notifications for trip invites, expense additions, itinerary changes, and checklist assignments.

## Tasks

### Firebase Setup
- [ ] Create Firebase project
- [ ] Add Firebase to Flutter app (iOS & Android)
- [ ] Configure FCM (Firebase Cloud Messaging)
- [ ] Set up Apple Push Notification Service (APNS) for iOS
- [ ] Test notification delivery

### Backend Integration
- [ ] Store FCM tokens in Supabase profiles table
- [ ] Create Supabase Edge Function for sending notifications
- [ ] Set up database triggers for notification events
- [ ] Implement notification templates

### App Implementation
- [ ] Request notification permissions
- [ ] Handle foreground notifications
- [ ] Handle background notifications
- [ ] Handle notification tap actions (deep linking)
- [ ] Create in-app notification center
- [ ] Add notification preferences (toggle on/off)
- [ ] Implement notification badge on bottom nav

## Notification Types
- Trip invite received
- Expense added to trip
- Settlement requested
- Itinerary item added/changed
- Checklist item assigned
- Trip date approaching reminder

## Files to Create/Modify
- \`lib/core/services/notification_service.dart\` (new)
- \`lib/features/notifications/presentation/pages/notification_center.dart\` (new)
- \`supabase/functions/send-notification/index.ts\` (new Edge Function)
- \`lib/main.dart\` (modify - initialize FCM)

## Acceptance Criteria
- Notifications received on iOS and Android
- Tapping notification opens relevant screen
- Users can toggle notification types
- In-app notification center works
- Background notifications work
- No duplicate notifications

**Assigned to**: Nithya"

echo "✅ Issue #10 created"

# Issue #11: Deep Linking
gh issue create \
  --repo "$REPO" \
  --title "Add Deep Link Support for Trip Invites and Sharing" \
  --label "enhancement,priority-low,deep-linking" \
  --body "Support deep links so invite links, trip shares, and notification taps open specific screens in the app.

## Tasks
- [ ] Configure iOS Universal Links
- [ ] Configure Android App Links
- [ ] Set up domain association files
- [ ] Handle deep link routes in Go Router
- [ ] Test invite link opening
- [ ] Test notification deep links
- [ ] Add fallback to web page if app not installed

## URL Scheme
\`\`\`
https://travelcrew.app/invite/{invite_code}
https://travelcrew.app/trip/{trip_id}
https://travelcrew.app/expense/{expense_id}
\`\`\`

## Files to Modify
- \`lib/core/router/app_router.dart\`
- \`ios/Runner/Info.plist\`
- \`android/app/src/main/AndroidManifest.xml\`

**Assigned to**: Vinoth"

echo "✅ Issue #11 created"

# Issue #12: Dark Mode
gh issue create \
  --repo "$REPO" \
  --title "Implement Dark Theme for Better UX" \
  --label "enhancement,priority-low,ui-ux,dark-mode" \
  --body "Add dark mode theme with proper color adaptations following Material Design 3 guidelines.

## Tasks
- [ ] Define dark color palette in AppTheme
- [ ] Create dark theme data
- [ ] Update all widgets to support dark mode
- [ ] Test all screens in dark mode
- [ ] Add theme toggle in settings
- [ ] Save theme preference locally
- [ ] Handle system theme changes

## Files to Modify
- \`lib/core/theme/app_theme.dart\`
- \`lib/features/settings/presentation/pages/settings_page.dart\` (new)
- \`lib/main.dart\`

## Dark Color Palette
\`\`\`dart
primaryTeal = #00D4C3
neutral900 = #F8FAFC (inverted for text)
neutral50 = #0F172A (inverted for background)
\`\`\`

**Assigned to**: Nithya"

echo "✅ Issue #12 created"

# Issue #13: Testing
gh issue create \
  --repo "$REPO" \
  --title "Implement Unit, Widget, and Integration Tests" \
  --label "enhancement,priority-low,testing,quality" \
  --body "Increase test coverage to 80%+ with unit tests, widget tests, and integration tests.

## Tasks

### Unit Tests
- [ ] Test all use cases (10+ files)
- [ ] Test all repositories (6+ files)
- [ ] Test all datasources (12+ files)
- [ ] Test utilities and helpers

### Widget Tests
- [ ] Test auth screens (login, signup)
- [ ] Test home page
- [ ] Test trip detail page
- [ ] Test expense screens
- [ ] Test itinerary screens
- [ ] Test checklist screens
- [ ] Test all custom widgets

### Integration Tests
- [ ] Test complete auth flow
- [ ] Test trip creation flow
- [ ] Test expense splitting flow
- [ ] Test itinerary creation flow
- [ ] Test checklist completion flow

## Files to Create
- \`test/features/*/domain/usecases/*_test.dart\` (25+ files)
- \`test/features/*/data/repositories/*_test.dart\` (10+ files)
- \`test/features/*/presentation/pages/*_test.dart\` (15+ files)
- \`integration_test/app_test.dart\` (5+ flows)

## Mock Setup
- [ ] Create mock Supabase client
- [ ] Create mock SQLite database
- [ ] Create mock providers

## Acceptance Criteria
- Test coverage > 80%
- All critical paths tested
- CI/CD runs tests automatically
- No flaky tests
- Fast test execution

**Assigned to**: Both (Vinoth & Nithya)"

echo "✅ Issue #13 created"

# Issue #14: Performance Optimization
gh issue create \
  --repo "$REPO" \
  --title "Optimize App Performance and Reduce Bundle Size" \
  --label "enhancement,priority-low,performance,optimization" \
  --body "Improve app performance, reduce memory usage, and decrease APK/IPA size.

## Tasks
- [ ] Implement image caching with cached_network_image
- [ ] Add lazy loading for long lists
- [ ] Optimize database queries (add indexes)
- [ ] Reduce widget rebuilds with const constructors
- [ ] Use compute for heavy operations
- [ ] Implement code splitting
- [ ] Compress images before upload
- [ ] Minimize dependencies
- [ ] Profile app with Flutter DevTools
- [ ] Fix performance bottlenecks

## Performance Targets
- App launch time: < 2 seconds
- Screen transitions: 60 FPS
- APK size: < 20 MB
- Memory usage: < 150 MB

## Files to Audit
- All list views (implement AutomaticKeepAliveClientMixin)
- All image widgets
- All Riverpod providers (check unnecessary rebuilds)
- \`pubspec.yaml\` (remove unused dependencies)

**Assigned to**: Nithya"

echo "✅ Issue #14 created"

# Issue #15: Settings and Profile
gh issue create \
  --repo "$REPO" \
  --title "Implement User Settings and Profile Management" \
  --label "enhancement,priority-low,profile,settings" \
  --body "Create settings page for app preferences and profile page for user info management.

## Tasks

### Profile Page
- [ ] Show user avatar and name
- [ ] Add edit profile functionality
- [ ] Implement profile photo upload
- [ ] Add bio/description field
- [ ] Show trip statistics (trips joined, expenses split)
- [ ] Add logout button

### Settings Page
- [ ] Notification preferences (toggle types)
- [ ] Theme selection (Light, Dark, System)
- [ ] Language selection (future: i18n)
- [ ] Currency preference
- [ ] About section (version, licenses)
- [ ] Privacy policy link
- [ ] Terms of service link
- [ ] Delete account option

## Files to Create
- \`lib/features/profile/presentation/pages/profile_page.dart\`
- \`lib/features/settings/presentation/pages/settings_page.dart\`
- \`lib/features/profile/domain/usecases/update_profile_usecase.dart\`
- \`lib/features/profile/presentation/widgets/profile_stats_widget.dart\`

**Assigned to**: Vinoth"

echo "✅ Issue #15 created"

# Issue #16: Animations
gh issue create \
  --repo "$REPO" \
  --title "Enhance UX with Premium Animations" \
  --label "enhancement,priority-low,ui-ux,animations" \
  --body "Add delightful animations and micro-interactions throughout the app.

## Tasks
- [ ] Add hero animations for images
- [ ] Implement shared element transitions between screens
- [ ] Add ripple effects on all buttons
- [ ] Implement swipe gestures (swipe-to-delete)
- [ ] Add pull-to-refresh with custom indicator
- [ ] Create loading skeletons for all async content
- [ ] Add success/error animations (Lottie)
- [ ] Implement smooth tab transitions
- [ ] Add haptic feedback for important actions
- [ ] Create onboarding animation sequence

## Animation Guidelines
- Duration: 200-400ms
- Easing: ease-in-out
- Subtle, not distracting

## Files to Create/Modify
- \`lib/core/widgets/animated_button.dart\` (new)
- \`lib/core/widgets/loading_skeleton.dart\` (new)
- All page transitions in router

**Assigned to**: Nithya"

echo "✅ Issue #16 created"

# Issue #17: Onboarding
gh issue create \
  --repo "$REPO" \
  --title "Create Welcome Screens for First-time Users" \
  --label "enhancement,priority-low,ui-ux,onboarding" \
  --body "Create beautiful onboarding screens to introduce app features.

## Tasks
- [ ] Design 3-4 onboarding screens
- [ ] Create illustrations for each screen
- [ ] Implement PageView with indicators
- [ ] Add skip button
- [ ] Add \"Get Started\" CTA on last screen
- [ ] Save onboarding completion to local storage
- [ ] Show only once (first launch)

## Onboarding Screens
1. **Welcome** - \"Plan trips together with your crew\"
2. **Expenses** - \"Split costs effortlessly\"
3. **Itinerary** - \"Build the perfect schedule\"
4. **AI Autopilot** - \"Let AI guide your adventure\"

## Files to Create
- \`lib/features/onboarding/presentation/pages/onboarding_page.dart\`
- \`lib/features/onboarding/presentation/widgets/onboarding_screen.dart\`

**Assigned to**: Vinoth"

echo "✅ Issue #17 created"

# Issue #18: UI Bug Fixes
gh issue create \
  --repo "$REPO" \
  --title "UI Bug Hunt and Fixes" \
  --label "bug,priority-medium,ui-ux" \
  --body "Comprehensive testing and fixing of any remaining UI issues.

## Tasks
- [ ] Test all screens on small devices (iPhone SE)
- [ ] Test all screens on tablets
- [ ] Fix overflow errors
- [ ] Fix alignment issues
- [ ] Test landscape orientation
- [ ] Ensure accessibility (screen readers, contrast)
- [ ] Fix keyboard overlap issues
- [ ] Test with long text (internationalization)

**Assigned to**: Both (Vinoth & Nithya)"

echo "✅ Issue #18 created"

# Issue #19: Error Messages
gh issue create \
  --repo "$REPO" \
  --title "Enhance User Feedback and Input Validation" \
  --label "enhancement,priority-medium,validation,ui-ux" \
  --body "Make error messages more helpful and validation more comprehensive.

## Tasks
- [ ] Review all error messages for clarity
- [ ] Add field-specific validation errors
- [ ] Implement inline validation (on blur)
- [ ] Add helpful hints for complex fields
- [ ] Improve network error messages
- [ ] Add retry buttons with exponential backoff
- [ ] Show connection status indicator

**Assigned to**: Nithya"

echo "✅ Issue #19 created"

# Issue #20: User Documentation
gh issue create \
  --repo "$REPO" \
  --title "Write User Guide and Help Documentation" \
  --label "documentation,priority-low" \
  --body "Write comprehensive user documentation for app features.

## Tasks
- [ ] Create USER_GUIDE.md
- [ ] Document trip creation flow
- [ ] Document expense splitting
- [ ] Document itinerary building
- [ ] Document checklist usage
- [ ] Add screenshots for each feature
- [ ] Create FAQ section
- [ ] Add troubleshooting guide

**Assigned to**: Vinoth"

echo "✅ Issue #20 created"

# Issue #21: API Documentation
gh issue create \
  --repo "$REPO" \
  --title "Document Supabase Schema and API" \
  --label "documentation,priority-low,backend" \
  --body "Create comprehensive API documentation for backend.

## Tasks
- [ ] Document all database tables
- [ ] Document RLS policies
- [ ] Document Edge Functions
- [ ] Create API endpoint documentation
- [ ] Add example requests/responses
- [ ] Document real-time subscriptions

## Files to Create
- \`docs/API_DOCUMENTATION.md\`
- \`docs/DATABASE_SCHEMA.md\`

**Assigned to**: Nithya"

echo "✅ Issue #21 created"

# Issue #22: CI/CD
gh issue create \
  --repo "$REPO" \
  --title "Set Up GitHub Actions for CI/CD" \
  --label "enhancement,priority-medium,devops" \
  --body "Automate testing, building, and deployment with GitHub Actions.

## Tasks
- [ ] Create GitHub Actions workflow
- [ ] Run tests on every PR
- [ ] Run linter on every PR
- [ ] Build APK/IPA on main branch
- [ ] Deploy to TestFlight (iOS)
- [ ] Deploy to Play Store Internal Testing (Android)
- [ ] Add version bumping automation

## Files to Create
- \`.github/workflows/test.yml\`
- \`.github/workflows/build.yml\`
- \`.github/workflows/deploy.yml\`

**Assigned to**: Vinoth"

echo "✅ Issue #22 created"

# Issue #23: App Store Listings
gh issue create \
  --repo "$REPO" \
  --title "Prepare App Store and Play Store Listings" \
  --label "priority-low,deployment,marketing" \
  --body "Create app store assets and listings for both iOS and Android.

## Tasks
- [ ] Design app icon (1024x1024)
- [ ] Create app screenshots (5-8 per platform)
- [ ] Write app description
- [ ] Create promotional text
- [ ] Design feature graphic
- [ ] Set up privacy policy
- [ ] Set up terms of service
- [ ] Submit for review

**Assigned to**: Nithya"

echo "✅ Issue #23 created"

echo ""
echo "🎉 All 23 issues created successfully!"
echo ""
echo "📊 Summary:"
echo "  - Priority High: 6 issues"
echo "  - Priority Medium: 8 issues"
echo "  - Priority Low: 9 issues"
echo ""
echo "View all issues at: https://github.com/$REPO/issues"
echo ""
echo "✅ Done!"
