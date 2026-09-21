import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the AES-256 master encryption key for the Biometric Vault.
///
/// The key is stored exclusively in [flutter_secure_storage], which is backed
/// by Android Keystore on Android and iOS Keychain on iOS.
///
/// SECURITY RULES:
/// - Never log the key.
/// - Never store the key in SharedPreferences, plain files, or SQLite.
/// - Never hardcode the key in source code.
class VaultKeyService {
  static const String _keyStorageKey = 'maskerv_vault_master_key_v1';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Retrieves the existing master key from secure storage, or generates a new
  /// 256-bit (32-byte) random key if none exists yet.
  ///
  /// Returns raw key bytes. Throws [VaultKeyException] on unrecoverable error.
  Future<Uint8List> getOrCreateMasterKey() async {
    try {
      final existing = await _secureStorage.read(key: _keyStorageKey);
      if (existing != null && existing.isNotEmpty) {
        final decoded = base64Decode(existing);
        if (decoded.length == 32) {
          return decoded;
        }
        // Key is malformed — generate a fresh one
        await _secureStorage.delete(key: _keyStorageKey);
      }
      // Generate new 256-bit key
      final newKey = _generateSecureRandom(32);
      await _secureStorage.write(
        key: _keyStorageKey,
        value: base64Encode(newKey),
      );
      return newKey;
    } catch (e) {
      throw VaultKeyException('Unable to access or create vault key: ${e.runtimeType}');
    }
  }

  /// Deletes the master key from secure storage.
  /// WARNING: All encrypted vault files will become permanently unreadable.
  Future<void> deleteMasterKey() async {
    await _secureStorage.delete(key: _keyStorageKey);
  }

  /// Generates cryptographically secure random bytes using [Random.secure].
  static Uint8List _generateSecureRandom(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => rng.nextInt(256)));
  }

  /// Generates a 96-bit (12-byte) random IV/nonce for AES-GCM.
  static Uint8List generateNonce() => _generateSecureRandom(12);
}

class VaultKeyException implements Exception {
  final String message;
  const VaultKeyException(this.message);

  @override
  String toString() => 'VaultKeyException: $message';
}
