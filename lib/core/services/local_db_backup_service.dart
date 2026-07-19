import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'local_db_service.dart';

/// Service for local database save/restore using .db files.
///
/// Saves the current Hive database as a `.db` file (a zip archive containing
/// all `.hive` files), and restores a previously saved `.db` file back to the
/// device's database directory.
class LocalDbBackupService {
  static const String _dbExtension = 'db';

  // ─── Save Database ─────────────────────────────────────────────
  /// Creates a backup archive of all Hive files and lets the user save it
  /// as a `.db` file via the system file picker.
  ///
  /// Returns `true` if the user saved a file successfully, `false` if cancelled.
  static Future<bool> saveDatabase() async {
    try {
      // 1. Create the backup archive from Hive files
      final archiveBytes = await _createBackupArchive();
      if (archiveBytes == null) {
        debugPrint('LocalDbBackupService: No Hive files found to back up.');
        return false;
      }

      // 2. Let user pick a save location
      final outputFile = await FilePicker.saveFile(
        dialogTitle: 'Save Database Backup',
        fileName: 'finance_tracker_backup.db',
        type: FileType.custom,
        allowedExtensions: [_dbExtension],
      );

      if (outputFile == null) {
        debugPrint('LocalDbBackupService: User cancelled save.');
        return false; // User cancelled
      }

      // 3. Write the archive bytes to the chosen file
      final file = File(outputFile);
      await file.writeAsBytes(archiveBytes, flush: true);

      debugPrint('LocalDbBackupService: Database saved to $outputFile');
      return true;
    } catch (e) {
      debugPrint('LocalDbBackupService Save Error: $e');
      rethrow;
    }
  }

  // ─── Restore Database ──────────────────────────────────────────
  /// Lets the user pick a `.db` file, then restores all Hive files from it.
  ///
  /// The process:
  /// 1. Close all open Hive boxes.
  /// 2. Extract the `.db` archive contents.
  /// 3. Overwrite existing `.hive` files in the app's documents directory.
  /// 4. Re-initialize Hive and reopen all boxes.
  ///
  /// Returns `true` on success, `false` if user cancelled.
  static Future<bool> restoreDatabase() async {
    try {
      // 1. Let user pick a .db file
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Select Database Backup to Restore',
        type: FileType.custom,
        allowedExtensions: [_dbExtension],
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('LocalDbBackupService: User cancelled restore.');
        return false; // User cancelled
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        debugPrint('LocalDbBackupService: No file path selected.');
        return false;
      }

      // 2. Read the selected file
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // 3. Restore from the archive
      await _restoreFromArchive(Uint8List.fromList(bytes));

      debugPrint(
          'LocalDbBackupService: Database restored successfully from $filePath');
      return true;
    } catch (e) {
      debugPrint('LocalDbBackupService Restore Error: $e');
      rethrow;
    }
  }

  // ─── Get Archive Bytes (for sharing) ───────────────────────────
  /// Returns the raw archive bytes of all Hive files, or `null` if no
  /// Hive files exist. Useful for sharing the database via [Share.shareXFiles].
  static Future<Uint8List?> getArchiveBytes() async {
    return await _createBackupArchive();
  }

  // ─── Internal: Create Backup Archive ───────────────────────────
  static Future<Uint8List?> _createBackupArchive() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> entities = directory.listSync();
    final archive = Archive();

    bool hasFiles = false;
    for (final entity in entities) {
      if (entity is File) {
        final fileName = entity.path.split(RegExp(r'[/\\]')).last;
        if (fileName.endsWith('.hive')) {
          final Uint8List bytes = await entity.readAsBytes();
          archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
          hasFiles = true;
        }
      }
    }

    if (!hasFiles) {
      return null;
    }

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  // ─── Internal: Restore From Archive ────────────────────────────
  static Future<void> _restoreFromArchive(Uint8List zipBytes) async {
    // 1. Safely close all active Hive boxes
    await LocalDbService.close();

    // 2. Decode the zip archive
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final directory = await getApplicationDocumentsDirectory();

    // 3. Write files back to database directory
    for (final file in archive) {
      if (file.isFile) {
        final String filePath = '${directory.path}/${file.name}';
        final File outputFile = File(filePath);

        // Ensure parent folders exist (safety)
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsBytes(file.content as List<int>, flush: true);
      }
    }

    // 4. Re-initialize Hive and reopen boxes
    await LocalDbService.init();
  }
}
