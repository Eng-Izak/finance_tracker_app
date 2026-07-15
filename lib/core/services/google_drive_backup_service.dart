import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'google_auth_service.dart';
import 'database_archiver_service.dart';

class GoogleDriveBackupService {
  final GoogleAuthService _authService;
  final DatabaseArchiverService _archiverService;

  GoogleDriveBackupService({
    required GoogleAuthService authService,
    required DatabaseArchiverService archiverService,
  })  : _authService = authService,
        _archiverService = archiverService;

  // ─── Perform Backup (Upload / Update) ──────────────────────────
  Future<DateTime> uploadBackup(String customName) async {
    try {
      // 1. Sanitize file name
      final fileName = customName.endsWith('.zip') ? customName : '$customName.zip';

      // 2. Compile databases into zip archive
      final zipBytes = await _archiverService.createBackupArchive();
      if (zipBytes == null) {
        throw Exception('لا توجد بيانات محلية لعمل نسخة احتياطية منها.');
      }

      // 3. Check if a backup file with the same name already exists on Drive
      final existingFileId = await _findBackupFileId(fileName);

      http.Response response;
      if (existingFileId != null) {
        // Update existing backup (PATCH)
        final url = Uri.parse(
            'https://www.googleapis.com/upload/drive/v3/files/$existingFileId?uploadType=media');
        response = await _sendWithAuth(
          'PATCH',
          url,
          headers: {'Content-Type': 'application/zip'},
          body: zipBytes,
        );
      } else {
        // Create new backup (POST multipart/related)
        final url = Uri.parse(
            'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart');
        const boundary = 'backup_system_boundary';
        final metadata = jsonEncode({
          'name': fileName,
          'parents': ['appDataFolder'],
        });

        final List<int> bodyBytes = [];
        bodyBytes.addAll(utf8.encode('--$boundary\r\n'));
        bodyBytes.addAll(utf8.encode(
            'Content-Type: application/json; charset=UTF-8\r\n\r\n'));
        bodyBytes.addAll(utf8.encode('$metadata\r\n'));
        bodyBytes.addAll(utf8.encode('--$boundary\r\n'));
        bodyBytes.addAll(utf8.encode('Content-Type: application/zip\r\n\r\n'));
        bodyBytes.addAll(zipBytes);
        bodyBytes.addAll(utf8.encode('\r\n--$boundary--\r\n'));

        response = await _sendWithAuth(
          'POST',
          url,
          headers: {
            'Content-Type': 'multipart/related; boundary=$boundary',
          },
          body: Uint8List.fromList(bodyBytes),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('GoogleDriveBackupService: Upload success.');
        return DateTime.now();
      } else {
        throw Exception(
            'فشل رفع النسخة الاحتياطية إلى Google Drive: ${response.body}');
      }
    } catch (e) {
      debugPrint('GoogleDriveBackupService Upload Error: $e');
      rethrow;
    }
  }

  // ─── Perform Restore (Download / Extract) ──────────────────────
  Future<void> downloadBackup(String fileId) async {
    try {
      // Download zip binary content
      final url = Uri.parse(
          'https://www.googleapis.com/drive/v3/files/$fileId?alt=media');
      final response = await _sendWithAuth('GET', url);

      if (response.statusCode == 200) {
        // Extract and overwrite database
        await _archiverService.restoreBackupArchive(response.bodyBytes);
        debugPrint('GoogleDriveBackupService: Restore success.');
      } else {
        throw Exception(
            'فشل تحميل النسخة الاحتياطية من Google Drive: ${response.body}');
      }
    } catch (e) {
      debugPrint('GoogleDriveBackupService Download Error: $e');
      rethrow;
    }
  }

  // ─── List Available Backups ────────────────────────────────────
  Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      final url = Uri.parse(
          'https://www.googleapis.com/drive/v3/files?spaces=appDataFolder&q=trashed=false&fields=files(id,name,createdTime,size)&orderBy=createdTime%20desc');
      final response = await _sendWithAuth('GET', url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final files = data['files'] as List<dynamic>;
        return files.map((file) => file as Map<String, dynamic>).toList();
      } else {
        throw Exception('فشل جلب قائمة النسخ الاحتياطية: ${response.body}');
      }
    } catch (e) {
      debugPrint('GoogleDriveBackupService listBackups Error: $e');
      rethrow;
    }
  }

  // ─── Find Backup file ID ───────────────────────────────────────
  Future<String?> _findBackupFileId(String fileName) async {
    final query = Uri.encodeComponent("name='$fileName' and trashed=false");
    final url = Uri.parse(
        'https://www.googleapis.com/drive/v3/files?spaces=appDataFolder&q=$query');
    final response = await _sendWithAuth('GET', url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final files = data['files'] as List<dynamic>;
      if (files.isNotEmpty) {
        return files.first['id'] as String;
      }
      return null;
    } else {
      throw Exception('فشل فحص ملفات Google Drive: ${response.body}');
    }
  }

  // ─── Send Request with Token Retry ─────────────────────────────
  Future<http.Response> _sendWithAuth(
    String method,
    Uri url, {
    Map<String, String>? headers,
    List<int>? body,
  }) async {
    String? token = await _authService.getAccessToken();
    if (token == null) {
      throw Exception('المستخدم غير متصل بحساب Google.');
    }

    final reqHeaders = {
      'Authorization': 'Bearer $token',
      ...?headers,
    };

    http.Response response;
    if (method == 'POST') {
      response = await http.post(url, headers: reqHeaders, body: body);
    } else if (method == 'PATCH') {
      response = await http.patch(url, headers: reqHeaders, body: body);
    } else if (method == 'GET') {
      response = await http.get(url, headers: reqHeaders);
    } else {
      throw UnsupportedError('HTTP Method $method not supported.');
    }

    // Attempt token refresh on 401 Unauthorized
    if (response.statusCode == 401) {
      final refreshSuccess = await _authService.silentSignIn();
      if (refreshSuccess) {
        token = await _authService.getAccessToken();
        reqHeaders['Authorization'] = 'Bearer $token';

        // Retry the request once
        if (method == 'POST') {
          response = await http.post(url, headers: reqHeaders, body: body);
        } else if (method == 'PATCH') {
          response = await http.patch(url, headers: reqHeaders, body: body);
        } else if (method == 'GET') {
          response = await http.get(url, headers: reqHeaders);
        }
      }
    }

    return response;
  }
}
