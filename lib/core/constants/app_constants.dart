/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Travel Crew';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your Ultimate Group Travel Companion';

  // API Timeouts (in seconds)
  static const int apiTimeout = 30;
  static const int realtimeTimeout = 60;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Duration (in hours)
  static const int cacheValidityDuration = 24;

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  static const List<String> allowedDocumentFormats = ['pdf', 'doc', 'docx'];

  // Expense
  static const String defaultCurrency = 'INR';
  static const String currencySymbol = '₹';
  static const List<String> supportedCurrencies = ['INR', 'USD', 'EUR', 'GBP'];

  // Trip
  static const int minTripNameLength = 3;
  static const int maxTripNameLength = 100;
  static const int maxTripDescriptionLength = 500;
  static const int maxCrewSize = 50;
  static const int inviteExpiryDays = 7;

  // Checklist
  static const int maxChecklistNameLength = 100;
  static const int maxChecklistItemLength = 200;

  // Itinerary
  static const int maxItineraryTitleLength = 100;
  static const int maxItineraryDescriptionLength = 500;

  // Notifications
  static const String fcmTopic = 'travel_crew_all';

  // Payment Methods
  static const List<String> paymentMethods = [
    'UPI',
    'Paytm',
    'PhonePe',
    'GPay',
    'Bank Transfer',
    'Cash',
  ];

  // UPI
  static const String upiScheme = 'upi://pay';

  // Autopilot
  static const int maxAutopilotSuggestions = 10;
  static const int autopilotCacheHours = 6;

  // Storage Buckets (Supabase)
  static const String profileAvatarsBucket = 'profile-avatars';
  static const String tripCoversBucket = 'trip-covers';
  static const String expenseReceiptsBucket = 'expense-receipts';
  static const String settlementProofsBucket = 'settlement-proofs';
}

/// Expense Categories
class ExpenseCategory {
  static const String food = 'Food & Drinks';
  static const String accommodation = 'Accommodation';
  static const String transportation = 'Transportation';
  static const String activities = 'Activities';
  static const String shopping = 'Shopping';
  static const String other = 'Other';

  static const List<String> all = [
    food,
    accommodation,
    transportation,
    activities,
    shopping,
    other,
  ];
}

/// Trip Roles
enum TripRole {
  admin,
  member;

  String get displayName {
    switch (this) {
      case TripRole.admin:
        return 'Admin';
      case TripRole.member:
        return 'Member';
    }
  }
}

/// Invite Status
enum InviteStatus {
  pending,
  accepted,
  rejected;

  String get displayName {
    switch (this) {
      case InviteStatus.pending:
        return 'Pending';
      case InviteStatus.accepted:
        return 'Accepted';
      case InviteStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Settlement Status
enum SettlementStatus {
  pending,
  completed,
  failed;

  String get displayName {
    switch (this) {
      case SettlementStatus.pending:
        return 'Pending';
      case SettlementStatus.completed:
        return 'Completed';
      case SettlementStatus.failed:
        return 'Failed';
    }
  }
}

/// Split Type for expenses
enum SplitType {
  equal,
  custom,
  percentage;

  String get displayName {
    switch (this) {
      case SplitType.equal:
        return 'Split Equally';
      case SplitType.custom:
        return 'Custom Amount';
      case SplitType.percentage:
        return 'Percentage';
    }
  }
}

/// Notification Types
enum NotificationType {
  tripInvite,
  expenseAdded,
  expenseUpdated,
  checklistUpdate,
  itineraryUpdate,
  settlementRequest,
  autopilotSuggestion,
  tripUpdate;

  String get displayName {
    switch (this) {
      case NotificationType.tripInvite:
        return 'Trip Invite';
      case NotificationType.expenseAdded:
        return 'Expense Added';
      case NotificationType.expenseUpdated:
        return 'Expense Updated';
      case NotificationType.checklistUpdate:
        return 'Checklist Update';
      case NotificationType.itineraryUpdate:
        return 'Itinerary Update';
      case NotificationType.settlementRequest:
        return 'Settlement Request';
      case NotificationType.autopilotSuggestion:
        return 'Autopilot Suggestion';
      case NotificationType.tripUpdate:
        return 'Trip Update';
    }
  }
}

/// Autopilot Suggestion Types
enum AutopilotSuggestionType {
  restaurant,
  attraction,
  activity,
  detour,
  accommodation,
  transportation;

  String get displayName {
    switch (this) {
      case AutopilotSuggestionType.restaurant:
        return 'Restaurant';
      case AutopilotSuggestionType.attraction:
        return 'Attraction';
      case AutopilotSuggestionType.activity:
        return 'Activity';
      case AutopilotSuggestionType.detour:
        return 'Detour';
      case AutopilotSuggestionType.accommodation:
        return 'Accommodation';
      case AutopilotSuggestionType.transportation:
        return 'Transportation';
    }
  }

  String get icon {
    switch (this) {
      case AutopilotSuggestionType.restaurant:
        return '🍽️';
      case AutopilotSuggestionType.attraction:
        return '🎭';
      case AutopilotSuggestionType.activity:
        return '🎯';
      case AutopilotSuggestionType.detour:
        return '🗺️';
      case AutopilotSuggestionType.accommodation:
        return '🏨';
      case AutopilotSuggestionType.transportation:
        return '🚗';
    }
  }
}
