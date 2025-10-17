import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/utils/validators.dart';
import '../providers/invite_providers.dart';

/// Premium invite generation bottom sheet
///
/// Features:
/// - Email/phone input with validation
/// - Expiry date selection
/// - Invite code display
/// - Share functionality
/// - Copy to clipboard
/// - Premium animations
class InviteBottomSheet extends ConsumerStatefulWidget {
  final String tripId;
  final String tripName;

  const InviteBottomSheet({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  /// Show the invite bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String tripId,
    required String tripName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InviteBottomSheet(
        tripId: tripId,
        tripName: tripName,
      ),
    );
  }

  @override
  ConsumerState<InviteBottomSheet> createState() => _InviteBottomSheetState();
}

class _InviteBottomSheetState extends ConsumerState<InviteBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  int _expiryDays = 7;
  String? _generatedInviteCode;
  bool _inviteGenerated = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _generateInvite() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    final invite = await ref.read(inviteControllerProvider.notifier).generateInvite(
          tripId: widget.tripId,
          email: email,
          phoneNumber: phone.isEmpty ? null : phone,
          expiresInDays: _expiryDays,
        );

    if (invite != null && mounted) {
      setState(() {
        _generatedInviteCode = invite.inviteCode;
        _inviteGenerated = true;
      });
    }
  }

  Future<void> _shareInvite() async {
    if (_generatedInviteCode == null) return;

    final inviteLink = 'https://travelcrew.app/invite/$_generatedInviteCode';

    // Format message to make link auto-detectable by email/messaging apps
    // Most email clients will automatically make URLs clickable
    final message = '''
🌍 You're invited to join "${widget.tripName}"!

Join using this link:
$inviteLink

Or use invite code: $_generatedInviteCode

⏰ Expires in $_expiryDays days

Let's make it an adventure! 🎉
''';

    try {
      // Share via native share sheet
      // Email apps will auto-detect and make the URL clickable
      await Share.share(
        message,
        subject: 'Join my trip: ${widget.tripName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing invite: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard() async {
    if (_generatedInviteCode == null) return;

    await Clipboard.setData(ClipboardData(text: _generatedInviteCode!));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: AppTheme.spacingMd),
              Text('Invite code copied to clipboard!'),
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

  @override
  Widget build(BuildContext context) {
    final inviteState = ref.watch(inviteControllerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusXl),
              topRight: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AppTheme.spacingMd),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header with animation
                        FadeSlideAnimation(
                          delay: Duration.zero,
                          child: _buildHeader(),
                        ),
                        const SizedBox(height: AppTheme.spacingXl),

                        if (!_inviteGenerated) ...[
                          // Email Field
                          FadeSlideAnimation(
                            delay: AppAnimations.staggerSmall,
                            child: _buildEmailField(),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),

                          // Phone Field (Optional)
                          FadeSlideAnimation(
                            delay: AppAnimations.staggerSmall * 2,
                            child: _buildPhoneField(),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),

                          // Expiry Selection
                          FadeSlideAnimation(
                            delay: AppAnimations.staggerSmall * 3,
                            child: _buildExpirySelection(),
                          ),
                          const SizedBox(height: AppTheme.spacingXl),

                          // Generate Button
                          FadeSlideAnimation(
                            delay: AppAnimations.staggerSmall * 4,
                            child: _buildGenerateButton(inviteState),
                          ),
                        ] else ...[
                          // Invite Generated Success
                          FadeSlideAnimation(
                            delay: Duration.zero,
                            child: _buildInviteCodeCard(),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),

                          // Action Buttons
                          FadeSlideAnimation(
                            delay: AppAnimations.staggerSmall,
                            child: _buildActionButtons(),
                          ),
                        ],

                        // Error Display
                        if (inviteState.error != null) ...[
                          const SizedBox(height: AppTheme.spacingMd),
                          FadeInAnimation(
                            child: _buildErrorCard(inviteState.error!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowTeal,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            _inviteGenerated ? 'Invite Created!' : 'Invite Crew Member',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            _inviteGenerated
                ? 'Share this invite to add member to ${widget.tripName}'
                : 'Send an invitation to join ${widget.tripName}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: 'Email Address',
          prefixIcon: const Icon(Icons.email, color: AppTheme.primaryTeal),
          hintText: 'friend@example.com',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(AppTheme.spacingMd),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter an email address';
          }
          if (!Validators.isValidEmail(value.trim())) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: 'Phone Number (Optional)',
          prefixIcon: const Icon(Icons.phone, color: AppTheme.neutral600),
          hintText: '+1 234 567 8900',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(AppTheme.spacingMd),
        ),
      ),
    );
  }

  Widget _buildExpirySelection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowMd,
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: AppTheme.accentCoral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.access_time,
                  size: 20,
                  color: AppTheme.accentCoral,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                'Invite Expires In',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Wrap(
            spacing: AppTheme.spacingMd,
            runSpacing: AppTheme.spacingMd,
            children: [
              _buildExpiryChip(1, '1 day'),
              _buildExpiryChip(3, '3 days'),
              _buildExpiryChip(7, '7 days'),
              _buildExpiryChip(14, '14 days'),
              _buildExpiryChip(30, '30 days'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryChip(int days, String label) {
    final isSelected = _expiryDays == days;
    return AnimatedScaleButton(
      onTap: () => setState(() => _expiryDays = days),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingMd,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.neutral100,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          boxShadow: isSelected ? AppTheme.shadowTeal : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected ? Colors.white : AppTheme.neutral700,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton(InviteState inviteState) {
    return AnimatedScaleButton(
      onTap: inviteState.isLoading ? null : _generateInvite,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.shadowTeal,
        ),
        child: ElevatedButton(
          onPressed: null, // Handled by AnimatedScaleButton
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spacingMd,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
          child: inviteState.isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send, color: Colors.white),
                    const SizedBox(width: AppTheme.spacingMd),
                    Text(
                      'Generate Invite',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInviteCodeCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            size: 48,
            color: AppTheme.success,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Invite Code',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutral600,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Text(
              _generatedInviteCode ?? '',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryTeal,
                    letterSpacing: 4,
                  ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Valid for $_expiryDays ${_expiryDays == 1 ? 'day' : 'days'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.neutral600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        AnimatedScaleButton(
          onTap: _shareInvite,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.sunsetGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.shadowCoral,
            ),
            child: ElevatedButton.icon(
              onPressed: null, // Handled by AnimatedScaleButton
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingMd,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text(
                'Share Invite',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        AnimatedScaleButton(
          onTap: _copyToClipboard,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryTeal, width: 2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: ElevatedButton.icon(
              onPressed: null, // Handled by AnimatedScaleButton
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingMd,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              icon: const Icon(Icons.copy, color: AppTheme.primaryTeal),
              label: const Text(
                'Copy Code',
                style: TextStyle(
                  color: AppTheme.primaryTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        TextButton(
          onPressed: () {
            setState(() {
              _inviteGenerated = false;
              _generatedInviteCode = null;
              _emailController.clear();
              _phoneController.clear();
            });
          },
          child: const Text('Send Another Invite'),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
