import 'dart:io';

class FileUtils {
  static Future<void> deleteFile(String path) async {
    try {
      final File file = File(path);
      if (file.existsSync()) {
        await file.delete();
      } else {
        throw 'There is no file at the following path: $path';
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteDirectory(String path) async {
    try {
      final Directory directory = Directory(path);
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      } else {
        throw 'There is no directory at the following path: $path';
      }
    } catch (e) {
      rethrow;
    }
  }
}
