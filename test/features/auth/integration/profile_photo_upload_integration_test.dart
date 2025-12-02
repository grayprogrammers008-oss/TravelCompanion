import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/features/auth/data/datasources/profile_photo_service.dart';
import 'package:travel_crew/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:travel_crew/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:travel_crew/features/auth/data/models/user_model.dart';

@GenerateMocks([
  AuthRemoteDataSource,
  SupabaseClient,
  SupabaseStorageClient,
  StorageFileApi,
  ImagePicker,
])
import 'profile_photo_upload_integration_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Photo Upload Integration Tests', () {
    late AuthRepositoryImpl authRepository;
    late ProfilePhotoService photoService;
    late MockAuthRemoteDataSource mockRemoteDataSource;
    late MockSupabaseClient mockSupabaseClient;
    late MockSupabaseStorageClient mockStorageClient;
    late MockStorageFileApi mockStorageFileApi;
    late MockImagePicker mockImagePicker;

    setUp(() {
      mockRemoteDataSource = MockAuthRemoteDataSource();
      mockSupabaseClient = MockSupabaseClient();
      mockStorageClient = MockSupabaseStorageClient();
      mockStorageFileApi = MockStorageFileApi();
      mockImagePicker = MockImagePicker();

      // Setup Supabase storage mock chain
      when(mockSupabaseClient.storage).thenReturn(mockStorageClient);
      when(mockStorageClient.from(any)).thenReturn(mockStorageFileApi);

      authRepository = AuthRepositoryImpl(mockRemoteDataSource);
      photoService = ProfilePhotoService(
        client: mockSupabaseClient,
        imagePicker: mockImagePicker,
      );
    });

    group('End-to-End Photo Upload Flow', () {
      test('should complete full flow: pick image -> upload -> update profile', () async {
        // Arrange
        final testUserId = 'test-user-123';
        final testEmail = 'test@example.com';
        final initialUser = UserModel(
          id: testUserId,
          email: testEmail,
          fullName: 'Test User',
          avatarUrl: null,
        );

        final mockBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        final mockXFile = MockXFile();
        when(mockXFile.readAsBytes()).thenAnswer((_) async => mockBytes);

        final uploadedUrl = 'https://supabase.com/storage/profile-avatars/$testUserId/profile_123.jpg';

        // Mock getCurrentUser
        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => initialUser);

        // Mock storage upload
        when(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).thenAnswer((_) async => 'uploaded');

        when(mockStorageFileApi.getPublicUrl(any))
            .thenReturn(uploadedUrl);

        // Mock profile update
        final updatedUser = UserModel(
          id: testUserId,
          email: testEmail,
          fullName: 'Test User',
          avatarUrl: uploadedUrl,
        );
        when(mockRemoteDataSource.updateProfile(
          userId: testUserId,
          avatarUrl: uploadedUrl,
        )).thenAnswer((_) async => updatedUser);

        // Act
        // Step 1: Upload photo
        final avatarUrl = await photoService.uploadProfilePhoto(
          userId: testUserId,
          imageFile: mockXFile,
        );

        // Step 2: Update profile with new avatar URL
        final result = await authRepository.updateProfile(
          avatarUrl: avatarUrl,
        );

        // Assert
        expect(avatarUrl, uploadedUrl);
        expect(result.avatarUrl, uploadedUrl);
        expect(result.id, testUserId);

        // Verify all steps executed
        verify(mockXFile.readAsBytes()).called(1);
        verify(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).called(1);
        verify(mockStorageFileApi.getPublicUrl(any)).called(1);
        verify(mockRemoteDataSource.updateProfile(
          userId: testUserId,
          avatarUrl: uploadedUrl,
        )).called(1);
      });

      test('should handle upload failure and not update profile', () async {
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
          () => photoService.uploadProfilePhoto(
            userId: 'test-user',
            imageFile: mockXFile,
          ),
          throwsA(isA<Exception>()),
        );

        // Verify profile update was never called
        verifyNever(mockRemoteDataSource.updateProfile(
          userId: anyNamed('userId'),
          avatarUrl: anyNamed('avatarUrl'),
        ));
      });

      test('should handle profile update failure after successful upload', () async {
        // Arrange
        final testUserId = 'test-user-123';
        final initialUser = UserModel(
          id: testUserId,
          email: 'test@example.com',
          fullName: 'Test User',
        );

        final mockBytes = Uint8List.fromList([1, 2, 3]);
        final mockXFile = MockXFile();
        when(mockXFile.readAsBytes()).thenAnswer((_) async => mockBytes);

        final uploadedUrl = 'https://example.com/avatar.jpg';

        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => initialUser);

        when(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).thenAnswer((_) async => 'uploaded');

        when(mockStorageFileApi.getPublicUrl(any))
            .thenReturn(uploadedUrl);

        when(mockRemoteDataSource.updateProfile(
          userId: testUserId,
          avatarUrl: uploadedUrl,
        )).thenThrow(Exception('Profile update failed'));

        // Act
        final avatarUrl = await photoService.uploadProfilePhoto(
          userId: testUserId,
          imageFile: mockXFile,
        );

        // Assert - upload succeeded
        expect(avatarUrl, uploadedUrl);

        // But profile update should fail
        expect(
          () => authRepository.updateProfile(avatarUrl: avatarUrl),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Photo Replacement Flow', () {
      test('should replace existing photo with new one', () async {
        // Arrange
        final testUserId = 'test-user-123';
        final oldAvatarUrl = 'https://supabase.com/storage/v1/object/public/profile-avatars/$testUserId/old_profile.jpg';
        final newAvatarUrl = 'https://supabase.com/storage/profile-avatars/$testUserId/profile_456.jpg';

        final userWithOldAvatar = UserModel(
          id: testUserId,
          email: 'test@example.com',
          fullName: 'Test User',
          avatarUrl: oldAvatarUrl,
        );

        final mockBytes = Uint8List.fromList([1, 2, 3]);
        final mockXFile = MockXFile();
        when(mockXFile.readAsBytes()).thenAnswer((_) async => mockBytes);

        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => userWithOldAvatar);

        // Mock upload of new photo
        when(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).thenAnswer((_) async => 'uploaded');

        when(mockStorageFileApi.getPublicUrl(any))
            .thenReturn(newAvatarUrl);

        // Mock deletion of old photo
        when(mockStorageFileApi.remove(any))
            .thenAnswer((_) async => []);

        final updatedUser = UserModel(
          id: testUserId,
          email: 'test@example.com',
          fullName: 'Test User',
          avatarUrl: newAvatarUrl,
        );

        when(mockRemoteDataSource.updateProfile(
          userId: testUserId,
          avatarUrl: newAvatarUrl,
        )).thenAnswer((_) async => updatedUser);

        // Act
        // Step 1: Delete old photo
        await photoService.deleteProfilePhoto(oldAvatarUrl);

        // Step 2: Upload new photo
        final newUrl = await photoService.uploadProfilePhoto(
          userId: testUserId,
          imageFile: mockXFile,
        );

        // Step 3: Update profile
        final result = await authRepository.updateProfile(
          avatarUrl: newUrl,
        );

        // Assert
        expect(result.avatarUrl, newAvatarUrl);
        expect(result.avatarUrl, isNot(oldAvatarUrl));

        // Verify old photo was deleted
        verify(mockStorageFileApi.remove(any)).called(1);
        // Verify new photo was uploaded
        verify(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).called(1);
      });
    });

    group('Concurrent Upload Handling', () {
      test('should handle multiple upload attempts gracefully', () async {
        // Arrange
        final testUserId = 'test-user-123';
        final mockBytes = Uint8List.fromList([1, 2, 3]);
        final mockXFile1 = MockXFile();
        final mockXFile2 = MockXFile();

        when(mockXFile1.readAsBytes()).thenAnswer((_) async => mockBytes);
        when(mockXFile2.readAsBytes()).thenAnswer((_) async => mockBytes);

        final url1 = 'https://example.com/profile_1.jpg';
        final url2 = 'https://example.com/profile_2.jpg';

        // Mock sequential uploads
        var callCount = 0;
        when(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).thenAnswer((_) async {
          callCount++;
          await Future.delayed(const Duration(milliseconds: 50));
          return 'uploaded_$callCount';
        });

        when(mockStorageFileApi.getPublicUrl(any))
            .thenAnswer((invocation) {
          return callCount == 1 ? url1 : url2;
        });

        // Act - Upload two photos concurrently
        final results = await Future.wait([
          photoService.uploadProfilePhoto(
            userId: testUserId,
            imageFile: mockXFile1,
          ),
          photoService.uploadProfilePhoto(
            userId: testUserId,
            imageFile: mockXFile2,
          ),
        ]);

        // Assert
        expect(results, hasLength(2));
        expect(results, contains(url1));
        expect(results, contains(url2));

        // Both uploads should complete
        verify(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).called(2);
      });
    });

    group('Error Recovery', () {
      test('should retry upload on transient network failure', () async {
        // Arrange
        final testUserId = 'test-user-123';
        final mockBytes = Uint8List.fromList([1, 2, 3]);
        final mockXFile = MockXFile();

        when(mockXFile.readAsBytes()).thenAnswer((_) async => mockBytes);

        var attemptCount = 0;
        when(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).thenAnswer((_) async {
          attemptCount++;
          if (attemptCount == 1) {
            throw Exception('Network timeout');
          }
          return 'uploaded';
        });

        when(mockStorageFileApi.getPublicUrl(any))
            .thenReturn('https://example.com/avatar.jpg');

        // Act - First attempt fails, second succeeds
        try {
          await photoService.uploadProfilePhoto(
            userId: testUserId,
            imageFile: mockXFile,
          );
        } catch (e) {
          // Expected failure
        }

        // Retry
        final result = await photoService.uploadProfilePhoto(
          userId: testUserId,
          imageFile: mockXFile,
        );

        // Assert
        expect(result, isA<String>());
        expect(attemptCount, 2);
      });

      test('should provide clear error messages for upload failures', () async {
        // Arrange
        final mockXFile = MockXFile();
        when(mockXFile.readAsBytes()).thenAnswer((_) async => Uint8List(0));
        when(mockStorageFileApi.uploadBinary(
          any,
          any,
          fileOptions: anyNamed('fileOptions'),
        )).thenThrow(Exception('Storage quota exceeded'));

        // Act & Assert
        expect(
          () => photoService.uploadProfilePhoto(
            userId: 'test-user',
            imageFile: mockXFile,
          ),
          throwsA(
            predicate((e) =>
                e is Exception &&
                e.toString().contains('Failed to upload photo')),
          ),
        );
      });
    });

    group('Data Validation', () {
      test('should verify uploaded file is accessible', () async {
        // Arrange
        final testUserId = 'test-user-123';
        final mockBytes = Uint8List.fromList([1, 2, 3]);
        final mockXFile = MockXFile();

        when(mockXFile.readAsBytes()).thenAnswer((_) async => mockBytes);

        final uploadedUrl = 'https://supabase.com/storage/profile-avatars/$testUserId/profile.jpg';

        when(mockStorageFileApi.uploadBinary(
          any,
          mockBytes,
          fileOptions: anyNamed('fileOptions'),
        )).thenAnswer((_) async => 'uploaded');

        when(mockStorageFileApi.getPublicUrl(any))
            .thenReturn(uploadedUrl);

        // Act
        final result = await photoService.uploadProfilePhoto(
          userId: testUserId,
          imageFile: mockXFile,
        );

        // Assert
        expect(result, uploadedUrl);
        expect(result, startsWith('https://'));
        expect(result, contains('profile-avatars'));
        expect(result, contains(testUserId));
      });

      test('should ensure profile update includes correct avatar URL', () async {
        // Arrange
        final testUserId = 'test-user-123';
        final testEmail = 'test@example.com';
        final avatarUrl = 'https://example.com/avatar.jpg';

        final initialUser = UserModel(
          id: testUserId,
          email: testEmail,
          fullName: 'Test User',
        );

        when(mockRemoteDataSource.getCurrentUser())
            .thenAnswer((_) async => initialUser);

        final updatedUser = UserModel(
          id: testUserId,
          email: testEmail,
          fullName: 'Test User',
          avatarUrl: avatarUrl,
        );

        when(mockRemoteDataSource.updateProfile(
          userId: testUserId,
          avatarUrl: avatarUrl,
        )).thenAnswer((_) async => updatedUser);

        // Act
        final result = await authRepository.updateProfile(avatarUrl: avatarUrl);

        // Assert
        expect(result.avatarUrl, avatarUrl);

        // Verify the exact URL was passed to update
        verify(mockRemoteDataSource.updateProfile(
          userId: testUserId,
          avatarUrl: avatarUrl,
        )).called(1);
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
