import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class FileHandler {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> _getFile(String date) async {
    final path = await _localPath;
    return File('$path/$date.txt');
  }

  static Future<void> writeData(String data) async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final file = await _getFile(date);
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    await file.writeAsString('$timestamp: $data\n', mode: FileMode.append);
  }

  static Future<List<String>> readData(String fileName) async {
    final file = await _getFile(fileName);
    if (await file.exists()) {
      return (await file.readAsString()).split('\n').where((line) => line.isNotEmpty).toList();
    }
    return [];
  }

  static Future<void> deleteFile(String fileName) async {
    final file = await _getFile(fileName);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
