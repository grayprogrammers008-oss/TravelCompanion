import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/widgets/premium_form_fields.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/widgets/gradient_backgrounds.dart';
import '../../../../core/widgets/confetti_animation.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../providers/expense_providers.dart';

class AddExpensePageNew extends ConsumerStatefulWidget {
  final String? tripId; // Optional for standalone expenses

  const AddExpensePageNew({super.key, this.tripId});

  @override
  ConsumerState<AddExpensePageNew> createState() => _AddExpensePageNewState();
}

class _AddExpensePageNewState extends ConsumerState<AddExpensePageNew> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  DateTime? _transactionDate;
  bool _isLoading = false;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Accommodation',
    'Activities',
    'Shopping',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }


  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authDataSource = ref.read(authLocalDataSourceProvider);
      final currentUserId = authDataSource.currentUserId;
      final scaffoldContext = context; // Store context before async

      if (currentUserId == null || currentUserId.isEmpty) {
        throw Exception('User not logged in');
      }

      List<String> memberIds;

      // Get split members
      if (widget.tripId != null) {
        // Trip expense: split with trip members
        final tripAsync = await ref.read(tripProvider(widget.tripId!).future);
        memberIds = tripAsync.members.map((m) => m.userId).toList();

        if (memberIds.isEmpty) {
          throw Exception('No members found in trip');
        }
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
            category: _selectedCategory,
            paidBy: currentUserId,
            splitWith: memberIds,
            transactionDate: _transactionDate ?? DateTime.now(),
          );

      if (mounted) {
        // Show confetti for new expense!
        ConfettiOverlay.show(scaffoldContext, particleCount: 100);

        // Refresh expenses list
        if (widget.tripId != null) {
          ref.invalidate(tripExpensesProvider(widget.tripId!));
          ref.invalidate(tripBalancesProvider(widget.tripId!));
        } else {
          ref.invalidate(userExpensesProvider);
          ref.invalidate(standaloneExpensesProvider);
        }

        await Future.delayed(const Duration(milliseconds: 500));
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

  @override
  Widget build(BuildContext context) {
    final isStandalone = widget.tripId == null;

    return Scaffold(
      body: MeshGradientBackground(
        opacity: 0.12,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section with Gradient
                  FadeSlideAnimation(
                    delay: Duration.zero,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: AppTheme.shadowTeal,
                      ),
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
                      prefixIcon: Icons.currency_rupee,
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

                  // Transaction Date Picker
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * 4,
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
                    delay: AppAnimations.staggerSmall * 5,
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
                    delay: AppAnimations.staggerSmall * 6,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.info.withValues(alpha: 0.1),
                            AppTheme.primaryTeal.withValues(alpha: 0.05),
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
                                  : 'This expense will be split equally among all trip members',
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
                    delay: AppAnimations.staggerSmall * 7,
                    child: AnimatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      gradient: AppTheme.primaryGradient,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      child: _isLoading
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
                                const Icon(Icons.add, color: Colors.white),
                                const SizedBox(width: AppTheme.spacingSm),
                                Text(
                                  'Add Expense',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
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
