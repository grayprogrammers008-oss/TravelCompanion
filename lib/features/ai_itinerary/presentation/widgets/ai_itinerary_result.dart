// AI Itinerary Result Widget
//
// Displays the generated AI itinerary with option to apply to trip.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../itinerary/presentation/providers/itinerary_providers.dart';
import '../../../checklists/presentation/providers/checklist_providers.dart';
import '../../domain/entities/ai_itinerary.dart';
import '../providers/ai_itinerary_providers.dart';

class AiItineraryResultPage extends ConsumerStatefulWidget {
  final AiGeneratedItinerary itinerary;
  final String? tripId;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? budget;
  final VoidCallback onBack;

  const AiItineraryResultPage({
    super.key,
    required this.itinerary,
    this.tripId,
    this.startDate,
    this.endDate,
    this.budget,
    required this.onBack,
  });

  @override
  ConsumerState<AiItineraryResultPage> createState() => _AiItineraryResultPageState();
}

class _AiItineraryResultPageState extends ConsumerState<AiItineraryResultPage> {
  // Refinement state
  late AiGeneratedItinerary _currentItinerary;
  int _refinementCount = 0;
  static const int _maxRefinements = 3;
  final TextEditingController _refinementController = TextEditingController();
  bool _isRefining = false;
  bool _isRefinementExpanded = false; // Collapsed by default to save space

  @override
  void initState() {
    super.initState();
    _currentItinerary = widget.itinerary;
  }

  @override
  void dispose() {
    _refinementController.dispose();
    super.dispose();
  }

  /// Refine the current _currentItinerary based on user's request
  Future<void> _refineItinerary(String refinementRequest) async {
    if (_refinementCount >= _maxRefinements) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum refinements reached. Please apply the _currentItinerary or start over.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (refinementRequest.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter what you\'d like to change')),
        );
      }
      return;
    }

    setState(() {
      _isRefining = true;
    });

    debugPrint('🔄 Refining _currentItinerary with: $refinementRequest');

    try {
      // Call the AI service to refine the _currentItinerary
      final aiService = ref.read(multiProviderAiServiceProvider);
      final refinedItinerary = await aiService.refineItinerary(
        currentItinerary: _currentItinerary,
        refinementRequest: refinementRequest,
      );

      if (mounted) {
        setState(() {
          _currentItinerary = refinedItinerary;
          _refinementCount++;
          _isRefining = false;
          _refinementController.clear();
        });

        final remaining = _maxRefinements - _refinementCount;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Itinerary updated! ${remaining > 0 ? '$remaining refinement${remaining > 1 ? 's' : ''} remaining' : 'No refinements left'}.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Refinement error: $e');
      if (mounted) {
        setState(() {
          _isRefining = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refine _currentItinerary: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: themeData.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _showDiscardDialog(context),
          tooltip: 'Go back',
        ),
        title: const Text(
          'Your AI Itinerary',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: themeData.primaryGradient,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.share, color: Colors.white),
            onSelected: (value) async {
              switch (value) {
                case 'whatsapp':
                  final success = await _currentItinerary.shareToWhatsAppItinerary();
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open WhatsApp. Please install WhatsApp to share.'),
                      ),
                    );
                  }
                  break;
                case 'whatsapp_compact':
                  final success = await _currentItinerary.shareToWhatsAppItinerary(compact: true);
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open WhatsApp. Please install WhatsApp to share.'),
                      ),
                    );
                  }
                  break;
                case 'whatsapp_contact':
                  _showPhoneNumberDialog(context);
                  break;
                case 'share':
                  await _currentItinerary.shareGeneralItinerary();
                  break;
                case 'copy':
                  final text = ShareService.formatAiItinerary(_currentItinerary);
                  await ShareService.copyToClipboard(text, context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'whatsapp',
                child: Row(
                  children: [
                    Icon(Icons.chat, color: Color(0xFF25D366)),
                    SizedBox(width: 12),
                    Text('WhatsApp (Full)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'whatsapp_compact',
                child: Row(
                  children: [
                    Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                    SizedBox(width: 12),
                    Text('WhatsApp (Summary)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'whatsapp_contact',
                child: Row(
                  children: [
                    Icon(Icons.contact_phone, color: Color(0xFF25D366)),
                    SizedBox(width: 12),
                    Text('WhatsApp to Contact'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined),
                    SizedBox(width: 12),
                    Text('Share via...'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy_outlined),
                    SizedBox(width: 12),
                    Text('Copy to clipboard'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingSm),
                        decoration: BoxDecoration(
                          color: themeData.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: themeData.primaryColor,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentItinerary.destination,
                              style: context.titleStyle.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${_currentItinerary.durationDays} days${_currentItinerary.budget != null ? ' • ₹${_currentItinerary.budget!.toStringAsFixed(0)}' : ''}',
                              style: context.bodyStyle.copyWith(
                                color: context.textColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Summary removed to maximize space for itinerary content
                  // Users can see the full itinerary in the tabs below
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: themeData.primaryColor,
                unselectedLabelColor: context.textColor.withValues(alpha: 0.5),
                indicatorColor: themeData.primaryColor,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.route, size: 20),
                    text: 'Itinerary (${_currentItinerary.days.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.checklist, size: 20),
                    text: 'Packing (${_currentItinerary.packingList.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.lightbulb_outline, size: 20),
                    text: 'Tips (${_currentItinerary.tips.length})',
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildItineraryTab(context),
                  _buildPackingTab(context),
                  _buildTipsTab(context),
                ],
              ),
            ),

            // Collapsible Refinement Section (3 revisions like Trip Wizard)
            if (_refinementCount < _maxRefinements)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.blue.shade200),
                  ),
                ),
                child: _isRefinementExpanded
                    // Expanded: Show full input area
                    ? Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_fix_high, color: themeData.primaryColor, size: 20),
                                const SizedBox(width: AppTheme.spacingSm),
                                Text(
                                  'Refine Itinerary',
                                  style: context.titleStyle.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: themeData.primaryColor,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingSm,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: themeData.primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_maxRefinements - _refinementCount} left',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingSm),
                                // Collapse button
                                GestureDetector(
                                  onTap: () => setState(() => _isRefinementExpanded = false),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: themeData.primaryColor,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _refinementController,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: 'e.g., "Add a cooking class" or "More budget-friendly"',
                                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                        borderSide: BorderSide(color: themeData.primaryColor, width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingMd,
                                        vertical: AppTheme.spacingSm,
                                      ),
                                    ),
                                    maxLines: 1,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _refineItinerary(_refinementController.text),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingSm),
                                ElevatedButton(
                                  onPressed: _isRefining
                                      ? null
                                      : () => _refineItinerary(_refinementController.text),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeData.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingMd,
                                      vertical: AppTheme.spacingMd,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    ),
                                  ),
                                  child: _isRefining
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.send, size: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    // Collapsed: Show compact button bar
                    : InkWell(
                        onTap: () => setState(() => _isRefinementExpanded = true),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd,
                            vertical: AppTheme.spacingSm,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_fix_high, color: themeData.primaryColor, size: 18),
                              const SizedBox(width: AppTheme.spacingSm),
                              Text(
                                'Tap to refine itinerary',
                                style: context.bodyStyle.copyWith(
                                  color: themeData.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: themeData.primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_maxRefinements - _refinementCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              Icon(Icons.keyboard_arrow_up, color: themeData.primaryColor, size: 20),
                            ],
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppTheme.spacingMd,
          AppTheme.spacingMd,
          AppTheme.spacingMd,
          AppTheme.spacingMd + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Close button to exit without creating trip
            OutlinedButton.icon(
              onPressed: () => _showDiscardDialog(context),
              icon: const Icon(Icons.close),
              label: const Text('Discard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.neutral600,
                side: const BorderSide(color: AppTheme.neutral300),
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingMd,
                  horizontal: AppTheme.spacingMd,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            // If we have a widget.tripId, show "Apply to Trip" as primary action
            // Otherwise show "Create Trip" as primary action
            if (widget.tripId != null) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _applyToExistingTrip(context, ref),
                  icon: const Icon(Icons.check),
                  label: const Text('Apply to Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeData.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _createTripFromItinerary(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeData.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show discard confirmation dialog
  void _showDiscardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 12),
            Text('Discard Itinerary?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to discard this AI-generated _currentItinerary? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Clear the _currentItinerary and navigate back to home
              widget.onBack();
              if (context.mounted) {
                context.go('/home');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  /// Show phone number input dialog for WhatsApp sharing
  void _showPhoneNumberDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.contact_phone, color: Color(0xFF25D366)),
            SizedBox(width: 12),
            Text('Share to Contact'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the phone number with country code (e.g., 919876543210)',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '919876543210',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (cleaned.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop();
                final text = ShareService.formatAiItinerary(_currentItinerary);
                final success = await ShareService.shareToWhatsApp(
                  text,
                  phoneNumber: phoneController.text,
                );
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open WhatsApp. Please check the phone number and try again.'),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Send'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to create trip page with pre-filled data
  void _createTripFromItinerary(BuildContext context) {
    // Build query parameters
    final queryParams = <String, String>{
      'destination': _currentItinerary.destination,
      'durationDays': _currentItinerary.durationDays.toString(),
    };

    if (widget.startDate != null) {
      queryParams['startDate'] = widget.startDate!.toIso8601String();
    }
    if (widget.endDate != null) {
      queryParams['endDate'] = widget.endDate!.toIso8601String();
    }
    if (widget.budget != null) {
      queryParams['budget'] = widget.budget.toString();
    }

    // Navigate to create trip page with query parameters
    final uri = Uri(path: '/trips/create', queryParameters: queryParams);
    context.push(uri.toString());
  }

  /// Apply _currentItinerary to an existing trip
  Future<void> _applyToExistingTrip(BuildContext context, WidgetRef ref) async {
    if (widget.tripId == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Applying itinerary to trip...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final itineraryController = ref.read(itineraryControllerProvider.notifier);
      final checklistController = ref.read(checklistControllerProvider.notifier);
      final currentUserId = SupabaseClientWrapper.currentUserId;

      int activitiesCount = 0;
      int checklistsCount = 0;
      int checklistItemsCount = 0;

      // Create itinerary items for each activity
      for (final day in _currentItinerary.days) {
        int orderIndex = 0;
        for (final activity in day.activities) {
          // Parse start time if available
          DateTime? activityStartTime;
          DateTime? activityEndTime;

          if (widget.startDate != null) {
            final dayDate = widget.startDate!.add(Duration(days: day.dayNumber - 1));

            if (activity.startTime != null) {
              activityStartTime = _parseTimeToDateTime(activity.startTime!, dayDate);
            }
            if (activity.endTime != null) {
              activityEndTime = _parseTimeToDateTime(activity.endTime!, dayDate);
            }
          }

          // Build description with tip if available
          String? fullDescription = activity.description;
          if (activity.tip != null && activity.tip!.isNotEmpty) {
            fullDescription = fullDescription != null
                ? '$fullDescription\n\n💡 Tip: ${activity.tip}'
                : '💡 Tip: ${activity.tip}';
          }

          await itineraryController.createItem(
            tripId: widget.tripId!,
            title: activity.title,
            description: fullDescription,
            location: activity.location,
            startTime: activityStartTime,
            endTime: activityEndTime,
            dayNumber: day.dayNumber,
            orderIndex: orderIndex,
          );

          activitiesCount++;
          orderIndex++;
        }
      }

      // Create checklists from packing list (grouped by category)
      if (kDebugMode) {
        debugPrint('📋 Packing list count: ${_currentItinerary.packingList.length}');
        debugPrint('📋 Current user ID: $currentUserId');
      }

      if (_currentItinerary.packingList.isNotEmpty && currentUserId != null) {
        // Group packing items by category
        final categories = <String, List<AiPackingItem>>{};
        for (final item in _currentItinerary.packingList) {
          final category = item.category ?? 'Other';
          categories.putIfAbsent(category, () => []).add(item);
        }

        if (kDebugMode) {
          debugPrint('📋 Creating ${categories.length} checklists from AI packing list');
          debugPrint('📋 Categories: ${categories.keys.toList()}');
        }

        // Create a checklist for each category
        for (final entry in categories.entries) {
          final categoryName = entry.key;
          final items = entry.value;

          if (kDebugMode) {
            debugPrint('📋 Creating checklist for category: $categoryName with ${items.length} items');
          }

          // Create the checklist
          final checklist = await checklistController.createChecklist(
            tripId: widget.tripId!,
            name: 'Packing: $categoryName',
            createdBy: currentUserId,
          );

          if (kDebugMode) {
            debugPrint('📋 Checklist created: ${checklist?.id ?? "NULL - FAILED!"}');
            if (checklist == null) {
              debugPrint('❌ Failed to create checklist! Check controller state for error.');
              final controllerState = ref.read(checklistControllerProvider);
              debugPrint('❌ Controller error: ${controllerState.error}');
            }
          }

          if (checklist != null) {
            checklistsCount++;

            // Add items to the checklist
            for (final packingItem in items) {
              // Include "Essential" marker in title if item is essential
              final itemTitle = packingItem.isEssential
                  ? '⭐ ${packingItem.item}'
                  : packingItem.item;

              final addedItem = await checklistController.addItem(
                checklistId: checklist.id,
                title: itemTitle,
              );

              if (kDebugMode && addedItem == null) {
                debugPrint('❌ Failed to add item: $itemTitle');
              }

              checklistItemsCount++;
            }

            if (kDebugMode) {
              debugPrint('✅ Created checklist "$categoryName" with ${items.length} items');
            }
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Skipping checklist creation: packingList empty=${_currentItinerary.packingList.isEmpty}, userId null=${currentUserId == null}');
        }
      }

      // Clear the success message from controller to prevent repeated SnackBars
      // on the _currentItinerary list page (which listens for successMessage changes)
      itineraryController.clearSuccessMessage();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        String message = 'Successfully added $activitiesCount activities';
        if (checklistsCount > 0) {
          message += ' and $checklistItemsCount packing items in $checklistsCount checklists';
        }
        message += ' to your trip!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate to the trip's itinerary page
        context.go('/trips/${widget.tripId}/itinerary');
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply itinerary: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Parse a time string (e.g., "09:00 AM", "14:30") to DateTime with the given date
  DateTime? _parseTimeToDateTime(String timeStr, DateTime date) {
    try {
      // Try to parse various time formats
      final cleanTime = timeStr.trim().toUpperCase();

      // Try "HH:MM AM/PM" format
      final amPmRegex = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$');
      final match = amPmRegex.firstMatch(cleanTime);

      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final period = match.group(3);

        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return DateTime(date.year, date.month, date.day, hour, minute);
      }

      // Try 24-hour format "HH:MM"
      final parts = cleanTime.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
        if (hour != null && minute != null) {
          return DateTime(date.year, date.month, date.day, hour, minute);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Widget _buildItineraryTab(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: _currentItinerary.days.length,
      itemBuilder: (context, index) {
        final day = _currentItinerary.days[index];
        return _buildDayCard(context, day);
      },
    );
  }

  Widget _buildDayCard(BuildContext context, AiItineraryDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: day.dayNumber <= 2,
          tilePadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${day.dayNumber}',
                  style: context.titleStyle.copyWith(
                    color: context.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.title ?? 'Day ${day.dayNumber}',
                      style: context.titleStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (day.description != null)
                      Text(
                        day.description!,
                        style: context.bodyStyle.copyWith(
                          fontSize: 12,
                          color: context.textColor.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '${day.activities.length} activities',
                  style: context.bodyStyle.copyWith(
                    fontSize: 11,
                    color: context.textColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                0,
                AppTheme.spacingMd,
                AppTheme.spacingMd,
              ),
              child: Column(
                children: day.activities.map((activity) {
                  return _buildActivityCard(context, activity);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, AiItineraryActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingXs),
                decoration: BoxDecoration(
                  color: activity.category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                ),
                child: Icon(
                  activity.category.icon,
                  size: 16,
                  color: activity.category.color,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  activity.title,
                  style: context.titleStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (activity.startTime != null)
                Text(
                  activity.startTime!,
                  style: context.bodyStyle.copyWith(
                    fontSize: 12,
                    color: context.textColor.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          if (activity.description != null) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              activity.description!,
              style: context.bodyStyle.copyWith(
                fontSize: 13,
                color: context.textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              if (activity.location != null) ...[
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: context.textColor.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    activity.location!,
                    style: context.bodyStyle.copyWith(
                      fontSize: 12,
                      color: context.textColor.withValues(alpha: 0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (activity.estimatedCost != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  ),
                  child: Text(
                    '₹${activity.estimatedCost!.toStringAsFixed(0)}',
                    style: context.bodyStyle.copyWith(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (activity.tip != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      activity.tip!,
                      style: context.bodyStyle.copyWith(
                        fontSize: 11,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPackingTab(BuildContext context) {
    if (_currentItinerary.packingList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_outlined,
              size: 64,
              color: AppTheme.neutral300,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No packing suggestions',
              style: context.titleStyle.copyWith(
                color: context.textColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Group by category
    final categories = <String, List<AiPackingItem>>{};
    for (final item in _currentItinerary.packingList) {
      final category = item.category ?? 'Other';
      categories.putIfAbsent(category, () => []).add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories.keys.elementAt(index);
        final items = categories[category]!;

        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Row(
                  children: [
                    Text(
                      category.toUpperCase(),
                      style: context.titleStyle.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.textColor.withValues(alpha: 0.5),
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${items.length} items',
                      style: context.bodyStyle.copyWith(
                        fontSize: 12,
                        color: context.textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.isEssential
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 18,
                          color: item.isEssential
                              ? context.primaryColor
                              : context.textColor.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Text(
                            item.item,
                            style: context.bodyStyle.copyWith(
                              fontWeight:
                                  item.isEssential ? FontWeight.w600 : null,
                            ),
                          ),
                        ),
                        if (item.isEssential)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingXs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusXs),
                            ),
                            child: Text(
                              'Essential',
                              style: context.bodyStyle.copyWith(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )),
              const SizedBox(height: AppTheme.spacingSm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipsTab(BuildContext context) {
    if (_currentItinerary.tips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: AppTheme.neutral300,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No tips available',
              style: context.titleStyle.copyWith(
                color: context.textColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: _currentItinerary.tips.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: context.titleStyle.copyWith(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  _currentItinerary.tips[index],
                  style: context.bodyStyle.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
