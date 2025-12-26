import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/network/supabase_client.dart';
import '../../data/packing_templates.dart';
import '../../data/smart_checklist_generator.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../itinerary/presentation/providers/itinerary_providers.dart';
import '../providers/checklist_providers.dart';

class AddChecklistPage extends ConsumerStatefulWidget {
  final String tripId;

  const AddChecklistPage({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<AddChecklistPage> createState() => _AddChecklistPageState();
}

class _AddChecklistPageState extends ConsumerState<AddChecklistPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  PackingTemplate? _selectedTemplate;
  bool _useSmartChecklist = false;
  List<SmartChecklistItem>? _smartItems;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createChecklist() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current user ID from Supabase (online-only mode)
      debugPrint('========== CREATE CHECKLIST START ==========');
      debugPrint('Checking user authentication...');

      final userId = SupabaseClientWrapper.currentUserId;
      debugPrint('User ID: ${userId ?? "NULL - USER NOT LOGGED IN"}');

      if (userId == null) {
        debugPrint('ERROR: User not logged in');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in. Please sign in and try again.'),
              backgroundColor: AppTheme.error,
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Prepare data
      final checklistName = _nameController.text.trim();
      final tripId = widget.tripId;

      // Debug logging
      debugPrint('Checklist Name: "$checklistName"');
      debugPrint('Trip ID: "$tripId"');
      debugPrint('User ID: "$userId"');
      debugPrint('Template: ${_selectedTemplate?.name ?? "None"}');
      debugPrint('Smart Checklist: $_useSmartChecklist');
      debugPrint('Calling controller.createChecklist...');

      final controller = ref.read(checklistControllerProvider.notifier);
      final checklist = await controller.createChecklist(
        tripId: tripId,
        name: checklistName,
        createdBy: userId,
      );

      debugPrint('Controller returned: ${checklist != null ? "SUCCESS" : "NULL (FAILED)"}');

      if (mounted) {
        if (checklist != null) {
          debugPrint('✅ Checklist created successfully!');
          debugPrint('   ID: ${checklist.id}');
          debugPrint('   Name: ${checklist.name}');
          debugPrint('   Trip ID: ${checklist.tripId}');
          debugPrint('   Created By: ${checklist.createdBy}');
          debugPrint('   Created At: ${checklist.createdAt}');

          // If smart checklist is enabled, add smart items
          if (_useSmartChecklist && _smartItems != null) {
            debugPrint('Adding ${_smartItems!.length} smart checklist items...');
            for (final smartItem in _smartItems!) {
              await controller.addItem(
                checklistId: checklist.id,
                title: smartItem.title,
              );
            }
            debugPrint('✅ All smart items added!');
          }
          // If a template was selected, add all template items
          else if (_selectedTemplate != null) {
            debugPrint('Adding ${_selectedTemplate!.items.length} items from template...');
            for (final itemTitle in _selectedTemplate!.items) {
              await controller.addItem(
                checklistId: checklist.id,
                title: itemTitle,
              );
            }
            debugPrint('✅ All template items added!');
          }

          debugPrint('========== CREATE CHECKLIST SUCCESS ==========');

          // Invalidate the trip checklists provider to refresh the list
          ref.invalidate(tripChecklistsProvider(tripId));

          Navigator.of(context).pop(true);

          final itemCount = _useSmartChecklist && _smartItems != null
              ? _smartItems!.length
              : _selectedTemplate?.items.length;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(itemCount != null
                  ? 'Created "${checklist.name}" with $itemCount items'
                  : 'Created "${checklist.name}"'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // Check controller state for error
          final error = ref.read(checklistControllerProvider).error;
          debugPrint('❌ Failed to create checklist');
          debugPrint('   Controller Error: ${error ?? "No error message"}');
          debugPrint('========== CREATE CHECKLIST FAILED ==========');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create checklist${error != null ? ':\n$error' : ''}'),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ EXCEPTION during checklist creation');
      debugPrint('   Exception Type: ${e.runtimeType}');
      debugPrint('   Exception Message: $e');
      debugPrint('   Stack Trace:');
      debugPrint('$stackTrace');
      debugPrint('========== CREATE CHECKLIST EXCEPTION ==========');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating checklist:\n${e.toString()}'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectTemplate(PackingTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _useSmartChecklist = false;
      _smartItems = null;
      _nameController.text = template.name;
    });
  }

  Future<void> _selectSmartChecklist() async {
    // Fetch trip data and itinerary
    final tripAsync = ref.read(tripProvider(widget.tripId));
    final itineraryAsync = ref.read(tripItineraryProvider(widget.tripId));

    tripAsync.when(
      data: (tripWithMembers) {
        final trip = tripWithMembers.trip;

        // Get itinerary items if available
        final itinerary = itineraryAsync.when(
          data: (items) => items,
          loading: () => <dynamic>[],
          error: (_, _) => <dynamic>[],
        );

        // Generate smart checklist
        final smartItems = SmartChecklistGenerator.generate(
          trip: trip,
          itinerary: itinerary.isNotEmpty ? itinerary.cast() : null,
        );

        setState(() {
          _useSmartChecklist = true;
          _smartItems = smartItems;
          _selectedTemplate = null;
          _nameController.text = 'Smart Packing List for ${trip.destination ?? trip.name}';
        });
      },
      loading: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loading trip data...')),
          );
        }
      },
      error: (error, _) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load trip: $error'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      },
    );
  }

  void _clearTemplate() {
    setState(() {
      _selectedTemplate = null;
      _useSmartChecklist = false;
      _smartItems = null;
      _nameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'New Checklist',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: themeData.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: themeData.primaryGradient,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          children: [
            // Icon header
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeData.primaryColor.withValues(alpha: 0.1),
                      themeData.primaryColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _selectedTemplate != null ? Icons.inventory_2 : Icons.checklist,
                  size: 64,
                  color: themeData.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing2xl),

            // Template section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start with a Template',
                  style: context.titleSmall.copyWith(
                    color: context.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_selectedTemplate != null || _useSmartChecklist)
                  TextButton.icon(
                    onPressed: _clearTemplate,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.neutral600,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),

            // Template grid with Smart Packing List
            SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Smart Packing List (first option)
                  Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                    child: _buildSmartChecklistCard(themeData),
                  ),
                  // Regular templates
                  ...PackingTemplates.all.map((template) {
                    final isSelected = _selectedTemplate?.id == template.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                      child: _buildTemplateCard(template, isSelected, themeData),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Selected template/smart checklist preview
            if (_useSmartChecklist && _smartItems != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeData.primaryColor.withValues(alpha: 0.1),
                      Colors.purple.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: themeData.primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [themeData.primaryColor, Colors.purple],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Packing List',
                                style: context.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${_smartItems!.length} items (AI-generated)',
                                style: context.bodySmall.copyWith(
                                  color: AppTheme.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.check_circle,
                          color: themeData.primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    const Divider(),
                    const SizedBox(height: AppTheme.spacingXs),
                    // Group by category
                    ...(_smartItems!
                        .take(8)
                        .map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    _getPriorityIcon(item.priority),
                                    size: 14,
                                    color: _getPriorityColor(item.priority),
                                  ),
                                  const SizedBox(width: AppTheme.spacingXs),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: context.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ))),
                    if (_smartItems!.length > 8)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+ ${_smartItems!.length - 8} more items',
                          style: context.bodySmall.copyWith(
                            color: themeData.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ] else if (_selectedTemplate != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: themeData.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: themeData.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _selectedTemplate!.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedTemplate!.name,
                                style: context.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${_selectedTemplate!.items.length} items included',
                                style: context.bodySmall.copyWith(
                                  color: AppTheme.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.check_circle,
                          color: themeData.primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    const Divider(),
                    const SizedBox(height: AppTheme.spacingXs),
                    // Show first 5 items as preview
                    ...(_selectedTemplate!.items.take(5).map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_box_outline_blank,
                                size: 16,
                                color: AppTheme.neutral400,
                              ),
                              const SizedBox(width: AppTheme.spacingXs),
                              Text(
                                item,
                                style: context.bodySmall,
                              ),
                            ],
                          ),
                        ))),
                    if (_selectedTemplate!.items.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+ ${_selectedTemplate!.items.length - 5} more items',
                          style: context.bodySmall.copyWith(
                            color: themeData.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            // Divider with "or"
            if (_selectedTemplate == null) ...[
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                    child: Text(
                      'or create your own',
                      style: context.bodySmall.copyWith(
                        color: AppTheme.neutral500,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            // Name field
            Text(
              'Checklist Name',
              style: context.titleSmall.copyWith(
                    color: context.textColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Packing List, Things to Do',
                prefixIcon: const Icon(Icons.label_outline),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.neutral200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.neutral200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(color: themeData.primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.error),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a checklist name';
                }
                if (value.length > 100) {
                  return 'Name must be 100 characters or less';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
              autofocus: _selectedTemplate == null,
              enabled: !_isLoading,
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Helper text
            if (_selectedTemplate == null)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: themeData.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: themeData.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: themeData.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        'You can add items to this checklist after creating it',
                        style: context.bodySmall.copyWith(
                              color: context.textColor.withValues(alpha: 0.87),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppTheme.spacing2xl),

            // Create button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createChecklist,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _useSmartChecklist && _smartItems != null
                            ? 'Create with ${_smartItems!.length} Smart Items'
                            : _selectedTemplate != null
                                ? 'Create with ${_selectedTemplate!.items.length} Items'
                                : 'Create Checklist',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(PackingTemplate template, bool isSelected, dynamic themeData) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _selectTemplate(template),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        padding: const EdgeInsets.all(AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: isSelected
              ? themeData.primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected
                ? themeData.primaryColor
                : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeData.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : AppTheme.shadowSm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              template.icon,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              template.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? themeData.primaryColor : AppTheme.neutral700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${template.items.length} items',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartChecklistCard(dynamic themeData) {
    final isSelected = _useSmartChecklist;
    return GestureDetector(
      onTap: _isLoading ? null : _selectSmartChecklist,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        padding: const EdgeInsets.all(AppTheme.spacingSm),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    themeData.primaryColor.withValues(alpha: 0.2),
                    Colors.purple.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected
                ? themeData.primaryColor
                : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeData.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppTheme.shadowSm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeData.primaryColor, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Smart\nPacking',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? themeData.primaryColor : AppTheme.neutral700,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: 2),
            Text(
              'AI-generated',
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? themeData.primaryColor : AppTheme.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPriorityIcon(SmartItemPriority priority) {
    switch (priority) {
      case SmartItemPriority.critical:
        return Icons.error;
      case SmartItemPriority.high:
        return Icons.priority_high;
      case SmartItemPriority.medium:
        return Icons.circle;
      case SmartItemPriority.low:
        return Icons.circle_outlined;
    }
  }

  Color _getPriorityColor(SmartItemPriority priority) {
    switch (priority) {
      case SmartItemPriority.critical:
        return AppTheme.error;
      case SmartItemPriority.high:
        return Colors.orange;
      case SmartItemPriority.medium:
        return Colors.blue;
      case SmartItemPriority.low:
        return AppTheme.neutral400;
    }
  }
}
