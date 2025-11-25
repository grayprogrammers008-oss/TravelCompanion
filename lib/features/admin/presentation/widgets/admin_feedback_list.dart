import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Admin Feedback List Widget
/// Displays user feedback and allows admins to review and respond
class AdminFeedbackList extends ConsumerStatefulWidget {
  const AdminFeedbackList({super.key});

  @override
  ConsumerState<AdminFeedbackList> createState() => _AdminFeedbackListState();
}

class _AdminFeedbackListState extends ConsumerState<AdminFeedbackList> {
  String _selectedFilter = 'all'; // all, pending, resolved

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', Icons.list),
                const SizedBox(width: AppTheme.spacingSm),
                _buildFilterChip('Pending', 'pending', Icons.pending_outlined),
                const SizedBox(width: AppTheme.spacingSm),
                _buildFilterChip('Resolved', 'resolved', Icons.check_circle_outline),
              ],
            ),
          ),
        ),

        // Feedback list
        Expanded(
          child: _buildFeedbackList(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AppTheme.neutral700,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Text(label),
        ],
      ),
      selected: isSelected,
      selectedColor: primaryColor,
      backgroundColor: AppTheme.neutral100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.neutral700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  Widget _buildFeedbackList() {
    // TODO: Replace with actual feedback data from provider
    // For now, showing placeholder data
    final feedbackItems = _getPlaceholderFeedback();

    if (feedbackItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.feedback_outlined,
                size: 64,
                color: AppTheme.neutral400,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'No feedback yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'User feedback will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutral600,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: feedbackItems.length,
      itemBuilder: (context, index) {
        final feedback = feedbackItems[index];
        return _buildFeedbackCard(feedback);
      },
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    final isPending = feedback['status'] == 'pending';
    final statusColor = isPending ? AppTheme.warning : AppTheme.success;
    final statusIcon = isPending ? Icons.pending : Icons.check_circle;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: InkWell(
        onTap: () => _showFeedbackDetail(feedback),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with user info and status
              Row(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      feedback['userName'][0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedback['userName'],
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          _formatDate(feedback['createdAt']),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.neutral600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: AppTheme.spacingXs),
                        Text(
                          feedback['status'],
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Feedback type chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  feedback['type'],
                  style: const TextStyle(
                    color: AppTheme.info,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),

              // Feedback message
              Text(
                feedback['message'],
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Rating if available
              if (feedback['rating'] != null) ...[
                const SizedBox(height: AppTheme.spacingMd),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < feedback['rating']
                            ? Icons.star
                            : Icons.star_border,
                        size: 16,
                        color: AppTheme.warning,
                      );
                    }),
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      '${feedback['rating']}/5',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.neutral600,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackDetail(Map<String, dynamic> feedback) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFeedbackDetailSheet(feedback),
    );
  }

  Widget _buildFeedbackDetailSheet(Map<String, dynamic> feedback) {
    final isPending = feedback['status'] == 'pending';

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXl),
          topRight: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusXl),
                topRight: Radius.circular(AppTheme.radiusXl),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    feedback['userName'][0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback['userName'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        _formatDate(feedback['createdAt']),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.neutral600,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type
                  Text(
                    'Type',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.neutral600,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      feedback['type'],
                      style: const TextStyle(
                        color: AppTheme.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  // Rating if available
                  if (feedback['rating'] != null) ...[
                    Text(
                      'Rating',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.neutral600,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < feedback['rating']
                                ? Icons.star
                                : Icons.star_border,
                            size: 24,
                            color: AppTheme.warning,
                          );
                        }),
                        const SizedBox(width: AppTheme.spacingMd),
                        Text(
                          '${feedback['rating']}/5',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                  ],

                  // Message
                  Text(
                    'Feedback',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.neutral600,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    feedback['message'],
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),

          // Actions
          if (isPending)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: AppTheme.neutral50,
                border: Border(
                  top: BorderSide(color: AppTheme.neutral200),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement mark as resolved
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback marked as resolved'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Resolved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingMd,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return DateFormat('MMM dd, yyyy').format(date);
  }

  List<Map<String, dynamic>> _getPlaceholderFeedback() {
    // Placeholder data - will be replaced with actual database queries
    return [
      {
        'id': '1',
        'userName': 'John Doe',
        'userEmail': 'john@example.com',
        'type': 'Feature Request',
        'message':
            'It would be great to have a feature that allows us to share trip itineraries with friends who are not on the trip.',
        'rating': 5,
        'status': 'pending',
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'id': '2',
        'userName': 'Jane Smith',
        'userEmail': 'jane@example.com',
        'type': 'Bug Report',
        'message':
            'The app crashes when I try to add more than 10 items to my checklist. Please fix this issue.',
        'rating': 3,
        'status': 'resolved',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'id': '3',
        'userName': 'Mike Johnson',
        'userEmail': 'mike@example.com',
        'type': 'General Feedback',
        'message':
            'Love the app! The expense tracking feature is really helpful for keeping track of group expenses.',
        'rating': 5,
        'status': 'resolved',
        'createdAt': DateTime.now().subtract(const Duration(days: 3)),
      },
      {
        'id': '4',
        'userName': 'Sarah Williams',
        'userEmail': 'sarah@example.com',
        'type': 'Feature Request',
        'message':
            'Please add support for multiple currencies in the expense tracker. We often travel to different countries.',
        'rating': 4,
        'status': 'pending',
        'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
      },
    ].where((feedback) {
      if (_selectedFilter == 'all') return true;
      return feedback['status'] == _selectedFilter;
    }).toList();
  }
}
