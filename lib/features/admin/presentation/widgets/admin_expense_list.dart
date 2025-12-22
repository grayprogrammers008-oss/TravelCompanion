import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/features/admin/presentation/providers/admin_expense_providers.dart';

/// Admin Expense List Widget
/// Displays all expenses with search, filter, and management capabilities
class AdminExpenseList extends ConsumerStatefulWidget {
  const AdminExpenseList({super.key});

  @override
  ConsumerState<AdminExpenseList> createState() => _AdminExpenseListState();
}

class _AdminExpenseListState extends ConsumerState<AdminExpenseList> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String _searchQuery = '';

  // Available categories for filtering
  static const List<Map<String, dynamic>> _categories = [
    {'value': null, 'label': 'All', 'icon': Icons.all_inclusive},
    {'value': 'food', 'label': 'Food', 'icon': Icons.restaurant},
    {'value': 'transport', 'label': 'Transport', 'icon': Icons.directions_car},
    {'value': 'accommodation', 'label': 'Stay', 'icon': Icons.hotel},
    {
      'value': 'activities',
      'label': 'Activities',
      'icon': Icons.local_activity,
    },
    {'value': 'shopping', 'label': 'Shopping', 'icon': Icons.shopping_bag},
    {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ExpenseListParams get _currentParams => ExpenseListParams(
    search: _searchQuery.isNotEmpty ? _searchQuery : null,
    category: _selectedCategory,
  );

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(adminExpensesProvider(_currentParams));

    return Column(
      children: [
        // Search and Filter Section
        _buildSearchAndFilter(context),

        // Expense List
        Expanded(
          child: expensesAsync.when(
            data: (expenses) => _buildExpenseList(context, expenses),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                _buildErrorState(context, error.toString()),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search expenses...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onSubmitted: (value) {
              setState(() => _searchQuery = value.trim());
            },
          ),
          const SizedBox(height: 12),

          // Category Filter Chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['value'];

                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        size: 16,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(category['label'] as String),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected
                          ? category['value'] as String?
                          : null;
                    });
                  },
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.15),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade700,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(
    BuildContext context,
    List<AdminExpenseModel> expenses,
  ) {
    if (expenses.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminExpensesProvider(_currentParams));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return _buildExpenseCard(context, expense);
        },
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, AdminExpenseModel expense) {
    final currencyFormat = NumberFormat.currency(
      symbol: _getCurrencySymbol(expense.currency),
      decimalDigits: 2,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Category Icon, Title, Amount
            Row(
              children: [
                // Category Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(
                      expense.category,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(expense.category),
                    color: _getCategoryColor(expense.category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Title and Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expense.categoryDisplayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(expense.amount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                    if (expense.pendingAmount > 0)
                      Text(
                        '${currencyFormat.format(expense.pendingAmount)} pending',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Trip Info
            if (expense.tripName != null) ...[
              Row(
                children: [
                  Icon(Icons.explore, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${expense.tripName}${expense.tripDestination != null ? ' • ${expense.tripDestination}' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Standalone Expense',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Payer Info
            Row(
              children: [
                Icon(Icons.payment, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Paid by: ${expense.payerDisplayName}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Stats Row: Splits, Settlement, Date
            Row(
              children: [
                // Split count
                _buildStatChip(
                  icon: Icons.people_outline,
                  label: '${expense.splitCount} splits',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),

                // Settlement status
                _buildStatChip(
                  icon: expense.isFullySettled
                      ? Icons.check_circle
                      : Icons.pending,
                  label: expense.isFullySettled
                      ? 'Settled'
                      : '${expense.settledCount}/${expense.splitCount}',
                  color: expense.isFullySettled ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),

                // Receipt indicator
                if (expense.hasReceipt)
                  _buildStatChip(
                    icon: Icons.receipt_long,
                    label: 'Receipt',
                    color: Colors.purple,
                  ),

                const Spacer(),

                // Date
                Text(
                  expense.transactionDate != null
                      ? DateFormat('MMM d, y').format(expense.transactionDate!)
                      : DateFormat('MMM d, y').format(expense.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),

            // Settlement Progress Bar
            if (expense.splitCount > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: expense.settlementPercentage / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    expense.isFullySettled ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Settle/Unsettle button
                if (expense.splitCount > 0 && !expense.isFullySettled)
                  TextButton.icon(
                    onPressed: () => _settleExpense(expense),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Settle All'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                if (expense.isFullySettled)
                  TextButton.icon(
                    onPressed: () => _unsettleExpense(expense),
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Unsettle'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                const SizedBox(width: 8),

                // Edit button
                TextButton.icon(
                  onPressed: () => _showEditDialog(expense),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),

                // Delete button
                TextButton.icon(
                  onPressed: () => _confirmDeleteExpense(expense),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    String message = 'No expenses found';
    String subtitle = 'Expenses will appear here once created';

    if (_searchQuery.isNotEmpty) {
      message = 'No matching expenses';
      subtitle = 'Try a different search term';
    } else if (_selectedCategory != null) {
      message = 'No expenses in this category';
      subtitle = 'Try selecting a different category';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error loading expenses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(adminExpensesProvider(_currentParams));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helper methods for category styling
  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'accommodation':
        return Icons.hotel;
      case 'activities':
        return Icons.local_activity;
      case 'shopping':
        return Icons.shopping_bag;
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.receipt;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'accommodation':
        return Colors.purple;
      case 'activities':
        return Colors.green;
      case 'shopping':
        return Colors.pink;
      case 'other':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

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

  // Action methods
  Future<void> _settleExpense(AdminExpenseModel expense) async {
    try {
      await ref
          .read(adminExpenseRepositoryProvider)
          .settleExpenseSplits(expense.id);
      if (context.mounted) {
        ref.invalidate(adminExpensesProvider(_currentParams));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settled ${expense.pendingSplitCount} splits'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to settle: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _unsettleExpense(AdminExpenseModel expense) async {
    try {
      await ref
          .read(adminExpenseRepositoryProvider)
          .unsettleExpenseSplits(expense.id);
      if (context.mounted) {
        ref.invalidate(adminExpensesProvider(_currentParams));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unsettled ${expense.settledCount} splits'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unsettle: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showEditDialog(AdminExpenseModel expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditExpenseDialog(
        expense: expense,
        onSave: (title, description, amount, category) async {
          try {
            await ref
                .read(adminExpenseRepositoryProvider)
                .updateExpense(
                  expense.id,
                  title: title,
                  description: description,
                  amount: amount,
                  category: category,
                );
            if (context.mounted) {
              ref.invalidate(adminExpensesProvider(_currentParams));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Expense updated'),
                  backgroundColor: AppTheme.success,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update expense: $e'),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmDeleteExpense(AdminExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Are you sure you want to delete "${expense.title}"? This will also delete all ${expense.splitCount} splits associated with this expense.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteExpense(expense);
    }
  }

  Future<void> _deleteExpense(AdminExpenseModel expense) async {
    try {
      await ref.read(adminExpenseRepositoryProvider).deleteExpense(expense.id);
      if (context.mounted) {
        ref.invalidate(adminExpensesProvider(_currentParams));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense "${expense.title}" deleted'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete expense: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}

/// Edit Expense Dialog
class _EditExpenseDialog extends StatefulWidget {
  final AdminExpenseModel expense;
  final Future<void> Function(
    String title,
    String? description,
    double? amount,
    String? category,
  )
  onSave;

  const _EditExpenseDialog({required this.expense, required this.onSave});

  @override
  State<_EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends State<_EditExpenseDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  String? _selectedCategory;
  bool _isLoading = false;

  static const List<Map<String, dynamic>> _categories = [
    {'value': 'food', 'label': 'Food & Dining', 'icon': Icons.restaurant},
    {
      'value': 'transport',
      'label': 'Transportation',
      'icon': Icons.directions_car,
    },
    {'value': 'accommodation', 'label': 'Accommodation', 'icon': Icons.hotel},
    {
      'value': 'activities',
      'label': 'Activities',
      'icon': Icons.local_activity,
    },
    {'value': 'shopping', 'label': 'Shopping', 'icon': Icons.shopping_bag},
    {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _descriptionController = TextEditingController(
      text: widget.expense.description ?? '',
    );
    _amountController = TextEditingController(
      text: widget.expense.amount.toString(),
    );
    _selectedCategory = widget.expense.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Edit Expense',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Title Field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Amount Field
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                border: const OutlineInputBorder(),
                prefixText: '${widget.expense.currency} ',
              ),
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat['value'] as String,
                  child: Row(
                    children: [
                      Icon(cat['icon'] as IconData, size: 20),
                      const SizedBox(width: 8),
                      Text(cat['label'] as String),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 16),

            // Description Field
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    final amountText = _amountController.text.trim();
    double? amount;
    if (amountText.isNotEmpty) {
      amount = double.tryParse(amountText);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    await widget.onSave(
      title,
      _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      amount,
      _selectedCategory,
    );

    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}
