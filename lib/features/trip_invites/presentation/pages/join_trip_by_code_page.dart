import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_header.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../providers/invite_providers.dart';

/// Page for manually entering an invite code to join a trip
class JoinTripByCodePage extends ConsumerStatefulWidget {
  const JoinTripByCodePage({super.key});

  @override
  ConsumerState<JoinTripByCodePage> createState() => _JoinTripByCodePageState();
}

class _JoinTripByCodePageState extends ConsumerState<JoinTripByCodePage> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValidating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateAndJoinTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final inviteCode = _codeController.text.trim().toUpperCase();
      final currentUser = ref.read(currentUserProvider).value;
      final userId = currentUser?.id;

      if (userId == null) {
        setState(() {
          _errorMessage = 'You must be logged in to join a trip';
          _isValidating = false;
        });
        return;
      }

      // Get invite by code
      final invite = await ref.read(inviteByCodeProvider(inviteCode).future);

      if (invite == null) {
        setState(() {
          _errorMessage = 'Invalid invite code. Please check and try again.';
          _isValidating = false;
        });
        return;
      }

      // Check if expired
      if (invite.expiresAt.isBefore(DateTime.now())) {
        setState(() {
          _errorMessage = 'This invite has expired.';
          _isValidating = false;
        });
        return;
      }

      // Check if already used
      if (invite.status != 'pending') {
        setState(() {
          _errorMessage = 'This invite has already been used.';
          _isValidating = false;
        });
        return;
      }

      // Accept the invite
      await ref.read(inviteRepositoryProvider).acceptInvite(
            inviteCode: inviteCode,
            userId: userId,
          );

      // Refresh user trips
      ref.invalidate(userTripsProvider);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppTheme.spacingMd),
                const Expanded(
                  child: Text(
                    'Successfully joined the trip!',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to trip details
        context.go('/trips/${invite.tripId}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to join trip: ${e.toString()}';
        _isValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Trip by Code'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingXl),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_membership,
                    size: 40,
                    color: Colors.white,
                  ),
                ),

                // Title
                Text(
                  'Enter Invite Code',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutral800,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // Description
                Text(
                  'Enter the 8-character invite code you received to join a trip',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.neutral600,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppTheme.spacing3xl),

                // Invite Code Input
                TextFormField(
                  controller: _codeController,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ABC123XY',
                    hintStyle: TextStyle(
                      color: AppTheme.neutral400,
                      letterSpacing: 4,
                    ),
                    prefixIcon: const Icon(Icons.qr_code),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      borderSide: BorderSide(color: AppTheme.neutral300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      borderSide: BorderSide(color: AppTheme.neutral300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      borderSide: const BorderSide(
                        color: AppTheme.fitonistPurple,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      borderSide: BorderSide(color: AppTheme.error),
                    ),
                    filled: true,
                    fillColor: AppTheme.neutral100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingXl,
                      vertical: AppTheme.spacingLg,
                    ),
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(8),
                    UpperCaseTextFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an invite code';
                    }
                    if (value.trim().length != 8) {
                      return 'Invite code must be 8 characters';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _validateAndJoinTrip(),
                ),

                // Error Message
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppTheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppTheme.spacing3xl),

                // Join Trip Button
                GlossyButton(
                  label: _isValidating ? 'Validating...' : 'Join Trip',
                  icon: Icons.check_circle,
                  onPressed: _isValidating ? null : _validateAndJoinTrip,
                  isLoading: _isValidating,
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // Cancel Button
                OutlinedButton.icon(
                  onPressed: _isValidating
                      ? null
                      : () {
                          context.pop();
                        },
                  icon: Icon(Icons.close, color: AppTheme.neutral600),
                  label: Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.neutral600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingLg,
                    ),
                    side: BorderSide(color: AppTheme.neutral300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacing3xl),

                // Help Text
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.fitonistPurple.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.fitonistPurple,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Text(
                          'Invite codes are case-insensitive and valid for 7 days',
                          style: TextStyle(
                            color: AppTheme.fitonistPurple,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
