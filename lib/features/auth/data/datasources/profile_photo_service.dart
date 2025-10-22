import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';

/// Service for handling profile photo uploads to Supabase Storage
class ProfilePhotoService {
  final SupabaseClient _client = SupabaseClientWrapper.client;
  final ImagePicker _imagePicker = ImagePicker();

  static const String bucketName = 'avatars';

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking image: $e');
      }
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error taking photo: $e');
      }
      throw Exception('Failed to take photo: $e');
    }
  }

  /// Upload profile photo to Supabase Storage
  Future<String> uploadProfilePhoto({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      if (kDebugMode) {
        print('📤 Uploading profile photo for user: $userId');
      }

      // Create file path: avatars/userId/profile.jpg
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$userId/$fileName';

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      await _client.storage.from(bucketName).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _client.storage.from(bucketName).getPublicUrl(filePath);

      if (kDebugMode) {
        print('✅ Photo uploaded successfully');
        print('   URL: $publicUrl');
      }

      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Photo upload failed: $e');
      }
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Delete profile photo from Supabase Storage
  Future<void> deleteProfilePhoto(String avatarUrl) async {
    try {
      if (kDebugMode) {
        print('🗑️ Deleting profile photo');
      }

      // Extract file path from URL
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;

      // Find bucket name and file path
      final bucketIndex = pathSegments.indexOf('object');
      if (bucketIndex == -1 || bucketIndex + 2 >= pathSegments.length) {
        throw Exception('Invalid avatar URL format');
      }

      final filePath = pathSegments.sublist(bucketIndex + 2).join('/');

      // Delete from storage
      await _client.storage.from(bucketName).remove([filePath]);

      if (kDebugMode) {
        print('✅ Photo deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Photo deletion failed: $e');
      }
      // Don't throw - deletion failure shouldn't block profile update
    }
  }
}
