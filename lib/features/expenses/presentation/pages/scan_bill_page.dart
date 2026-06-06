import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/services/bill_scanner_service.dart';
import '../../../../core/widgets/gradient_page_backgrounds.dart';
import '../../../../core/widgets/premium_form_fields.dart';
import '../../../../core/widgets/premium_header.dart' show GlossyButton, GlossyCard;
import '../../../../core/widgets/member_picker.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/config/secrets.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../shared/models/trip_model.dart';
import '../../../home/presentation/providers/dashboard_providers.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../providers/expense_providers.dart';

const String _groqApiKey = String.fromEnvironment(
  'GROQ_API_KEY',
  defaultValue: kGroqApiKey,
);

/// Page for scanning bills/receipts and adding them as expenses
class ScanBillPage extends ConsumerStatefulWidget {
  final String? tripId; // Pre-selected trip, null to use active trip

  const ScanBillPage({super.key, this.tripId});

  @override
  ConsumerState<ScanBillPage> createState() => _ScanBillPageState();
}

class _ScanBillPageState extends ConsumerState<ScanBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  DateTime? _transactionDate;
  String? _selectedTripId;
  File? _selectedImage;
  ParsedBillData? _parsedData;
  bool _isScanning = false;
  bool _isSubmitting = false;
  String _currency = 'INR';
  // Split participants. Pre-filled from trip members when a trip is picked;
  // user can deselect anyone or add ghosts before submitting.
  List<String> _selectedMemberIds = [];
  final List<String> _selectedGhostIds = [];
  // Track which trip the member list was seeded from so we re-seed on change.
  String? _seededFromTripId;

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

  Future<void> _fetchTripCurrency() async {
    final tripId = _selectedTripId ?? widget.tripId;
    if (tripId == null) return;
    try {
      final tripData = await ref.read(tripProvider(tripId).future);
      if (mounted) {
        setState(() {
          _currency = tripData.trip.currency;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch trip currency: $e');
    }
  }

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
    _selectedTripId = widget.tripId;
    _fetchTripCurrency();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _parsedData = null;
      });
      await _scanBill();
    }
  }

  Future<void> _scanBill() async {
    if (_selectedImage == null) return;

    setState(() => _isScanning = true);

    try {
      final scanner = BillScannerService(_groqApiKey);

      final result = await scanner.scanBill(_selectedImage!.path);

      setState(() {
        _parsedData = result;
        // Pre-fill form with parsed data
        if (result.totalAmount != null) {
          _amountController.text = result.totalAmount!.toStringAsFixed(2);
        }
        if (result.vendorName != null || result.description != null) {
          _titleController.text = result.description ?? result.vendorName ?? '';
        }
        if (result.category != null) {
          // Match category to our list
          final matchedCategory = _categories.firstWhere(
            (c) => c.toLowerCase() == result.category?.toLowerCase(),
            orElse: () => 'Other',
          );
          _selectedCategory = matchedCategory;
        }
        if (result.date != null) {
          _transactionDate = result.date;
        }
      });

      // Show feedback about parsing confidence
      if (mounted) {
        final confidence = (result.confidence * 100).toInt();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.totalAmount != null
                  ? 'Bill scanned! Confidence: $confidence%'
                  : 'Could not find total amount. Please enter manually.',
            ),
            backgroundColor:
                result.totalAmount != null ? AppTheme.success : AppTheme.warning,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      scanner.dispose();
    } catch (e) {
      debugPrint('Error scanning bill: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning bill: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUserId = SupabaseClientWrapper.currentUserId;
      if (currentUserId == null || currentUserId.isEmpty) {
        throw Exception('User not logged in');
      }

      // For a trip expense, use what the user actually selected in the
      // picker (default = all members). For a standalone expense, the
      // current user covers it.
      List<String> memberIds;
      List<String> ghostIds = const [];
      if (_selectedTripId != null) {
        if (_selectedMemberIds.isEmpty && _selectedGhostIds.isEmpty) {
          throw Exception('Please select at least one participant to split with');
        }
        memberIds = _selectedMemberIds;
        ghostIds = _selectedGhostIds;
      } else {
        memberIds = [currentUserId];
      }

      // Create expense
      await ref.read(expenseControllerProvider.notifier).createExpense(
            tripId: _selectedTripId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            amount: double.parse(_amountController.text.trim()),
            category: _selectedCategory?.toLowerCase(),
            paidBy: currentUserId,
            splitWith: memberIds,
            ghostSplitWith: ghostIds,
            transactionDate: _transactionDate ?? DateTime.now(),
          );

      if (mounted) {
        // Refresh expenses
        if (_selectedTripId != null) {
          ref.invalidate(tripExpensesProvider(_selectedTripId!));
          ref.invalidate(tripBalancesProvider(_selectedTripId!));
        } else {
          ref.invalidate(userExpensesProvider);
          ref.invalidate(standaloneExpensesProvider);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added from bill!'),
            backgroundColor: AppTheme.success,
          ),
        );

        context.pop();
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Renders the trip-member picker. Pre-seeds [_selectedMemberIds] to every
  /// member on first render of a new trip; the user can deselect anyone
  /// before submitting.
  Widget _buildMemberPicker() {
    final tripId = _selectedTripId;
    if (tripId == null) return const SizedBox.shrink();
    final tripAsync = ref.watch(tripProvider(tripId));
    final frequencyAsync = ref.watch(memberFrequencyProvider(tripId));

    return tripAsync.when(
      data: (trip) {
        final members = trip.members;
        final frequency = frequencyAsync.when(
          data: (data) => data,
          loading: () => <String, int>{},
          error: (_, _) => <String, int>{},
        );

        // Seed on first render OR when the user changes trips.
        if (_seededFromTripId != tripId && members.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedMemberIds = members.map((m) => m.userId).toList();
                _selectedGhostIds.clear();
                _seededFromTripId = tripId;
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
      loading: () => const Padding(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Text(
          'Failed to load members',
          style: TextStyle(color: AppTheme.error),
        ),
      ),
    );
  }

  /// Picker for trip-scoped ghost (non-member) participants. Mirrors the
  /// one on AddExpensePage — see [add_expense_page.dart] for the design
  /// rationale (ghost shares fold into the creator's balance).
  Widget _buildGhostPicker() {
    final tripId = _selectedTripId;
    if (tripId == null) return const SizedBox.shrink();
    final currentUserId = SupabaseClientWrapper.currentUserId;
    final ghostsAsync = ref.watch(tripGhostParticipantsProvider(tripId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.person_add_alt_1, size: 18, color: AppTheme.neutral700),
              const SizedBox(width: 6),
              Text(
                'Guests (non-members)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.neutral700,
                ),
              ),
            ],
          ),
        ),
        ghostsAsync.when(
          data: (ghosts) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ghost in ghosts)
                  FilterChip(
                    label: Text(ghost.name),
                    avatar: const Icon(Icons.child_care, size: 18),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    selected: _selectedGhostIds.contains(ghost.id),
                    onSelected: _isSubmitting
                        ? null
                        : (selected) {
                            setState(() {
                              if (selected) {
                                _selectedGhostIds.add(ghost.id);
                              } else {
                                _selectedGhostIds.remove(ghost.id);
                              }
                            });
                          },
                    tooltip: ghost.creatorName != null
                        ? 'Added by ${ghost.creatorName} — share goes to them'
                        : null,
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Add guest'),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onPressed: _isSubmitting || currentUserId == null
                      ? null
                      : () => _showAddGuestDialog(tripId, currentUserId),
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => Text(
            'Failed to load guests',
            style: TextStyle(color: AppTheme.error, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddGuestDialog(String tripId, String currentUserId) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add guest'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g., My son, Mom, Alice (friend)',
          ),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final ghost = await repo.createGhostParticipant(
        tripId: tripId,
        name: name,
        createdBy: currentUserId,
      );
      ref.invalidate(tripGhostParticipantsProvider(tripId));
      if (mounted) {
        setState(() => _selectedGhostIds.add(ghost.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add guest: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTripAsync = ref.watch(activeTripProvider);
    final userTripsAsync = ref.watch(userTripsProvider);

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
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppTheme.neutral700),
                        onPressed: () => context.pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Scan Bill',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.neutral800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingMd),

                  // Image Preview or Capture Section
                  FadeSlideAnimation(
                    delay: Duration.zero,
                    child: _buildImageSection(),
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // Trip Selector — hide when opened from a specific trip's
                  // expenses page (tripId already known from the route).
                  if (widget.tripId == null) ...[
                    FadeSlideAnimation(
                      delay: AppAnimations.staggerSmall,
                      child: _buildTripSelector(userTripsAsync, activeTripAsync),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                  ],

                  // Form fields (only show after scanning)
                  if (_parsedData != null || _selectedImage != null) ...[
                    // Amount
                    FadeSlideAnimation(
                      delay: AppAnimations.staggerSmall * 2,
                      child: PremiumTextField(
                        controller: _amountController,
                        labelText: 'Amount *',
                        hintText: '0.00',
                        prefixIcon: _getCurrencyIcon(_currency),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value.trim());
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                        enabled: !_isSubmitting,
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingLg),

                    // Title
                    FadeSlideAnimation(
                      delay: AppAnimations.staggerSmall * 3,
                      child: PremiumTextField(
                        controller: _titleController,
                        labelText: 'Expense Title *',
                        hintText: 'e.g., Lunch at restaurant',
                        prefixIcon: Icons.title,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                        maxLength: 100,
                        showCharacterCount: true,
                        enabled: !_isSubmitting,
                      ),
                    ),

                    // Split-with + guests pickers (only when a trip is selected)
                    if (_selectedTripId != null) ...[
                      const SizedBox(height: AppTheme.spacingLg),
                      FadeSlideAnimation(
                        delay: AppAnimations.staggerSmall * 3,
                        child: _buildMemberPicker(),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      FadeSlideAnimation(
                        delay: AppAnimations.staggerSmall * 3,
                        child: _buildGhostPicker(),
                      ),
                    ],

                    const SizedBox(height: AppTheme.spacingLg),

                    // Category
                    FadeSlideAnimation(
                      delay: AppAnimations.staggerSmall * 4,
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
                        onChanged: _isSubmitting
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
                        enabled: !_isSubmitting,
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingLg),

                    // Date
                    FadeSlideAnimation(
                      delay: AppAnimations.staggerSmall * 5,
                      child: PremiumDateTimePicker(
                        selectedDate: _transactionDate,
                        labelText: 'Transaction Date',
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
                      delay: AppAnimations.staggerSmall * 6,
                      child: PremiumTextField(
                        controller: _descriptionController,
                        labelText: 'Description (Optional)',
                        hintText: 'Add any notes',
                        prefixIcon: Icons.notes,
                        maxLines: 2,
                        enabled: !_isSubmitting,
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingXl),

                    // Submit Button
                    FadeSlideAnimation(
                      delay: AppAnimations.staggerSmall * 7,
                      child: GlossyButton(
                        label: 'Add Expense',
                        icon: Icons.add,
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        isLoading: _isSubmitting,
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingMd),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (_selectedImage == null) {
      // Show capture options
      return GlossyCard(
        useHeaderGradient: true,
        child: Column(
          children: [
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
            Text(
              'Scan Your Bill',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing2xs),
            Text(
              'Take a photo or select from gallery',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCaptureButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildCaptureButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Show captured image with option to rescan
    return Column(
      children: [
        // Image preview
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.shadowMd,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
                if (_isScanning)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          'Scanning bill...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacingSm),

        // Rescan button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _isScanning
                  ? null
                  : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('Retake'),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            TextButton.icon(
              onPressed: _isScanning
                  ? null
                  : () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library, size: 18),
              label: const Text('Choose Another'),
            ),
          ],
        ),

        // Parsing result summary
        if (_parsedData != null && _parsedData!.confidence > 0)
          Container(
            margin: const EdgeInsets.only(top: AppTheme.spacingSm),
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: _parsedData!.confidence > 0.7
                  ? AppTheme.success.withValues(alpha: 0.1)
                  : AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: _parsedData!.confidence > 0.7
                    ? AppTheme.success.withValues(alpha: 0.3)
                    : AppTheme.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _parsedData!.confidence > 0.7
                      ? Icons.check_circle
                      : Icons.info,
                  size: 16,
                  color: _parsedData!.confidence > 0.7
                      ? AppTheme.success
                      : AppTheme.warning,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    _parsedData!.vendorName != null
                        ? 'Found: ${_parsedData!.vendorName}'
                        : 'Bill scanned - please verify details',
                    style: TextStyle(
                      fontSize: 13,
                      color: _parsedData!.confidence > 0.7
                          ? AppTheme.success
                          : AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCaptureButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg,
          vertical: AppTheme.spacingMd,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: AppTheme.spacing2xs),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripSelector(
    AsyncValue<List<TripWithMembers>> userTripsAsync,
    AsyncValue<TripWithMembers?> activeTripAsync,
  ) {
    return userTripsAsync.when(
      data: (trips) {
        // Filter to non-completed trips
        final activeTrips = trips.where((t) => !t.trip.isCompleted).toList();

        // Reset _selectedTripId if it no longer matches any dropdown item —
        // otherwise DropdownButton asserts with "zero or 2+ items with the
        // same value". Happens after a trip is completed/deleted under us.
        final selectedStillExists = _selectedTripId == null ||
            activeTrips.any((t) => t.trip.id == _selectedTripId);
        if (!selectedStillExists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedTripId = null);
          });
        }

        // If no trip selected, try to use active trip
        if (_selectedTripId == null && activeTrips.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final activeTrip = activeTripAsync.value;
              final activeId = activeTrip?.trip.id;
              final activeInList = activeId != null &&
                  activeTrips.any((t) => t.trip.id == activeId);
              setState(() {
                _selectedTripId =
                    activeInList ? activeId : activeTrips.first.trip.id;
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
                'Add to Trip',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.neutral700,
                ),
              ),
            ),
            // Dropdown
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
                child: DropdownButton<String?>(
                  value: selectedStillExists ? _selectedTripId : null,
                  isExpanded: true,
                  // Allow each item to size to its contents instead of being
                  // clamped to kMinInteractiveDimension (48dp). The trip name
                  // + destination column is ~50dp and was overflowing by 2px.
                  itemHeight: null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.neutral500),
                  hint: const Text('Select a trip'),
                  items: [
                    // Option for no trip (standalone expense)
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 20, color: AppTheme.neutral500),
                          const SizedBox(width: 12),
                          Text(
                            'Personal Expense (No trip)',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Trip options
                    ...activeTrips.map((t) {
                      final isActive = activeTripAsync.value?.trip.id == t.trip.id;
                      return DropdownMenuItem<String?>(
                        value: t.trip.id,
                        child: Row(
                          children: [
                            Icon(
                              Icons.flight_takeoff,
                              size: 20,
                              color: isActive ? context.primaryColor : AppTheme.neutral500,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    t.trip.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.neutral800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (t.trip.destination != null)
                                    Text(
                                      t.trip.destination!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.neutral500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: context.primaryColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() => _selectedTripId = value);
                        },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading trips: $e'),
    );
  }
}
