# Welcome Screens for First-time Users - Implementation Guide

**Issue**: #17 - Create Welcome Screens for First-time Users
**Status**: Ready for Implementation
**Date**: 2025-10-20

---

## 🎯 Overview

Comprehensive onboarding experience for first-time users of the Travel Crew app, introducing key features and setting expectations.

---

## 📋 Requirements

### Core Features
1. **3-4 Welcome Screens** with smooth transitions
2. **Feature Highlights** for main app capabilities
3. **Skip Button** to bypass onboarding
4. **Get Started** button on final screen
5. **First-time Detection** using SharedPreferences
6. **Smooth Animations** between screens
7. **Travel-themed Design** matching app aesthetic

### Technical Requirements
- Persist onboarding completion status
- Integrate with existing router/navigation
- Support both light and dark themes
- Responsive design for all screen sizes
- Comprehensive unit and E2E tests

---

## 🎨 Design Specifications

### Onboarding Screens (4 screens)

#### Screen 1: Welcome
- **Title**: "Welcome to Travel Crew"
- **Subtitle**: "Plan trips with friends, split expenses fairly, and create unforgettable memories together"
- **Icon/Image**: App logo with gradient background
- **Color**: Primary Teal gradient

#### Screen 2: Collaborative Trip Planning
- **Title**: "Plan Together, Travel Better"
- **Subtitle**: "Create shared itineraries, track activities, and keep everyone on the same page"
- **Icon/Image**: Itinerary/calendar illustration
- **Color**: Sunset gradient
- **Features**:
  - Shared trip planning
  - Real-time sync
  - Collaborative checklists

#### Screen 3: Smart Expense Splitting
- **Title**: "Split Expenses Effortlessly"
- **Subtitle**: "Track who paid what, calculate splits automatically, and settle up with ease"
- **Icon/Image**: Money/calculator illustration
- **Color**: Ocean gradient
- **Features**:
  - Automatic expense splitting
  - Balance tracking
  - Settlement suggestions

#### Screen 4: Get Started
- **Title**: "Ready for Your Next Adventure?"
- **Subtitle**: "Join your crew and start planning your next unforgettable trip"
- **Icon/Image**: Travel illustration (plane/map)
- **Color**: Twilight gradient
- **CTA**: Large "Get Started" button

---

## 📁 File Structure

```
lib/features/onboarding/
├── domain/
│   └── models/
│       └── onboarding_page_model.dart          # Data model for each screen
├── presentation/
│   ├── pages/
│   │   └── onboarding_page.dart                # Main onboarding page
│   ├── widgets/
│   │   ├── onboarding_content.dart             # Individual screen content
│   │   ├── onboarding_indicator.dart           # Page dots indicator
│   │   └── onboarding_buttons.dart             # Skip/Next/Get Started buttons
│   └── providers/
│       └── onboarding_provider.dart            # State management

test/features/onboarding/
├── presentation/
│   └── pages/
│       └── onboarding_page_test.dart           # Unit tests
└── e2e/
    └── onboarding_flow_test.dart               # E2E tests
```

---

## 💻 Implementation Details

### 1. Onboarding Page Model

```dart
// lib/features/onboarding/domain/models/onboarding_page_model.dart
class OnboardingPageModel {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final List<String>? features;

  const OnboardingPageModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    this.features,
  });

  static List<OnboardingPageModel> get pages => [
    OnboardingPageModel(
      title: 'Welcome to Travel Crew',
      subtitle: 'Plan trips with friends, split expenses fairly...',
      icon: Icons.luggage,
      gradientColors: [AppTheme.primaryTeal, AppTheme.primaryDeep],
    ),
    // ... more pages
  ];
}
```

### 2. Onboarding Provider

```dart
// lib/features/onboarding/presentation/providers/onboarding_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_provider.g.dart';

@riverpod
class OnboardingState extends _$OnboardingState {
  static const String _key = 'onboarding_completed';

  @override
  Future<bool> build() async {
    return await _isOnboardingCompleted();
  }

  Future<bool> _isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    state = const AsyncValue.data(true);
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = const AsyncValue.data(false);
  }
}
```

### 3. Onboarding Page

```dart
// lib/features/onboarding/presentation/pages/onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/onboarding_content.dart';
import '../widgets/onboarding_indicator.dart';
import '../widgets/onboarding_buttons.dart';
import '../providers/onboarding_provider.dart';
import '../../domain/models/onboarding_page_model.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageModel> _pages = OnboardingPageModel.pages;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingStateProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/');
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (_currentPage < _pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onTap: _skipOnboarding,
                  child: const Text('Skip'),
                ),
              ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingContent(page: _pages[index]);
                },
              ),
            ),

            // Page indicator
            OnboardingIndicator(
              currentPage: _currentPage,
              pageCount: _pages.length,
            ),

            const SizedBox(height: 32),

            // Navigation buttons
            OnboardingButtons(
              currentPage: _currentPage,
              pageCount: _pages.length,
              onNext: _nextPage,
              onSkip: _skipOnboarding,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
```

### 4. Router Integration

```dart
// Update lib/core/router/app_router.dart
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';

class AppRoutes {
  // ... existing routes
  static const String onboarding = '/onboarding';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingState = ref.watch(onboardingStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final needsOnboarding = onboardingState.value == false;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;

      // Show onboarding for first-time authenticated users
      if (isAuthenticated && needsOnboarding && !isOnboarding) {
        return AppRoutes.onboarding;
      }

      // Skip onboarding if already completed
      if (isAuthenticated && !needsOnboarding && isOnboarding) {
        return AppRoutes.home;
      }

      // Existing redirect logic...
      return null;
    },
    routes: [
      // ... existing routes
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
    ],
  );
});
```

---

## 🧪 Testing

### Unit Tests

```dart
// test/features/onboarding/presentation/pages/onboarding_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_crew/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingPage Tests', () {
    testWidgets('should display all onboarding screens', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingPage()),
        ),
      );

      // Verify first screen
      expect(find.text('Welcome to Travel Crew'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('should navigate to next screen on swipe', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingPage()),
        ),
      );

      // Swipe to next screen
      await tester.drag(
        find.byType(PageView),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();

      // Verify second screen
      expect(find.text('Plan Together, Travel Better'), findsOneWidget);
    });

    testWidgets('should complete onboarding on last screen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingPage()),
        ),
      );

      // Navigate to last screen
      for (int i = 0; i < 3; i++) {
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pumpAndSettle();
      }

      // Tap Get Started
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Verify onboarding completed
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), isTrue);
    });

    testWidgets('should skip onboarding when skip button tapped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingPage()),
        ),
      );

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), isTrue);
    });
  });
}
```

### E2E Tests

```dart
// test/features/onboarding/e2e/onboarding_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Onboarding Flow E2E Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should show onboarding for first-time users', (tester) async {
      // ... test implementation
    });

    testWidgets('should skip onboarding for returning users', (tester) async {
      // Mark as completed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);

      // ... test implementation
    });
  });
}
```

---

## 🚀 Implementation Steps

### Step 1: Create Feature Structure
```bash
mkdir -p lib/features/onboarding/domain/models
mkdir -p lib/features/onboarding/presentation/pages
mkdir -p lib/features/onboarding/presentation/widgets
mkdir -p lib/features/onboarding/presentation/providers
mkdir -p test/features/onboarding/presentation/pages
mkdir -p test/features/onboarding/e2e
```

### Step 2: Implement Core Files
1. Create `onboarding_page_model.dart`
2. Create `onboarding_provider.dart`
3. Run code generation: `flutter pub run build_runner build`
4. Create `onboarding_page.dart`
5. Create widget files

### Step 3: Update Router
1. Add onboarding route to `app_router.dart`
2. Add redirect logic for first-time users
3. Test navigation flow

### Step 4: Write Tests
1. Create unit tests for provider
2. Create widget tests for pages
3. Create E2E navigation tests
4. Run all tests: `flutter test`

### Step 5: Verify
1. Clear app data
2. Run app: `flutter run`
3. Verify onboarding shows on first launch
4. Complete onboarding
5. Restart app - verify it doesn't show again

---

## ✅ Acceptance Criteria

- [ ] First-time users see onboarding screens
- [ ] Returning users skip directly to login/home
- [ ] Users can skip onboarding
- [ ] Users can navigate between screens
- [ ] Smooth animations between screens
- [ ] "Get Started" completes onboarding
- [ ] Onboarding state persists
- [ ] All tests pass (unit + E2E)
- [ ] No compilation errors
- [ ] Design matches app theme

---

## 📊 Files to Create/Modify

### New Files (10)
1. `lib/features/onboarding/domain/models/onboarding_page_model.dart`
2. `lib/features/onboarding/presentation/pages/onboarding_page.dart`
3. `lib/features/onboarding/presentation/widgets/onboarding_content.dart`
4. `lib/features/onboarding/presentation/widgets/onboarding_indicator.dart`
5. `lib/features/onboarding/presentation/widgets/onboarding_buttons.dart`
6. `lib/features/onboarding/presentation/providers/onboarding_provider.dart`
7. `test/features/onboarding/presentation/pages/onboarding_page_test.dart`
8. `test/features/onboarding/e2e/onboarding_flow_test.dart`
9. `test/features/onboarding/presentation/providers/onboarding_provider_test.dart`
10. `ONBOARDING_IMPLEMENTATION_COMPLETE.md` (documentation)

### Modified Files (1)
1. `lib/core/router/app_router.dart` - Add onboarding route and redirect logic

---

## 🎯 Success Metrics

**Implementation Time**: ~4-6 hours
**Test Coverage**: >85%
**User Experience**: Smooth, engaging, skippable
**Technical Debt**: None

---

## 📝 Notes

- Use existing Travel Crew design system
- Leverage animations from `lib/core/animations/`
- Follow clean architecture pattern
- Ensure all strings are externalizable for i18n
- Add illustrations or use IconData for visual elements
- Consider adding animated transitions
- Keep screens concise (max 3 lines subtitle)

---

**Ready for Implementation**: Yes ✅
**Dependencies**: SharedPreferences (already in pubspec.yaml)
**Breaking Changes**: None
**Migration Required**: No
