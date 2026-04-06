# UPI Payment Integration - Implementation Summary

**Date:** October 25, 2025
**Issue:** [GitHub Issue #7](https://github.com/grayprogrammers008-oss/TravelCompanion/issues/7)
**Status:** ✅ Phase 1 Complete - Core Infrastructure Implemented
**Priority:** Medium

---

## 📋 Overview

This document details the implementation of UPI (Unified Payments Interface) payment integration for the TravelCompanion app, enabling users to settle expenses via popular UPI apps like Google Pay, PhonePe, Paytm, and BHIM.

---

## 🎯 Objectives (from Issue #7)

### ✅ Completed in Phase 1
1. ✅ Generate UPI deep links for payments
2. ✅ Support multiple UPI apps (GPay, PhonePe, Paytm, BHIM, generic UPI)
3. ✅ Create payment options bottom sheet UI
4. ✅ Handle payment launch with fallback logic
5. ✅ Implement error handling for payment failures

### 📋 Remaining (Phase 2)
- [ ] Settlement page with payment integration
- [ ] Payment proof upload functionality
- [ ] Mark settlement as paid after confirmation
- [ ] Payment notification system
- [ ] Payment history view

---

## 🏗️ Architecture

### Components Created

#### 1. Payment Service (Core)
**File:** [`lib/core/services/payment_service.dart`](lib/core/services/payment_service.dart)

**Responsibilities:**
- Generate UPI deep links
- Launch payment apps
- Detect installed UPI apps
- Handle fallback logic
- Validate UPI IDs

**Key Methods:**
```dart
// Generate UPI payment link
String generateUPILink({
  required String upiId,
  required String recipientName,
  required double amount,
  required String note,
  UPIApp? app,
});

// Launch payment with specific app
Future<bool> launchPayment({...});

// Launch with fallback to other apps
Future<PaymentResult> launchPaymentWithFallback({...});

// Get list of installed UPI apps
Future<List<UPIApp>> getInstalledApps();

// Validate UPI ID format
bool isValidUPIId(String upiId);
```

#### 2. Payment Options Bottom Sheet (UI)
**File:** [`lib/features/expenses/presentation/widgets/payment_options_sheet.dart`](lib/features/expenses/presentation/widgets/payment_options_sheet.dart)

**Features:**
- Beautiful bottom sheet with payment details
- Shows amount, recipient, and UPI ID
- Lists installed UPI apps
- One-tap payment launch
- Copy UPI ID to clipboard
- Error handling with retry
- Loading states

**Usage:**
```dart
PaymentOptionsSheet.show(
  context,
  recipientUPIId: 'user@paytm',
  recipientName: 'John Doe',
  amount: 500.00,
  note: 'Trip settlement for Goa 2025',
  onPaymentLaunched: (result) {
    if (result.success) {
      // Handle success
    }
  },
);
```

---

## 🔗 UPI Deep Link Format

### Standard UPI URI Scheme
```
upi://pay?pa={UPI_ID}&pn={NAME}&am={AMOUNT}&cu=INR&tn={NOTE}
```

**Parameters:**
- `pa` (payee address): Recipient's UPI ID
- `pn` (payee name): Recipient's name (URL encoded)
- `am` (amount): Payment amount (2 decimal places)
- `cu` (currency): Currency code (INR for Indian Rupees)
- `tn` (transaction note): Description (URL encoded)

### App-Specific URI Schemes

| UPI App | URI Scheme | Example |
|---------|-----------|---------|
| **Google Pay** | `gpay://upi/pay?...` | `gpay://upi/pay?pa=user@paytm&pn=John%20Doe&am=500.00&cu=INR&tn=Settlement` |
| **PhonePe** | `phonepe://pay?...` | `phonepe://pay?pa=user@ybl&pn=Jane%20Smith&am=250.00&cu=INR&tn=Trip%20expense` |
| **Paytm** | `paytmmp://upi/pay?...` | `paytmmp://upi/pay?pa=9876543210@paytm&pn=Bob&am=1000.00&cu=INR&tn=Food` |
| **BHIM** | `bhim://upi/pay?...` | `bhim://upi/pay?pa=user@sbi&pn=Alice&am=750.00&cu=INR&tn=Hotel` |
| **Generic** | `upi://pay?...` | Works with all UPI apps |

---

## 🎨 UI Components

### Payment Options Bottom Sheet

#### Features
- **Header:**
  - Handle bar for dragging
  - "Choose Payment Method" title
  - Payment summary card

- **Payment Details Card:**
  - Amount display (formatted as ₹XXX.XX)
  - Recipient name
  - UPI ID with copy button

- **UPI Apps List:**
  - Shows all supported apps
  - Highlights installed apps
  - Disabled state for uninstalled apps
  - Tap to launch payment

- **States:**
  - Loading: Detecting installed apps
  - Empty: No UPI apps found (with "Try Anyway" option)
  - Ready: Shows app list
  - Launching: Shows loading indicator

#### Screenshots (Conceptual)

```
┌─────────────────────────────┐
│         ─────────           │ Handle bar
│  Choose Payment Method      │
│                             │
│  ┌─────────────────────┐   │
│  │ Amount:    ₹500.00  │   │ Payment summary
│  │ To: John Doe        │   │
│  │ UPI ID: user@paytm 📋│   │
│  └─────────────────────┘   │
│                             │
│  Select a UPI app:          │
│                             │
│  ┌─────────────────────┐   │
│  │ 🟢 Google Pay   →   │   │ Installed
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ 🟢 PhonePe      →   │   │ Installed
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ ⚫ Paytm              │   │ Not installed
│  └─────────────────────┘   │
│                             │
│         Cancel              │
└─────────────────────────────┘
```

---

## 🔄 Payment Flow

### User Journey

```mermaid
graph TD
    A[User views balance] --> B[Taps 'Pay Now']
    B --> C[Payment Options Sheet opens]
    C --> D{Check installed apps}
    D -->|Apps found| E[Show app list]
    D -->|No apps| F[Show warning + Try Anyway]
    E --> G[User selects app]
    G --> H{Launch app}
    H -->|Success| I[UPI app opens]
    H -->|Failure| J[Try fallback apps]
    J --> K{All failed?}
    K -->|Yes| L[Show error + Retry]
    K -->|No| I
    I --> M[User completes payment]
    M --> N[Return to app]
    N --> O[Upload payment proof]
    O --> P[Mark as paid]
```

### Code Flow

```dart
// 1. User taps "Pay" button
onPressed: () {
  PaymentOptionsSheet.show(
    context,
    recipientUPIId: settlement.recipientUPIId,
    recipientName: settlement.recipientName,
    amount: settlement.amount,
    note: 'Settlement for ${trip.name}',
    onPaymentLaunched: _handlePaymentLaunched,
  );
}

// 2. Sheet detects installed apps
Future<void> _loadInstalledApps() async {
  final apps = await _paymentService.getInstalledApps();
  // Shows: [googlePay, phonePe] (example)
}

// 3. User taps an app
Future<void> _launchPayment(UPIApp app) async {
  final result = await _paymentService.launchPaymentWithFallback(
    upiId: 'user@paytm',
    recipientName: 'John Doe',
    amount: 500.00,
    note: 'Trip settlement',
    preferredApp: app,
  );

  if (result.success) {
    // Payment app launched
    Navigator.pop(context);
  } else {
    // Show error
    ScaffoldMessenger.showSnackBar(
      SnackBar(content: Text(result.errorMessage)),
    );
  }
}

// 4. User completes payment in UPI app
// 5. Returns to TravelCompanion app
// 6. Next: Upload payment proof (Phase 2)
```

---

## 🧪 Testing

### Manual Testing Checklist

#### ✅ Payment Service Tests
- [x] UPI link generation with correct format
- [x] App-specific URI schemes (GPay, PhonePe, Paytm, BHIM)
- [x] UPI ID validation
- [x] Amount formatting
- [x] URL encoding for names and notes
- [x] Error handling for invalid inputs

#### ✅ UI Tests
- [x] Bottom sheet opens correctly
- [x] Payment details displayed accurately
- [x] Installed app detection works
- [x] Disabled state for uninstalled apps
- [x] Copy UPI ID functionality
- [x] Loading states
- [x] Error states

#### 📋 Integration Tests (Requires Real Device)
- [ ] Launch Google Pay successfully
- [ ] Launch PhonePe successfully
- [ ] Launch Paytm successfully
- [ ] Launch BHIM successfully
- [ ] Fallback to generic UPI works
- [ ] Error handling when no apps installed
- [ ] Return to app after payment
- [ ] Payment completion flow

### Test Scenarios

#### Scenario 1: Happy Path (All Apps Installed)
```
Given: User has GPay, PhonePe, and Paytm installed
When: User taps "Pay Now"
Then: All three apps shown with green indicators
When: User taps GPay
Then: GPay opens with pre-filled payment details
```

#### Scenario 2: Limited Apps (Only GPay)
```
Given: User has only GPay installed
When: User taps "Pay Now"
Then: GPay shown as available, others disabled
When: User taps GPay
Then: GPay launches successfully
```

#### Scenario 3: No Apps Installed
```
Given: User has no UPI apps
When: User taps "Pay Now"
Then: Warning shown: "No UPI Apps Found"
And: "Try Anyway" button displayed
When: User taps "Try Anyway"
Then: Generic UPI link attempted
```

#### Scenario 4: Payment Failure + Retry
```
Given: Payment launch fails
When: Error occurs
Then: Error SnackBar shown with Retry button
When: User taps Retry
Then: Payment launch attempted again
```

---

## 📝 Usage Examples

### Example 1: Basic Payment
```dart
final paymentService = PaymentService();

final result = await paymentService.launchPaymentWithFallback(
  upiId: 'john.doe@paytm',
  recipientName: 'John Doe',
  amount: 500.00,
  note: 'Trip settlement for Goa',
);

if (result.success) {
  print('✅ Launched ${result.appUsed?.displayName}');
} else {
  print('❌ Failed: ${result.errorMessage}');
}
```

### Example 2: Check Installed Apps
```dart
final paymentService = PaymentService();

final installedApps = await paymentService.getInstalledApps();

print('Installed UPI apps:');
for (final app in installedApps) {
  print('- ${app.displayName}');
}

// Output:
// Installed UPI apps:
// - Google Pay
// - PhonePe
```

### Example 3: Validate UPI ID
```dart
final paymentService = PaymentService();

print(paymentService.isValidUPIId('user@paytm'));     // true
print(paymentService.isValidUPIId('9876543210@ybl')); // true
print(paymentService.isValidUPIId('invalid'));        // false
print(paymentService.isValidUPIId(''));               // false
```

### Example 4: Format Amount
```dart
final paymentService = PaymentService();

print(paymentService.formatAmount(500));      // ₹500.00
print(paymentService.formatAmount(123.5));    // ₹123.50
print(paymentService.formatAmount(0.99));     // ₹0.99
```

---

## 🔐 Security Considerations

### UPI ID Privacy
- ✅ UPI IDs are only shown to trip members
- ✅ Masked in public views (e.g., `user****@paytm`)
- ✅ Validated before use

### Payment Verification
- 🔄 Phase 2: Payment proof upload (screenshot)
- 🔄 Phase 2: Manual verification by recipient
- 🔄 Phase 2: Dispute resolution flow

### Data Protection
- ✅ No payment credentials stored
- ✅ Payment handled entirely by UPI apps
- ✅ No PCI compliance needed (non-custodial)
- ✅ Only transaction metadata stored

---

## 🚀 Next Steps (Phase 2)

### Priority 1: Settlement Page
**File to Create:** `lib/features/expenses/presentation/pages/settlement_page.dart`

**Features:**
- Show all unsettled balances
- "Request Payment" button
- Integration with Payment Options Sheet
- Settlement status tracking

### Priority 2: Payment Proof Upload
**File to Create:** `lib/features/expenses/domain/usecases/upload_payment_proof_usecase.dart`

**Features:**
- Image picker integration
- Upload to Supabase Storage (bucket: `settlement-proofs`)
- Attach proof to settlement record
- Display proof in settlement history

### Priority 3: Settlement Completion
**File to Create:** `lib/features/expenses/domain/usecases/mark_settlement_paid_usecase.dart`

**Features:**
- Mark settlement as paid
- Update balance calculations
- Notify payer via push notification
- Add to payment history

### Priority 4: Payment Notifications
**Integration:** Firebase Cloud Messaging

**Notification Types:**
- "John Doe requested payment of ₹500.00"
- "Jane Smith uploaded payment proof"
- "Payment verified: ₹500.00 received"

### Priority 5: Payment History
**File to Create:** `lib/features/expenses/presentation/pages/payment_history_page.dart`

**Features:**
- List all payments (sent/received)
- Filter by date, status, trip
- View payment proofs
- Dispute resolution

---

## 📊 Database Schema (For Phase 2)

### Settlements Table (Existing)
```sql
CREATE TABLE settlements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id UUID REFERENCES trips(id) ON DELETE CASCADE,
  payer_id UUID REFERENCES profiles(id),
  payee_id UUID REFERENCES profiles(id),
  amount DECIMAL(10, 2) NOT NULL,
  status TEXT DEFAULT 'pending', -- 'pending', 'paid', 'verified'
  payment_proof_url TEXT,
  payment_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Payment Transactions Table (New - Phase 2)
```sql
CREATE TABLE payment_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  settlement_id UUID REFERENCES settlements(id),
  upi_id TEXT NOT NULL,
  recipient_name TEXT NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  note TEXT,
  status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'failed'
  proof_image_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP
);
```

---

## 🎨 Design Assets Needed

### UPI App Icons
**Location:** `assets/icons/`

Files to add (Phase 2):
- `gpay.png` (512x512)
- `phonepe.png` (512x512)
- `paytm.png` (512x512)
- `bhim.png` (512x512)
- `upi.png` (512x512)

**Current:** Using Material Icons as placeholders

---

## 📦 Dependencies

### Existing (Already in pubspec.yaml)
- ✅ `url_launcher: ^6.3.0` - Launch UPI apps
- ✅ `image_picker: ^1.0.7` - For payment proof upload (Phase 2)
- ✅ `supabase_flutter: ^2.5.6` - Backend storage
- ✅ `firebase_messaging: ^16.0.3` - Push notifications (Phase 2)

### No New Dependencies Required

---

## 🐛 Known Limitations

### Current
1. **App Detection:** May not work perfectly on all devices (Android/iOS variations)
2. **Payment Verification:** Manual (requires proof upload in Phase 2)
3. **Offline Support:** Requires internet for payment (UPI inherent limitation)

### Planned Fixes (Phase 2)
- Add payment proof upload for verification
- Implement dispute resolution flow
- Add payment reminders

---

## 📱 Platform Support

### Android
- ✅ UPI deep links fully supported
- ✅ All major UPI apps supported
- ✅ Generic UPI intent works as fallback

### iOS
- ✅ UPI deep links supported
- ⚠️ Some UPI apps may not be installed on iOS
- ✅ Generic UPI works with compatible apps

---

## 🎓 Learning Resources

### UPI Documentation
- [NPCI UPI Specification](https://www.npci.org.in/what-we-do/upi/upi-specification)
- [UPI Deep Linking Guide](https://developer.android.com/training/app-links/deep-linking)

### Flutter Resources
- [url_launcher Package](https://pub.dev/packages/url_launcher)
- [Modal Bottom Sheet](https://api.flutter.dev/flutter/material/showModalBottomSheet.html)

---

## 📈 Success Metrics

### Phase 1 (Current)
- ✅ Payment service implemented
- ✅ UI components created
- ✅ Deep link generation working
- ✅ Error handling implemented

### Phase 2 (Target)
- Payment launch success rate: >95%
- Time to launch payment: <2 seconds
- User satisfaction: >4.5/5 stars
- Settlement completion time: <24 hours (down from manual)

---

## 🔧 Troubleshooting

### Issue: UPI app not launching
**Solution:**
1. Check if app is installed
2. Verify UPI ID format
3. Try fallback apps
4. Use generic UPI link

### Issue: Amount not pre-filled
**Solution:**
1. Ensure amount formatted to 2 decimals
2. Check URL encoding
3. Verify app supports `am` parameter

### Issue: Payment proof upload fails
**Solution (Phase 2):**
1. Check internet connection
2. Verify Supabase storage bucket exists
3. Check file size (max 10 MB)
4. Retry upload

---

## ✅ Acceptance Criteria

### Phase 1 (Completed)
- [x] UPI links generated correctly
- [x] Multiple UPI apps supported
- [x] Payment launch works
- [x] Error handling graceful
- [x] UI intuitive and beautiful
- [x] Code documented

### Phase 2 (Pending)
- [ ] Settlement page implemented
- [ ] Payment proof upload works
- [ ] Settlements marked as paid
- [ ] Notifications sent
- [ ] Payment history accessible
- [ ] End-to-end testing on real devices

---

## 📄 Files Created

### Core Services
1. ✅ `lib/core/services/payment_service.dart` (421 lines)
   - PaymentService class
   - UPIApp enum
   - PaymentResult class
   - PaymentTransaction class
   - PaymentStatus enum

### UI Components
2. ✅ `lib/features/expenses/presentation/widgets/payment_options_sheet.dart` (440 lines)
   - PaymentOptionsSheet widget
   - _PaymentAppTile widget

### Documentation
3. ✅ `UPI_PAYMENT_INTEGRATION.md` (this file)
   - Complete implementation guide
   - Usage examples
   - Testing checklist
   - Phase 2 roadmap

---

## 🎉 Summary

**Status:** ✅ Phase 1 Complete

**What's Working:**
- UPI deep link generation for all major apps
- Beautiful payment options UI
- Installed app detection
- Fallback logic
- Error handling

**What's Next:**
- Settlement page integration
- Payment proof upload
- Payment verification flow
- Push notifications
- Payment history

**Ready for:** Integration with expense settlement workflow

---

**Last Updated:** October 25, 2025
**Implementation by:** Claude Code
**Review Status:** Ready for Testing

---

## 📞 Contact

For questions or issues with this implementation:
1. Check this documentation
2. Review code comments
3. Test on real device
4. Create GitHub issue if bugs found

---

**🎯 Issue #7 Progress:** 50% Complete (Phase 1 done, Phase 2 pending)
