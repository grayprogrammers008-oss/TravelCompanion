# 🔄 Dynamic Theming Migration Guide

Quick reference for converting hardcoded colors to dynamic theme.

---

## 📋 Quick Replacement Table

### Colors

| Old (Hardcoded) ❌ | New (Dynamic) ✅ | Notes |
|-------------------|------------------|-------|
| `AppTheme.primaryTeal` | `context.primaryColor` | Main brand color |
| `AppTheme.primaryDeep` | `context.primaryDark` | Dark variant |
| `AppTheme.primaryLight` | `context.primaryColor.withValues(alpha: 0.7)` | Light variant |
| `AppTheme.primaryPale` | `context.primaryLight` | Very light background |
| `AppTheme.accentCoral` | `context.accentColor` | Secondary color |
| `AppTheme.accentPurple` | `context.accentColor` | Secondary color |
| `AppTheme.accentGold` | `context.accentColor` | Secondary color |
| `AppTheme.neutral900` | `context.textColor` | Dark text |
| `AppTheme.neutral700` | `context.textColor.withValues(alpha: 0.87)` | Medium text |
| `AppTheme.neutral600` | `context.textColor.withValues(alpha: 0.7)` | Light text |
| `AppTheme.neutral300` | `context.textColor.withValues(alpha: 0.3)` | Very light |
| `AppTheme.neutral100` | `context.backgroundColor` | Light background |
| `AppTheme.neutral50` | `context.backgroundColor` | Lightest background |
| `Colors.white` | Keep as-is | Absolute white |
| `Colors.black` | Keep as-is | Absolute black |

### Spacing

| Old ❌ | New ✅ |
|-------|--------|
| `AppTheme.spacingXs` or `8.0` | `context.spacingXs` |
| `AppTheme.spacingSm` or `12.0` | `context.spacingSm` |
| `AppTheme.spacingMd` or `16.0` | `context.spacingMd` |
| `AppTheme.spacingLg` or `24.0` | `context.spacingLg` |
| `AppTheme.spacingXl` or `32.0` | `context.spacingXl` |
| `const EdgeInsets.all(16)` | `EdgeInsets.all(context.spacingMd)` |

### Border Radius

| Old ❌ | New ✅ |
|-------|--------|
| `AppTheme.radiusXs` or `4.0` | `context.radiusXs` |
| `AppTheme.radiusSm` or `8.0` | `context.radiusSm` |
| `AppTheme.radiusMd` or `12.0` | `context.radiusMd` |
| `AppTheme.radiusLg` or `16.0` | `context.radiusLg` |
| `AppTheme.radiusXl` or `24.0` | `context.radiusXl` |
| `AppTheme.radiusFull` or `999.0` | `context.radiusFull` |
| `BorderRadius.circular(12)` | `BorderRadius.circular(context.radiusMd)` |

### Text Styles

| Old ❌ | New ✅ |
|-------|--------|
| `Theme.of(context).textTheme.headlineMedium` | `context.headlineStyle` |
| `Theme.of(context).textTheme.titleMedium` | `context.titleStyle` |
| `Theme.of(context).textTheme.bodyMedium` | `context.bodyStyle` |
| `Theme.of(context).textTheme.labelSmall` | `context.captionStyle` |

### Icons

| Old ❌ | New ✅ |
|-------|--------|
| `Icon(Icons.star, color: AppTheme.primaryTeal)` | `ThemedIcon(icon: Icons.star, isPrimary: true)` |
| `Icon(Icons.star, color: AppTheme.neutral700)` | `ThemedIcon(icon: Icons.star)` |
| `Icon(Icons.star, size: 20)` | `Icon(Icons.star, size: context.iconSizeSm)` |

---

## 🎯 Common Migration Patterns

### Pattern 1: Simple Container

**Before:**
```dart
Container(
  color: AppTheme.primaryPale,
  padding: const EdgeInsets.all(16),
  child: Icon(
    Icons.location_on,
    color: AppTheme.primaryTeal,
  ),
)
```

**After:**
```dart
Container(
  color: context.primaryLight,
  padding: EdgeInsets.all(context.spacingMd),
  child: Icon(
    Icons.location_on,
    color: context.primaryColor,
  ),
)
```

**Or use ThemedCard:**
```dart
ThemedCard(
  child: Icon(
    Icons.location_on,
    color: context.primaryColor,
  ),
)
```

---

### Pattern 2: Decorated Container

**Before:**
```dart
Container(
  padding: const EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: AppTheme.primaryPale,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Icon(
    Icons.person,
    color: AppTheme.primaryTeal,
  ),
)
```

**After:**
```dart
Container(
  padding: EdgeInsets.all(context.spacingXs),
  decoration: BoxDecoration(
    color: context.primaryLight,
    borderRadius: BorderRadius.circular(context.radiusSm),
  ),
  child: Icon(
    Icons.person,
    color: context.primaryColor,
  ),
)
```

---

### Pattern 3: Badge/Chip

**Before:**
```dart
Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  ),
  decoration: BoxDecoration(
    color: AppTheme.accentCoral,
    borderRadius: BorderRadius.circular(999),
  ),
  child: Row(
    children: [
      const Icon(Icons.access_time, size: 12, color: Colors.white),
      const SizedBox(width: 4),
      const Text(
        '5 days left',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
)
```

**After:**
```dart
ThemedChip(
  label: '5 days left',
  icon: Icons.access_time,
  isPrimary: true,
)
```

**Or manually:**
```dart
Container(
  padding: EdgeInsets.symmetric(
    horizontal: context.spacingSm,
    vertical: context.spacingXs,
  ),
  decoration: BoxDecoration(
    color: context.accentColor,
    borderRadius: BorderRadius.circular(context.radiusFull),
  ),
  child: Row(
    children: [
      Icon(Icons.access_time, size: 12, color: Colors.white),
      SizedBox(width: context.spacingXs),
      Text(
        '5 days left',
        style: context.captionStyle.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
)
```

---

### Pattern 4: Button

**Before:**
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryTeal,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 16,
    ),
  ),
  child: const Text('Create Trip'),
)
```

**After:**
```dart
ThemedButton(
  label: 'Create Trip',
  onPressed: () {},
)
```

**Or manually:**
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: context.primaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(
      horizontal: context.spacingLg,
      vertical: context.spacingMd,
    ),
  ),
  child: const Text('Create Trip'),
)
```

---

### Pattern 5: Text with Custom Style

**Before:**
```dart
Text(
  'Trip Name',
  style: const TextStyle(
    color: AppTheme.neutral900,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
)
```

**After:**
```dart
Text(
  'Trip Name',
  style: context.titleStyle.copyWith(
    fontWeight: FontWeight.w600,
  ),
)
```

---

### Pattern 6: ListTile with Icon

**Before:**
```dart
ListTile(
  leading: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: AppTheme.primaryPale,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(
      Icons.person_outline,
      color: AppTheme.primaryTeal,
    ),
  ),
  title: const Text('Profile'),
)
```

**After:**
```dart
ListTile(
  leading: Container(
    padding: EdgeInsets.all(context.spacingXs),
    decoration: BoxDecoration(
      color: context.primaryLight,
      borderRadius: BorderRadius.circular(context.radiusSm),
    ),
    child: Icon(
      Icons.person_outline,
      color: context.primaryColor,
    ),
  ),
  title: const Text('Profile'),
)
```

---

## 🔍 Search & Replace Guide

### Step 1: Find All Hardcoded Colors

Search for these patterns in your code:

```
AppTheme.primaryTeal
AppTheme.primaryPale
AppTheme.primaryLight
AppTheme.accentCoral
AppTheme.accentPurple
AppTheme.accentGold
```

### Step 2: Replace One at a Time

For each file:
1. Add import: `import '../../../../core/theme/theme_extensions.dart';`
2. Replace hardcoded colors with dynamic ones
3. Test the page
4. Commit changes

### Step 3: Remove const Keywords

Dynamic theme requires non-const widgets:

**Before:**
```dart
const Icon(Icons.star, color: AppTheme.primaryTeal)
```

**After:**
```dart
Icon(Icons.star, color: context.primaryColor)  // Remove 'const'
```

---

## ✅ Migration Checklist

For each component:

- [ ] Added `theme_extensions.dart` import
- [ ] Replaced hardcoded colors with `context.*`
- [ ] Replaced hardcoded spacing with `context.spacing*`
- [ ] Replaced hardcoded radius with `context.radius*`
- [ ] Removed `const` from widgets using dynamic theme
- [ ] Tested with multiple themes (Ocean, Sunset, Emerald)
- [ ] Verified smooth theme switching

---

## 🎨 Testing Your Migration

After migrating a component:

1. **Run the app**
   ```bash
   flutter run
   ```

2. **Navigate to the migrated component**

3. **Go to Settings → Theme**

4. **Switch between themes:**
   - Ocean Blue → Should show blue
   - Sunset Coral → Should show coral
   - Emerald Green → Should show green

5. **Verify:**
   - Colors update instantly
   - Layout stays consistent
   - No visual glitches

---

## 🚨 Common Mistakes

### Mistake 1: Forgetting to remove `const`

**Wrong:**
```dart
const Icon(Icons.star, color: context.primaryColor)  // ERROR!
```

**Right:**
```dart
Icon(Icons.star, color: context.primaryColor)
```

### Mistake 2: Mixing hardcoded and dynamic

**Wrong:**
```dart
Container(
  color: context.primaryLight,
  child: Icon(Icons.star, color: AppTheme.primaryTeal),  // Mixed!
)
```

**Right:**
```dart
Container(
  color: context.primaryLight,
  child: Icon(Icons.star, color: context.primaryColor),
)
```

### Mistake 3: Using context in const constructors

**Wrong:**
```dart
const EdgeInsets.all(context.spacingMd)  // ERROR!
```

**Right:**
```dart
EdgeInsets.all(context.spacingMd)  // Remove const
```

---

## 💡 Pro Tips

### Tip 1: Migrate Files by Feature

Don't try to migrate everything at once:
- ✅ Migrate trips/ folder first
- ✅ Then expenses/
- ✅ Then checklists/
- ✅ Etc.

### Tip 2: Use Themed Widgets When Possible

Instead of:
```dart
Container(
  padding: EdgeInsets.all(context.spacingMd),
  decoration: BoxDecoration(
    color: context.cardColor,
    borderRadius: BorderRadius.circular(context.radiusLg),
  ),
  child: ...,
)
```

Use:
```dart
ThemedCard(child: ...)
```

### Tip 3: Batch Similar Replacements

Use VS Code multi-cursor:
1. Select `AppTheme.primaryTeal`
2. Press `Cmd+D` (Mac) or `Ctrl+D` (Windows) to select next occurrence
3. Replace all at once with `context.primaryColor`

### Tip 4: Test Frequently

After migrating 2-3 components, test theme switching. Don't wait until the end!

---

## 🎯 Priority Order

Migrate in this order for maximum visual impact:

1. **High Priority** (Most visible)
   - [ ] Home page cards
   - [ ] Primary buttons
   - [ ] Navigation bar
   - [ ] Trip cards

2. **Medium Priority**
   - [ ] Trip detail pages
   - [ ] Expense cards
   - [ ] Checklist items
   - [ ] Forms

3. **Low Priority**
   - [ ] Settings pages
   - [ ] Empty states
   - [ ] Loading screens
   - [ ] Error messages

---

## 📊 Progress Tracking

Create a checklist for your migration:

```markdown
## Migration Progress

### Trips Feature
- [x] home_page.dart (partially done)
- [ ] trip_detail_page.dart
- [ ] create_trip_page.dart
- [ ] edit_trip_page.dart

### Expenses Feature
- [ ] expense_list_page.dart
- [ ] expense_detail_page.dart
- [ ] add_expense_page.dart

### Checklists Feature
- [ ] checklist_page.dart
- [ ] checklist_item_card.dart

### Settings Feature
- [ ] settings_page.dart
- [ ] theme_settings_page.dart (already done)
- [ ] profile_page.dart
```

---

## 🔗 Related Documentation

- [DYNAMIC_THEMING_IMPLEMENTED.md](DYNAMIC_THEMING_IMPLEMENTED.md) - Complete implementation guide
- [DYNAMIC_THEMING_ARCHITECTURE.md](DYNAMIC_THEMING_ARCHITECTURE.md) - Architecture overview
- [lib/core/theme/theme_extensions.dart](lib/core/theme/theme_extensions.dart) - Extension source code
- [lib/core/widgets/themed_widgets.dart](lib/core/widgets/themed_widgets.dart) - Themed widgets source

---

**Happy migrating! Your app will look amazing with dynamic themes.** 🎨✨
