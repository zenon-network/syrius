import 'dart:io';

/// Utilities for deleting local files and directories.
class FileUtils {
  /// Deletes the file at [path], throwing a [FileSystemException] if it does
  /// not exist.
  static Future<void> deleteFile(String path) async {
    try {
      final File file = File(path);
      if (file.existsSync()) {
        await file.delete();
      } else {
        throw FileSystemException(
          'There is no file at the following path: $path',
          path,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Recursively deletes the directory at [path], throwing a
  /// [FileSystemException] if it does not exist.
  static Future<void> deleteDirectory(String path) async {
    try {
      final Directory directory = Directory(path);
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      } else {
        throw FileSystemException(
          'There is no directory at the following path: $path',
          path,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
