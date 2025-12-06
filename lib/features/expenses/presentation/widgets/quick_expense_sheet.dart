// Quick Expense Sheet
//
// A streamlined bottom sheet for adding expenses quickly:
// 1. Enter amount via numpad
// 2. Select category
// 3. (Optional) Customize split members
// 4. Tap "Add" button
//
// Defaults to splitting equally among all trip members,
// but allows customization to split with specific members.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_data.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/network/supabase_client.dart';
import '../../../../shared/models/trip_model.dart';
import '../providers/expense_providers.dart';

/// Category data with icon and color
class ExpenseCategory {
  final String name;
  final IconData icon;
  final Color color;

  const ExpenseCategory({
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Available expense categories
const List<ExpenseCategory> expenseCategories = [
  ExpenseCategory(name: 'Food', icon: Icons.restaurant, color: Color(0xFFFF9800)),
  ExpenseCategory(name: 'Transport', icon: Icons.directions_car, color: Color(0xFF2196F3)),
  ExpenseCategory(name: 'Accommodation', icon: Icons.hotel, color: Color(0xFF9C27B0)),
  ExpenseCategory(name: 'Activities', icon: Icons.confirmation_number, color: Color(0xFF4CAF50)),
  ExpenseCategory(name: 'Shopping', icon: Icons.shopping_bag, color: Color(0xFFE91E63)),
  ExpenseCategory(name: 'Other', icon: Icons.more_horiz, color: Color(0xFF607D8B)),
];

/// Show quick expense bottom sheet
Future<bool> showQuickExpenseSheet({
  required BuildContext context,
  required String tripId,
  required TripWithMembers trip,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => QuickExpenseSheet(
      tripId: tripId,
      trip: trip,
    ),
  );
  return result ?? false;
}

class QuickExpenseSheet extends ConsumerStatefulWidget {
  final String tripId;
  final TripWithMembers trip;

  const QuickExpenseSheet({
    super.key,
    required this.tripId,
    required this.trip,
  });

  @override
  ConsumerState<QuickExpenseSheet> createState() => _QuickExpenseSheetState();
}

class _QuickExpenseSheetState extends ConsumerState<QuickExpenseSheet> {
  String _amount = '';
  ExpenseCategory? _selectedCategory;
  bool _isSubmitting = false;
  bool _showMemberSelector = false;
  late Set<String> _selectedMemberIds;
  DateTime _transactionDate = DateTime.now();
  bool _isPersonalExpense = false; // "Just Me" mode

  @override
  void initState() {
    super.initState();
    // Default: all members selected
    _selectedMemberIds = widget.trip.members.map((m) => m.userId).toSet();
  }

  /// Get currency symbol
  String get _currencySymbol {
    switch (widget.trip.trip.currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
      default:
        return '₹';
    }
  }

  /// Format amount for display
  String get _displayAmount {
    if (_amount.isEmpty) return '0';
    return _amount;
  }

  /// Get the numeric amount
  double get _numericAmount {
    if (_amount.isEmpty) return 0;
    return double.tryParse(_amount) ?? 0;
  }

  /// Handle numpad tap
  void _onNumpadTap(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (value == '⌫') {
        // Backspace
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else if (value == '.') {
        // Decimal point - only allow one
        if (!_amount.contains('.')) {
          _amount = _amount.isEmpty ? '0.' : '$_amount.';
        }
      } else {
        // Number
        // Limit to 2 decimal places
        if (_amount.contains('.')) {
          final parts = _amount.split('.');
          if (parts[1].length >= 2) return;
        }
        // Limit total length
        if (_amount.length >= 10) return;
        // Remove leading zero unless it's "0."
        if (_amount == '0' && value != '.') {
          _amount = value;
        } else {
          _amount += value;
        }
      }
    });
  }

  /// Handle category selection
  void _onCategoryTap(ExpenseCategory category) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = category;
    });
  }

  /// Submit expense
  Future<void> _submitExpense() async {
    if (_numericAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_isPersonalExpense && _selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member to split with'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUserId = SupabaseClientWrapper.currentUserId;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      // Get member IDs for split
      // Personal expense: only current user; otherwise selected members
      final memberIds = _isPersonalExpense
          ? [currentUserId]
          : _selectedMemberIds.toList();

      // Create expense with auto-generated title
      final controller = ref.read(expenseControllerProvider.notifier);
      await controller.createExpense(
        tripId: widget.tripId,
        title: _isPersonalExpense
            ? '${_selectedCategory!.name} (Personal)'
            : _selectedCategory!.name,
        amount: _numericAmount,
        category: _selectedCategory!.name.toLowerCase(),
        paidBy: currentUserId,
        splitWith: memberIds,
        transactionDate: _transactionDate,
      );

      if (mounted) {
        // Refresh expense list so changes appear immediately
        ref.invalidate(tripExpensesProvider(widget.tripId));
        ref.invalidate(tripBalancesProvider(widget.tripId));

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('$_currencySymbol$_displayAmount added to ${_selectedCategory!.name}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Close bottom sheet with success
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXl),
          topRight: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: AppTheme.spacingMd),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: themeData.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(
                        Icons.bolt,
                        color: themeData.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Expense',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _isPersonalExpense
                                ? 'Personal expense (not shared)'
                                : _selectedMemberIds.length == widget.trip.members.length
                                    ? 'Split equally with all members'
                                    : 'Split with ${_selectedMemberIds.length} of ${widget.trip.members.length} members',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isPersonalExpense ? Colors.orange : AppTheme.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),

              // Amount display
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                  vertical: AppTheme.spacingMd,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neutral50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: _numericAmount > 0
                        ? themeData.primaryColor.withValues(alpha: 0.3)
                        : AppTheme.neutral200,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currencySymbol,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: _numericAmount > 0
                            ? themeData.primaryColor
                            : AppTheme.neutral400,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _displayAmount,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: _numericAmount > 0 ? Colors.black87 : AppTheme.neutral400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Category selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: AppTheme.spacingSm, bottom: AppTheme.spacingSm),
                      child: Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.neutral600,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: AppTheme.spacingSm,
                      runSpacing: AppTheme.spacingSm,
                      children: expenseCategories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () => _onCategoryTap(category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMd,
                              vertical: AppTheme.spacingSm,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? category.color.withValues(alpha: 0.15)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(
                                color: isSelected ? category.color : AppTheme.neutral200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  category.icon,
                                  size: 18,
                                  color: isSelected ? category.color : AppTheme.neutral500,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? category.color : AppTheme.neutral700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingSm),

              // Split with section
              _buildSplitWithSection(themeData),

              const SizedBox(height: AppTheme.spacingSm),

              // Transaction date section
              _buildDateSection(themeData),

              const SizedBox(height: AppTheme.spacingMd),

              // Numpad
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                child: Column(
                  children: [
                    _buildNumpadRow(['1', '2', '3'], themeData),
                    const SizedBox(height: AppTheme.spacingSm),
                    _buildNumpadRow(['4', '5', '6'], themeData),
                    const SizedBox(height: AppTheme.spacingSm),
                    _buildNumpadRow(['7', '8', '9'], themeData),
                    const SizedBox(height: AppTheme.spacingSm),
                    _buildNumpadRow(['.', '0', '⌫'], themeData),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Add button
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingLg,
                  0,
                  AppTheme.spacingLg,
                  AppTheme.spacingLg,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_numericAmount > 0 && _selectedCategory != null && (_isPersonalExpense || _selectedMemberIds.isNotEmpty) && !_isSubmitting)
                        ? _submitExpense
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeData.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      disabledBackgroundColor: AppTheme.neutral200,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _numericAmount > 0 && _selectedCategory != null
                                    ? 'Add $_currencySymbol$_displayAmount'
                                    : 'Add Expense',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the date section
  Widget _buildDateSection(AppThemeData themeData) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = _transactionDate.year == today.year &&
        _transactionDate.month == today.month &&
        _transactionDate.day == today.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.selectionClick();
          final picked = await showDatePicker(
            context: context,
            initialDate: _transactionDate,
            firstDate: now.subtract(const Duration(days: 365)),
            lastDate: now.add(const Duration(days: 30)),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: themeData.primaryColor,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              _transactionDate = picked;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: AppTheme.spacingXs,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppTheme.neutral600,
              ),
              const SizedBox(width: 6),
              Text(
                'Date',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isToday
                      ? themeData.primaryColor.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isToday
                      ? 'Today'
                      : '${_transactionDate.day}/${_transactionDate.month}/${_transactionDate.year}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isToday ? themeData.primaryColor : Colors.blue,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppTheme.neutral400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the split with section
  Widget _buildSplitWithSection(AppThemeData themeData) {
    final allSelected = _selectedMemberIds.length == widget.trip.members.length;

    // Determine badge text and color
    String badgeText;
    Color badgeColor;
    if (_isPersonalExpense) {
      badgeText = 'Just Me';
      badgeColor = Colors.orange;
    } else if (allSelected) {
      badgeText = 'Everyone';
      badgeColor = themeData.primaryColor;
    } else {
      badgeText = '${_selectedMemberIds.length} selected';
      badgeColor = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with toggle
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _showMemberSelector = !_showMemberSelector;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: AppTheme.spacingXs,
              ),
              child: Row(
                children: [
                  Icon(
                    _isPersonalExpense ? Icons.person_outline : Icons.people_outline,
                    size: 16,
                    color: AppTheme.neutral600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Split with',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutral600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showMemberSelector
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppTheme.neutral500,
                  ),
                ],
              ),
            ),
          ),

          // Expandable member selector
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _showMemberSelector
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.only(top: AppTheme.spacingSm),
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: AppTheme.neutral50,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.neutral200),
              ),
              child: Column(
                children: [
                  // Personal expense toggle ("Just Me")
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isPersonalExpense = !_isPersonalExpense;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isPersonalExpense
                            ? Colors.orange.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                          color: _isPersonalExpense
                              ? Colors.orange
                              : AppTheme.neutral300,
                          width: _isPersonalExpense ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPersonalExpense
                                ? Icons.check_circle
                                : Icons.person_outline,
                            size: 18,
                            color: _isPersonalExpense
                                ? Colors.orange
                                : AppTheme.neutral500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Just Me (Personal)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _isPersonalExpense
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: _isPersonalExpense
                                  ? Colors.orange
                                  : AppTheme.neutral700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Show member selection only if not personal expense
                  if (!_isPersonalExpense) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    // Select all / None row
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedMemberIds = widget.trip.members
                                  .map((m) => m.userId)
                                  .toSet();
                            });
                          },
                          icon: const Icon(Icons.select_all, size: 16),
                          label: const Text('All'),
                          style: TextButton.styleFrom(
                            foregroundColor: themeData.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedMemberIds.clear();
                            });
                          },
                          icon: const Icon(Icons.deselect, size: 16),
                          label: const Text('None'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.neutral500,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    // Member chips (only shown when not personal expense)
                    Wrap(
                      spacing: AppTheme.spacingSm,
                      runSpacing: AppTheme.spacingSm,
                      children: widget.trip.members.map((member) {
                        final isSelected = _selectedMemberIds.contains(member.userId);
                        final displayName = member.fullName ?? member.email ?? 'Unknown';
                        final initials = _getInitials(displayName);

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (isSelected) {
                                _selectedMemberIds.remove(member.userId);
                              } else {
                                _selectedMemberIds.add(member.userId);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? themeData.primaryColor.withValues(alpha: 0.15)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? themeData.primaryColor
                                    : AppTheme.neutral300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Avatar or initials
                                if (member.avatarUrl != null)
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundImage: NetworkImage(member.avatarUrl!),
                                  )
                                else
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: isSelected
                                        ? themeData.primaryColor
                                        : AppTheme.neutral400,
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                // Name
                                Text(
                                  displayName.length > 12
                                      ? '${displayName.substring(0, 12)}...'
                                      : displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? themeData.primaryColor
                                        : AppTheme.neutral700,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: themeData.primaryColor,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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

  /// Get initials from name
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Widget _buildNumpadRow(List<String> keys, AppThemeData themeData) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildNumpadKey(key, themeData),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumpadKey(String key, AppThemeData themeData) {
    final isBackspace = key == '⌫';

    return Material(
      color: isBackspace ? AppTheme.neutral100 : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: () => _onNumpadTap(key),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Center(
            child: isBackspace
                ? Icon(Icons.backspace_outlined, color: AppTheme.neutral600, size: 24)
                : Text(
                    key,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
