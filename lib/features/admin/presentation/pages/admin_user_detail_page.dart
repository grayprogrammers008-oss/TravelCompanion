import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/core/widgets/destination_image.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';
import 'package:travel_crew/features/admin/presentation/providers/admin_providers.dart';

/// Admin User Detail Page
/// View and edit individual user details with admin actions
class AdminUserDetailPage extends ConsumerStatefulWidget {
  final String userId;

  const AdminUserDetailPage({super.key, required this.userId});

  @override
  ConsumerState<AdminUserDetailPage> createState() =>
      _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends ConsumerState<AdminUserDetailPage> {
  bool _isProcessing = false;

  Future<void> _suspendUser() async {
    final reason = await _showSuspendDialog();
    if (reason == null || reason.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final suspendAction = ref.read(suspendUserActionProvider);
      await suspendAction(widget.userId, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User suspended successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh user data
        ref.invalidate(adminUsersProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to suspend user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _activateUser() async {
    final confirmed = await _showConfirmDialog(
      title: 'Activate User',
      message: 'Are you sure you want to activate this user?',
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      final activateAction = ref.read(activateUserActionProvider);
      await activateAction(widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User activated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh user data
        ref.invalidate(adminUsersProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _updateUserRole(UserRole newRole) async {
    final confirmed = await _showConfirmDialog(
      title: 'Change User Role',
      message:
          'Are you sure you want to change this user\'s role to ${newRole.displayName}?',
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      final updateRoleAction = ref.read(updateUserRoleActionProvider);
      await updateRoleAction(widget.userId, newRole);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User role updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh user data
        ref.invalidate(adminUsersProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String?> _showSuspendDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for suspending this user:'),
            const SizedBox(height: AppTheme.spacingMd),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason for suspension...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Fetch all users and filter by ID
    // Note: In production, you'd want a dedicated getUserById endpoint
    final params = UserListParams(limit: 100, offset: 0); // Fetch enough users
    final usersAsync = ref.watch(adminUsersProvider(params));

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        title: const Text('User Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: usersAsync.when(
        data: (users) {
          // Find the specific user by ID
          final userIndex = users.indexWhere((u) => u.id == widget.userId);

          if (userIndex == -1) {
            return const Center(child: Text('User not found'));
          }

          final user = users[userIndex];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      children: [
                        // Avatar using UserAvatarWidget with cache busting
                        UserAvatarWidget(
                          imageUrl: user.avatarUrl,
                          userName: user.displayName,
                          size: 100,
                          showBorder: true,
                          cacheKey: '${user.id}_${user.updatedAt.millisecondsSinceEpoch}',
                        ),
                        const SizedBox(height: AppTheme.spacingLg),

                        // Name
                        Text(
                          user.displayName,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacingXs),

                        // Email
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // Badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildRoleBadge(user.role),
                            const SizedBox(width: AppTheme.spacingSm),
                            _buildStatusBadge(user.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // User Information
                _buildSectionHeader('User Information'),
                const SizedBox(height: AppTheme.spacingMd),
                Card(
                  child: Column(
                    children: [
                      _buildInfoRow('User ID', user.id),
                      const Divider(height: 1),
                      _buildInfoRow('Created', _formatDate(user.createdAt)),
                      const Divider(height: 1),
                      _buildInfoRow(
                        'Last Login',
                        _formatDate(user.lastLoginAt),
                      ),
                      const Divider(height: 1),
                      _buildInfoRow('Login Count', '${user.loginCount}'),
                      const Divider(height: 1),
                      _buildInfoRow('Activity', user.activityLevel),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Statistics
                _buildSectionHeader('Statistics'),
                const SizedBox(height: AppTheme.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Trips',
                        user.tripsCount.toString(),
                        Icons.flight_takeoff,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: _buildStatCard(
                        'Messages',
                        user.messagesCount.toString(),
                        Icons.message,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Expenses',
                        user.expensesCount.toString(),
                        Icons.receipt,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: _buildStatCard(
                        'Total Spent',
                        '\$${user.totalExpenses.toStringAsFixed(2)}',
                        Icons.attach_money,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Admin Actions
                _buildSectionHeader('Admin Actions'),
                const SizedBox(height: AppTheme.spacingMd),

                // Change Role
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Role',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Wrap(
                          spacing: AppTheme.spacingSm,
                          runSpacing: AppTheme.spacingSm,
                          children: UserRole.values.map((role) {
                            final isSelected = user.role == role;
                            final primaryColor = Theme.of(
                              context,
                            ).colorScheme.primary;

                            return ChoiceChip(
                              label: Text(role.displayName),
                              selected: isSelected,
                              selectedColor: primaryColor.withValues(
                                alpha: 0.15,
                              ),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? primaryColor
                                    : AppTheme.neutral700,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                              checkmarkColor: primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingLg,
                                vertical: AppTheme.spacingMd,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? primaryColor
                                      : AppTheme.neutral300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              onSelected: _isProcessing || isSelected
                                  ? null
                                  : (_) => _updateUserRole(role),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Suspend/Activate
                if (user.status == UserStatus.active)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _suspendUser,
                      icon: const Icon(Icons.block),
                      label: const Text('Suspend User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                      ),
                    ),
                  )
                else if (user.status == UserStatus.suspended)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _activateUser,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Activate User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                      ),
                    ),
                  ),

                if (_isProcessing) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'Failed to load user',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    Color color;
    switch (role) {
      case UserRole.superAdmin:
        color = Colors.purple;
        break;
      case UserRole.admin:
        color = Colors.blue;
        break;
      case UserRole.user:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(UserStatus status) {
    Color color;
    switch (status) {
      case UserStatus.active:
        color = Colors.green;
        break;
      case UserStatus.suspended:
        color = Colors.orange;
        break;
      case UserStatus.deleted:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}
