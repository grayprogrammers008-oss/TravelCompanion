# 🎨 Fitonist Theme - Usage Guide

A vibrant, playful theme inspired by the Fitonist design's 3D aesthetic, now integrated into your existing TravelCompanion theme system.

---

## ✨ What's New

**Added to your existing `AppTheme` class:**

### New Colors
- `fitonistPurple` - Vibrant purple `#7B5FE8`
- `fitonistPurpleLight` - Soft lavender `#C8B8FF`
- `fitonistPurpleDark` - Deep purple `#5234B8`
- `fitonistPink` - Candy pink `#FF88CC`
- `fitonistPinkLight` - Light pink `#FFB8E6`
- `fitonistBlue` - Sky blue `#A8D8FF`
- `fitonistPeach` - Soft peach `#FFB8A8`
- `fitonistMint` - Fresh mint `#88FFDD`
- `fitonistYellow` - Bright yellow `#FFE066`

### New Gradients
- `fitonistGradient` - Purple to dark purple
- `fitonistCandyGradient` - Pink to purple
- `fitonistSunsetGradient` - Peach → Pink → Purple (3-color!)
- `fitonistOceanGradient` - Blue to purple
- `fitonistMintGradient` - Mint to purple

### New Theme Variants
- `AppTheme.fitonistLightTheme` - Light mode with vibrant purple
- `AppTheme.fitonistDarkTheme` - Dark mode variant

---

## 🚀 Quick Start

### Apply Fitonist Theme to Your App

```dart
import 'package:travel_crew/core/theme/app_theme.dart';

MaterialApp(
  title: 'TravelCompanion',
  theme: AppTheme.fitonistLightTheme,      // ← Use Fitonist light theme
  darkTheme: AppTheme.fitonistDarkTheme,   // ← Use Fitonist dark theme
  themeMode: ThemeMode.system,
  home: HomePage(),
)
```

---

## 🎨 Using Fitonist Colors

### Direct Color Access

```dart
import 'package:travel_crew/core/theme/app_theme.dart';

// Use Fitonist colors directly
Container(
  color: AppTheme.fitonistPurple,
  child: Text('Vibrant Purple'),
);

// With your existing theme colors
Container(
  color: AppTheme.fitonistPink,
  child: Text('Candy Pink'),
);
```

### Via Theme Colors (Recommended)

```dart
// When using fitonistLightTheme, these will automatically use Fitonist colors
Container(
  color: Theme.of(context).colorScheme.primary,      // fitonistPurple
  child: Text('Uses theme primary'),
);

ElevatedButton(
  // Automatically styled with Fitonist purple
  onPressed: () {},
  child: Text('Fitonist Button'),
);
```

---

## 🌈 Using Fitonist Gradients

### Hero Section

```dart
Container(
  height: 300,
  decoration: BoxDecoration(
    gradient: AppTheme.fitonistGradient,
    borderRadius: BorderRadius.circular(24),
  ),
  child: Center(
    child: Text(
      'Explore the World',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  ),
);
```

### Trip Card with Gradient Header

```dart
Card(
  child: Column(
    children: [
      // Gradient header
      Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: AppTheme.fitonistCandyGradient,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Center(
          child: Icon(
            Icons.flight_takeoff,
            size: 64,
            color: Colors.white,
          ),
        ),
      ),
      // Card content
      Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Tokyo Adventure'),
            Text('Mar 15 - Mar 22, 2024'),
          ],
        ),
      ),
    ],
  ),
);
```

### Gradient Button

```dart
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.fitonistSunsetGradient,
    borderRadius: BorderRadius.circular(24),
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Plan New Trip',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
```

---

## 🎯 Mix & Match with Existing Themes

You can use Fitonist colors and gradients even with your existing `lightTheme`:

```dart
// Keep your current theme
MaterialApp(
  theme: AppTheme.lightTheme,  // Your existing teal theme
  // ...
)

// But use Fitonist gradients for accents
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.fitonistGradient,  // Add Fitonist flair!
  ),
  child: YourWidget(),
);
```

---

## 🎨 Gradient Examples by Use Case

### For Trip Headers
```dart
gradient: AppTheme.fitonistSunsetGradient  // Warm, adventurous
```

### For Stats/Metrics
```dart
gradient: AppTheme.fitonistGradient  // Bold, primary
```

### For Secondary Actions
```dart
gradient: AppTheme.fitonistCandyGradient  // Playful, friendly
```

### For Cool Features (e.g., Weather, Maps)
```dart
gradient: AppTheme.fitonistOceanGradient  // Cool, refreshing
```

### For Health/Eco Features
```dart
gradient: AppTheme.fitonistMintGradient  // Fresh, energetic
```

---

## 🎭 Theme Comparison

| Theme | Primary Color | Vibe | Best For |
|-------|--------------|------|----------|
| **lightTheme** | Teal `#00B8A9` | Premium, Luxury | Current default |
| **fitonistLightTheme** | Purple `#7B5FE8` | Energetic, Playful | Creative, Youthful |

---

## 💡 Usage Tips

### When to Use Fitonist Theme

✅ **Great for:**
- Creative/artistic travel apps
- Apps targeting Gen Z/younger audiences
- Fitness/wellness travel features
- Social travel features
- Gamified experiences

⚠️ **Consider carefully for:**
- Corporate/business travel
- Luxury/premium positioning (use existing teal theme)
- Conservative audiences

### Best Practices

1. **Use gradients sparingly** - Headers, cards, CTAs
2. **Maintain contrast** - White text on gradients
3. **Keep it playful** - Fitonist theme is about fun!
4. **Round corners** - More rounded = more playful
5. **Bold typography** - Thicker fonts match the energy

---

## 🔧 Customization

### Create Custom Fitonist Combinations

```dart
// Combine multiple Fitonist colors
const customGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    AppTheme.fitonistPeach,
    AppTheme.fitonistPink,
    AppTheme.fitonistPurple,
    AppTheme.fitonistBlue,
  ],
  stops: [0.0, 0.33, 0.66, 1.0],
);
```

### Use Fitonist Accents with Existing Theme

```dart
// Keep teal primary, add purple accents
Chip(
  label: Text('Adventure'),
  backgroundColor: AppTheme.fitonistPurplePale,
  labelStyle: TextStyle(color: AppTheme.fitonistPurple),
);
```

---

## 📱 Example Implementations

### App Bar with Gradient

```dart
AppBar(
  flexibleSpace: Container(
    decoration: BoxDecoration(
      gradient: AppTheme.fitonistGradient,
    ),
  ),
  title: Text('My Trips'),
);
```

### Category Chips

```dart
Wrap(
  spacing: 8,
  children: [
    Chip(
      label: Text('Beach'),
      backgroundColor: AppTheme.fitonistPurplePale,
      avatar: Icon(Icons.beach_access, size: 16),
    ),
    Chip(
      label: Text('Adventure'),
      backgroundColor: AppTheme.fitonistPinkPale,
      avatar: Icon(Icons.explore, size: 16),
    ),
  ],
);
```

### Stats Card

```dart
Container(
  padding: EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: AppTheme.shadowMd,
  ),
  child: Column(
    children: [
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.fitonistGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.flight, color: Colors.white, size: 32),
      ),
      SizedBox(height: 16),
      Text('24', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
      Text('Trips', style: TextStyle(color: Colors.grey)),
    ],
  ),
);
```

---

## 🎨 Color Palette Reference

### Purple Family
```
fitonistPurple       #7B5FE8  ███ Primary brand
fitonistPurpleLight  #C8B8FF  ███ Light accent
fitonistPurpleDark   #5234B8  ███ Dark accent
fitonistPurplePale   #EFE9FF  ███ Container bg
```

### Accent Colors
```
fitonistPink         #FF88CC  ███ Playful
fitonistPinkLight    #FFB8E6  ███ Soft
fitonistBlue         #A8D8FF  ███ Cool
fitonistPeach        #FFB8A8  ███ Warm
fitonistMint         #88FFDD  ███ Fresh
fitonistYellow       #FFE066  ███ Energetic
```

---

## 🚦 Migration Guide

### Switching from Teal to Fitonist

**Before:**
```dart
MaterialApp(
  theme: AppTheme.lightTheme,  // Teal theme
  darkTheme: AppTheme.darkTheme,
)
```

**After:**
```dart
MaterialApp(
  theme: AppTheme.fitonistLightTheme,  // Purple theme
  darkTheme: AppTheme.fitonistDarkTheme,
)
```

All your existing widgets will automatically update to use the new purple color scheme!

---

## 📚 Summary

**What You Get:**
- ✅ 9 new Fitonist colors added to `AppTheme`
- ✅ 5 new vibrant gradients
- ✅ 2 new theme variants (light + dark)
- ✅ Fully integrated with your existing theme system
- ✅ Same spacing, shadows, and design system

**How to Use:**
1. Apply `AppTheme.fitonistLightTheme` to your app
2. Use `AppTheme.fitonistGradient` for headers/cards
3. Access colors via `AppTheme.fitonistPurple` etc.
4. Mix with existing themes as needed

---

**Enjoy your vibrant new Fitonist theme!** 🎨✨
