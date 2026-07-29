import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';

class BackupService {
  static const String _backupDateKey = 'last_backup_date';

  /// Create a backup zip containing the SQLite DB and sent_media folder
  /// Returns the path to the created zip file
  Future<String> createBackup({
    bool includeMedia = true,
    void Function(String stage, double progress)? onProgress,
  }) async {
    onProgress?.call('Closing database...', 0.1);
    await AppDatabase.instance.close();

    try {
      final dbPath = AppDatabase.instance.databasePath;
      if (dbPath == null) throw Exception('Database path is null');

      final archive = Archive();

      onProgress?.call('Reading database...', 0.3);
      _addFileToArchive(archive, File(dbPath), 'mechat.db');
      
      // Also copy WAL and SHM if they exist
      _addFileToArchive(archive, File('$dbPath-wal'), 'mechat.db-wal');
      _addFileToArchive(archive, File('$dbPath-shm'), 'mechat.db-shm');

      if (includeMedia) {
        onProgress?.call('Reading media files...', 0.6);
        final appDocsDir = await getApplicationDocumentsDirectory();
        final mediaDir = Directory(p.join(appDocsDir.path, 'sent_media'));
        if (mediaDir.existsSync()) {
          final files = mediaDir.listSync(recursive: true);
          for (final entity in files) {
            if (entity is File) {
              final relativePath = p.relative(entity.path, from: appDocsDir.path);
              _addFileToArchive(archive, entity, relativePath);
            }
          }
        }
      }

      onProgress?.call('Zipping backup...', 0.8);
      final zipBytes = ZipEncoder().encode(archive);

      final docsDir = await getApplicationDocumentsDirectory();
      final zipPath = p.join(docsDir.path, 'mechat_backup_${DateTime.now().millisecondsSinceEpoch}.zip');
      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipBytes);

      // Save backup date
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backupDateKey, DateTime.now().toIso8601String());

      onProgress?.call('Backup complete!', 1.0);
      return zipPath;
    } finally {
      // Reopen database
      await AppDatabase.instance.database;
    }
  }

  void _addFileToArchive(Archive archive, File file, String archivePath) {
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
    }
  }

  /// Restore from a zip file
  Future<void> restoreBackup(
    String zipFilePath, {
    void Function(String stage, double progress)? onProgress,
  }) async {
    onProgress?.call('Closing database...', 0.1);
    await AppDatabase.instance.close();

    try {
      final dbPath = AppDatabase.instance.databasePath;
      if (dbPath == null) throw Exception('Database path is null');
      
      onProgress?.call('Extracting backup...', 0.4);
      final bytes = File(zipFilePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final appDocsDir = await getApplicationDocumentsDirectory();

      for (final file in archive) {
        if (!file.isFile) continue;

        final filename = file.name;
        final data = file.content as List<int>;

        if (filename == 'mechat.db') {
          File(dbPath).writeAsBytesSync(data);
        } else if (filename == 'mechat.db-wal') {
          File('$dbPath-wal').writeAsBytesSync(data);
        } else if (filename == 'mechat.db-shm') {
          File('$dbPath-shm').writeAsBytesSync(data);
        } else if (filename.startsWith('sent_media/')) {
          final outFile = File(p.join(appDocsDir.path, filename));
          outFile.parent.createSync(recursive: true);
          outFile.writeAsBytesSync(data);
        }
      }

      onProgress?.call('Restore complete!', 1.0);
    } finally {
      // Reopen database
      await AppDatabase.instance.database;
    }
  }

  Future<Map<String, int>> getBackupSizes() async {
    int dbSize = 0;
    int mediaSize = 0;

    // Ensure _dbPath is populated
    await AppDatabase.instance.database;
    final dbPath = AppDatabase.instance.databasePath;
    
    if (dbPath != null) {
      final dbFile = File(dbPath);
      if (dbFile.existsSync()) {
        dbSize += dbFile.lengthSync();
      }
      final walFile = File('$dbPath-wal');
      if (walFile.existsSync()) dbSize += walFile.lengthSync();
      final shmFile = File('$dbPath-shm');
      if (shmFile.existsSync()) dbSize += shmFile.lengthSync();
    }

    final appDocsDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(appDocsDir.path, 'sent_media'));
    if (mediaDir.existsSync()) {
      final files = mediaDir.listSync(recursive: true);
      for (final entity in files) {
        if (entity is File) {
          mediaSize += entity.lengthSync();
        }
      }
    }

    return {'database': dbSize, 'media': mediaSize};
  }

  Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_backupDateKey);
    if (dateStr != null) {
      return DateTime.tryParse(dateStr);
    }
    return null;
  }
}
