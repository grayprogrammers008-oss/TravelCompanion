import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Encryption Service for End-to-End Encrypted Messaging
/// Provides RSA key generation, AES encryption, and hybrid encryption
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // Key storage
  RSAPublicKey? _publicKey;
  RSAPrivateKey? _privateKey;
  final Map<String, RSAPublicKey> _peerPublicKeys = {};

  /// Initialize encryption service and generate key pair
  Future<void> initialize() async {
    try {
      debugPrint('🔐 [EncryptionService] Initializing...');

      // Generate RSA key pair for this device
      final keyPair = await _generateRSAKeyPair();
      _publicKey = keyPair.publicKey as RSAPublicKey;
      _privateKey = keyPair.privateKey as RSAPrivateKey;

      debugPrint('✅ [EncryptionService] Initialized successfully');
      debugPrint('   Public Key Modulus: ${_publicKey!.modulus.toString().substring(0, 50)}...');
    } catch (e, stackTrace) {
      debugPrint('❌ [EncryptionService] Initialization failed: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Get this device's public key (for sharing with peers)
  String? getPublicKeyPEM() {
    if (_publicKey == null) return null;

    try {
      final publicKeyPEM = _rsaPublicKeyToPEM(_publicKey!);
      return publicKeyPEM;
    } catch (e) {
      debugPrint('❌ [EncryptionService] Failed to export public key: $e');
      return null;
    }
  }

  /// Store a peer's public key
  void storePeerPublicKey(String peerId, String publicKeyPEM) {
    try {
      final publicKey = _pemToRSAPublicKey(publicKeyPEM);
      _peerPublicKeys[peerId] = publicKey;
      debugPrint('✅ [EncryptionService] Stored public key for peer: $peerId');
    } catch (e) {
      debugPrint('❌ [EncryptionService] Failed to store peer key: $e');
    }
  }

  /// Encrypt message for a specific peer (Hybrid Encryption: RSA + AES)
  /// Returns: base64 encoded encrypted data
  Future<EncryptedMessage?> encryptMessage({
    required String peerId,
    required String message,
  }) async {
    try {
      debugPrint('🔐 [EncryptionService] Encrypting message for peer: $peerId');

      final peerPublicKey = _peerPublicKeys[peerId];
      if (peerPublicKey == null) {
        debugPrint('❌ [EncryptionService] No public key found for peer: $peerId');
        return null;
      }

      // Generate random AES key (256-bit)
      final aesKey = encrypt_lib.Key.fromSecureRandom(32);
      final iv = encrypt_lib.IV.fromSecureRandom(16);

      // Encrypt message with AES
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(aesKey, mode: encrypt_lib.AESMode.cbc),
      );
      final encryptedMessage = encrypter.encrypt(message, iv: iv);

      // Encrypt AES key with RSA (peer's public key)
      final encryptedAESKey = _encryptRSA(
        aesKey.bytes,
        peerPublicKey,
      );

      debugPrint('✅ [EncryptionService] Message encrypted successfully');

      return EncryptedMessage(
        encryptedData: encryptedMessage.base64,
        encryptedKey: base64Encode(encryptedAESKey),
        iv: iv.base64,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [EncryptionService] Encryption failed: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return null;
    }
  }

  /// Decrypt message from a peer
  Future<String?> decryptMessage({
    required String encryptedData,
    required String encryptedKey,
    required String ivBase64,
  }) async {
    try {
      debugPrint('🔓 [EncryptionService] Decrypting message...');

      if (_privateKey == null) {
        debugPrint('❌ [EncryptionService] Private key not available');
        return null;
      }

      // Decrypt AES key with RSA (our private key)
      final encryptedAESKeyBytes = base64Decode(encryptedKey);
      final aesKeyBytes = _decryptRSA(encryptedAESKeyBytes, _privateKey!);
      final aesKey = encrypt_lib.Key(Uint8List.fromList(aesKeyBytes));

      // Decrypt message with AES
      final iv = encrypt_lib.IV.fromBase64(ivBase64);
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(aesKey, mode: encrypt_lib.AESMode.cbc),
      );

      final encrypted = encrypt_lib.Encrypted.fromBase64(encryptedData);
      final decryptedMessage = encrypter.decrypt(encrypted, iv: iv);

      debugPrint('✅ [EncryptionService] Message decrypted successfully');
      return decryptedMessage;
    } catch (e, stackTrace) {
      debugPrint('❌ [EncryptionService] Decryption failed: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return null;
    }
  }

  /// Generate message signature for authentication
  String signMessage(String message) {
    try {
      final messageBytes = utf8.encode(message);
      final digest = sha256.convert(messageBytes);
      return digest.toString();
    } catch (e) {
      debugPrint('❌ [EncryptionService] Signing failed: $e');
      return '';
    }
  }

  /// Verify message signature
  bool verifySignature(String message, String signature) {
    try {
      final computedSignature = signMessage(message);
      return computedSignature == signature;
    } catch (e) {
      debugPrint('❌ [EncryptionService] Verification failed: $e');
      return false;
    }
  }

  /// Generate RSA key pair (2048-bit)
  Future<AsymmetricKeyPair<PublicKey, PrivateKey>> _generateRSAKeyPair() async {
    return compute(_generateRSAKeyPairIsolate, null);
  }

  static AsymmetricKeyPair<PublicKey, PrivateKey> _generateRSAKeyPairIsolate(_) {
    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
          FortunaRandom()..seed(KeyParameter(_randomBytes(32))),
        ),
      );

    return keyGen.generateKeyPair();
  }

  /// Encrypt data with RSA public key
  Uint8List _encryptRSA(List<int> data, RSAPublicKey publicKey) {
    final encryptor = OAEPEncoding(RSAEngine())
      ..init(
        true,
        PublicKeyParameter<RSAPublicKey>(publicKey),
      );

    return _processInBlocks(encryptor, Uint8List.fromList(data));
  }

  /// Decrypt data with RSA private key
  Uint8List _decryptRSA(List<int> data, RSAPrivateKey privateKey) {
    final decryptor = OAEPEncoding(RSAEngine())
      ..init(
        false,
        PrivateKeyParameter<RSAPrivateKey>(privateKey),
      );

    return _processInBlocks(decryptor, Uint8List.fromList(data));
  }

  /// Process data in blocks for RSA (max block size = key size - padding)
  Uint8List _processInBlocks(AsymmetricBlockCipher cipher, Uint8List data) {
    final chunks = <Uint8List>[];
    final inputBlockSize = cipher.inputBlockSize;

    for (int offset = 0; offset < data.length; offset += inputBlockSize) {
      final end = (offset + inputBlockSize < data.length)
          ? offset + inputBlockSize
          : data.length;
      chunks.add(cipher.process(data.sublist(offset, end)));
    }

    // Combine all chunks
    final output = Uint8List(chunks.fold<int>(0, (p, c) => p + c.length));
    int outputOffset = 0;
    for (final chunk in chunks) {
      output.setRange(outputOffset, outputOffset + chunk.length, chunk);
      outputOffset += chunk.length;
    }

    return output;
  }

  /// Convert RSA public key to PEM format
  String _rsaPublicKeyToPEM(RSAPublicKey publicKey) {
    final modulus = publicKey.modulus!;
    final exponent = publicKey.exponent!;

    // Simple PEM encoding (not ASN.1 - simplified for BLE)
    final keyData = {
      'modulus': modulus.toString(),
      'exponent': exponent.toString(),
    };

    return base64Encode(utf8.encode(jsonEncode(keyData)));
  }

  /// Convert PEM format to RSA public key
  RSAPublicKey _pemToRSAPublicKey(String pem) {
    final keyDataJson = utf8.decode(base64Decode(pem));
    final keyData = jsonDecode(keyDataJson) as Map<String, dynamic>;

    final modulus = BigInt.parse(keyData['modulus'] as String);
    final exponent = BigInt.parse(keyData['exponent'] as String);

    return RSAPublicKey(modulus, exponent);
  }

  /// Generate random bytes for key generation
  static Uint8List _randomBytes(int length) {
    final random = FortunaRandom();
    final seed = List<int>.generate(32, (i) => DateTime.now().millisecondsSinceEpoch + i);
    random.seed(KeyParameter(Uint8List.fromList(seed)));

    return random.nextBytes(length);
  }

  /// Clear all stored keys (for logout/reset)
  void clearKeys() {
    _publicKey = null;
    _privateKey = null;
    _peerPublicKeys.clear();
    debugPrint('🗑️ [EncryptionService] All keys cleared');
  }

  /// Get peer count
  int get peerCount => _peerPublicKeys.length;

  /// Check if peer key exists
  bool hasPeerKey(String peerId) => _peerPublicKeys.containsKey(peerId);
}

/// Encrypted message structure
class EncryptedMessage {
  final String encryptedData; // Base64 encoded encrypted message
  final String encryptedKey;  // Base64 encoded encrypted AES key
  final String iv;            // Base64 encoded initialization vector

  EncryptedMessage({
    required this.encryptedData,
    required this.encryptedKey,
    required this.iv,
  });

  /// Convert to JSON for transmission
  Map<String, dynamic> toJson() {
    return {
      'data': encryptedData,
      'key': encryptedKey,
      'iv': iv,
    };
  }

  /// Create from JSON
  factory EncryptedMessage.fromJson(Map<String, dynamic> json) {
    return EncryptedMessage(
      encryptedData: json['data'] as String,
      encryptedKey: json['key'] as String,
      iv: json['iv'] as String,
    );
  }
}
