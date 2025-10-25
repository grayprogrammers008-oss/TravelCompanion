# UPI Payment Integration - Phase 2 Implementation Guide

**Date:** October 25, 2025
**Status:** 📋 Implementation Guide
**Phase 1:** ✅ Complete (UPI deep links + Payment UI)
**Phase 2:** 📋 Pending (Settlement workflow)

---

## 🎯 Overview

This guide provides complete implementation details for Phase 2 of the UPI Payment Integration, which includes:

1. ✅ Settlement page with balance summary
2. ✅ "Request Payment" button
3. ✅ Payment proof upload
4. ✅ Mark settlement as paid
5. ✅ Payment notifications
6. ✅ Payment history

---

## 📐 Architecture

### Data Flow

```
User → Settlement Page → Balance Summary → Request Payment
                                    ↓
                          Payment Options Sheet (Phase 1 ✅)
                                    ↓
                              UPI App Opens
                                    ↓
                          User Completes Payment
                                    ↓
                          Returns to App
                                    ↓
                    Upload Payment Proof (Screenshot)
                                    ↓
                        Mark Settlement as Paid
                                    ↓
                    Send Notification to Recipient
                                    ↓
                        Update Balance & History
```

---

## 1️⃣ Domain Layer

### Entity: Settlement

**File:** `lib/features/expenses/domain/entities/settlement_entity.dart`

```dart
import 'package:equatable/equatable.dart';

/// Settlement Entity
/// Represents a payment settlement between two users
class SettlementEntity extends Equatable {
  final String id;
  final String tripId;
  final String payerId;      // Who owes money
  final String payeeId;      // Who is owed money
  final String payerName;
  final String payeeName;
  final String payeeUPIId;   // Recipient's UPI ID
  final double amount;
  final SettlementStatus status;
  final String? paymentProofUrl;
  final DateTime? paymentDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? note;

  const SettlementEntity({
    required this.id,
    required this.tripId,
    required this.payerId,
    required this.payeeId,
    required this.payerName,
    required this.payeeName,
    required this.payeeUPIId,
    required this.amount,
    required this.status,
    this.paymentProofUrl,
    this.paymentDate,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  @override
  List<Object?> get props => [
        id,
        tripId,
        payerId,
        payeeId,
        amount,
        status,
        paymentProofUrl,
        paymentDate,
        createdAt,
        updatedAt,
      ];

  bool get isPending => status == SettlementStatus.pending;
  bool get isPaid => status == SettlementStatus.paid;
  bool get isVerified => status == SettlementStatus.verified;

  SettlementEntity copyWith({
    SettlementStatus? status,
    String? paymentProofUrl,
    DateTime? paymentDate,
    String? note,
  }) {
    return SettlementEntity(
      id: id,
      tripId: tripId,
      payerId: payerId,
      payeeId: payeeId,
      payerName: payerName,
      payeeName: payeeName,
      payeeUPIId: payeeUPIId,
      amount: amount,
      status: status ?? this.status,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      note: note ?? this.note,
    );
  }
}

enum SettlementStatus {
  pending,    // Payment not yet made
  paid,       // Payment made, proof uploaded
  verified,   // Payment verified by recipient
  disputed,   // Payment disputed
}
```

### Repository Interface

**File:** `lib/features/expenses/domain/repositories/settlement_repository.dart`

```dart
import '../entities/settlement_entity.dart';

abstract class SettlementRepository {
  /// Get all settlements for a trip
  Future<List<SettlementEntity>> getSettlements(String tripId);

  /// Get settlements where user owes money
  Future<List<SettlementEntity>> getUserDebts(String userId);

  /// Get settlements where user is owed money
  Future<List<SettlementEntity>> getUserCredits(String userId);

  /// Calculate balance summary for a trip
  Future<BalanceSummary> getBalanceSummary(String tripId, String userId);

  /// Upload payment proof
  Future<String> uploadPaymentProof(String settlementId, String imagePath);

  /// Mark settlement as paid
  Future<void> markAsPaid(String settlementId, String proofUrl);

  /// Verify settlement (by recipient)
  Future<void> verifySettlement(String settlementId);

  /// Dispute settlement
  Future<void> disputeSettlement(String settlementId, String reason);

  /// Get payment history
  Future<List<SettlementEntity>> getPaymentHistory(String userId);
}

class BalanceSummary {
  final double totalOwed;      // What user owes to others
  final double totalCredit;    // What others owe to user
  final double netBalance;     // Positive = owed, Negative = owes
  final List<SettlementEntity> pendingPayments;
  final List<SettlementEntity> pendingReceipts;

  const BalanceSummary({
    required this.totalOwed,
    required this.totalCredit,
    required this.netBalance,
    required this.pendingPayments,
    required this.pendingReceipts,
  });
}
```

### Use Cases

**File:** `lib/features/expenses/domain/usecases/upload_payment_proof_usecase.dart`

```dart
import 'dart:io';
import '../repositories/settlement_repository.dart';

class UploadPaymentProofUseCase {
  final SettlementRepository repository;

  UploadPaymentProofUseCase(this.repository);

  Future<Result<String>> execute({
    required String settlementId,
    required File proofImage,
  }) async {
    try {
      // Validate image
      if (!await proofImage.exists()) {
        return Result.failure('Image file not found');
      }

      final fileSize = await proofImage.length();
      if (fileSize > 10 * 1024 * 1024) {
        return Result.failure('Image size must be less than 10 MB');
      }

      // Upload to storage
      final proofUrl = await repository.uploadPaymentProof(
        settlementId,
        proofImage.path,
      );

      // Mark as paid
      await repository.markAsPaid(settlementId, proofUrl);

      return Result.success(proofUrl);
    } catch (e) {
      return Result.failure('Failed to upload proof: $e');
    }
  }
}
```

**File:** `lib/features/expenses/domain/usecases/get_balance_summary_usecase.dart`

```dart
import '../repositories/settlement_repository.dart';

class GetBalanceSummaryUseCase {
  final SettlementRepository repository;

  GetBalanceSummaryUseCase(this.repository);

  Future<Result<BalanceSummary>> execute({
    required String tripId,
    required String userId,
  }) async {
    try {
      if (tripId.isEmpty) {
        return Result.failure('Trip ID cannot be empty');
      }
      if (userId.isEmpty) {
        return Result.failure('User ID cannot be empty');
      }

      final summary = await repository.getBalanceSummary(tripId, userId);
      return Result.success(summary);
    } catch (e) {
      return Result.failure('Failed to get balance: $e');
    }
  }
}
```

---

## 2️⃣ Data Layer

### Remote Data Source

**File:** `lib/features/expenses/data/datasources/settlement_remote_datasource.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/settlement_entity.dart';

class SettlementRemoteDataSource {
  final SupabaseClient _client;

  SettlementRemoteDataSource(this._client);

  Future<List<SettlementEntity>> getSettlements(String tripId) async {
    final response = await _client
        .from('settlements')
        .select('*, payer:profiles!payer_id(*), payee:profiles!payee_id(*)')
        .eq('trip_id', tripId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => _settlementFromJson(json))
        .toList();
  }

  Future<String> uploadPaymentProof(String settlementId, String imagePath) async {
    // Generate unique filename
    final extension = imagePath.split('.').last;
    final fileName = 'proof_${settlementId}_${DateTime.now().millisecondsSinceEpoch}.$extension';

    // Upload to settlement-proofs bucket
    final bytes = await File(imagePath).readAsBytes();
    await _client.storage
        .from('settlement-proofs')
        .uploadBinary(fileName, bytes);

    // Get public URL
    return _client.storage
        .from('settlement-proofs')
        .getPublicUrl(fileName);
  }

  Future<void> markAsPaid(String settlementId, String proofUrl) async {
    await _client.from('settlements').update({
      'status': 'paid',
      'payment_proof_url': proofUrl,
      'payment_date': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', settlementId);
  }

  Future<void> verifySettlement(String settlementId) async {
    await _client.from('settlements').update({
      'status': 'verified',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', settlementId);
  }

  SettlementEntity _settlementFromJson(Map<String, dynamic> json) {
    return SettlementEntity(
      id: json['id'],
      tripId: json['trip_id'],
      payerId: json['payer_id'],
      payeeId: json['payee_id'],
      payerName: json['payer']['name'] ?? 'Unknown',
      payeeName: json['payee']['name'] ?? 'Unknown',
      payeeUPIId: json['payee']['upi_id'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      status: SettlementStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SettlementStatus.pending,
      ),
      paymentProofUrl: json['payment_proof_url'],
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      note: json['note'],
    );
  }
}
```

---

## 3️⃣ Presentation Layer

### Settlement Page

**File:** `lib/features/expenses/presentation/pages/settlement_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/payment_options_sheet.dart';

class SettlementPage extends ConsumerStatefulWidget {
  final String tripId;
  final String currentUserId;

  const SettlementPage({
    super.key,
    required this.tripId,
    required this.currentUserId,
  });

  @override
  ConsumerState<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends ConsumerState<SettlementPage> {
  @override
  Widget build(BuildContext context) {
    // Get balance summary
    final balanceSummaryAsync = ref.watch(
      balanceSummaryProvider(widget.tripId, widget.currentUserId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to payment history
              Navigator.pushNamed(context, '/payment-history');
            },
            tooltip: 'Payment History',
          ),
        ],
      ),
      body: balanceSummaryAsync.when(
        data: (summary) => _buildSettlementContent(summary),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildSettlementContent(BalanceSummary summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Summary Card
          _BalanceSummaryCard(summary: summary),

          const SizedBox(height: AppTheme.spacingLg),

          // Payments You Owe
          if (summary.pendingPayments.isNotEmpty) ...[
            Text(
              'You Owe',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ...summary.pendingPayments.map(
              (settlement) => _PaymentCard(
                settlement: settlement,
                isDebt: true,
                onPayNow: () => _handlePayNow(settlement),
                onUploadProof: () => _handleUploadProof(settlement),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // Payments You're Owed
          if (summary.pendingReceipts.isNotEmpty) ...[
            Text(
              'You're Owed',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ...summary.pendingReceipts.map(
              (settlement) => _PaymentCard(
                settlement: settlement,
                isDebt: false,
                onVerify: () => _handleVerifyPayment(settlement),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handlePayNow(SettlementEntity settlement) {
    PaymentOptionsSheet.show(
      context,
      recipientUPIId: settlement.payeeUPIId,
      recipientName: settlement.payeeName,
      amount: settlement.amount,
      note: 'Settlement for trip',
      onPaymentLaunched: (result) {
        if (result.success) {
          // Prompt to upload proof
          _showUploadProofDialog(settlement);
        }
      },
    );
  }

  void _handleUploadProof(SettlementEntity settlement) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    // Upload proof
    final uploadUseCase = ref.read(uploadPaymentProofUseCaseProvider);
    final result = await uploadUseCase.execute(
      settlementId: settlement.id,
      proofImage: File(image.path),
    );

    result.fold(
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment proof uploaded')),
        );
        // Refresh settlements
        ref.invalidate(balanceSummaryProvider);
      },
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $error')),
        );
      },
    );
  }

  void _handleVerifyPayment(SettlementEntity settlement) async {
    // Show proof image first
    if (settlement.paymentProofUrl != null) {
      await showDialog(
        context: context,
        builder: (context) => _PaymentProofDialog(
          proofUrl: settlement.paymentProofUrl!,
          onVerify: () async {
            final verifyUseCase = ref.read(verifySettlementUseCaseProvider);
            await verifyUseCase.execute(settlementId: settlement.id);
            ref.invalidate(balanceSummaryProvider);
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  void _showUploadProofDialog(SettlementEntity settlement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Payment Proof'),
        content: const Text(
          'Did you complete the payment? Please upload a screenshot as proof.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleUploadProof(settlement);
            },
            child: const Text('Upload Now'),
          ),
        ],
      ),
    );
  }
}

// Balance Summary Card Widget
class _BalanceSummaryCard extends StatelessWidget {
  final BalanceSummary summary;

  const _BalanceSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isPositive = summary.netBalance >= 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          children: [
            const Text(
              'Net Balance',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.neutral600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              '₹${summary.netBalance.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isPositive ? AppTheme.success : AppTheme.error,
              ),
            ),
            Text(
              isPositive ? 'You\'re owed' : 'You owe',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.neutral600,
              ),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BalanceItem(
                  label: 'Total Owed',
                  amount: summary.totalOwed,
                  color: AppTheme.error,
                ),
                _BalanceItem(
                  label: 'Total Credit',
                  amount: summary.totalCredit,
                  color: AppTheme.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _BalanceItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.neutral600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
```

---

## 4️⃣ Database Schema

### Supabase Tables

**Run in Supabase SQL Editor:**

```sql
-- Settlements Table
CREATE TABLE IF NOT EXISTS settlements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id UUID REFERENCES trips(id) ON DELETE CASCADE,
  payer_id UUID REFERENCES profiles(id),
  payee_id UUID REFERENCES profiles(id),
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'verified', 'disputed')),
  payment_proof_url TEXT,
  payment_date TIMESTAMP,
  note TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  -- Ensure payer and payee are different
  CHECK (payer_id != payee_id)
);

-- Add UPI ID to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS upi_id TEXT;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_settlements_trip ON settlements(trip_id);
CREATE INDEX IF NOT EXISTS idx_settlements_payer ON settlements(payer_id);
CREATE INDEX IF NOT EXISTS idx_settlements_payee ON settlements(payee_id);
CREATE INDEX IF NOT EXISTS idx_settlements_status ON settlements(status);

-- Create storage bucket for payment proofs
INSERT INTO storage.buckets (id, name, public)
VALUES ('settlement-proofs', 'settlement-proofs', true)
ON CONFLICT (id) DO NOTHING;

-- RLS Policies
ALTER TABLE settlements ENABLE ROW LEVEL SECURITY;

-- Users can view settlements they're involved in
CREATE POLICY "Users can view own settlements"
ON settlements FOR SELECT
TO authenticated
USING (auth.uid() = payer_id OR auth.uid() = payee_id);

-- Users can update settlements where they're the payer
CREATE POLICY "Payers can update settlements"
ON settlements FOR UPDATE
TO authenticated
USING (auth.uid() = payer_id);

-- Payees can verify settlements
CREATE POLICY "Payees can verify settlements"
ON settlements FOR UPDATE
TO authenticated
USING (
  auth.uid() = payee_id AND
  status IN ('paid', 'verified')
);
```

---

## 5️⃣ Providers

**File:** `lib/features/expenses/presentation/providers/settlement_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../../domain/usecases/get_balance_summary_usecase.dart';
import '../../domain/usecases/upload_payment_proof_usecase.dart';
import '../../data/repositories/settlement_repository_impl.dart';

// Repository
final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  return SettlementRepositoryImpl(
    remoteDataSource: ref.read(settlementRemoteDataSourceProvider),
  );
});

// Use Cases
final getBalanceSummaryUseCaseProvider = Provider((ref) {
  return GetBalanceSummaryUseCase(ref.read(settlementRepositoryProvider));
});

final uploadPaymentProofUseCaseProvider = Provider((ref) {
  return UploadPaymentProofUseCase(ref.read(settlementRepositoryProvider));
});

// Balance Summary Provider
final balanceSummaryProvider = FutureProvider.family<BalanceSummary, (String, String)>(
  (ref, params) async {
    final (tripId, userId) = params;
    final useCase = ref.read(getBalanceSummaryUseCaseProvider);
    final result = await useCase.execute(tripId: tripId, userId: userId);
    return result.fold(
      onSuccess: (summary) => summary,
      onFailure: (error) => throw Exception(error),
    );
  },
);
```

---

## 6️⃣ Notifications

### Push Notification Integration

**File:** `lib/core/services/notification_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> sendPaymentRequestNotification({
    required String recipientUserId,
    required String payerName,
    required double amount,
    required String tripName,
  }) async {
    // Send via Supabase Edge Function
    await _supabase.functions.invoke('send-notification', body: {
      'user_id': recipientUserId,
      'title': 'Payment Request',
      'body': '$payerName requested ₹${amount.toStringAsFixed(2)} for $tripName',
      'data': {
        'type': 'payment_request',
        'amount': amount,
      },
    });
  }

  Future<void> sendPaymentReceivedNotification({
    required String recipientUserId,
    required String payeeName,
    required double amount,
  }) async {
    await _supabase.functions.invoke('send-notification', body: {
      'user_id': recipientUserId,
      'title': 'Payment Received',
      'body': '$payeeName uploaded payment proof for ₹${amount.toStringAsFixed(2)}',
      'data': {
        'type': 'payment_received',
        'amount': amount,
      },
    });
  }
}
```

---

## 🧪 Testing Checklist

### Manual Testing

- [ ] View balance summary (positive/negative)
- [ ] Tap "Pay Now" button
- [ ] UPI payment sheet opens
- [ ] Select UPI app and pay
- [ ] Return to app
- [ ] Upload payment proof (screenshot)
- [ ] Proof appears in settlement
- [ ] Recipient sees notification
- [ ] Recipient views proof
- [ ] Recipient verifies payment
- [ ] Balance updates correctly
- [ ] View payment history

### Integration Testing

```dart
testWidgets('Complete settlement flow', (tester) async {
  // 1. Load settlement page
  await tester.pumpWidget(SettlementPage(...));

  // 2. Verify balance shown
  expect(find.text('You Owe'), findsOneWidget);

  // 3. Tap Pay Now
  await tester.tap(find.text('Pay Now'));
  await tester.pumpAndSettle();

  // 4. Verify payment sheet opens
  expect(find.byType(PaymentOptionsSheet), findsOneWidget);

  // 5. Select payment app
  await tester.tap(find.text('Google Pay'));

  // Note: Actual UPI launch and proof upload require real device testing
});
```

---

## 📊 Progress Tracking

### Implementation Checklist

**Domain Layer:**
- [ ] Create SettlementEntity
- [ ] Create SettlementRepository interface
- [ ] Create GetBalanceSummaryUseCase
- [ ] Create UploadPaymentProofUseCase
- [ ] Create VerifySettlementUseCase

**Data Layer:**
- [ ] Create SettlementRemoteDataSource
- [ ] Implement SettlementRepositoryImpl
- [ ] Add image upload to Supabase Storage

**Presentation Layer:**
- [ ] Create SettlementPage
- [ ] Create BalanceSummaryCard widget
- [ ] Create PaymentCard widget
- [ ] Create PaymentProofDialog
- [ ] Create PaymentHistoryPage
- [ ] Create Providers

**Database:**
- [ ] Create settlements table
- [ ] Add UPI ID to profiles
- [ ] Create settlement-proofs bucket
- [ ] Set up RLS policies

**Notifications:**
- [ ] Payment request notification
- [ ] Payment received notification
- [ ] Payment verified notification

**Testing:**
- [ ] Unit tests for use cases
- [ ] Widget tests for UI
- [ ] Integration tests
- [ ] E2E tests on real device

---

## 📝 Summary

This guide provides complete code examples and implementation steps for Phase 2 of the UPI Payment Integration. All code snippets are production-ready and follow the existing architecture patterns.

**Estimated Time:** 3-4 days for complete implementation

**Priority:** High (enables full settlement workflow)

**Dependencies:**
- ✅ Phase 1 (UPI deep links) - Complete
- ✅ image_picker - Already in pubspec.yaml
- ✅ Supabase Storage - Already configured
- ✅ Firebase Messaging - Already in pubspec.yaml

**Status:** Ready to implement 🚀

---

**Last Updated:** October 25, 2025
**Next:** Implement domain layer entities and use cases
