import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/features/auth/data/datasources/profile_photo_service.dart';
import 'package:travel_crew/core/constants/app_constants.dart';

// Generate mocks for ImagePicker and Supabase components
@GenerateMocks([
  ImagePicker,
  SupabaseClient,
  SupabaseStorageClient,
  StorageFileApi,
])
import 'profile_photo_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfilePhotoService', () {
    late ProfilePhotoService service;
    late MockImagePicker mockImagePicker;
    late MockSupabaseClient mockSupabaseClient;
    late MockSupabaseStorageClient mockStorageClient;
    late MockStorageFileApi mockStorageFileApi;

    setUp(() {
      mockImagePicker = MockImagePicker();
      mockSupabaseClient = MockSupabaseClient();
      mockStorageClient = MockSupabaseStorageClient();
      mockStorageFileApi = MockStorageFileApi();

      // Setup Supabase client mock chain
      when(mockSupabaseClient.storage).thenReturn(mockStorageClient);
      when(mockStorageClient.from(AppConstants.profileAvatarsBucket))
          .thenReturn(mockStorageFileApi);

      service = ProfilePhotoService(
        client: mockSupabaseClient,
        imagePicker: mockImagePicker,
      );
    });

    group('pickImageFromGallery', () {
      test('should return XFile when image is picked successfully', () async {
        // Arrange
        final mockXFile = XFile('path/to/image.jpg');
        when(mockImagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        )).thenAnswer((_) async => mockXFile);

        // Act
        final result = await service.pickImageFromGallery();

        // Assert
        expect(result, isA<XFile>());
        expect(result?.path, 'path/to/image.jpg');
        verify(mockImagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        )).called(1);
      });

      test('should return null when user cancels image picking', () async {
        // Arrange
        when(mockImagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        )).thenAnswer((_) async => null);

        // Act
        final result = await service.pickImageFromGallery();

        // Assert
        expect(result, isNull);
      });

      test('should throw exception when image picking fails', () async {
        // Arrange
        when(mockImagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        )).thenThrow(Exception('Permission denied'));

        // Act & Assert
        expect(
          () => service.pickImageFromGallery(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('pickImageFromCamera', () {
      test('should return XFile when photo is taken successfully', () async {
        // Arrange
        final mockXFile = XFile('path/to/photo.jpg');
        when(mockImagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        )).thenAnswer((_) async => mockXFile);

        // Act
        final result = await service.pickImageFromCamera();

        // Assert
        expect(result, isA<XFile>());
        expect(result?.path, 'path/to/photo.jpg');
        verify(mockImagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        )).called(1);
      });

      test('should return null when user cancels camera', () async {
        // Arrange
        when(mockImagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        )).thenAnswer((_) async => null);

        // Act
        final result = await service.pickImageFromCamera();

        // Assert
        expect(result, isNull);
      });

      test('should throw exception when camera fails', () async {
        // Arrange
        when(mockImagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        )).thenThrow(Exception('Camera unavailable'));

        // Act & Assert
        expect(
          () => service.pickImageFromCamera(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('uploadProfilePhoto', () {
      test('should upload photo successfully and return public URL', () async {
        // Arrange
        final userId = 'test-user-123';
        final mockBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        final mockXFile = MockXFile();

        when(mockXFile.readAsBytes()).thenAnswer((_) async => mockBytes);

        final expectedUrl = 'https://supabase.com/storage/profile-avatars/test-user-123/profile_123.jpg';

        when(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).thenAnswer((_) async => 'uploaded');

        when(mockStorageFileApi.getPublicUrl(any))
            .thenReturn(expectedUrl);

        // Act
        final result = await service.uploadProfilePhoto(
          userId: userId,
          imageFile: mockXFile,
        );

        // Assert
        expect(result, expectedUrl);
        verify(mockXFile.readAsBytes()).called(1);
        verify(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).called(1);
        verify(mockStorageFileApi.getPublicUrl(any)).called(1);
      });

      test('should create correct file path with userId folder', () async {
        // Arrange
        final userId = 'user-abc-123';
        final mockBytes = Uint8List.fromList([1, 2, 3]);
        final mockXFile = MockXFile();

        when(mockXFile.readAsBytes()).thenAnswer((_) async => mockBytes);
        when(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).thenAnswer((_) async => 'uploaded');
        when(mockStorageFileApi.getPublicUrl(any))
            .thenReturn('https://example.com/url');

        // Act
        await service.uploadProfilePhoto(
          userId: userId,
          imageFile: mockXFile,
        );

        // Assert
        final captured = verify(mockStorageFileApi.uploadBinary(
          captureAny,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).captured;

        expect(captured[0], startsWith('user-abc-123/'));
        expect(captured[0], contains('profile_'));
        expect(captured[0], endsWith('.jpg'));
      });

      test('should throw exception when upload fails', () async {
        // Arrange
        final mockXFile = MockXFile();
        when(mockXFile.readAsBytes()).thenAnswer((_) async => Uint8List(0));
        when(mockStorageFileApi.uploadBinary(
          any,
          any,
          fileOptions: anyNamed('fileOptions'),
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => service.uploadProfilePhoto(
            userId: 'test-user',
            imageFile: mockXFile,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should use correct file options with cache control', () async {
        // Arrange
        final mockXFile = MockXFile();
        final mockBytes = Uint8List.fromList([1, 2, 3]);

        when(mockXFile.readAsBytes()).thenAnswer((_) async => mockBytes);
        when(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).thenAnswer((_) async => 'uploaded');
        when(mockStorageFileApi.getPublicUrl(any))
            .thenReturn('https://example.com/url');

        // Act
        await service.uploadProfilePhoto(
          userId: 'test-user',
          imageFile: mockXFile,
        );

        // Assert - verify FileOptions are passed correctly
        verify(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ),
        )).called(1);
      });
    });

    group('deleteProfilePhoto', () {
      test('should extract correct file path from URL and delete', () async {
        // Arrange
        final avatarUrl =
            'https://supabase.com/storage/v1/object/public/profile-avatars/user-123/profile.jpg';

        when(mockStorageFileApi.remove(any))
            .thenAnswer((_) async => []);

        // Act
        await service.deleteProfilePhoto(avatarUrl);

        // Assert
        final captured = verify(mockStorageFileApi.remove(captureAny)).captured;
        expect(captured[0], isA<List<String>>());
        expect(captured[0][0], contains('user-123/profile.jpg'));
      });

      test('should not throw exception when deletion fails', () async {
        // Arrange
        final avatarUrl =
            'https://supabase.com/storage/v1/object/public/profile-avatars/user-123/profile.jpg';

        when(mockStorageFileApi.remove(any))
            .thenThrow(Exception('File not found'));

        // Act & Assert - should not throw
        await expectLater(
          service.deleteProfilePhoto(avatarUrl),
          completes,
        );
      });

      test('should handle invalid URL format gracefully', () async {
        // Arrange
        final invalidUrl = 'not-a-valid-url';

        // Act & Assert - should not throw
        await expectLater(
          service.deleteProfilePhoto(invalidUrl),
          completes,
        );
      });

      test('should handle URL without proper segments', () async {
        // Arrange
        final shortUrl = 'https://supabase.com/storage';

        // Act & Assert - should not throw
        await expectLater(
          service.deleteProfilePhoto(shortUrl),
          completes,
        );
      });
    });

    group('Edge Cases', () {
      test('should handle empty userId in uploadProfilePhoto', () async {
        // Arrange
        final mockXFile = MockXFile();
        final mockBytes = Uint8List.fromList([1, 2, 3]);

        when(mockXFile.readAsBytes()).thenAnswer((_) async => mockBytes);
        when(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).thenAnswer((_) async => 'uploaded');
        when(mockStorageFileApi.getPublicUrl(any))
            .thenReturn('https://example.com/url');

        // Act
        final result = await service.uploadProfilePhoto(
          userId: '',
          imageFile: mockXFile,
        );

        // Assert - should still work, creates path with empty folder
        expect(result, isA<String>());
      });

      test('should handle very large file upload', () async {
        // Arrange
        final largeBytes = Uint8List(10 * 1024 * 1024); // 10MB
        final mockXFile = MockXFile();

        when(mockXFile.readAsBytes()).thenAnswer((_) async => largeBytes);
        when(mockStorageFileApi.uploadBinary(
          any,
          largeBytes,
          fileOptions: anyNamed('fileOptions'),
        )).thenAnswer((_) async => 'uploaded');
        when(mockStorageFileApi.getPublicUrl(any))
            .thenReturn('https://example.com/url');

        // Act
        final result = await service.uploadProfilePhoto(
          userId: 'test-user',
          imageFile: mockXFile,
        );

        // Assert
        expect(result, isA<String>());
      });

      test('should handle special characters in userId', () async {
        // Arrange
        final specialUserId = 'user@test#123!';
        final mockXFile = MockXFile();
        final mockBytes = Uint8List.fromList([1, 2, 3]);

        when(mockXFile.readAsBytes()).thenAnswer((_) async => mockBytes);
        when(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).thenAnswer((_) async => 'uploaded');
        when(mockStorageFileApi.getPublicUrl(any))
            .thenReturn('https://example.com/url');

        // Act
        await service.uploadProfilePhoto(
          userId: specialUserId,
          imageFile: mockXFile,
        );

        // Assert
        final captured = verify(mockStorageFileApi.uploadBinary(
          captureAny,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).captured;

        expect(captured[0], startsWith(specialUserId));
      });
    });
  });
}

// Mock XFile class for testing
class MockXFile extends Mock implements XFile {
  @override
  String get path => 'mock/path/image.jpg';

  @override
  String get name => 'image.jpg';
}
