import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/features/admin/presentation/providers/admin_checklist_providers.dart';

/// Admin Checklist List Widget
/// Displays all checklists with search, filter, and management capabilities
class AdminChecklistList extends ConsumerStatefulWidget {
  const AdminChecklistList({super.key});

  @override
  ConsumerState<AdminChecklistList> createState() => _AdminChecklistListState();
}

class _AdminChecklistListState extends ConsumerState<AdminChecklistList> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all'; // 'all', 'completed', 'pending', 'empty'
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ChecklistListParams get _currentParams => ChecklistListParams(
        limit: 50,
        offset: _currentPage * 50,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );

  void _applyFilters() {
    setState(() {
      _currentPage = 0; // Reset to first page when filters change
    });
  }

  @override
  Widget build(BuildContext context) {
    final checklistsAsync = ref.watch(adminChecklistsProvider(_currentParams));

    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          color: Colors.white,
          child: Column(
            children: [
              // Search Field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by checklist or trip name...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                ),
                onSubmitted: (_) => _applyFilters(),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all', Icons.list),
                    const SizedBox(width: AppTheme.spacingSm),
                    _buildFilterChip('Completed', 'completed', Icons.check_circle_outline),
                    const SizedBox(width: AppTheme.spacingSm),
                    _buildFilterChip('Pending', 'pending', Icons.pending_outlined),
                    const SizedBox(width: AppTheme.spacingSm),
                    _buildFilterChip('Empty', 'empty', Icons.inbox_outlined),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Checklist List
        Expanded(
          child: checklistsAsync.when(
            data: (checklists) {
              if (checklists.isEmpty) {
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
                          Icons.checklist_outlined,
                          size: 64,
                          color: AppTheme.neutral400,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      Text(
                        'No checklists found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.neutral700,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        _searchController.text.isNotEmpty
                            ? 'Try adjusting your search'
                            : 'Checklists will appear here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.neutral600,
                            ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminChecklistsProvider);
                  await ref.read(adminChecklistsProvider(_currentParams).future);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: checklists.length,
                  itemBuilder: (context, index) {
                    final checklist = checklists[index];
                    return _buildChecklistCard(context, checklist);
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    'Error loading checklists',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                    child: Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.neutral600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(adminChecklistsProvider(_currentParams));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedStatus == value;
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
          _selectedStatus = value;
        });
        _applyFilters();
      },
    );
  }

  Widget _buildChecklistCard(BuildContext context, AdminChecklistModel checklist) {
    final createdAt = checklist.createdAt != null
        ? DateFormat('MMM dd, yyyy').format(checklist.createdAt!)
        : 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: InkWell(
        onTap: () => _showChecklistDetail(checklist),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Status Badge
              Row(
                children: [
                  // Checklist Icon
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: _getStatusColor(checklist).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      _getStatusIcon(checklist),
                      color: _getStatusColor(checklist),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),

                  // Checklist Name and Trip
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          checklist.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 14,
                              color: AppTheme.neutral600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                checklist.tripName,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.neutral600,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  _buildStatusBadge(checklist),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Progress Bar
              if (checklist.itemCount > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        child: LinearProgressIndicator(
                          value: checklist.completionPercentage / 100,
                          backgroundColor: AppTheme.neutral200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            checklist.isFullyCompleted
                                ? AppTheme.success
                                : Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Text(
                      '${checklist.completionPercentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: checklist.isFullyCompleted
                                ? AppTheme.success
                                : Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
              ],

              // Stats Row
              Row(
                children: [
                  // Items count
                  _buildStatChip(
                    icon: Icons.format_list_numbered,
                    label: '${checklist.itemCount} Items',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),

                  // Completed count
                  if (checklist.completedCount > 0)
                    _buildStatChip(
                      icon: Icons.check_circle_outline,
                      label: '${checklist.completedCount} Done',
                      color: Colors.green,
                    ),
                  if (checklist.completedCount > 0)
                    const SizedBox(width: AppTheme.spacingSm),

                  // Pending count
                  if (checklist.pendingCount > 0)
                    _buildStatChip(
                      icon: Icons.pending_outlined,
                      label: '${checklist.pendingCount} Pending',
                      color: Colors.orange,
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Footer Row
              Row(
                children: [
                  // Trip Destination
                  if (checklist.tripDestination != null) ...[
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppTheme.neutral600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        checklist.tripDestination!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.neutral600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppTheme.neutral600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Created $createdAt',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.neutral600,
                            ),
                      ),
                    ),
                  ],

                  // Action Buttons
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 20,
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () => _editChecklist(checklist),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    color: AppTheme.error,
                    onPressed: () => _confirmDeleteChecklist(checklist),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AdminChecklistModel checklist) {
    String text;
    Color color;
    IconData icon;

    if (checklist.isEmpty) {
      text = 'Empty';
      color = AppTheme.neutral500;
      icon = Icons.inbox_outlined;
    } else if (checklist.isFullyCompleted) {
      text = 'Complete';
      color = AppTheme.success;
      icon = Icons.check_circle;
    } else {
      text = 'In Progress';
      color = AppTheme.info;
      icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AdminChecklistModel checklist) {
    if (checklist.isEmpty) return AppTheme.neutral500;
    if (checklist.isFullyCompleted) return AppTheme.success;
    return AppTheme.info;
  }

  IconData _getStatusIcon(AdminChecklistModel checklist) {
    if (checklist.isEmpty) return Icons.inbox_outlined;
    if (checklist.isFullyCompleted) return Icons.check_circle;
    return Icons.checklist;
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
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

  void _showChecklistDetail(AdminChecklistModel checklist) {
    // Navigate to trip's checklists page
    context.push('/trips/${checklist.tripId}/checklists');
  }

  void _editChecklist(AdminChecklistModel checklist) {
    showDialog(
      context: context,
      builder: (context) => _EditChecklistDialog(
        checklist: checklist,
        onSave: (newName) async {
          try {
            await ref.read(adminChecklistRepositoryProvider).updateChecklist(
                  checklist.id,
                  name: newName,
                );
            if (context.mounted) {
              ref.invalidate(adminChecklistsProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Checklist renamed to "$newName"'),
                  backgroundColor: AppTheme.success,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update checklist: $e'),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmDeleteChecklist(AdminChecklistModel checklist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Checklist'),
        content: Text(
          'Are you sure you want to delete "${checklist.name}"? This will delete all ${checklist.itemCount} items in this checklist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteChecklist(checklist);
    }
  }

  Future<void> _deleteChecklist(AdminChecklistModel checklist) async {
    try {
      await ref.read(adminChecklistRepositoryProvider).deleteChecklist(checklist.id);

      if (mounted) {
        // Refresh the list
        ref.invalidate(adminChecklistsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checklist "${checklist.name}" deleted successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete checklist: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}

/// Simple Edit Checklist Dialog
class _EditChecklistDialog extends StatefulWidget {
  final AdminChecklistModel checklist;
  final Future<void> Function(String newName) onSave;

  const _EditChecklistDialog({
    required this.checklist,
    required this.onSave,
  });

  @override
  State<_EditChecklistDialog> createState() => _EditChecklistDialogState();
}

class _EditChecklistDialogState extends State<_EditChecklistDialog> {
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.checklist.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Checklist'),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Checklist Name',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        enabled: !_isLoading,
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  final newName = _nameController.text.trim();
                  if (newName.isEmpty) return;
                  if (newName == widget.checklist.name) {
                    Navigator.pop(context);
                    return;
                  }

                  setState(() => _isLoading = true);
                  await widget.onSave(newName);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
