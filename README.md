# 🧭 Travel Crew - Your Ultimate Group Travel Companion

[![Flutter](https://img.shields.io/badge/Flutter-3.35.5-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-blue.svg)](https://dart.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)

A comprehensive Flutter mobile app for group travel planning and coordination with real-time sync, expense tracking, itinerary management, and AI-powered recommendations.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Documentation](#documentation)
- [Development Status](#development-status)

## 🎯 Overview

Travel Crew simplifies group travel planning by providing:
- **Real-time collaboration** on itineraries and plans
- **Transparent expense tracking** with automated splitting
- **Shared checklists** to ensure nothing is forgotten
- **AI-powered recommendations** via Claude Autopilot
- **Seamless payment integration** with UPI/Paytm
- **Push notifications** for important updates

## ✨ Features

### Phase 1: MVP (Current Development)

- ✅ **Trip Management**
  - Create and manage trips
  - Invite crew members via email/phone
  - Real-time trip synchronization

- ✅ **Daily Itinerary Builder**
  - Add, edit, and organize daily activities
  - Set locations and timing
  - Collaborative editing

- ✅ **Shared Checklists**
  - Create custom packing/todo lists
  - Assign items to crew members
  - Track completion status

- ✅ **Expense Tracker**
  - Log shared expenses
  - Multiple split types (equal, custom, percentage)
  - View who owes what
  - Settlement tracking

- ✅ **Payment Integration**
  - Generate UPI payment links
  - Support for Paytm, PhonePe, GPay
  - Payment proof upload

- ✅ **AI Autopilot**
  - Claude-powered recommendations
  - Restaurant and attraction suggestions
  - Context-aware trip guidance

- ✅ **Push Notifications**
  - Trip invites
  - Expense updates
  - Itinerary changes

## 🛠 Tech Stack

### Frontend
- **Flutter 3.35.5** - Cross-platform UI framework
- **Dart 3.9.2** - Programming language
- **Riverpod** - State management
- **Freezed** - Code generation for immutable classes
- **Go Router** - Navigation and routing
- **Hive** - Local storage and caching

### Backend
- **Supabase** - Backend-as-a-Service
  - PostgreSQL database
  - Real-time subscriptions
  - Row Level Security (RLS)
  - Authentication (JWT)
  - Storage for media files

### AI & Services
- **Claude AI (Anthropic)** - AI-powered trip recommendations
- **Firebase Cloud Messaging** - Push notifications
- **UPI/Paytm** - Payment integration

## 📁 Project Structure

```
lib/
├── core/
│   ├── config/              # App configuration
│   │   └── supabase_config.dart
│   ├── constants/           # App-wide constants
│   │   └── app_constants.dart
│   ├── network/             # Network utilities
│   │   └── supabase_client.dart
│   ├── router/              # Navigation
│   ├── theme/               # App theming
│   └── utils/               # Utilities
│       ├── validators.dart
│       └── extensions.dart
│
├── features/                # Feature modules (Clean Architecture)
│   ├── auth/                # Authentication
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── widgets/
│   │       └── providers/
│   │
│   ├── trips/               # Trip management
│   ├── itinerary/           # Itinerary builder
│   ├── checklists/          # Shared checklists
│   ├── expenses/            # Expense tracking
│   ├── autopilot/           # AI recommendations
│   └── notifications/       # Push notifications
│
└── shared/                  # Shared components
    ├── models/
    ├── widgets/
    └── providers/
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.35.5 or higher)
- Dart SDK (3.9.2 or higher)
- A Supabase account
- Claude API key (for Autopilot)
- Firebase project (for notifications)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd TravelCompanion
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Supabase**
   - Create a project at [supabase.com](https://supabase.com)
   - Run the SQL schema from `SUPABASE_SCHEMA.sql`
   - Copy your project URL and anon key
   - Update `lib/core/config/supabase_config.dart`

4. **Configure Firebase** (Optional, for push notifications)
   - Create a Firebase project
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

5. **Run code generation**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

For detailed setup instructions, see [SETUP.md](SETUP.md).

## 📖 Documentation

- **[PRD.md](PRD.md)** - Product Requirements Document
- **[SETUP.md](SETUP.md)** - Detailed setup guide
- **[SUPABASE_SCHEMA.sql](SUPABASE_SCHEMA.sql)** - Database schema

## 🏗 Development Status

### Completed ✅
- Project initialization and architecture
- Supabase backend schema design
- Core utilities and configuration
- Feature-based folder structure
- Code generation setup
- Main app entry point with theming

### In Progress 🚧
- Authentication system
- Trip management UI
- Expense tracker implementation

### Planned 📅
- Itinerary builder
- Shared checklists
- Claude AI Autopilot integration
- Push notifications
- Testing suite

## 🎨 Design Principles

### Clean Architecture
Each feature follows a three-layer architecture:
- **Presentation Layer**: UI components, pages, and state management
- **Domain Layer**: Business logic, entities, and use cases
- **Data Layer**: API calls, models, and repository implementations

### State Management
- **Riverpod** for dependency injection and state management
- **Freezed** for immutable data classes
- **Code generation** for boilerplate reduction

### Security
- Row Level Security (RLS) in Supabase
- JWT-based authentication
- No sensitive data in source control
- API keys via environment variables

---

**Built with ❤️ for travelers who love to explore together**
