import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:travel_crew/features/emergency/domain/usecases/add_emergency_contact_usecase.dart';
import 'package:travel_crew/shared/models/emergency_contact_model.dart';

import 'add_emergency_contact_usecase_test.mocks.dart';

@GenerateMocks([EmergencyRepository])
void main() {
  late AddEmergencyContactUseCase useCase;
  late MockEmergencyRepository mockRepository;

  setUp(() {
    mockRepository = MockEmergencyRepository();
    useCase = AddEmergencyContactUseCase(mockRepository);
  });

  final now = DateTime.now();

  final testContact = EmergencyContactModel(
    id: 'contact-123',
    userId: 'user-123',
    name: 'John Doe',
    phoneNumber: '+1234567890',
    email: 'john@example.com',
    relationship: 'Spouse',
    isPrimary: false,
    createdAt: now,
  );

  group('AddEmergencyContactUseCase', () {
    group('Positive Cases', () {
      test('should add emergency contact successfully', () async {
        // Arrange
        when(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).thenAnswer((_) async => testContact);

        // Act
        final result = await useCase(
          name: 'John Doe',
          phoneNumber: '+1234567890',
          email: 'john@example.com',
          relationship: 'Spouse',
        );

        // Assert
        expect(result.id, 'contact-123');
        expect(result.name, 'John Doe');
        verify(mockRepository.addEmergencyContact(
          name: 'John Doe',
          phoneNumber: '+1234567890',
          email: 'john@example.com',
          relationship: 'Spouse',
          isPrimary: false,
        )).called(1);
      });

      test('should add contact without email', () async {
        // Arrange
        final contactWithoutEmail = EmergencyContactModel(
          id: 'contact-456',
          userId: 'user-123',
          name: 'Jane Doe',
          phoneNumber: '1234567890',
          email: null,
          relationship: 'Parent',
          isPrimary: false,
          createdAt: now,
        );
        when(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).thenAnswer((_) async => contactWithoutEmail);

        // Act
        final result = await useCase(
          name: 'Jane Doe',
          phoneNumber: '1234567890',
          relationship: 'Parent',
        );

        // Assert
        expect(result.email, isNull);
      });

      test('should add primary contact', () async {
        // Arrange
        final primaryContact = testContact.copyWith(isPrimary: true);
        when(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).thenAnswer((_) async => primaryContact);

        // Act
        final result = await useCase(
          name: 'Emergency Contact',
          phoneNumber: '+1234567890',
          relationship: 'Friend',
          isPrimary: true,
        );

        // Assert
        expect(result.isPrimary, true);
      });

      test('should trim whitespace from inputs', () async {
        // Arrange
        when(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).thenAnswer((_) async => testContact);

        // Act
        await useCase(
          name: '  John Doe  ',
          phoneNumber: '  +1234567890  ',
          email: '  john@example.com  ',
          relationship: '  Spouse  ',
        );

        // Assert
        verify(mockRepository.addEmergencyContact(
          name: 'John Doe',
          phoneNumber: '+1234567890',
          email: 'john@example.com',
          relationship: 'Spouse',
          isPrimary: false,
        )).called(1);
      });

      test('should accept various phone formats', () async {
        // Arrange
        when(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).thenAnswer((_) async => testContact);

        // Test different phone formats
        final phoneNumbers = [
          '+1 (234) 567-8901', // US format with formatting
          '01onal2-345-6789', // Indian format
          '+44 7911 123456', // UK format
          '9876543210', // Plain digits
        ];

        for (final phone in phoneNumbers) {
          await useCase(
            name: 'Test Contact',
            phoneNumber: phone,
            relationship: 'Friend',
          );
        }

        // Assert - should have been called for each valid phone
        verify(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).called(4);
      });

      test('should handle various relationship types', () async {
        // Arrange
        when(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).thenAnswer((_) async => testContact);

        final relationships = ['Spouse', 'Parent', 'Sibling', 'Friend', 'Colleague', 'Doctor'];

        // Act
        for (final rel in relationships) {
          await useCase(
            name: 'Contact',
            phoneNumber: '1234567890',
            relationship: rel,
          );
        }

        // Assert
        verify(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).called(6);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw ArgumentError for empty name', () async {
        // Act & Assert
        expect(
          () => useCase(
            name: '',
            phoneNumber: '+1234567890',
            relationship: 'Friend',
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Name cannot be empty'),
          )),
        );
        verifyNever(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        ));
      });

      test('should throw ArgumentError for whitespace-only name', () async {
        // Act & Assert
        expect(
          () => useCase(
            name: '   ',
            phoneNumber: '+1234567890',
            relationship: 'Friend',
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Name cannot be empty'),
          )),
        );
      });

      test('should throw ArgumentError for empty phone number', () async {
        // Act & Assert
        expect(
          () => useCase(
            name: 'John Doe',
            phoneNumber: '',
            relationship: 'Friend',
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Phone number cannot be empty'),
          )),
        );
      });

      test('should throw ArgumentError for phone number with less than 10 digits', () async {
        // Act & Assert
        expect(
          () => useCase(
            name: 'John Doe',
            phoneNumber: '123456', // Only 6 digits
            relationship: 'Friend',
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid phone number'),
          )),
        );
      });

      test('should throw ArgumentError for empty relationship', () async {
        // Act & Assert
        expect(
          () => useCase(
            name: 'John Doe',
            phoneNumber: '+1234567890',
            relationship: '',
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Relationship cannot be empty'),
          )),
        );
      });

      test('should throw ArgumentError for invalid email', () async {
        // Act & Assert
        expect(
          () => useCase(
            name: 'John Doe',
            phoneNumber: '+1234567890',
            email: 'invalid-email',
            relationship: 'Friend',
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid email address'),
          )),
        );
      });

      test('should throw ArgumentError for email without domain', () async {
        // Act & Assert
        expect(
          () => useCase(
            name: 'John Doe',
            phoneNumber: '+1234567890',
            email: 'john@',
            relationship: 'Friend',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError for email without @', () async {
        // Act & Assert
        expect(
          () => useCase(
            name: 'John Doe',
            phoneNumber: '+1234567890',
            email: 'johnexample.com',
            relationship: 'Friend',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase(
            name: 'John Doe',
            phoneNumber: '+1234567890',
            relationship: 'Friend',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle network error', () async {
        // Arrange
        when(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).thenThrow(Exception('Network unavailable'));

        // Act & Assert
        expect(
          () => useCase(
            name: 'John Doe',
            phoneNumber: '+1234567890',
            relationship: 'Friend',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network unavailable'),
          )),
        );
      });
    });

    group('Edge Cases', () {
      test('should accept empty email string (treated as null)', () async {
        // Arrange
        when(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).thenAnswer((_) async => testContact);

        // Act - empty string email should pass validation (treated as no email)
        final result = await useCase(
          name: 'John Doe',
          phoneNumber: '+1234567890',
          email: '',
          relationship: 'Friend',
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should accept phone number with exactly 10 digits', () async {
        // Arrange
        when(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).thenAnswer((_) async => testContact);

        // Act
        final result = await useCase(
          name: 'John Doe',
          phoneNumber: '1234567890', // Exactly 10 digits
          relationship: 'Friend',
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should accept international phone format', () async {
        // Arrange
        when(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).thenAnswer((_) async => testContact);

        // Act
        final result = await useCase(
          name: 'John Doe',
          phoneNumber: '+91 98765 43210',
          relationship: 'Friend',
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should handle long names', () async {
        // Arrange
        final longName = 'A' * 200;
        when(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).thenAnswer((_) async => testContact);

        // Act
        await useCase(
          name: longName,
          phoneNumber: '+1234567890',
          relationship: 'Friend',
        );

        // Assert
        verify(mockRepository.addEmergencyContact(
          name: longName,
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).called(1);
      });

      test('should handle special characters in name', () async {
        // Arrange
        when(mockRepository.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).thenAnswer((_) async => testContact);

        // Act
        await useCase(
          name: "Jean-Pierre O'Brien III",
          phoneNumber: '+1234567890',
          relationship: 'Friend',
        );

        // Assert
        verify(mockRepository.addEmergencyContact(
          name: "Jean-Pierre O'Brien III",
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).called(1);
      });
    });
  });
}
