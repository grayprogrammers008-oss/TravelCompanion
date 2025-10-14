# Travel Crew App - UX Documentation

## 📱 Overview

Travel Crew is a collaborative trip planning and expense management app designed for groups of friends traveling together. The UX is built around three core pillars:

1. **Simple & Intuitive** - Minimize cognitive load, maximum clarity
2. **Collaborative** - Real-time updates, transparent information sharing
3. **Mobile-First** - Optimized for on-the-go usage during trips

---

## 🎨 Design Principles

### 1. **Card-Based UI**
- Each piece of information lives in a card
- Clear visual hierarchy
- Easy to scan and understand

### 2. **Bottom Navigation**
- Quick access to main features (Trips & Expenses)
- Always visible, context-aware
- Material Design 3 standards

### 3. **Gradient Headers**
- Beautiful visual appeal
- Clear section differentiation
- Travel-themed blue color palette

### 4. **Action-Oriented**
- Primary actions as FAB (Floating Action Button)
- Secondary actions in context menus
- Clear CTAs (Call-to-Actions)

### 5. **Real-Time Feedback**
- Loading states
- Error states with retry
- Success confirmations
- Pull-to-refresh

---

## 📂 Documentation Structure

```
UX/
├── README.md                    # This file
├── auth/                        # Authentication flows
│   ├── login-flow.md
│   ├── signup-flow.md
│   └── password-reset-flow.md
├── trips/                       # Trip management
│   ├── trip-list.md
│   ├── create-trip.md
│   ├── trip-details.md
│   ├── edit-trip.md
│   └── member-management.md
├── expenses/                    # Expense tracking
│   ├── expense-list.md
│   ├── add-expense.md
│   ├── expense-details.md
│   ├── balances.md
│   └── settlements.md
├── itinerary/                   # Trip itinerary (Future)
│   ├── itinerary-view.md
│   ├── add-activity.md
│   └── day-view.md
├── checklists/                  # Packing/todo lists (Future)
│   ├── checklist-view.md
│   ├── create-checklist.md
│   └── checklist-items.md
├── common/                      # Shared components
│   ├── navigation.md
│   ├── cards.md
│   ├── forms.md
│   ├── modals.md
│   └── error-handling.md
└── flows/                       # User journeys
    ├── onboarding.md
    ├── create-first-trip.md
    ├── add-first-expense.md
    └── split-settlement.md
```

---

## 🎯 Key User Flows

### 1. **New User Onboarding**
```
Sign Up → Create Profile → Create First Trip → Add Members → Add First Expense
```

### 2. **Creating a Trip**
```
Home → + Button → Fill Trip Details → Add Members → Save → View Trip
```

### 3. **Adding an Expense**
```
Expenses Tab → + Button → Fill Details → Select Category → Choose Split → Save
```

### 4. **Settling Up**
```
Trip Details → Balances Tab → View Who Owes Whom → Create Settlement → Mark as Paid
```

---

## 📊 Screen Inventory

### ✅ Implemented Screens

| Screen | Route | Purpose |
|--------|-------|---------|
| Login | `/` | User authentication |
| Sign Up | `/signup` | New user registration |
| Home (Trips List) | `/home` | View all user's trips |
| Create Trip | `/trips/create` | Create a new trip |
| Trip Details | `/trips/:id` | View trip info, members, expenses |
| Expenses Home | `/expenses` | View all user expenses |
| Add Expense (Trip) | `/trips/:id/expenses/add` | Add expense to specific trip |
| Add Expense (Standalone) | `/expenses/add` | Add personal expense |
| Expense Test Page | `/expenses/test` | CRUD testing (dev only) |

### 📅 Planned Screens

| Screen | Route | Purpose |
|--------|-------|---------|
| Itinerary View | `/trips/:id/itinerary` | Day-by-day activity plan |
| Add Activity | `/trips/:id/itinerary/add` | Add itinerary item |
| Checklists | `/trips/:id/checklists` | Packing/todo lists |
| Settlements | `/trips/:id/settlements` | Payment history |
| Profile | `/profile` | User profile settings |
| Trip Settings | `/trips/:id/settings` | Edit trip, manage members |

---

## 🎨 Color Palette

### Primary Colors
- **Primary Blue**: `#2196F3` - Main brand color, CTAs
- **Primary Dark**: `#1976D2` - AppBar, important elements
- **Primary Light**: `#BBDEFB` - Backgrounds, accents

### Secondary Colors
- **Secondary Teal**: `#00BCD4` - Highlights, chips
- **Accent Orange**: `#FF9800` - Warnings, pending states
- **Success Green**: `#4CAF50` - Success states, completed

### Neutral Colors
- **Background**: `#FAFAFA` - App background
- **Surface**: `#FFFFFF` - Card backgrounds
- **Text Primary**: `#212121` - Main text
- **Text Secondary**: `#757575` - Supporting text
- **Divider**: `#BDBDBD` - Separators

### Status Colors
- **Error Red**: `#F44336` - Errors, destructive actions
- **Warning Amber**: `#FFC107` - Warnings, cautions
- **Info Blue**: `#2196F3` - Information, tips

---

## 📐 Spacing System

### Consistent Spacing Scale
- **4px** - Micro spacing (icon-text gaps)
- **8px** - Small spacing (between related elements)
- **12px** - Medium spacing (section gaps)
- **16px** - Standard spacing (card padding)
- **24px** - Large spacing (section headers)
- **32px** - XL spacing (major sections)

---

## 🔤 Typography

### Text Styles
- **Display Large**: 32sp, Bold - Screen titles
- **Headline**: 24sp, Semi-Bold - Section headers
- **Title**: 20sp, Medium - Card titles
- **Body**: 16sp, Regular - Main content
- **Body Small**: 14sp, Regular - Supporting text
- **Caption**: 12sp, Regular - Metadata, timestamps

---

## 📱 Component Library

### 1. **Cards**
- Elevation: 2dp
- Border Radius: 12px
- Padding: 16px
- Margin: 8px vertical

### 2. **Buttons**
- **Primary**: Filled, Elevated
- **Secondary**: Outlined
- **Tertiary**: Text only
- Height: 48px minimum (touch target)

### 3. **Form Fields**
- Border Radius: 8px
- Padding: 16px
- Label: Floating
- Error State: Red underline + helper text

### 4. **Bottom Navigation**
- Height: 56px
- Icons: 24x24px
- Active: Primary color
- Inactive: Grey

### 5. **FAB (Floating Action Button)**
- Size: 56x56px
- Icon: 24x24px
- Position: Bottom right, 16px margin
- Extended FAB for labels

---

## 🔄 Interaction Patterns

### 1. **Pull-to-Refresh**
- Available on all list screens
- Shows loading indicator
- Refreshes data from source

### 2. **Swipe Actions**
- Swipe left: Delete (red)
- Swipe right: Edit (blue)
- Confirmation for destructive actions

### 3. **Long Press**
- Opens context menu
- Shows additional actions
- Haptic feedback

### 4. **Tap**
- Single tap: Navigate/Select
- Double tap: Like/Favorite (future)
- Minimum 48x48px touch target

---

## ♿ Accessibility

### 1. **Touch Targets**
- Minimum: 48x48px
- Recommended: 56x56px for primary actions

### 2. **Contrast Ratios**
- Text: Minimum 4.5:1
- UI Elements: Minimum 3:1

### 3. **Screen Readers**
- Semantic labels on all interactive elements
- Descriptive button labels
- Image alt text

### 4. **Focus Indicators**
- Visible focus states
- Logical tab order
- Skip links for navigation

---

## 📊 Loading & Empty States

### Loading States
- **Skeleton Screens**: Show content structure while loading
- **Shimmer Effect**: Animated loading placeholder
- **Progress Indicators**: For long operations

### Empty States
- **Friendly Illustration**: Visual interest
- **Clear Message**: What's missing, why it's empty
- **Call-to-Action**: Guide user to next step

### Error States
- **Icon**: Exclamation or error icon
- **Message**: Clear, actionable error description
- **Retry Button**: Allow user to try again
- **Support Link**: If error persists

---

## 🚀 Animation Guidelines

### Micro-interactions
- **Duration**: 200-300ms
- **Easing**: Ease-in-out for smooth feel
- **Purpose**: Provide feedback, guide attention

### Page Transitions
- **Duration**: 300-400ms
- **Type**: Shared element transitions
- **Direction**: Match user's mental model

### Loading Animations
- **Subtle**: Don't distract from content
- **Purposeful**: Indicate progress
- **Consistent**: Same style throughout app

---

## 📝 Content Guidelines

### Voice & Tone
- **Friendly**: Like a helpful travel buddy
- **Clear**: Simple, jargon-free language
- **Encouraging**: Positive, supportive messaging

### Error Messages
- **Specific**: What went wrong
- **Actionable**: How to fix it
- **Human**: No technical jargon

### Success Messages
- **Celebratory**: Acknowledge completion
- **Brief**: Don't interrupt flow
- **Informative**: Confirm what happened

---

## 🎯 Next Steps

1. Review each screen's detailed UX documentation
2. Check user flow diagrams for complete journeys
3. Refer to component library for consistency
4. Follow accessibility guidelines for inclusive design

---

**Last Updated**: 2025-10-11
**Version**: 1.0
**Maintained by**: Travel Crew UX Team
