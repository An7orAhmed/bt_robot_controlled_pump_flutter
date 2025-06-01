import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import 'file_handler.dart';

class BluetoothService {
  final _controller = StreamController<String>.broadcast();
  Stream<String> get dataStream => _controller.stream;

  BluetoothConnection? _connection;
  bool get isConnected => _connection != null && _connection!.isConnected;
  String? connectedDevice;

  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothConnect].request();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<List<BluetoothDevice>> getPairedDevices() async {
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      if (_connection == null) {
        debugPrint('Failed to connect to the device');
        return false;
      }
      _connection?.input!
          .listen((data) {
            String received = String.fromCharCodes(data).trim();
            if (received.isNotEmpty) {
              _controller.add(received);
              if (received.contains('t=') && received.contains('h=')) {
                FileHandler.writeData(received);
              }
            }
          })
          .onDone(() {
            disconnect();
          });
      connectedDevice = device.name;
      return true;
    } catch (e) {
      debugPrint('Connection error: $e');
      return false;
    }
  }

  void disconnect() {
    _connection?.dispose();
    _connection = null;
  }

  void sendCommand(String command) {
    if (isConnected) {
      _connection!.output.add(Uint8List.fromList(command.codeUnits));
    }
  }

  void dispose() {
    _controller.close();
    disconnect();
  }
}
