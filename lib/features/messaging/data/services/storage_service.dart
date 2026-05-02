import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Storage Service
/// Handles file uploads to Supabase Storage
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService({SupabaseClient? supabase}) {
    if (supabase != null) {
      return StorageService._withClient(supabase);
    }
    return _instance;
  }
  StorageService._internal() : _supabase = Supabase.instance.client;
  StorageService._withClient(this._supabase);

  final SupabaseClient _supabase;
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

  /// Upload any file (document, image, etc.) to Supabase Storage
  /// Returns the public URL of the uploaded file
  Future<String> uploadFile({
    required File file,
    required String tripId,
    required String messageId,
    Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('🔵 [Storage] Uploading file...');
      debugPrint('   Trip ID: $tripId');
      debugPrint('   Message ID: $messageId');
      debugPrint('   File: ${file.path}');

      // Generate unique filename
      final extension = file.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$extension';
      final filePath = '$tripId/documents/$fileName';

      debugPrint('   File path: $filePath');

      // Read file as bytes
      final fileBytes = await file.readAsBytes();
      final fileSize = fileBytes.length;

      debugPrint('   File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Determine content type
      final contentType = _getContentType(extension);
      debugPrint('   Content type: $contentType');

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
      debugPrint('❌ [Storage] File upload failed');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Get content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'rtf':
        return 'application/rtf';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/vnd.rar';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get file icon based on extension
  static String getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'ppt':
      case 'pptx':
        return '📽️';
      case 'txt':
        return '📃';
      case 'csv':
        return '📈';
      case 'zip':
      case 'rar':
        return '🗜️';
      default:
        return '📎';
    }
  }

  /// Get human-readable file type name
  static String getFileTypeName(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'PDF Document';
      case 'doc':
      case 'docx':
        return 'Word Document';
      case 'xls':
      case 'xlsx':
        return 'Excel Spreadsheet';
      case 'ppt':
      case 'pptx':
        return 'PowerPoint';
      case 'txt':
        return 'Text File';
      case 'csv':
        return 'CSV File';
      case 'zip':
        return 'ZIP Archive';
      case 'rar':
        return 'RAR Archive';
      default:
        return 'File';
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
