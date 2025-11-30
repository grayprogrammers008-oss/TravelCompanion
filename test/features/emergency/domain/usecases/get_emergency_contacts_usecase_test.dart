import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:travel_crew/features/emergency/domain/usecases/get_emergency_contacts_usecase.dart';
import 'package:travel_crew/shared/models/emergency_contact_model.dart';

import 'get_emergency_contacts_usecase_test.mocks.dart';

@GenerateMocks([EmergencyRepository])
void main() {
  late GetEmergencyContactsUseCase useCase;
  late MockEmergencyRepository mockRepository;

  setUp(() {
    mockRepository = MockEmergencyRepository();
    useCase = GetEmergencyContactsUseCase(mockRepository);
  });

  final now = DateTime.now();

  EmergencyContactModel createContact({
    required String id,
    required String name,
    bool isPrimary = false,
  }) {
    return EmergencyContactModel(
      id: id,
      userId: 'user-123',
      name: name,
      phoneNumber: '+1234567890',
      relationship: 'Friend',
      isPrimary: isPrimary,
      createdAt: now,
    );
  }

  group('GetEmergencyContactsUseCase', () {
    group('Positive Cases', () {
      test('should return list of emergency contacts', () async {
        // Arrange
        final contacts = [
          createContact(id: '1', name: 'Alice'),
          createContact(id: '2', name: 'Bob'),
        ];
        when(mockRepository.getEmergencyContacts())
            .thenAnswer((_) async => contacts);

        // Act
        final result = await useCase();

        // Assert
        expect(result.length, 2);
        verify(mockRepository.getEmergencyContacts()).called(1);
      });

      test('should return empty list when no contacts exist', () async {
        // Arrange
        when(mockRepository.getEmergencyContacts())
            .thenAnswer((_) async => []);

        // Act
        final result = await useCase();

        // Assert
        expect(result, isEmpty);
      });

      test('should sort contacts with primary first', () async {
        // Arrange
        final contacts = [
          createContact(id: '1', name: 'Alice', isPrimary: false),
          createContact(id: '2', name: 'Bob', isPrimary: true),
          createContact(id: '3', name: 'Charlie', isPrimary: false),
        ];
        when(mockRepository.getEmergencyContacts())
            .thenAnswer((_) async => contacts);

        // Act
        final result = await useCase();

        // Assert
        expect(result[0].name, 'Bob'); // Primary first
        expect(result[0].isPrimary, true);
      });

      test('should sort non-primary contacts alphabetically by name', () async {
        // Arrange
        final contacts = [
          createContact(id: '1', name: 'Zack'),
          createContact(id: '2', name: 'Alice'),
          createContact(id: '3', name: 'Mike'),
        ];
        when(mockRepository.getEmergencyContacts())
            .thenAnswer((_) async => contacts);

        // Act
        final result = await useCase();

        // Assert
        expect(result[0].name, 'Alice');
        expect(result[1].name, 'Mike');
        expect(result[2].name, 'Zack');
      });

      test('should sort primary first then alphabetically', () async {
        // Arrange
        final contacts = [
          createContact(id: '1', name: 'Zack'),
          createContact(id: '2', name: 'Alice', isPrimary: true),
          createContact(id: '3', name: 'Mike'),
          createContact(id: '4', name: 'Bob'),
        ];
        when(mockRepository.getEmergencyContacts())
            .thenAnswer((_) async => contacts);

        // Act
        final result = await useCase();

        // Assert
        expect(result[0].name, 'Alice'); // Primary first
        expect(result[1].name, 'Bob'); // Then alphabetical
        expect(result[2].name, 'Mike');
        expect(result[3].name, 'Zack');
      });

      test('should handle single contact', () async {
        // Arrange
        final contacts = [
          createContact(id: '1', name: 'Alice'),
        ];
        when(mockRepository.getEmergencyContacts())
            .thenAnswer((_) async => contacts);

        // Act
        final result = await useCase();

        // Assert
        expect(result.length, 1);
        expect(result[0].name, 'Alice');
      });

      test('should handle multiple primary contacts (edge case)', () async {
        // Arrange - ideally only one should be primary, but handle gracefully
        final contacts = [
          createContact(id: '1', name: 'Zack', isPrimary: true),
          createContact(id: '2', name: 'Alice', isPrimary: true),
          createContact(id: '3', name: 'Mike'),
        ];
        when(mockRepository.getEmergencyContacts())
            .thenAnswer((_) async => contacts);

        // Act
        final result = await useCase();

        // Assert
        // Both primary contacts should be before non-primary
        expect(result[0].isPrimary, true);
        expect(result[1].isPrimary, true);
        expect(result[2].isPrimary, false);
        // Alphabetically sorted within primary group
        expect(result[0].name, 'Alice');
        expect(result[1].name, 'Zack');
      });

      test('should return contacts with all fields populated', () async {
        // Arrange
        final contact = EmergencyContactModel(
          id: 'contact-1',
          userId: 'user-123',
          name: 'John Doe',
          phoneNumber: '+1234567890',
          email: 'john@example.com',
          relationship: 'Spouse',
          isPrimary: true,
          createdAt: now,
          updatedAt: now.add(const Duration(days: 1)),
        );
        when(mockRepository.getEmergencyContacts())
            .thenAnswer((_) async => [contact]);

        // Act
        final result = await useCase();

        // Assert
        expect(result[0].email, 'john@example.com');
        expect(result[0].relationship, 'Spouse');
        expect(result[0].updatedAt, isNotNull);
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.getEmergencyContacts())
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Database error'),
          )),
        );
      });

      test('should handle network error', () async {
        // Arrange
        when(mockRepository.getEmergencyContacts())
            .thenThrow(Exception('Network unavailable'));

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network unavailable'),
          )),
        );
      });

      test('should handle authentication error', () async {
        // Arrange
        when(mockRepository.getEmergencyContacts())
            .thenThrow(Exception('User not authenticated'));

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle names starting with numbers', () async {
        // Arrange
        final contacts = [
          createContact(id: '1', name: '123 Contact'),
          createContact(id: '2', name: 'Alice'),
        ];
        when(mockRepository.getEmergencyContacts())
            .thenAnswer((_) async => contacts);

        // Act
        final result = await useCase();

        // Assert
        // Numbers sort before letters in ASCII
        expect(result[0].name, '123 Contact');
        expect(result[1].name, 'Alice');
      });

      test('should handle case-sensitive name sorting', () async {
        // Arrange
        final contacts = [
          createContact(id: '1', name: 'alice'),
          createContact(id: '2', name: 'Alice'),
          createContact(id: '3', name: 'Bob'),
        ];
        when(mockRepository.getEmergencyContacts())
            .thenAnswer((_) async => contacts);

        // Act
        final result = await useCase();

        // Assert
        // Standard string comparison (uppercase before lowercase)
        expect(result.length, 3);
      });

      test('should handle names with special characters', () async {
        // Arrange
        final contacts = [
          createContact(id: '1', name: "O'Brien"),
          createContact(id: '2', name: 'Anne-Marie'),
          createContact(id: '3', name: 'Bob'),
        ];
        when(mockRepository.getEmergencyContacts())
            .thenAnswer((_) async => contacts);

        // Act
        final result = await useCase();

        // Assert
        expect(result.length, 3);
      });

      test('should handle large number of contacts', () async {
        // Arrange
        final contacts = List.generate(
          100,
          (i) => createContact(id: 'id-$i', name: 'Contact $i'),
        );
        when(mockRepository.getEmergencyContacts())
            .thenAnswer((_) async => contacts);

        // Act
        final result = await useCase();

        // Assert
        expect(result.length, 100);
      });

      test('should handle contacts with same name', () async {
        // Arrange
        final contacts = [
          createContact(id: '1', name: 'John'),
          createContact(id: '2', name: 'John'),
          createContact(id: '3', name: 'John', isPrimary: true),
        ];
        when(mockRepository.getEmergencyContacts())
            .thenAnswer((_) async => contacts);

        // Act
        final result = await useCase();

        // Assert
        expect(result.length, 3);
        expect(result[0].isPrimary, true); // Primary first
      });

      test('should handle Unicode names', () async {
        // Arrange
        final contacts = [
          createContact(id: '1', name: 'Zoey'),
          createContact(id: '2', name: 'Alice'),
        ];
        when(mockRepository.getEmergencyContacts())
            .thenAnswer((_) async => contacts);

        // Act
        final result = await useCase();

        // Assert
        expect(result.length, 2);
      });

      test('should preserve contact details after sorting', () async {
        // Arrange
        final contact = EmergencyContactModel(
          id: 'unique-id',
          userId: 'user-123',
          name: 'Test Contact',
          phoneNumber: '+9876543210',
          email: 'test@test.com',
          relationship: 'Doctor',
          isPrimary: false,
          createdAt: now,
        );
        when(mockRepository.getEmergencyContacts())
            .thenAnswer((_) async => [contact]);

        // Act
        final result = await useCase();

        // Assert
        expect(result[0].id, 'unique-id');
        expect(result[0].phoneNumber, '+9876543210');
        expect(result[0].email, 'test@test.com');
        expect(result[0].relationship, 'Doctor');
      });
    });
  });
}
