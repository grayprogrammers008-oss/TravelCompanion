import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/utils/trip_permissions.dart';
import '../../../../core/services/share_service.dart';
import '../../../../shared/models/trip_model.dart';
import '../providers/trip_providers.dart';
import '../../../trip_invites/presentation/widgets/invite_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../expenses/presentation/widgets/quick_expense_sheet.dart';
import '../../../checklists/presentation/providers/checklist_providers.dart';
import '../../../messaging/presentation/providers/conversation_providers.dart';
import '../widgets/trip_qr_share.dart';

class TripDetailPage extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailPage({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends ConsumerState<TripDetailPage> {
  // Member management state (for bottom sheet)
  final TextEditingController _memberSearchController = TextEditingController();

  @override
  void dispose() {
    _memberSearchController.dispose();
    super.dispose();
  }

  /// Navigate directly to the default "All Members" group chat
  /// Uses fast getDefaultGroupId method to avoid loading full conversation details
  Future<void> _openDefaultGroupChat() async {
    final currentUserId = ref.read(authStateProvider).value ?? '';

    try {
      final repository = ref.read(conversationRepositoryProvider);
      // Use fast method that only fetches the ID (no heavy RPC call)
      final result = await repository.getDefaultGroupId(tripId: widget.tripId);

      result.fold(
        onSuccess: (conversationId) {
          if (conversationId != null && mounted) {
            context.push(
              '/trips/${widget.tripId}/conversations/$conversationId?userId=$currentUserId',
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No group chat found for this trip'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        onFailure: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to open chat: $error'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripProvider(widget.tripId));
    final themeData = context.appThemeData;
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: tripAsync.when(
        data: (trip) => _buildV3Layout(context, trip, themeData, screenHeight, safeAreaTop, safeAreaBottom),
        loading: () => const Center(
          child: AppLoadingIndicator(message: 'Loading trip details...'),
        ),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  /// V3.0: Zero-scroll "Hub" layout - everything visible at a glance
  /// Inspired by: Apple Watch complications, Uber home, Linear dashboard
  Widget _buildV3Layout(
    BuildContext context,
    dynamic trip,
    dynamic themeData,
    double screenHeight,
    double safeAreaTop,
    double safeAreaBottom,
  ) {
    final heroHeight = screenHeight * 0.28; // 28% for hero image

    return Stack(
      children: [
        // Full-screen background with hero image at top
        Column(
          children: [
            // Hero section with image, title, status
            _buildV3HeroSection(context, trip, themeData, heroHeight, safeAreaTop),

            // Main content area - fills remaining space
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: _buildV3ContentArea(context, trip, themeData, safeAreaBottom),
                ),
              ),
            ),
          ],
        ),

        // Floating back button
        Positioned(
          top: safeAreaTop + 8,
          left: 12,
          child: _buildFloatingBackButton(context),
        ),

        // Floating action buttons (edit, more)
        Positioned(
          top: safeAreaTop + 8,
          right: 12,
          child: _buildFloatingActions(context, trip),
        ),
      ],
    );
  }

  Widget _buildFloatingBackButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
        onPressed: () {
          HapticFeedback.lightImpact();
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/trips');
          }
        },
      ),
    );
  }

  Widget _buildFloatingActions(BuildContext context, dynamic trip) {
    final canEdit = TripPermissions.canEditTrip(
      currentUserId: ref.watch(authStateProvider).value,
      tripWithMembers: trip,
    );

    return Row(
      children: [
        if (canEdit)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/trips/${widget.tripId}/edit');
              },
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildCompactPopupMenu(context, trip),
        ),
      ],
    );
  }

  /// V3.0: Compact hero with all key info overlaid
  Widget _buildV3HeroSection(
    BuildContext context,
    dynamic trip,
    dynamic themeData,
    double height,
    double safeAreaTop,
  ) {
    return SizedBox(
      height: height + safeAreaTop,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          DestinationImage(
            tripName: trip.trip.destination ?? trip.trip.name,
            height: height + safeAreaTop,
            width: double.infinity,
            fit: BoxFit.cover,
            showOverlay: false,
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.3, 0.7, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          // Content overlay at bottom
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip name
                Text(
                  trip.trip.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    shadows: [
                      Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 8),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Inline info row: destination • dates • status
                Row(
                  children: [
                    if (trip.trip.destination != null) ...[
                      const Icon(Icons.location_on, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          trip.trip.destination!,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (trip.trip.startDate != null) ...[
                      const Icon(Icons.calendar_today, color: Colors.white70, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateRange(trip.trip.startDate, trip.trip.endDate),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                    const Spacer(),
                    _buildCompactStatusBadge(context, trip),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return '';
    final startStr = DateFormat('MMM d').format(start);
    if (end == null) return startStr;
    final endStr = DateFormat('MMM d').format(end);
    return '$startStr - $endStr';
  }

  Widget _buildCompactStatusBadge(BuildContext context, dynamic trip) {
    final now = DateTime.now();
    final startDate = trip.trip.startDate;
    final endDate = trip.trip.endDate;

    String statusText;
    Color statusColor;

    if (trip.trip.isCompleted) {
      statusText = '✓ Done';
      statusColor = AppTheme.success;
    } else if (startDate != null && now.isBefore(startDate)) {
      final daysUntil = startDate.difference(now).inDays;
      statusText = daysUntil == 0 ? 'Today!' : '${daysUntil}d';
      statusColor = AppTheme.info;
    } else if (startDate != null && endDate != null && now.isAfter(startDate) && now.isBefore(endDate)) {
      final currentDay = now.difference(startDate).inDays + 1;
      statusText = 'Day $currentDay';
      statusColor = AppTheme.success;
    } else {
      statusText = 'Upcoming';
      statusColor = AppTheme.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// V3.1: "Info First, Actions Second" - prioritize trip information
  Widget _buildV3ContentArea(
    BuildContext context,
    dynamic trip,
    dynamic themeData,
    double safeAreaBottom,
  ) {
    final expensesAsync = ref.watch(tripExpensesProvider(widget.tripId));
    final checklistsAsync = ref.watch(tripChecklistsProvider(widget.tripId));
    final currentUserId = ref.watch(currentUserProvider).value?.id ?? '';
    final unreadCountAsync = ref.watch(tripUnreadCountProvider(
      TripConversationsParams(tripId: widget.tripId, userId: currentUserId),
    ));

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, safeAreaBottom + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ABOUT SECTION - Trip description and key info
          _buildAboutSection(context, trip, themeData),
          const SizedBox(height: 20),

          // 2. CREW SECTION - Member avatars row (tap to see all)
          _buildCrewSection(context, trip, themeData),
          const SizedBox(height: 20),

          // 3. QUICK ACTIONS - Compact grid of action tiles
          _buildQuickActionsSection(
            context,
            trip,
            themeData,
            expensesAsync,
            checklistsAsync,
            unreadCountAsync,
          ),
        ],
      ),
    );
  }

  /// About section with description and info chips
  Widget _buildAboutSection(BuildContext context, dynamic trip, dynamic themeData) {
    final description = trip.trip.description as String?;
    final isPublic = trip.trip.isPublic ?? false;
    final budget = trip.trip.budget as double?;
    final currency = trip.trip.currency ?? 'INR';
    final startDate = trip.trip.startDate as DateTime?;
    final endDate = trip.trip.endDate as DateTime?;
    final memberCount = (trip.members as List).length;

    // Calculate duration
    int? durationDays;
    if (startDate != null && endDate != null) {
      durationDays = endDate.difference(startDate).inDays + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppTheme.neutral500),
              const SizedBox(width: 8),
              Text(
                'About',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          if (description != null && description.isNotEmpty) ...[
            Text(
              description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Text(
              'No description added yet.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppTheme.neutral400,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Info chips row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Public/Private chip
              _buildInfoChip(
                icon: isPublic ? Icons.public : Icons.lock,
                label: isPublic ? 'Public' : 'Private',
                color: isPublic ? AppTheme.info : AppTheme.neutral500,
              ),
              // Budget chip
              if (budget != null && budget > 0)
                _buildInfoChip(
                  icon: Icons.account_balance_wallet,
                  label: '${_getCurrencySymbol(currency)}${_formatAmount(budget)}',
                  color: const Color(0xFF4CAF93),
                )
              else
                _buildInfoChip(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'No budget',
                  color: AppTheme.neutral400,
                ),
              // Duration chip
              if (durationDays != null)
                _buildInfoChip(
                  icon: Icons.schedule,
                  label: '$durationDays ${durationDays == 1 ? 'day' : 'days'}',
                  color: const Color(0xFFFFB74D),
                ),
              // Travelers chip
              _buildInfoChip(
                icon: Icons.group,
                label: '$memberCount ${memberCount == 1 ? 'traveler' : 'travelers'}',
                color: const Color(0xFF7E57C2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Info chip widget for displaying trip details
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Get currency symbol from currency code
  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }

  /// Crew section with member avatars
  Widget _buildCrewSection(BuildContext context, dynamic trip, dynamic themeData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.people_outline, size: 18, color: AppTheme.neutral500),
              const SizedBox(width: 8),
              Text(
                'Crew',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        _buildV3MembersRow(context, trip, themeData),
      ],
    );
  }

  /// Quick Actions section with 2x3 compact grid
  Widget _buildQuickActionsSection(
    BuildContext context,
    dynamic trip,
    dynamic themeData,
    AsyncValue<List<dynamic>> expensesAsync,
    AsyncValue<List<dynamic>> checklistsAsync,
    AsyncValue<int> unreadCountAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded, size: 18, color: AppTheme.neutral500),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // 2x3 Compact grid of action tiles
        _buildCompactActionGrid(
          context,
          trip,
          themeData,
          expensesAsync,
          checklistsAsync,
          unreadCountAsync,
        ),
      ],
    );
  }

  /// Compact 2x3 grid of action tiles
  Widget _buildCompactActionGrid(
    BuildContext context,
    dynamic trip,
    dynamic themeData,
    AsyncValue<List<dynamic>> expensesAsync,
    AsyncValue<List<dynamic>> checklistsAsync,
    AsyncValue<int> unreadCountAsync,
  ) {
    final isCompleted = trip.trip.isCompleted;
    final totalExpenses = expensesAsync.when(
      data: (expenses) => expenses.fold<double>(0, (sum, e) => sum + e.expense.amount),
      loading: () => 0.0,
      error: (_, _) => 0.0,
    );
    final checklistCount = checklistsAsync.when(
      data: (c) => c.length,
      loading: () => 0,
      error: (_, _) => 0,
    );
    final unreadCount = unreadCountAsync.value ?? 0;

    return Column(
      children: [
        // Row 1: Expenses, Itinerary
        Row(
          children: [
            Expanded(
              child: _buildCompactTile(
                context,
                icon: Icons.payments_rounded,
                title: 'Expenses',
                value: '₹${_formatAmount(totalExpenses)}',
                color: const Color(0xFF4CAF93),
                onTap: () => context.push('/trips/${widget.tripId}/expenses'),
                onLongPress: isCompleted ? null : () => showQuickExpenseSheet(
                  context: context,
                  tripId: widget.tripId,
                  trip: trip,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactTile(
                context,
                icon: Icons.map_rounded,
                title: 'Itinerary',
                value: _getTripDayInfo(trip),
                color: const Color(0xFFFFB74D),
                onTap: () => context.push('/trips/${widget.tripId}/itinerary'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Chat, Checklists
        Row(
          children: [
            Expanded(
              child: _buildCompactTile(
                context,
                icon: Icons.chat_bubble_rounded,
                title: 'Chat',
                value: unreadCount > 0 ? '$unreadCount new' : 'Group',
                color: const Color(0xFF7E57C2),
                badge: unreadCount > 0 ? unreadCount : null,
                onTap: () => _openDefaultGroupChat(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactTile(
                context,
                icon: Icons.checklist_rounded,
                title: 'Checklists',
                value: '$checklistCount ${checklistCount == 1 ? 'list' : 'lists'}',
                color: const Color(0xFF4DB6AC),
                onTap: () => context.push('/trips/${widget.tripId}/checklists'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 3: SOS/Rating, Share
        Row(
          children: [
            Expanded(
              child: !isCompleted
                  ? _buildCompactTile(
                      context,
                      icon: Icons.emergency_rounded,
                      title: 'SOS',
                      value: 'Emergency',
                      color: const Color(0xFFE57373),
                      onTap: () => context.push('/emergency?tripId=${widget.tripId}'),
                    )
                  : _buildCompactTile(
                      context,
                      icon: Icons.star_rounded,
                      title: 'Rating',
                      value: trip.trip.rating != null ? '${trip.trip.rating}★' : 'Rate',
                      color: const Color(0xFFFFD54F),
                      onTap: () => _showCompleteDialog(context, ref),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactTile(
                context,
                icon: Icons.share_rounded,
                title: 'Share',
                value: 'Invite',
                color: const Color(0xFF64B5F6),
                onTap: () => TripQrShare.show(
                  context: context,
                  tripId: widget.tripId,
                  tripName: trip.trip.name,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Compact action tile for 2x3 grid
  Widget _buildCompactTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    int? badge,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      onLongPress: onLongPress != null
          ? () {
              HapticFeedback.heavyImpact();
              onLongPress();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon row with optional badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 2),
            // Value
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// V3.0: Compact members row with invite action
  Widget _buildV3MembersRow(BuildContext context, dynamic trip, dynamic themeData) {
    final members = trip.members as List<TripMemberModel>;
    const maxVisible = 5;
    final visibleMembers = members.take(maxVisible).toList();
    final remainingCount = members.length - maxVisible;
    final currentUserId = ref.watch(authStateProvider).value;
    final canInvite = TripPermissions.canEditTrip(
      currentUserId: currentUserId,
      tripWithMembers: trip,
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showMembersBottomSheet(context, trip, themeData);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Overlapping avatars
            SizedBox(
              width: visibleMembers.length == 1 ? 32.0 : (visibleMembers.length * 22.0) + 10.0,
              height: 32,
              child: Stack(
                children: List.generate(visibleMembers.length, (index) {
                  final member = visibleMembers[index];
                  return Positioned(
                    left: index * 22.0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(
                        child: UserAvatarWidget(
                          imageUrl: member.avatarUrl,
                          userName: member.fullName ?? member.email,
                          size: 28,
                          showBorder: false,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
            // Member count text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${members.length} ${members.length == 1 ? 'Traveler' : 'Travelers'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (remainingCount > 0)
                    Text(
                      '+$remainingCount more',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.neutral500,
                      ),
                    ),
                ],
              ),
            ),
            // Invite button
            if (canInvite)
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  InviteBottomSheet.show(
                    context: context,
                    tripId: widget.tripId,
                    tripName: trip.trip.name,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: themeData.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Invite',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 8),
            // Chevron to indicate tappable
            Icon(Icons.chevron_right, size: 20, color: AppTheme.neutral400),
          ],
        ),
      ),
    );
  }

  String _getTripDayInfo(dynamic trip) {
    if (trip.trip.startDate == null || trip.trip.endDate == null) return 'Plan';
    final now = DateTime.now();
    final totalDays = trip.trip.endDate!.difference(trip.trip.startDate!).inDays + 1;
    if (now.isBefore(trip.trip.startDate!)) {
      return '${totalDays}d trip';
    } else if (now.isAfter(trip.trip.endDate!)) {
      return '${totalDays}d done';
    } else {
      final currentDay = now.difference(trip.trip.startDate!).inDays + 1;
      return 'Day $currentDay';
    }
  }

  /// Format amount for display (e.g., 1.5K, 2.3L)
  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// Show members in bottom sheet
  void _showMembersBottomSheet(BuildContext context, dynamic trip, dynamic themeData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Trip Crew',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${trip.members.length} members',
                      style: TextStyle(
                        color: AppTheme.neutral500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Members list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: trip.members.length,
                  itemBuilder: (context, index) {
                    final member = trip.members[index] as TripMemberModel;
                    final isCreator = member.userId == trip.trip.createdBy;
                    return ListTile(
                      leading: UserAvatarWidget(
                        imageUrl: member.avatarUrl,
                        userName: member.fullName ?? member.email,
                        size: 44,
                        showBorder: true,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.fullName ?? member.email ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCreator) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Organizer',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        member.role == 'admin' ? 'Admin' : 'Member',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.neutral500,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: AppTheme.neutral400,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        final currentUserId = ref.read(authStateProvider).value ?? '';
                        if (member.userId == currentUserId) {
                          context.push('/profile');
                        } else {
                          context.push(
                            '/profile'
                            '?userId=${Uri.encodeComponent(member.userId)}'
                            '&fullName=${Uri.encodeComponent(member.fullName ?? '')}'
                            '&email=${Uri.encodeComponent(member.email ?? '')}'
                            '&role=${Uri.encodeComponent(member.role)}',
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPopupMenu(BuildContext context, dynamic trip) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => [
        _buildPopupItem('share_whatsapp', Icons.chat, 'Share via WhatsApp', const Color(0xFF25D366)),
        _buildPopupItem('share_general', Icons.share, 'Share via...', AppTheme.info),
        _buildPopupItem('share_qr', Icons.qr_code_2, 'Show QR Code', Colors.purple),
        const PopupMenuDivider(),
        if (!trip.trip.isCompleted)
          _buildPopupItem('complete', Icons.check_circle, 'Mark Completed', AppTheme.success)
        else
          _buildPopupItem('reopen', Icons.refresh, 'Reopen Trip', AppTheme.info),
        if (TripPermissions.canDeleteTrip(
          currentUserId: ref.watch(authStateProvider).value,
          tripWithMembers: trip,
        ))
          _buildPopupItem('delete', Icons.delete, 'Delete Trip', AppTheme.error),
      ],
      onSelected: (value) => _handleMenuAction(context, value, trip),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, dynamic trip) async {
    switch (action) {
      case 'share_whatsapp':
        final text = ShareService.formatTrip(trip.trip);
        await ShareService.shareToWhatsApp(text);
        break;
      case 'share_general':
        final text = ShareService.formatTrip(trip.trip);
        await ShareService.shareGeneral(text, subject: 'Trip: ${trip.trip.name}');
        break;
      case 'share_qr':
        TripQrShare.show(context: context, tripId: widget.tripId, tripName: trip.trip.name);
        break;
      case 'complete':
        _showCompleteDialog(context, ref);
        break;
      case 'reopen':
        _showReopenDialog(context, ref);
        break;
      case 'delete':
        _showDeleteDialog(context, ref);
        break;
    }
  }

  // V2 legacy methods removed in V3.0 redesign
  // _buildTripStatusBadge, _buildHeroMemberAvatars, _buildStatsCards, etc.
  // All replaced by V3 hub layout


  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Error loading trip',
              style: context.headlineStyle.copyWith(
                color: context.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: context.bodyStyle.copyWith(
                color: context.textColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, WidgetRef ref) {
    double rating = 0.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.check_circle, color: AppTheme.success),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              const Text('Complete Trip?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mark this trip as completed and rate your experience.',
                style: context.bodyStyle,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              const Text('Rate your trip:'),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        rating = (index + 1).toDouble();
                      });
                    },
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: AppTheme.warning,
                      size: 32,
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final userId = ref.read(authStateProvider).value ?? '';
                  await ref
                      .read(tripControllerProvider.notifier)
                      .markTripAsCompleted(
                        tripId: widget.tripId,
                        userId: userId,
                        rating: rating > 0 ? rating : null,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trip marked as completed!'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Complete'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReopenDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.refresh, color: AppTheme.info),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            const Text('Reopen Trip?'),
          ],
        ),
        content: const Text('This trip will be moved back to active trips.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final userId = ref.read(authStateProvider).value ?? '';
                await ref
                    .read(tripControllerProvider.notifier)
                    .unmarkTripAsCompleted(
                      tripId: widget.tripId,
                      userId: userId,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trip reopened successfully!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Reopen'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.delete_outline, color: AppTheme.error),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            const Text('Delete Trip?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this trip? This action cannot be undone.',
          style: context.bodyStyle.copyWith(
            color: context.textColor.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(tripControllerProvider.notifier)
                    .deleteTrip(widget.tripId);
                if (context.mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Trip deleted successfully'),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
