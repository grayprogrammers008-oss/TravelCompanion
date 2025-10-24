import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Storage Service
/// Handles file uploads to Supabase Storage
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _supabase = Supabase.instance.client;
  static const String _bucketName = 'message-attachments';

  /// Upload image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadImage({
    required File file,
    required String tripId,
    required String messageId,
    Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('🔵 [Storage] Uploading image...');
      debugPrint('   Trip ID: $tripId');
      debugPrint('   Message ID: $messageId');

      // Generate unique filename
      final extension = file.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$extension';
      final filePath = '$tripId/$fileName';

      debugPrint('   File path: $filePath');

      // Read file as bytes
      final fileBytes = await file.readAsBytes();
      final fileSize = fileBytes.length;

      debugPrint('   File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Determine content type
      final contentType = _getContentType(extension);

      // Upload to Supabase Storage
      await _supabase.storage.from(_bucketName).uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
            ),
          );

      debugPrint('   ✅ File uploaded successfully');

      // Get public URL
      final publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(filePath);

      debugPrint('   ✅ Public URL: $publicUrl');

      return publicUrl;
    } catch (e, stackTrace) {
      debugPrint('❌ [Storage] Upload failed');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Upload image with progress tracking (chunked upload)
  /// Returns the public URL of the uploaded image
  Future<String> uploadImageWithProgress({
    required File file,
    required String tripId,
    required String messageId,
    required Function(double progress) onProgress,
  }) async {
    try {
      debugPrint('🔵 [Storage] Uploading image with progress...');

      // For now, use the standard upload
      // Supabase doesn't support chunked uploads with progress yet
      // We'll simulate progress
      onProgress(0.1);

      final url = await uploadImage(
        file: file,
        tripId: tripId,
        messageId: messageId,
      );

      onProgress(1.0);

      return url;
    } catch (e) {
      debugPrint('❌ [Storage] Upload with progress failed: $e');
      rethrow;
    }
  }

  /// Delete image from Supabase Storage
  Future<void> deleteImage(String url) async {
    try {
      debugPrint('🔵 [Storage] Deleting image...');
      debugPrint('   URL: $url');

      // Extract file path from URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Find the bucket name index
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        throw Exception('Invalid storage URL');
      }

      // Get the file path (everything after bucket name)
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      debugPrint('   File path: $filePath');

      // Delete from storage
      await _supabase.storage.from(_bucketName).remove([filePath]);

      debugPrint('   ✅ Image deleted successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [Storage] Delete failed');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Get content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  /// Ensure storage bucket exists (call on app init)
  Future<void> ensureBucketExists() async {
    try {
      debugPrint('🔵 [Storage] Checking if bucket exists...');

      // Try to list files (this will fail if bucket doesn't exist)
      await _supabase.storage.from(_bucketName).list(
            path: '',
            searchOptions: const SearchOptions(limit: 1),
          );

      debugPrint('   ✅ Bucket exists');
    } catch (e) {
      debugPrint('   ⚠️ Bucket might not exist or no access: $e');
      debugPrint('   💡 Create bucket "$_bucketName" in Supabase dashboard');
      debugPrint('   💡 Make it public for message attachments');
    }
  }

  /// Get download URL for a file
  String getPublicUrl(String filePath) {
    return _supabase.storage.from(_bucketName).getPublicUrl(filePath);
  }

  /// Check if URL is a storage URL
  bool isStorageUrl(String url) {
    return url.contains(_bucketName);
  }
}
