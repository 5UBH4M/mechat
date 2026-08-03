import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';

class BackupService {
  static const String _backupDateKey = 'last_backup_date';
  static const String _appDirName = 'MeChat';
  static const String _packageName = 'com.mechat';


  Future<Directory> _getAppMediaDir() async {
    final extDir = await getExternalStorageDirectory();
    final dir = Directory(p.join(extDir?.path ?? (await getApplicationDocumentsDirectory()).path, _appDirName));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }


  Future<Directory> _getSubDir(String name) async {
    final base = await _getAppMediaDir();
    final dir = Directory(p.join(base.path, name));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }


  Future<String> createBackup({
    required String ownerUid,
    bool includeMedia = true,
    void Function(String stage, double progress)? onProgress,
  }) async {
    onProgress?.call('Closing database...', 0.1);
    await AppDatabase.instance.close();

    try {
      final dbPath = AppDatabase.instance.databasePath;
      if (dbPath == null) throw Exception('Database path is null');

      final archive = Archive();

      final metaJson = jsonEncode({'uid': ownerUid, 'createdAt': DateTime.now().toIso8601String()});
      final metaBytes = utf8.encode(metaJson);
      archive.addFile(ArchiveFile('metadata.json', metaBytes.length, metaBytes));

      onProgress?.call('Reading database...', 0.3);
      _addFileToArchive(archive, File(dbPath), 'Databases/mechat.db');


      _addFileToArchive(archive, File('$dbPath-wal'), 'Databases/mechat.db-wal');
      _addFileToArchive(archive, File('$dbPath-shm'), 'Databases/mechat.db-shm');

      if (includeMedia) {
        onProgress?.call('Reading media files...', 0.6);
        final appDocsDir = await getApplicationDocumentsDirectory();
        final mediaDir = Directory(p.join(appDocsDir.path, 'sent_media'));
        if (mediaDir.existsSync()) {
          final files = mediaDir.listSync(recursive: true);
          for (final entity in files) {
            if (entity is File) {
              final relativePath = p.relative(entity.path, from: mediaDir.path);
              _addFileToArchive(archive, entity, 'Media/$relativePath');
            }
          }
        }
      }

      onProgress?.call('Zipping backup...', 0.8);
      final zipBytes = ZipEncoder().encode(archive);

      final backupsDir = await _getSubDir('Backups');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final zipPath = p.join(backupsDir.path, 'mechat_backup_$timestamp.zip');
      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipBytes);


      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backupDateKey, DateTime.now().toIso8601String());

      onProgress?.call('Backup complete!', 1.0);
      return zipPath;
    } finally {

      await AppDatabase.instance.database;
    }
  }

  void _addFileToArchive(Archive archive, File file, String archivePath) {
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
    }
  }


  Future<void> restoreBackup(
    String zipFilePath, {
    required String currentUid,
    void Function(String stage, double progress)? onProgress,
  }) async {
    onProgress?.call('Closing database...', 0.1);
    await AppDatabase.instance.close();

    try {
      final dbPath = AppDatabase.instance.databasePath;
      if (dbPath == null) throw Exception('Database path is null');

      onProgress?.call('Verifying backup...', 0.2);
      final bytes = File(zipFilePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      final metaFile = archive.findFile('metadata.json');
      if (metaFile != null) {
        final metaStr = utf8.decode(metaFile.content as List<int>);
        final meta = jsonDecode(metaStr) as Map<String, dynamic>;
        final backupUid = meta['uid'] as String?;
        if (backupUid != null && backupUid != currentUid) {
          throw Exception('This backup belongs to a different account');
        }
      }

      onProgress?.call('Extracting backup...', 0.4);
      final appDocsDir = await getApplicationDocumentsDirectory();

      for (final file in archive) {
        if (!file.isFile) continue;

        final filename = file.name;
        final data = file.content as List<int>;

        if (filename == 'Databases/mechat.db' || filename == 'mechat.db') {
          File(dbPath).writeAsBytesSync(data);
        } else if (filename == 'Databases/mechat.db-wal' || filename == 'mechat.db-wal') {
          File('$dbPath-wal').writeAsBytesSync(data);
        } else if (filename == 'Databases/mechat.db-shm' || filename == 'mechat.db-shm') {
          File('$dbPath-shm').writeAsBytesSync(data);
        } else if (filename.startsWith('Media/')) {
          final relativePath = filename.substring('Media/'.length);
          final outFile = File(p.join(appDocsDir.path, 'sent_media', relativePath));
          outFile.parent.createSync(recursive: true);
          outFile.writeAsBytesSync(data);
        } else if (filename.startsWith('sent_media/')) {

          final outFile = File(p.join(appDocsDir.path, filename));
          outFile.parent.createSync(recursive: true);
          outFile.writeAsBytesSync(data);
        }
      }

      onProgress?.call('Restore complete!', 1.0);
    } finally {

      await AppDatabase.instance.database;
    }
  }

  Future<Map<String, int>> getBackupSizes() async {
    int dbSize = 0;
    int mediaSize = 0;


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


  Future<String> getBackupDirPath() async {
    final dir = await _getSubDir('Backups');
    return dir.path;
  }


  Future<List<FileSystemEntity>> listBackups() async {
    final dir = await _getSubDir('Backups');
    if (!dir.existsSync()) return [];
    return dir.listSync().where((f) => f.path.endsWith('.zip')).toList()
      ..sort((a, b) => b.path.compareTo(a.path));
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
