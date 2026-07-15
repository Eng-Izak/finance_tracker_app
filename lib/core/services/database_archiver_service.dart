import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'local_db_service.dart';

class DatabaseArchiverService {
  
  // ─── Create Zip Archive ───────────────────────────────────────
  Future<Uint8List?> createBackupArchive() async {
    try {
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
        debugPrint('DatabaseArchiverService: No Hive database files found to zip.');
        return null;
      }

      final zipData = ZipEncoder().encode(archive);
      return Uint8List.fromList(zipData);
    } catch (e) {
      debugPrint('DatabaseArchiverService Create Error: $e');
      rethrow;
    }
  }

  // ─── Restore Database From Zip ────────────────────────────────
  Future<void> restoreBackupArchive(Uint8List zipBytes) async {
    try {
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
      debugPrint('DatabaseArchiverService: Restore completed successfully.');
    } catch (e) {
      debugPrint('DatabaseArchiverService Restore Error: $e');
      // Attempt to re-initialize anyway to prevent leaving the app in a broken state
      try {
        await LocalDbService.init();
      } catch (_) {}
      rethrow;
    }
  }
}
