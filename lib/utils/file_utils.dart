import 'dart:io';

class FileUtils {
  static Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
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
      final directory = Directory(path);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      } else {
        throw 'There is no directory at the following path: $path';
      }
    } catch (e) {
      rethrow;
    }
  }
}
