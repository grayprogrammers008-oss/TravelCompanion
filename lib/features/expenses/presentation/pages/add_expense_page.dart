import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/widgets/premium_form_fields.dart';
import '../../../../core/widgets/gradient_page_backgrounds.dart';
import '../../../../core/widgets/premium_header.dart';
import '../../../../core/widgets/confetti_animation.dart';
import '../../../../core/widgets/member_picker.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../providers/expense_providers.dart';

class AddExpensePage extends ConsumerStatefulWidget {
  final String? tripId; // Optional for standalone expenses

  const AddExpensePage({super.key, this.tripId});

  @override
  ConsumerState<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends ConsumerState<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  DateTime? _transactionDate;
  bool _isLoading = false;
  List<String> _selectedMemberIds = [];
  String? _paidByUserId; // Who paid for this expense
  String _currency = 'INR'; // Trip currency for display

  final List<String> _categories = [
    'Food',
    'Transport',
    'Accommodation',
    'Activities',
    'Shopping',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchTripCurrency();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchTripCurrency() async {
    if (widget.tripId == null) return;
    try {
      final tripData = await ref.read(tripProvider(widget.tripId!).future);
      if (mounted) {
        setState(() {
          _currency = tripData.trip.currency;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch trip currency: $e');
    }
  }

  IconData _getCurrencyIcon(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return Icons.attach_money;
      case 'EUR':
        return Icons.euro;
      case 'GBP':
        return Icons.currency_pound;
      case 'JPY':
      case 'CNY':
        return Icons.currency_yen;
      case 'INR':
      default:
        return Icons.currency_rupee;
    }
  }


  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get current user ID from Supabase (online-only mode)
      final currentUserId = SupabaseClientWrapper.currentUserId;
      final scaffoldContext = context; // Store context before async

      if (currentUserId == null || currentUserId.isEmpty) {
        throw Exception('User not logged in');
      }

      List<String> memberIds;

      // Get split members
      if (widget.tripId != null) {
        // Trip expense: use selected members from picker
        if (_selectedMemberIds.isEmpty) {
          throw Exception('Please select at least one member to split with');
        }
        memberIds = _selectedMemberIds;
      } else {
        // Standalone expense: split with just current user
        memberIds = [currentUserId];
      }

      // Create expense
      await ref.read(expenseControllerProvider.notifier).createExpense(
            tripId: widget.tripId, // Can be null for standalone
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            amount: double.parse(_amountController.text.trim()),
            category: _selectedCategory?.toLowerCase(),
            paidBy: _paidByUserId ?? currentUserId, // Use selected payer or default to current user
            splitWith: memberIds,
            transactionDate: _transactionDate ?? DateTime.now(),
          );

      if (mounted) {
        // Show confetti for new expense!
        if (scaffoldContext.mounted) {
          ConfettiOverlay.show(scaffoldContext, particleCount: 100);
        }

        // Refresh expenses list
        if (widget.tripId != null) {
          ref.invalidate(tripExpensesProvider(widget.tripId!));
          ref.invalidate(tripBalancesProvider(widget.tripId!));
        } else {
          ref.invalidate(userExpensesProvider);
          ref.invalidate(standaloneExpensesProvider);
        }

        await Future.delayed(const Duration(milliseconds: 500));
        if (!scaffoldContext.mounted) return;
        scaffoldContext.pop();

        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildMemberPicker() {
    if (widget.tripId == null) return const SizedBox.shrink();

    final tripAsync = ref.watch(tripProvider(widget.tripId!));
    final frequencyAsync = ref.watch(memberFrequencyProvider(widget.tripId!));

    return tripAsync.when(
      data: (trip) {
        final members = trip.members;
        final frequency = frequencyAsync.when(
          data: (data) => data,
          loading: () => <String, int>{},
          error: (_, __) => <String, int>{},
        );

        // Initialize selected members to all members if not set yet
        if (_selectedMemberIds.isEmpty && members.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedMemberIds = members.map((m) => m.userId).toList();
              });
            }
          });
        }

        return MemberPickerWidget(
          members: members,
          selectedMemberIds: _selectedMemberIds,
          memberFrequency: frequency,
          labelText: 'Split With *',
          hintText: 'Select members to split this expense',
          onSelectionChanged: (selectedIds) {
            setState(() {
              _selectedMemberIds = selectedIds;
            });
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.error),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                'Failed to load members',
                style: TextStyle(color: AppTheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhoPaidPicker() {
    if (widget.tripId == null) return const SizedBox.shrink();

    final tripAsync = ref.watch(tripProvider(widget.tripId!));
    final currentUserId = SupabaseClientWrapper.currentUserId;

    return tripAsync.when(
      data: (trip) {
        final members = trip.members;

        // Initialize paidByUserId to current user if not set yet
        if (_paidByUserId == null && currentUserId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _paidByUserId = currentUserId;
              });
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Paid By *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.neutral700,
                ),
              ),
            ),
            // Dropdown-style selector
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.neutral300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _paidByUserId ?? currentUserId,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.neutral500),
                  items: members.map((member) {
                    final displayName = member.fullName ?? member.email ?? 'Unknown';
                    final isSelf = member.userId == currentUserId;
                    final initials = _getInitials(displayName);

                    return DropdownMenuItem<String>(
                      value: member.userId,
                      child: Row(
                        children: [
                          // Avatar
                          if (member.avatarUrl != null)
                            CircleAvatar(
                              radius: 14,
                              backgroundImage: NetworkImage(member.avatarUrl!),
                            )
                          else
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppTheme.primaryTeal,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          // Name
                          Expanded(
                            child: Text(
                              isSelf ? '$displayName (Me)' : displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.neutral800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _paidByUserId = value);
                          }
                        },
                ),
              ),
            ),
            // Helper text
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6),
              child: Text(
                'Select who paid for this expense',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutral500,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.error),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                'Failed to load members',
                style: TextStyle(color: AppTheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isStandalone = widget.tripId == null;
    final themeData = context.appThemeData;

    return Scaffold(
      body: MeshGradientBackground(
        intensity: 0.6,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppTheme.neutral700),
                      onPressed: () => context.pop(),
                      tooltip: 'Back',
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingSm),

                  // Header Section with Gradient
                  FadeSlideAnimation(
                    delay: Duration.zero,
                    child: GlossyCard(
                      useHeaderGradient: true,
                      child: Column(
                        children: [
                          // Icon in circle
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingMd),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),

                          // Title
                          Text(
                            isStandalone ? 'Track Your Spending' : 'Split an Expense',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppTheme.spacing2xs),

                          // Subtitle
                          Text(
                            isStandalone
                                ? 'Add a personal expense to track your spending'
                                : 'Add a shared expense and split it with your crew',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXl),

                  // Expense Title
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall,
                    child: PremiumTextField(
                      controller: _titleController,
                      labelText: 'Expense Title *',
                      hintText: 'e.g., Lunch at restaurant',
                      prefixIcon: Icons.title,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        if (value.trim().length < 3) {
                          return 'Title must be at least 3 characters';
                        }
                        return null;
                      },
                      maxLength: 100,
                      showCharacterCount: true,
                      enabled: !_isLoading,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // Amount
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * 2,
                    child: PremiumTextField(
                      controller: _amountController,
                      labelText: 'Amount *',
                      hintText: '0.00',
                      prefixIcon: _getCurrencyIcon(_currency),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value.trim());
                        if (amount == null) {
                          return 'Please enter a valid amount';
                        }
                        if (amount <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // Category Dropdown
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * 3,
                    child: PremiumDropdown<String>(
                      value: _selectedCategory,
                      labelText: 'Category *',
                      hintText: 'Select category',
                      prefixIcon: Icons.category,
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() => _selectedCategory = value);
                            },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // Member Picker (only for trip expenses)
                  if (!isStandalone && widget.tripId != null)
                    FadeSlideAnimation(
                      delay: AppAnimations.staggerSmall * 4,
                      child: _buildMemberPicker(),
                    ),

                  if (!isStandalone && widget.tripId != null)
                    const SizedBox(height: AppTheme.spacingLg),

                  // Who Paid Picker (only for trip expenses)
                  if (!isStandalone && widget.tripId != null)
                    FadeSlideAnimation(
                      delay: AppAnimations.staggerSmall * 5,
                      child: _buildWhoPaidPicker(),
                    ),

                  if (!isStandalone && widget.tripId != null)
                    const SizedBox(height: AppTheme.spacingLg),

                  // Transaction Date Picker
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * (isStandalone ? 4 : 5),
                    child: PremiumDateTimePicker(
                      selectedDate: _transactionDate,
                      labelText: 'Transaction Date (optional)',
                      prefixIcon: Icons.calendar_today,
                      pickDate: true,
                      pickTime: false,
                      onDateChanged: (date) {
                        setState(() => _transactionDate = date);
                      },
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // Description
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * (isStandalone ? 5 : 6),
                    child: PremiumTextField(
                      controller: _descriptionController,
                      labelText: 'Description (Optional)',
                      hintText: 'Add any notes about this expense',
                      prefixIcon: Icons.notes,
                      maxLines: 3,
                      maxLength: 500,
                      showCharacterCount: true,
                      enabled: !_isLoading,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXl),

                  // Info Card
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * (isStandalone ? 6 : 7),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.info.withValues(alpha: 0.1),
                            themeData.primaryColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppTheme.info.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingSm),
                            decoration: BoxDecoration(
                              color: AppTheme.info.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: AppTheme.info,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: Text(
                              isStandalone
                                  ? 'This is a personal expense tracked only by you'
                                  : 'This expense will be split equally among the selected members',
                              style: TextStyle(
                                color: AppTheme.neutral800,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXl),

                  // Submit Button
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * (isStandalone ? 7 : 8),
                    child: GlossyButton(
                      label: 'Add Expense',
                      icon: Icons.add,
                      onPressed: _isLoading ? null : _handleSubmit,
                      isLoading: _isLoading,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingMd),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
