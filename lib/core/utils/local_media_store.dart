import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;


class LocalMediaStore {
  static Future<String> saveFile(String sourcePath, String messageId, String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(appDir.path, 'sent_media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final ext = p.extension(fileName).isNotEmpty ? p.extension(fileName) : p.extension(sourcePath);
    final destPath = p.join(mediaDir.path, '$messageId$ext');


    if (await File(destPath).exists()) return destPath;

    await File(sourcePath).copy(destPath);
    return destPath;
  }


  static Future<void> deleteFile(String messageId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(appDir.path, 'sent_media'));
    if (!await mediaDir.exists()) return;

    await for (final entity in mediaDir.list()) {
      if (entity is File && p.basenameWithoutExtension(entity.path) == messageId) {
        await entity.delete();
        break;
      }
    }
  }
}
