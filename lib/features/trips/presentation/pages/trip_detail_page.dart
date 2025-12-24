import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/utils/trip_permissions.dart';
import '../../../../core/services/share_service.dart';
import '../../../../shared/models/trip_model.dart';
import '../providers/trip_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../expenses/presentation/widgets/quick_expense_sheet.dart';
import '../../../checklists/presentation/providers/checklist_providers.dart';
import '../../../checklists/domain/entities/checklist_entity.dart';
import '../../../messaging/presentation/providers/conversation_providers.dart';
import '../../../messaging/presentation/providers/messaging_providers.dart';
import '../../../messaging/domain/entities/message_entity.dart';
import '../widgets/trip_qr_share.dart';
import '../widgets/add_member_bottom_sheet.dart';
import '../widgets/copy_trip_dialog.dart';
import '../../../trip_invites/presentation/widgets/invite_bottom_sheet.dart';
import '../../../../core/services/pdf_export_service.dart';
import '../../../itinerary/presentation/providers/itinerary_providers.dart';
import '../../../itinerary/domain/entities/itinerary_entity.dart';
// TODO: Re-enable when budget tracking is fully implemented
// import '../../../budget/presentation/widgets/budget_overview_card.dart';

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
    // Slightly taller hero to accommodate stats and description
    final heroHeight = screenHeight * 0.32; // 32% for expanded info panel

    return Stack(
      children: [
        // Background - image at top, content area below
        Column(
          children: [
            // Hero section with image, stats, and description overlay
            _buildV3HeroSection(context, trip, themeData, heroHeight, safeAreaTop),

            // Main content area - fills remaining space
            Expanded(
              child: Container(
                color: context.backgroundColor,
                child: _buildV3ContentArea(context, trip, themeData, safeAreaBottom),
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

  /// Hero section with gradient info panel overlay
  /// All trip info (name, stats, description) displayed on the image
  Widget _buildV3HeroSection(
    BuildContext context,
    dynamic trip,
    dynamic themeData,
    double height,
    double safeAreaTop,
  ) {
    final startDate = trip.trip.startDate as DateTime?;
    final endDate = trip.trip.endDate as DateTime?;
    final description = trip.trip.description as String?;
    final isPublic = trip.trip.isPublic ?? false;
    final memberCount = (trip.members as List).length;
    final cost = trip.trip.cost as double?;
    final currency = trip.trip.currency ?? 'INR';

    // Calculate duration
    int? durationDays;
    if (startDate != null && endDate != null) {
      durationDays = endDate.difference(startDate).inDays + 1;
    }

    return SizedBox(
      height: height + safeAreaTop,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          DestinationImage(
            imageUrl: trip.trip.coverImageUrl,
            tripName: trip.trip.destination ?? trip.trip.name,
            height: height + safeAreaTop,
            width: double.infinity,
            fit: BoxFit.cover,
            showOverlay: false,
          ),
          // Extended gradient overlay for info panel (covers bottom 60%)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.25, 0.45, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
          // Trip info overlay at bottom - now includes stats and description
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Status badge + View Only badge + Visibility badge
                Row(
                  children: [
                    _buildCompactStatusBadge(context, trip),
                    // View Only badge for completed trips
                    if (trip.trip.isCompleted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 11,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'View Only',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    // Public/Private badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPublic ? Icons.public : Icons.lock,
                            size: 11,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPublic ? 'Public' : 'Private',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 2: Trip name
                Text(
                  trip.trip.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 4,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Row 3: Location + Dates
                Row(
                  children: [
                    if (trip.trip.destination != null) ...[
                      const Icon(Icons.location_on, size: 13, color: Colors.white70),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          trip.trip.destination!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (trip.trip.destination != null && startDate != null)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('•', style: TextStyle(color: Colors.white54)),
                      ),
                    if (startDate != null) ...[
                      const Icon(Icons.calendar_today, size: 11, color: Colors.white70),
                      const SizedBox(width: 3),
                      Text(
                        _formatDateRange(startDate, endDate),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Row 4: Stats chips (duration, travelers, budget)
                Row(
                  children: [
                    if (durationDays != null) ...[
                      _buildHeroStatChip(
                        icon: Icons.schedule,
                        label: '$durationDays ${durationDays == 1 ? 'day' : 'days'}',
                      ),
                      const SizedBox(width: 8),
                    ],
                    _buildHeroStatChip(
                      icon: Icons.group,
                      label: '$memberCount',
                    ),
                    if (cost != null && cost > 0) ...[
                      const SizedBox(width: 8),
                      _buildHeroStatChip(
                        icon: Icons.payments_outlined,
                        label: '${_getCurrencySymbol(currency)}${_formatAmount(cost)}',
                      ),
                    ],
                  ],
                ),

                // Row 5: Description preview (if exists) - tap to see full
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showFullDescription(context, trip.trip.name, description),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info icon to indicate it's tappable
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Always show chevron to indicate it's tappable
                          Padding(
                            padding: const EdgeInsets.only(top: 2, left: 4),
                            child: Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Stat chip for hero overlay (translucent white style)
  Widget _buildHeroStatChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Show full description in a bottom sheet
  void _showFullDescription(BuildContext context, String tripName, String description) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.25,
        maxChildSize: 0.7,
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: context.primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About This Trip',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            tripName,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.neutral500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppTheme.neutral500),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Description content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    final isCompleted = trip.trip.isCompleted;

    return Row(
      children: [
        // SOS Badge - only show for active trips
        if (!isCompleted)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.heavyImpact();
                  _showSOSBottomSheet(context, trip);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emergency_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
          // 1. CREW SECTION - Member avatars row (tap to see all)
          _buildCrewSection(context, trip, themeData),
          const SizedBox(height: 20),

          // 2. QUICK ACTIONS - Compact grid of action tiles
          _buildQuickActionsSection(
            context,
            trip,
            themeData,
            expensesAsync,
            checklistsAsync,
            unreadCountAsync,
          ),
          // TODO: Re-enable Budget section when budget tracking is fully implemented
          // const SizedBox(height: 20),
          // // 3. BUDGET SECTION - Budget overview with progress and categories
          // _buildBudgetSection(context, trip),
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

  // TODO: Re-enable when budget tracking is fully implemented
  // /// Budget section with overview card
  // Widget _buildBudgetSection(BuildContext context, dynamic trip) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Section header
  //       Padding(
  //         padding: const EdgeInsets.only(left: 4, bottom: 8),
  //         child: Row(
  //           children: [
  //             Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppTheme.neutral500),
  //             const SizedBox(width: 8),
  //             Text(
  //               'Budget',
  //               style: TextStyle(
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w600,
  //                 color: AppTheme.neutral500,
  //                 letterSpacing: 0.5,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       // Budget overview card
  //       BudgetOverviewCard(
  //         tripId: widget.tripId,
  //         onTap: () {
  //           // Navigate to expenses page
  //           context.push('/trips/${widget.tripId}/expenses');
  //         },
  //       ),
  //     ],
  //   );
  // }

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
              child: _buildExpensesTileWithQuickAdd(
                context,
                totalExpenses: totalExpenses,
                trip: trip,
                isCompleted: isCompleted,
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
    String? hint,
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
            // Hint text for long press action
            if (hint != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 10,
                    color: color.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: color.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Expenses tile with prominent Quick Add button
  Widget _buildExpensesTileWithQuickAdd(
    BuildContext context, {
    required double totalExpenses,
    required TripWithMembers trip,
    required bool isCompleted,
  }) {
    const color = Color(0xFF4CAF93);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/trips/${widget.tripId}/expenses');
      },
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
            // Icon row with Quick Add button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payments_rounded, color: color, size: 20),
                ),
                const Spacer(),
                // Prominent Quick Add button - only for active trips
                if (!isCompleted)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      showQuickExpenseSheet(
                        context: context,
                        tripId: widget.tripId,
                        trip: trip,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Quick',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Title
            const Text(
              'Expenses',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 2),
            // Value
            Text(
              '₹${_formatAmount(totalExpenses)}',
              style: const TextStyle(
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
    final canInvite = TripPermissions.canManageMembers(
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
            // Add member button - for existing app users
            if (canInvite)
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  AddMemberBottomSheet.show(
                    context: context,
                    tripId: widget.tripId,
                    tripName: trip.trip.name,
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: themeData.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: themeData.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_add, size: 18, color: Colors.white),
                ),
              ),
            if (canInvite) const SizedBox(width: 8),
            // Invite button - for external users via link/code
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.neutral100,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.neutral300),
                  ),
                  child: Icon(Icons.share, size: 18, color: themeData.primaryColor),
                ),
              ),
            if (canInvite) const SizedBox(width: 8),
            // Chevron to view all members
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
    final currentUserId = ref.read(authStateProvider).value;
    final canInvite = TripPermissions.canManageMembers(
      currentUserId: currentUserId,
      tripWithMembers: trip,
    );

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
              // Header with Add Member button
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
                    if (canInvite)
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          HapticFeedback.mediumImpact();
                          AddMemberBottomSheet.show(
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
                              Icon(Icons.person_add, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Add Member',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Member count subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${trip.members.length} ${trip.members.length == 1 ? 'member' : 'members'}',
                    style: TextStyle(
                      color: AppTheme.neutral500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
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

  /// Show SOS emergency bottom sheet with emergency features
  void _showSOSBottomSheet(BuildContext context, dynamic trip) {
    final destination = trip.trip.destination ?? 'Unknown';
    final members = trip.members as List<TripMemberModel>;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
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
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE53935).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emergency_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emergency SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Location: $destination',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Emergency Services Section
                    _buildSOSSection(
                      title: 'Emergency Services',
                      icon: Icons.local_hospital_rounded,
                      color: const Color(0xFFE53935),
                      children: [
                        _buildEmergencyTile(
                          icon: Icons.local_police_rounded,
                          title: 'Police',
                          subtitle: 'Emergency: 100',
                          color: const Color(0xFF1976D2),
                          onTap: () => _makeEmergencyCall('100'),
                        ),
                        _buildEmergencyTile(
                          icon: Icons.local_hospital_rounded,
                          title: 'Ambulance',
                          subtitle: 'Emergency: 108',
                          color: const Color(0xFFE53935),
                          onTap: () => _makeEmergencyCall('108'),
                        ),
                        _buildEmergencyTile(
                          icon: Icons.fire_extinguisher,
                          title: 'Fire',
                          subtitle: 'Emergency: 101',
                          color: const Color(0xFFFF6D00),
                          onTap: () => _makeEmergencyCall('101'),
                        ),
                        _buildEmergencyTile(
                          icon: Icons.support_agent_rounded,
                          title: 'Women Helpline',
                          subtitle: 'Emergency: 1091',
                          color: const Color(0xFFE91E63),
                          onTap: () => _makeEmergencyCall('1091'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Contact Co-Travelers Section
                    _buildSOSSection(
                      title: 'Contact Co-Travelers',
                      icon: Icons.groups_rounded,
                      color: const Color(0xFF7E57C2),
                      children: [
                        ...members.map((member) => _buildMemberCallTile(member)),
                        if (members.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No co-travelers in this trip',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Quick Actions Section
                    _buildSOSSection(
                      title: 'Quick Actions',
                      icon: Icons.flash_on_rounded,
                      color: const Color(0xFFFF9800),
                      children: [
                        _buildActionTile(
                          icon: Icons.broadcast_on_personal_rounded,
                          title: 'Emergency Broadcast',
                          subtitle: 'Send alert to all trip members',
                          color: const Color(0xFFE53935),
                          onTap: () {
                            Navigator.pop(context);
                            _sendEmergencyBroadcast(trip);
                          },
                        ),
                        _buildActionTile(
                          icon: Icons.location_on_rounded,
                          title: 'Share Live Location',
                          subtitle: 'Share your location with trip group',
                          color: const Color(0xFF4CAF50),
                          onTap: () {
                            Navigator.pop(context);
                            _shareLiveLocation(trip);
                          },
                        ),
                        _buildActionTile(
                          icon: Icons.navigate_next_rounded,
                          title: 'Find Nearest Hospital',
                          subtitle: 'Open maps for nearby hospitals',
                          color: const Color(0xFF2196F3),
                          onTap: () => _openNearbyHospitals(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.neutral800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.neutral50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.heavyImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.neutral500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCallTile(TripMemberModel member) {
    final currentUserId = ref.read(authStateProvider).value;
    final isCurrentUser = member.userId == currentUserId;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCurrentUser ? null : () {
          HapticFeedback.mediumImpact();
          // TODO: Implement call to member (needs phone number from profile)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calling ${member.fullName ?? 'Member'}...'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF7E57C2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              UserAvatarWidget(
                imageUrl: member.avatarUrl,
                userName: member.fullName ?? 'User',
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.fullName ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.neutral200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      member.role == 'organizer' ? 'Organizer' : member.role == 'admin' ? 'Admin' : 'Member',
                      style: TextStyle(
                        color: AppTheme.neutral500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCurrentUser)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7E57C2).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call, color: Color(0xFF7E57C2), size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.neutral500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.neutral400),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makeEmergencyCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not call $number'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _sendEmergencyBroadcast(dynamic trip) {
    _showBroadcastDialog(
      context,
      isEmergency: true,
      tripName: trip.name ?? 'Trip',
    );
  }

  /// Show broadcast message dialog
  void _showBroadcastDialog(
    BuildContext context, {
    required bool isEmergency,
    required String tripName,
  }) {
    final messageController = TextEditingController(
      text: isEmergency ? '🚨 EMERGENCY: ' : '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isEmergency ? Icons.emergency : Icons.campaign,
              color: isEmergency ? AppTheme.error : context.primaryColor,
            ),
            const SizedBox(width: 12),
            Text(isEmergency ? 'Emergency Broadcast' : 'Broadcast Message'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEmergency
                  ? 'Send an emergency alert to all trip members immediately.'
                  : 'Send a message to all trip members.',
              style: context.bodySmall.copyWith(
                color: context.textColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: isEmergency
                    ? 'Describe the emergency...'
                    : 'Enter your message...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: isEmergency
                    ? AppTheme.error.withValues(alpha: 0.05)
                    : null,
              ),
              autofocus: true,
            ),
            if (isEmergency) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppTheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will send an urgent notification to all members',
                        style: context.bodySmall.copyWith(
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final message = messageController.text.trim();
              if (message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a message'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              await _sendBroadcastMessage(message, isEmergency);
            },
            icon: Icon(isEmergency ? Icons.send : Icons.campaign),
            label: Text(isEmergency ? 'Send Emergency Alert' : 'Send Broadcast'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEmergency ? AppTheme.error : context.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Send broadcast message to the default group chat
  Future<void> _sendBroadcastMessage(String message, bool isEmergency) async {
    final currentUserId = ref.read(authStateProvider).value ?? '';

    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to send messages'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Show sending indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(isEmergency ? 'Sending emergency alert...' : 'Sending broadcast...'),
            ],
          ),
          backgroundColor: isEmergency ? AppTheme.error : context.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );

      // Send the message via the messaging use case
      final sendMessageUseCase = ref.read(sendMessageUseCaseProvider);
      final result = await sendMessageUseCase.execute(
        tripId: widget.tripId,
        senderId: currentUserId,
        message: message,
        messageType: MessageType.text,
      );

      if (result.isSuccess) {
        // Show success
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isEmergency ? Icons.check_circle : Icons.campaign,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEmergency
                          ? 'Emergency alert sent to all members!'
                          : 'Broadcast sent to all members!',
                    ),
                  ),
                ],
              ),
              backgroundColor: isEmergency ? AppTheme.error : AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate to chat so user can see the message
          _openDefaultGroupChat();
        }
      } else {
        throw Exception(result.error ?? 'Failed to send message');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send broadcast: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _shareLiveLocation(dynamic trip) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.location_on_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Live location sharing started for 1 hour')),
          ],
        ),
        backgroundColor: Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // TODO: Implement actual live location sharing
  }

  Future<void> _openNearbyHospitals() async {
    // Open Google Maps with nearby hospitals search
    final uri = Uri.parse('https://www.google.com/maps/search/hospitals+near+me');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildCompactPopupMenu(BuildContext context, dynamic trip) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => [
        _buildPopupItem('broadcast', Icons.campaign, 'Broadcast Announcement', Colors.orange),
        _buildPopupItem('export_pdf', Icons.picture_as_pdf, 'Export to PDF', Colors.red),
        const PopupMenuDivider(),
        _buildPopupItem('share_whatsapp', Icons.chat, 'Share via WhatsApp', const Color(0xFF25D366)),
        _buildPopupItem('share_general', Icons.share, 'Share via...', AppTheme.info),
        _buildPopupItem('share_qr', Icons.qr_code_2, 'Show QR Code', Colors.purple),
        const PopupMenuDivider(),
        _buildPopupItem('copy', Icons.copy, 'Copy Trip', Colors.blue),
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
      case 'broadcast':
        _showBroadcastDialog(
          context,
          isEmergency: false,
          tripName: trip.trip.name ?? 'Trip',
        );
        break;
      case 'export_pdf':
        await _exportTripToPdf(trip);
        break;
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
      case 'copy':
        await _showCopyTripDialog(trip);
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

  /// Export trip details to PDF
  Future<void> _exportTripToPdf(dynamic tripWithMembers) async {
    debugPrint('📄 _exportTripToPdf: Starting...');
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Preparing PDF...'),
            ],
          ),
          backgroundColor: context.primaryColor,
          duration: const Duration(seconds: 10),
        ),
      );

      // Fetch additional data with timeouts to prevent hanging
      debugPrint('📄 _exportTripToPdf: Fetching checklists...');
      final checklistsData = await _fetchChecklists();
      debugPrint('📄 _exportTripToPdf: Checklists fetched: ${checklistsData.length}');

      debugPrint('📄 _exportTripToPdf: Fetching itinerary...');
      var itinerary = <ItineraryItemEntity>[];
      try {
        // Use repository directly with Future (not StreamProvider which can hang)
        final repository = ref.read(itineraryRepositoryProvider);
        itinerary = await repository
            .getTripItinerary(widget.tripId)
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('📄 _exportTripToPdf: Failed to fetch itinerary: $e');
      }
      debugPrint('📄 _exportTripToPdf: Itinerary fetched: ${itinerary.length}');

      if (!mounted) {
        debugPrint('📄 _exportTripToPdf: Widget not mounted, aborting');
        return;
      }

      debugPrint('📄 _exportTripToPdf: Calling PdfExportService.exportTrip...');
      // Generate and show PDF
      await PdfExportService.exportTrip(
        context: context,
        trip: tripWithMembers.trip,
        members: tripWithMembers.members,
        checklists: checklistsData.cast<ChecklistWithItemsEntity>(),
        itinerary: itinerary,
      );
      debugPrint('📄 _exportTripToPdf: PDF export completed');

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e, stackTrace) {
      debugPrint('📄 _exportTripToPdf ERROR: $e');
      debugPrint('📄 _exportTripToPdf STACK: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  /// Fetch all checklists with their items
  Future<List<dynamic>> _fetchChecklists() async {
    try {
      final checklists = await ref.read(tripChecklistsProvider(widget.tripId).future);
      final checklistsWithItems = <dynamic>[];

      for (final checklist in checklists) {
        final withItems = await ref.read(checklistWithItemsProvider(checklist.id).future);
        checklistsWithItems.add(withItems);
      }

      return checklistsWithItems;
    } catch (e) {
      debugPrint('Failed to fetch checklists: $e');
      return [];
    }
  }

  // V2 legacy methods removed in V3.0 redesign
  // _buildTripStatusBadge, _buildHeroMemberAvatars, _buildStatsCards, etc.
  // All replaced by V3 hub layout

  /// Show copy trip dialog and navigate to new trip on success
  Future<void> _showCopyTripDialog(dynamic tripWithMembers) async {
    // Get itinerary count
    int itineraryCount = 0;
    try {
      final repository = ref.read(itineraryRepositoryProvider);
      final itinerary = await repository.getTripItinerary(widget.tripId);
      itineraryCount = itinerary.length;
    } catch (e) {
      debugPrint('Failed to get itinerary count: $e');
    }

    // Get checklist count and total items
    int checklistCount = 0;
    int checklistItemsCount = 0;
    try {
      final checklists = await ref.read(tripChecklistsProvider(widget.tripId).future);
      checklistCount = checklists.length;
      for (final checklist in checklists) {
        final withItems = await ref.read(checklistWithItemsProvider(checklist.id).future);
        checklistItemsCount += withItems.items.length;
      }
    } catch (e) {
      debugPrint('Failed to get checklist count: $e');
    }

    if (!mounted) return;

    // Show the copy dialog
    final newTripId = await CopyTripDialog.show(
      context,
      trip: tripWithMembers.trip,
      itineraryCount: itineraryCount,
      checklistCount: checklistCount,
      checklistItemsCount: checklistItemsCount,
    );

    // Navigate to new trip if copy was successful
    if (newTripId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Trip copied successfully!')),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to the new trip detail page
      context.push('/trips/$newTripId');
    }
  }

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
