import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Image Picker Service
/// Handles image selection from camera or gallery
class ImagePickerService {
  static final ImagePickerService _instance = ImagePickerService._internal();
  factory ImagePickerService() => _instance;
  ImagePickerService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<File?> pickImageFromGallery({
    int maxWidth = 1920,
    int maxHeight = 1920,
    int imageQuality = 85,
  }) async {
    try {
      debugPrint('🔵 [ImagePicker] Picking image from gallery...');

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFile == null) {
        debugPrint('   ⚠️ No image selected');
        return null;
      }

      final file = File(pickedFile.path);
      final fileSize = await file.length();
      debugPrint('   ✅ Image selected: ${pickedFile.name}');
      debugPrint('   Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      return file;
    } catch (e, stackTrace) {
      debugPrint('❌ [ImagePicker] Failed to pick image from gallery');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return null;
    }
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera({
    int maxWidth = 1920,
    int maxHeight = 1920,
    int imageQuality = 85,
  }) async {
    try {
      debugPrint('🔵 [ImagePicker] Taking photo from camera...');

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFile == null) {
        debugPrint('   ⚠️ No photo taken');
        return null;
      }

      final file = File(pickedFile.path);
      final fileSize = await file.length();
      debugPrint('   ✅ Photo taken: ${pickedFile.name}');
      debugPrint('   Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      return file;
    } catch (e, stackTrace) {
      debugPrint('❌ [ImagePicker] Failed to take photo from camera');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>?> pickMultipleImages({
    int maxWidth = 1920,
    int maxHeight = 1920,
    int imageQuality = 85,
    int? limit,
  }) async {
    try {
      debugPrint('🔵 [ImagePicker] Picking multiple images from gallery...');

      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFiles.isEmpty) {
        debugPrint('   ⚠️ No images selected');
        return null;
      }

      // Apply limit if specified
      final filesToProcess = limit != null
          ? pickedFiles.take(limit).toList()
          : pickedFiles;

      final files = filesToProcess.map((xFile) => File(xFile.path)).toList();

      debugPrint('   ✅ ${files.length} images selected');

      return files;
    } catch (e, stackTrace) {
      debugPrint('❌ [ImagePicker] Failed to pick multiple images');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return null;
    }
  }

  /// Validate image file
  bool validateImage(File file, {int maxSizeInMB = 10}) {
    try {
      // Check if file exists
      if (!file.existsSync()) {
        debugPrint('❌ [ImagePicker] File does not exist');
        return false;
      }

      // Check file size
      final fileSize = file.lengthSync();
      final fileSizeInMB = fileSize / 1024 / 1024;

      if (fileSizeInMB > maxSizeInMB) {
        debugPrint('❌ [ImagePicker] File too large: ${fileSizeInMB.toStringAsFixed(2)} MB');
        return false;
      }

      // Check file extension
      final extension = file.path.split('.').last.toLowerCase();
      final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

      if (!validExtensions.contains(extension)) {
        debugPrint('❌ [ImagePicker] Invalid file extension: $extension');
        return false;
      }

      debugPrint('✅ [ImagePicker] Image validation passed');
      return true;
    } catch (e) {
      debugPrint('❌ [ImagePicker] Validation error: $e');
      return false;
    }
  }

  /// Get image file size in MB
  double getFileSizeInMB(File file) {
    final fileSize = file.lengthSync();
    return fileSize / 1024 / 1024;
  }

  /// Get image file extension
  String getFileExtension(File file) {
    return file.path.split('.').last.toLowerCase();
  }
}
