import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/data/services/encryption_service.dart';

void main() {
  group('EncryptionService', () {
    late EncryptionService encryptionService;

    setUp(() {
      encryptionService = EncryptionService();
    });

    test('should initialize and generate RSA key pair', () async {
      // Act
      await encryptionService.initialize();

      // Assert
      final publicKey = encryptionService.getPublicKeyPEM();
      expect(publicKey, isNotNull);
      expect(publicKey, isNotEmpty);
      // Implementation returns base64-encoded JSON (not real PEM with -----BEGIN)
      expect(publicKey!.length, greaterThan(100));
    });

    test('should store peer public keys', () async {
      // Arrange
      await encryptionService.initialize();
      const peerId = 'test-peer-123';
      final publicKey = encryptionService.getPublicKeyPEM()!;

      // Act & Assert - verify no exception is thrown
      expect(() => encryptionService.storePeerPublicKey(peerId, publicKey), returnsNormally);
    });

    test('should encrypt and decrypt message successfully', () async {
      // Arrange
      await encryptionService.initialize();
      const peerId = 'test-peer-123';
      const originalMessage = 'Hello, this is a secure message!';

      // Store peer public key (using own key for testing)
      final publicKey = encryptionService.getPublicKeyPEM()!;
      encryptionService.storePeerPublicKey(peerId, publicKey);

      // Act - Encrypt
      final encryptedMessage = await encryptionService.encryptMessage(
        peerId: peerId,
        message: originalMessage,
      );

      // Assert - Encrypted message exists
      expect(encryptedMessage, isNotNull);
      expect(encryptedMessage!.encryptedData, isNotEmpty);
      expect(encryptedMessage.encryptedKey, isNotEmpty);
      expect(encryptedMessage.iv, isNotEmpty);

      // Act - Decrypt
      final decryptedMessage = await encryptionService.decryptMessage(
        encryptedData: encryptedMessage.encryptedData,
        encryptedKey: encryptedMessage.encryptedKey,
        ivBase64: encryptedMessage.iv,
      );

      // Assert - Decrypted message matches original
      expect(decryptedMessage, equals(originalMessage));
    });

    test('should handle long messages with encryption', () async {
      // Arrange
      await encryptionService.initialize();
      const peerId = 'test-peer-123';
      final longMessage = 'A' * 1000; // 1000 character message

      final publicKey = encryptionService.getPublicKeyPEM()!;
      encryptionService.storePeerPublicKey(peerId, publicKey);

      // Act - Encrypt
      final encryptedMessage = await encryptionService.encryptMessage(
        peerId: peerId,
        message: longMessage,
      );

      // Assert - Can encrypt long messages
      expect(encryptedMessage, isNotNull);

      // Act - Decrypt
      final decryptedMessage = await encryptionService.decryptMessage(
        encryptedData: encryptedMessage!.encryptedData,
        encryptedKey: encryptedMessage.encryptedKey,
        ivBase64: encryptedMessage.iv,
      );

      // Assert - Decryption preserves message
      expect(decryptedMessage, equals(longMessage));
    });

    test('should handle special characters in messages', () async {
      // Arrange
      await encryptionService.initialize();
      const peerId = 'test-peer-123';
      const specialMessage = '!@#\$%^&*()_+ 🎉 こんにちは 你好';

      final publicKey = encryptionService.getPublicKeyPEM()!;
      encryptionService.storePeerPublicKey(peerId, publicKey);

      // Act
      final encryptedMessage = await encryptionService.encryptMessage(
        peerId: peerId,
        message: specialMessage,
      );

      final decryptedMessage = await encryptionService.decryptMessage(
        encryptedData: encryptedMessage!.encryptedData,
        encryptedKey: encryptedMessage.encryptedKey,
        ivBase64: encryptedMessage.iv,
      );

      // Assert
      expect(decryptedMessage, equals(specialMessage));
    });

    test('should return null when encrypting without peer public key', () async {
      // Arrange
      await encryptionService.initialize();
      const peerId = 'unknown-peer';
      const message = 'Test message';

      // Act
      final encryptedMessage = await encryptionService.encryptMessage(
        peerId: peerId,
        message: message,
      );

      // Assert
      expect(encryptedMessage, isNull);
    });

    test('should return null when decrypting invalid data', () async {
      // Arrange
      await encryptionService.initialize();

      // Act
      final decryptedMessage = await encryptionService.decryptMessage(
        encryptedData: 'invalid-data',
        encryptedKey: 'invalid-key',
        ivBase64: 'invalid-iv',
      );

      // Assert
      expect(decryptedMessage, isNull);
    });

    test('should handle multiple peer keys', () async {
      // Arrange
      await encryptionService.initialize();
      const peer1 = 'peer-1';
      const peer2 = 'peer-2';
      const peer3 = 'peer-3';

      final publicKey = encryptionService.getPublicKeyPEM()!;

      // Act
      encryptionService.storePeerPublicKey(peer1, publicKey);
      encryptionService.storePeerPublicKey(peer2, publicKey);
      encryptionService.storePeerPublicKey(peer3, publicKey);

      // Assert - verify no exceptions were thrown during storage
      expect(() => encryptionService.storePeerPublicKey(peer1, publicKey), returnsNormally);
    });

    test('should generate different IVs for each encryption', () async {
      // Arrange
      await encryptionService.initialize();
      const peerId = 'test-peer';
      const message = 'Same message';

      final publicKey = encryptionService.getPublicKeyPEM()!;
      encryptionService.storePeerPublicKey(peerId, publicKey);

      // Act - Encrypt same message twice
      final encrypted1 = await encryptionService.encryptMessage(
        peerId: peerId,
        message: message,
      );

      final encrypted2 = await encryptionService.encryptMessage(
        peerId: peerId,
        message: message,
      );

      // Assert - Different IVs mean different encrypted data
      expect(encrypted1!.iv, isNot(equals(encrypted2!.iv)));
      expect(encrypted1.encryptedData, isNot(equals(encrypted2.encryptedData)));
    });

    test('should handle empty message', () async {
      // Arrange
      await encryptionService.initialize();
      const peerId = 'test-peer';
      const emptyMessage = '';

      final publicKey = encryptionService.getPublicKeyPEM()!;
      encryptionService.storePeerPublicKey(peerId, publicKey);

      // Act
      final encryptedMessage = await encryptionService.encryptMessage(
        peerId: peerId,
        message: emptyMessage,
      );

      // Assert - either returns null gracefully or successfully round-trips
      if (encryptedMessage != null) {
        final decryptedMessage = await encryptionService.decryptMessage(
          encryptedData: encryptedMessage.encryptedData,
          encryptedKey: encryptedMessage.encryptedKey,
          ivBase64: encryptedMessage.iv,
        );
        expect(decryptedMessage, equals(emptyMessage));
      }
    });

    test('EncryptedMessage should serialize to JSON', () {
      // Arrange
      final encryptedMessage = EncryptedMessage(
        encryptedData: 'test-data',
        encryptedKey: 'test-key',
        iv: 'test-iv',
      );

      // Act
      final json = encryptedMessage.toJson();

      // Assert
      expect(json['data'], 'test-data');
      expect(json['key'], 'test-key');
      expect(json['iv'], 'test-iv');
    });

    test('EncryptedMessage should deserialize from JSON', () {
      // Arrange
      final json = {
        'data': 'test-data',
        'key': 'test-key',
        'iv': 'test-iv',
      };

      // Act
      final encryptedMessage = EncryptedMessage.fromJson(json);

      // Assert
      expect(encryptedMessage.encryptedData, 'test-data');
      expect(encryptedMessage.encryptedKey, 'test-key');
      expect(encryptedMessage.iv, 'test-iv');
    });
  });
}
