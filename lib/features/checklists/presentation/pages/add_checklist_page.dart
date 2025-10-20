import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createChecklist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authDataSource = ref.read(authLocalDataSourceProvider);
      final userId = authDataSource.currentUserId;

      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }

      final controller = ref.read(checklistControllerProvider.notifier);
      final checklist = await controller.createChecklist(
        tripId: widget.tripId,
        name: _nameController.text.trim(),
        createdBy: userId,
      );

      if (mounted) {
        if (checklist != null) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created "${checklist.name}"'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create checklist'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
    final themeData = context.appThemeData;

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        title: const Text('New Checklist'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  Icons.checklist,
                  size: 64,
                  color: themeData.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing2xl),

            // Name field
            Text(
              'Checklist Name',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.neutral900,
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
              autofocus: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Helper text
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.neutral700,
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
                    : const Text(
                        'Create Checklist',
                        style: TextStyle(
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
}
