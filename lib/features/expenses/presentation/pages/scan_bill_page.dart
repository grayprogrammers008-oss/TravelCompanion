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
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../shared/models/trip_model.dart';
import '../../../home/presentation/providers/dashboard_providers.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../providers/expense_providers.dart';

/// Groq API Key for bill parsing
const String _groqApiKey = String.fromEnvironment(
  'GROQ_API_KEY',
  defaultValue: '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',
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

      // Get the selected trip to determine split members
      List<String> memberIds = [currentUserId]; // Default: just current user

      if (_selectedTripId != null) {
        final trip = await ref.read(tripProvider(_selectedTripId!).future);
        memberIds = trip.members.map((m) => m.userId).toList();
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

                  // Trip Selector
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall,
                    child: _buildTripSelector(userTripsAsync, activeTripAsync),
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // Form fields (only show after scanning)
                  if (_parsedData != null || _selectedImage != null) ...[
                    // Amount
                    FadeSlideAnimation(
                      delay: AppAnimations.staggerSmall * 2,
                      child: PremiumTextField(
                        controller: _amountController,
                        labelText: 'Amount *',
                        hintText: '0.00',
                        prefixIcon: Icons.currency_rupee,
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

        // If no trip selected, try to use active trip
        if (_selectedTripId == null && activeTrips.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final activeTrip = activeTripAsync.value;
              setState(() {
                _selectedTripId = activeTrip?.trip.id ?? activeTrips.first.trip.id;
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
                  value: _selectedTripId,
                  isExpanded: true,
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
                      return DropdownMenuItem<String>(
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
