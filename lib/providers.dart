import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:robot_controlled_pump/bluetooth_service.dart';

final bluetoothServiceProvider = Provider<BluetoothService>((ref) {
  final service = BluetoothService();
  ref.onDispose(() => service.dispose());
  return service;
});

final connectionStateProvider = StateProvider<bool>((ref) => false);
final connectedDeviceProvider = StateProvider<String?>((ref) => null);
final sensorDataProvider = StateProvider<Map<String, String>>((ref) => {});

final logFilesProvider = FutureProvider<List<String>>((ref) async {
  final dir = await getDownloadsDirectory();
  return dir!.listSync().whereType<File>().map((f) => f.path.split('/').last).toList();
});

final pumpStateProvider = StateProvider<bool>((ref) => false);
final upStateProvider = StateProvider<bool>((ref) => false);
final downStateProvider = StateProvider<bool>((ref) => false);
final leftStateProvider = StateProvider<bool>((ref) => false);
final rightStateProvider = StateProvider<bool>((ref) => false);