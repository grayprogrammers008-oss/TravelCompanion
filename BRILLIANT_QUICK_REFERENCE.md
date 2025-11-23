# 🌟 BRILLIANT THEME - Quick Reference Card

---

## 🚀 Apply Theme (One Line!)

```dart
import 'package:travel_crew/core/theme/brilliant_theme.dart';

MaterialApp(
  theme: BrilliantTheme.lightTheme,
  darkTheme: BrilliantTheme.darkTheme,
)
```

---

## 🎨 Essential Colors

| Color | Hex | Use For |
|-------|-----|---------|
| `electricPurple` | `#7B5FE8` | Primary brand, CTAs |
| `candyPink` | `#FF88CC` | Secondary, playful elements |
| `skyBlue` | `#A8D8FF` | Cool features, calm sections |
| `sunsetPeach` | `#FFB8A8` | Warm accents, highlights |
| `mintFresh` | `#88FFDD` | Fresh content, eco features |
| `sunshineyellow` | `#FFE066` | Energy, achievements |

---

## 🌈 Top 5 Gradients

```dart
// 1. Purple Power (Main brand)
gradient: BrilliantTheme.purplePower

// 2. Sunset Paradise (3-color WOW!)
gradient: BrilliantTheme.sunsetParadise

// 3. Candy Crush (Sweet & fun)
gradient: BrilliantTheme.candyCrush

// 4. Ocean Breeze (Cool & calm)
gradient: BrilliantTheme.oceanBreeze

// 5. Rainbow Dreams (4-color magic!)
gradient: BrilliantTheme.rainbowDreams
```

---

## 💎 Colored Shadows (3D Effect!)

```dart
boxShadow: BrilliantTheme.shadowPurple  // Purple glow
boxShadow: BrilliantTheme.shadowPink    // Pink glow
boxShadow: BrilliantTheme.shadowBlue    // Blue glow
boxShadow: BrilliantTheme.shadowNeon    // Neon glow!
```

---

## 📏 Spacing & Radius

```dart
// Spacing
BrilliantTheme.spaceSm    // 12dp
BrilliantTheme.spaceMd    // 16dp
BrilliantTheme.spaceLg    // 24dp
BrilliantTheme.spaceXl    // 32dp

// Border Radius (Extra rounded!)
BrilliantTheme.radiusLg   // 24dp - Good for cards
BrilliantTheme.radiusXl   // 32dp - Perfect for cards!
BrilliantTheme.radiusFull // 9999 - Pills & circles
```

---

## 🎯 Quick Copy-Paste Templates

### Gradient Hero Section
```dart
Container(
  height: 300,
  decoration: BoxDecoration(
    gradient: BrilliantTheme.sunsetParadise,
    borderRadius: BorderRadius.circular(32),
    boxShadow: BrilliantTheme.shadowPink,
  ),
  child: Center(
    child: Text(
      'Amazing!',
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    ),
  ),
);
```

### Gradient Button
```dart
Container(
  decoration: BoxDecoration(
    gradient: BrilliantTheme.purplePower,
    borderRadius: BorderRadius.circular(32),
    boxShadow: BrilliantTheme.shadowPurple,
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(32),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Text(
          'Click Me!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    ),
  ),
);
```

### Gradient Card Header
```dart
Card(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(32),
  ),
  child: Column(
    children: [
      Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: BrilliantTheme.oceanBreeze,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Center(
          child: Icon(Icons.flight, size: 64, color: Colors.white),
        ),
      ),
      Padding(
        padding: EdgeInsets.all(24),
        child: Text('Trip Card'),
      ),
    ],
  ),
);
```

### Colored Chip
```dart
Chip(
  label: Text('Adventure'),
  backgroundColor: BrilliantTheme.purpleMist,
  labelStyle: TextStyle(
    color: BrilliantTheme.electricPurple,
    fontWeight: FontWeight.w700,
  ),
);
```

---

## 🎨 Color Combos That Work

| Combo | Colors | Vibe |
|-------|--------|------|
| **Candy Dream** | Purple + Pink | Sweet & playful |
| **Ocean Fresh** | Blue + Mint | Cool & refreshing |
| **Sunset Glow** | Peach + Pink + Purple | Warm & inviting |
| **Tropical Pop** | Yellow + Peach + Pink | Energetic & fun |
| **Neon Energy** | Electric Blue + Neon Pink | Maximum impact |

---

## 💡 Quick Tips

1. **Use `radiusXl` (32dp)** for cards - looks amazing!
2. **Add colored shadows** to gradients for 3D depth
3. **Bold everything** - FontWeight.w900 for headers
4. **Layer gradients** with glass morph overlay
5. **Round corners generously** - more playful!

---

## 📚 Full Documentation

→ [BRILLIANT_THEME_GUIDE.md](BRILLIANT_THEME_GUIDE.md) - Complete guide with all examples

---

**Make it BRILLIANT! 🌟✨**
