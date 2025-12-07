import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../trip_invites/presentation/providers/invite_providers.dart';

/// QR Code sharing widget for trips
/// Generates a QR code that others can scan to join the trip
class TripQrShare extends ConsumerStatefulWidget {
  final String tripId;
  final String tripName;

  const TripQrShare({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  /// Show the QR share bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String tripId,
    required String tripName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TripQrShare(
        tripId: tripId,
        tripName: tripName,
      ),
    );
  }

  @override
  ConsumerState<TripQrShare> createState() => _TripQrShareState();
}

class _TripQrShareState extends ConsumerState<TripQrShare> {
  String? _inviteCode;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer the invite code generation to after the build phase
    // to avoid "modifying provider while building" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateInviteCode();
    });
  }

  Future<void> _generateInviteCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Generate a 7-day invite code for QR sharing
      final invite = await ref.read(inviteControllerProvider.notifier).generateInvite(
            tripId: widget.tripId,
            email: 'qr-share@travelcrew.app', // Placeholder for QR shares
            expiresInDays: 7,
          );

      if (invite != null && mounted) {
        setState(() {
          _inviteCode = invite.inviteCode;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _error = 'Failed to generate invite code';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  String get _inviteLink => 'https://travelcrew.app/invite/$_inviteCode';

  Future<void> _copyLink() async {
    if (_inviteCode == null) return;

    await Clipboard.setData(ClipboardData(text: _inviteLink));

    if (mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Invite link copied!'),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareLink() async {
    if (_inviteCode == null) return;

    final message = '''
Join my trip "${widget.tripName}" on TravelCrew!

$_inviteLink

Or use code: $_inviteCode
''';

    try {
      await Share.share(
        message,
        subject: 'Join ${widget.tripName} on TravelCrew',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXl),
          topRight: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.qr_code_2,
                      color: context.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share via QR Code',
                          style: context.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Scan to join ${widget.tripName}',
                          style: context.bodySmall.copyWith(
                            color: context.textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // QR Code
              if (_isLoading)
                const SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: context.bodyMedium.copyWith(color: AppTheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _generateInviteCode,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _inviteLink,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: context.primaryColor,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: context.primaryColor,
                    ),
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),

              const SizedBox(height: AppTheme.spacingLg),

              // Invite code display
              if (_inviteCode != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                    vertical: AppTheme.spacingMd,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Code: ',
                        style: context.bodyMedium.copyWith(
                          color: context.textColor.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        _inviteCode!,
                        style: context.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: context.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Valid for 7 days',
                  style: context.bodySmall.copyWith(
                    color: context.textColor.withValues(alpha: 0.5),
                  ),
                ),
              ],

              const SizedBox(height: AppTheme.spacingXl),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _inviteCode != null ? _copyLink : null,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Link'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _inviteCode != null ? _shareLink : null,
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
        ),
      ),
    );
  }
}
