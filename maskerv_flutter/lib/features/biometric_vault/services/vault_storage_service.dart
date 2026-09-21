import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/vault_file.dart';

/// Manages the local vault directory and metadata file.
///
/// Vault directory is inside [getApplicationDocumentsDirectory] which is
/// app-private on both Android and iOS and NOT accessible through the
/// system file browser or external URIs.
///
/// Structure:
///   {appDocuments}/biometric_vault/
///     vault_metadata.json
///     enc_{id}           ← encrypted file blobs
class VaultStorageService {
  static const String _vaultDirName = 'biometric_vault';
  static const String _metadataFileName = 'vault_metadata.json';

  // ── Directory ──────────────────────────────────────────────────

  Future<Directory> getVaultDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/$_vaultDirName');
    if (!vaultDir.existsSync()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir;
  }

  Future<Directory> getTempDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final vaultTemp = Directory('${tempDir.path}/vault_temp');
    if (!vaultTemp.existsSync()) {
      await vaultTemp.create(recursive: true);
    }
    return vaultTemp;
  }

  // ── Encrypted file storage ─────────────────────────────────────

  /// Returns the [File] reference for an encrypted vault entry (not yet written).
  Future<File> getEncryptedFilePath(String id) async {
    final dir = await getVaultDirectory();
    return File('${dir.path}/enc_$id');
  }

  /// Returns a temporary [File] path for decrypted data (never persisted to vault).
  Future<File> getTempDecryptedFilePath(String originalName) async {
    final dir = await getTempDirectory();
    return File('${dir.path}/$originalName');
  }

  /// Deletes a specific encrypted vault file from disk.
  Future<void> deleteEncryptedFile(String id) async {
    final file = await getEncryptedFilePath(id);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  // ── Metadata ───────────────────────────────────────────────────

  Future<File> _getMetadataFile() async {
    final dir = await getVaultDirectory();
    return File('${dir.path}/$_metadataFileName');
  }

  Future<List<VaultFile>> loadMetadata() async {
    try {
      final file = await _getMetadataFile();
      if (!file.existsSync()) return [];
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return [];
      return VaultFile.listFromJson(contents);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMetadata(List<VaultFile> files) async {
    final file = await _getMetadataFile();
    await file.writeAsString(VaultFile.listToJson(files), flush: true);
  }

  Future<void> addVaultEntry(VaultFile entry) async {
    final existing = await loadMetadata();
    // Remove any duplicate with same id
    existing.removeWhere((e) => e.id == entry.id);
    existing.insert(0, entry);
    await saveMetadata(existing);
  }

  Future<void> deleteVaultEntry(String id) async {
    final existing = await loadMetadata();
    existing.removeWhere((e) => e.id == id);
    await saveMetadata(existing);
    await deleteEncryptedFile(id);
  }

  // ── Temp cleanup ───────────────────────────────────────────────

  /// Deletes all files inside the temp vault directory.
  /// Call this on screen dispose or when the app goes to background.
  Future<void> clearTempFiles() async {
    try {
      final dir = await getTempDirectory();
      if (dir.existsSync()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
    } catch (_) {
      // Best-effort cleanup — ignore errors
    }
  }

  /// Deletes a specific temp file by its [File] reference.
  Future<void> deleteTempFile(File file) async {
    try {
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
