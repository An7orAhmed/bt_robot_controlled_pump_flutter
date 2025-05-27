import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class FileHandler {
  static Future<String> get _localPath async {
    final directory = await getDownloadsDirectory();
    return directory!.path;
  }

  static Future<File> _getFile(String date) async {
    date = date.split('.').first;
    final path = await _localPath;
    return File('$path/$date.txt');
  }

  static Future<bool> writeData(String data) async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final file = await _getFile(date);
    bool isCreated = false;
    if (!await file.exists()) {
      debugPrint('File does not exist, creating new file...');
      await file.create();
      isCreated = true;
    } else {
      debugPrint('File exists, appending data...');
    }
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    await file.writeAsString('$timestamp: $data\n', mode: FileMode.append);
    return isCreated;
  }

  static Future<List<String>> readData(String fileName) async {
    final file = await _getFile(fileName);
    if (await file.exists()) {
      debugPrint('File exists, reading content');
      return (await file.readAsString()).split('\n').where((line) => line.isNotEmpty).toList();
    }
    return [];
  }

  static Future<void> deleteFile(String fileName) async {
    final file = await _getFile(fileName);
    if (await file.exists()) {
      debugPrint('File exists, deleting');
      await file.delete();
    }
  }
}
