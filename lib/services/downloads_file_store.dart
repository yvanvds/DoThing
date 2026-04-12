import 'dart:io';

class DownloadsFileStore {
  const DownloadsFileStore._();

  static Future<File> saveToDownloads(String fileName, List<int> bytes) async {
    final userProfile = Platform.environment['USERPROFILE'];
    Directory targetDir;
    if (userProfile != null && userProfile.isNotEmpty) {
      final downloads = Directory('$userProfile\\Downloads');
      if (await downloads.exists()) {
        targetDir = downloads;
      } else {
        targetDir = Directory.current;
      }
    } else {
      targetDir = Directory.current;
    }

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final uniquePath = _buildUniquePath(targetDir.path, fileName);
    final file = File(uniquePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static String _buildUniquePath(String directoryPath, String fileName) {
    final safeName = fileName.trim().isEmpty ? 'attachment.bin' : fileName;
    final dotIndex = safeName.lastIndexOf('.');
    final hasExtension = dotIndex > 0 && dotIndex < safeName.length - 1;
    final baseName = hasExtension ? safeName.substring(0, dotIndex) : safeName;
    final extension = hasExtension ? safeName.substring(dotIndex) : '';

    var candidate = '$directoryPath${Platform.pathSeparator}$safeName';
    var counter = 1;
    while (File(candidate).existsSync()) {
      candidate =
          '$directoryPath${Platform.pathSeparator}$baseName ($counter)$extension';
      counter++;
    }
    return candidate;
  }
}
