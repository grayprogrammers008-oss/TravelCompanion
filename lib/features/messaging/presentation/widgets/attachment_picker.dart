import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Attachment Picker Bottom Sheet
/// Shows options to pick image from camera or gallery
class AttachmentPicker extends StatelessWidget {
  final Function(File image) onImageSelected;

  const AttachmentPicker({
    super.key,
    required this.onImageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: AppTheme.spacingSm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.neutral300,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
              child: Row(
                children: [
                  const Icon(
                    Icons.attachment,
                    color: AppTheme.neutral700,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    'Add Attachment',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // Options
            _AttachmentOption(
              icon: Icons.camera_alt,
              iconColor: AppTheme.primaryTeal,
              backgroundColor: AppTheme.primaryPale,
              title: 'Camera',
              subtitle: 'Take a photo',
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera(context);
              },
            ),

            _AttachmentOption(
              icon: Icons.photo_library,
              iconColor: AppTheme.accentCoral,
              backgroundColor: const Color(0xFFFFE8EE),
              title: 'Gallery',
              subtitle: 'Choose from gallery',
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery(context);
              },
            ),

            const SizedBox(height: AppTheme.spacingMd),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    // Implementation will be in chat screen using ImagePickerService
    debugPrint('📸 Pick from camera');
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    // Implementation will be in chat screen using ImagePickerService
    debugPrint('🖼️ Pick from gallery');
  }

  /// Show attachment picker
  static Future<void> show(
    BuildContext context, {
    required Function(File image) onImageSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AttachmentPicker(
        onImageSelected: onImageSelected,
      ),
    );
  }
}

/// Attachment Option Widget
class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg,
          vertical: AppTheme.spacingSm,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.neutral600,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}
