import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../core/widgets/premium_header.dart';
import '../../../../core/widgets/gradient_page_backgrounds.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../providers/invite_providers.dart';

/// Accept Invite Page with premium animations
///
/// Features:
/// - Display trip information from invite
/// - Accept/Decline actions
/// - Premium animations
/// - Error handling
/// - Loading states
class AcceptInvitePage extends ConsumerStatefulWidget {
  final String inviteCode;

  const AcceptInvitePage({
    super.key,
    required this.inviteCode,
  });

  @override
  ConsumerState<AcceptInvitePage> createState() => _AcceptInvitePageState();
}

class _AcceptInvitePageState extends ConsumerState<AcceptInvitePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isAccepting = false;
  bool _isDeclining = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _acceptInvite(String userId, String tripId) async {
    setState(() => _isAccepting = true);

    final success = await ref.read(inviteControllerProvider.notifier).acceptInvite(
          inviteCode: widget.inviteCode,
          userId: userId,
        );

    if (mounted) {
      setState(() => _isAccepting = false);

      if (success) {
        // Refresh trips list
        ref.invalidate(userTripsProvider);

        // Show success and navigate to trip
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: AppTheme.spacingMd),
                Text('Successfully joined the trip!'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );

        // Navigate to trip detail
        context.go('/trips/$tripId');
      }
    }
  }

  Future<void> _declineInvite() async {
    setState(() => _isDeclining = true);

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isDeclining = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invite declined'),
          backgroundColor: AppTheme.neutral600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );

      // Navigate to home
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final inviteAsync = ref.watch(inviteByCodeProvider(widget.inviteCode));
    final currentUser = ref.watch(currentUserProvider).value;
    final themeData = context.appThemeData;

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: MeshGradientBackground(
        intensity: 0.5,
        child: inviteAsync.when(
          data: (invite) {
          if (invite == null) {
            return _buildInvalidInvite(themeData);
          }

          // Check if invite is expired
          if (invite.isExpired) {
            return _buildExpiredInvite(themeData);
          }

          // Check if invite is not pending
          if (invite.status != 'pending') {
            return _buildUsedInvite(invite.status, themeData);
          }

            return _buildInviteContent(invite, currentUser?.id ?? '', themeData);
          },
          loading: () => _buildLoading(themeData),
          error: (error, stack) => _buildError(error.toString(), themeData),
        ),
      ),
    );
  }

  Widget _buildInviteContent(dynamic invite, String userId, dynamic themeData) {
    final inviteState = ref.watch(inviteControllerProvider);
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: themeData.primaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Trip Invitation',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black38,
                      offset: Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero Image
                  DestinationImage(
                    tripName: 'Adventure',
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    showOverlay: true,
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black54,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Card
                  FadeSlideAnimation(
                    delay: Duration.zero,
                    child: _buildWelcomeCard(invite, themeData),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),

                  // Invite Details
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall,
                    child: _buildInviteDetails(invite, themeData),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),

                  // Action Buttons
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * 2,
                    child: _buildActionButtons(userId, invite.tripId, themeData),
                  ),

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
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(dynamic invite, dynamic themeData) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: AppTheme.sunsetGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowCoral,
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
              Icons.celebration,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            "You're Invited!",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Join your friends on an amazing adventure',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInviteDetails(dynamic invite, dynamic themeData) {
    final daysUntilExpiry = invite.expiresAt.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: context.primaryLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: context.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                'Invite Details',
                style: context.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.textColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Invite Code
          _buildDetailRow(
            icon: Icons.qr_code,
            iconColor: themeData.primaryColor,
            iconBg: themeData.primaryColor.withValues(alpha: 0.1),
            label: 'Invite Code',
            value: invite.inviteCode,
          ),

          const Divider(height: AppTheme.spacingLg),

          // Invited By
          _buildDetailRow(
            icon: Icons.person,
            iconColor: context.accentColor,
            iconBg: context.accentColor.withValues(alpha: 0.1),
            label: 'Sent By',
            value: invite.email,
          ),

          const Divider(height: AppTheme.spacingLg),

          // Expires In
          _buildDetailRow(
            icon: Icons.schedule,
            iconColor: daysUntilExpiry <= 1 ? AppTheme.error : context.accentColor,
            iconBg: daysUntilExpiry <= 1
                ? AppTheme.error.withValues(alpha: 0.1)
                : context.accentColor.withValues(alpha: 0.1),
            label: 'Expires In',
            value: daysUntilExpiry <= 0
                ? 'Expires today!'
                : '$daysUntilExpiry ${daysUntilExpiry == 1 ? 'day' : 'days'}',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(icon, size: 24, color: iconColor),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.neutral600,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.neutral900,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String userId, String tripId, dynamic themeData) {
    return Column(
      children: [
        // Accept Button
        GlossyButton(
          label: 'Accept Invitation',
          icon: Icons.check_circle,
          onPressed: (_isAccepting || _isDeclining) ? null : () => _acceptInvite(userId, tripId),
          isLoading: _isAccepting,
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Decline Button
        OutlinedButton.icon(
          onPressed: (_isAccepting || _isDeclining) ? null : _declineInvite,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingMd,
            ),
            side: const BorderSide(color: AppTheme.neutral300, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
          icon: _isDeclining
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.neutral600,
                  ),
                )
              : const Icon(Icons.close, color: AppTheme.neutral600),
          label: Text(
            _isDeclining ? 'Declining...' : 'Decline',
            style: const TextStyle(
              color: AppTheme.neutral700,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading(dynamic themeData) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleAnimation(
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                gradient: themeData.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: themeData.primaryShadow,
              ),
              child: const Icon(
                Icons.mail,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Loading invitation...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.neutral600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidInvite(dynamic themeData) {
    return _buildMessageScreen(
      icon: Icons.error_outline,
      iconColor: AppTheme.error,
      title: 'Invalid Invite',
      message: 'This invitation code is not valid or has been removed.',
      actionLabel: 'Go Home',
      onAction: () => context.go('/'),
      themeData: themeData,
    );
  }

  Widget _buildExpiredInvite(dynamic themeData) {
    return _buildMessageScreen(
      icon: Icons.event_busy,
      iconColor: AppTheme.warning,
      title: 'Invite Expired',
      message:
          'This invitation has expired. Please ask for a new invitation link.',
      actionLabel: 'Go Home',
      onAction: () => context.go('/'),
      themeData: themeData,
    );
  }

  Widget _buildUsedInvite(String status, dynamic themeData) {
    return _buildMessageScreen(
      icon: status == 'accepted' ? Icons.check_circle : Icons.cancel,
      iconColor: status == 'accepted' ? AppTheme.success : AppTheme.error,
      title: status == 'accepted' ? 'Already Accepted' : 'Invite Declined',
      message: status == 'accepted'
          ? 'This invitation has already been accepted.'
          : 'This invitation was declined.',
      actionLabel: 'Go Home',
      onAction: () => context.go('/'),
      themeData: themeData,
    );
  }

  Widget _buildError(String error, dynamic themeData) {
    return _buildMessageScreen(
      icon: Icons.error_outline,
      iconColor: AppTheme.error,
      title: 'Error',
      message: error,
      actionLabel: 'Try Again',
      onAction: () => ref.invalidate(inviteByCodeProvider(widget.inviteCode)),
      themeData: themeData,
    );
  }

  Widget _buildMessageScreen({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    required dynamic themeData,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleAnimation(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            FadeSlideAnimation(
              delay: AppAnimations.staggerSmall,
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.neutral900,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            FadeSlideAnimation(
              delay: AppAnimations.staggerSmall * 2,
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.neutral600,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            FadeSlideAnimation(
              delay: AppAnimations.staggerSmall * 3,
              child: GlossyButton(
                label: actionLabel,
                icon: Icons.arrow_forward,
                onPressed: onAction,
              ),
            ),
          ],
        ),
      ),
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
