import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bluetooth_service.dart';
import 'file_handler.dart';
import 'providers.dart';

class ControlTab extends ConsumerStatefulWidget {
  const ControlTab({super.key});

  @override
  ConsumerState<ControlTab> createState() => _ControlTabState();
}

class _ControlTabState extends ConsumerState<ControlTab> {
  StreamSubscription<String>? _dataSubscription;

  void showPopupMessage(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
  }

  @override
  void initState() {
    super.initState();
    final bluetooth = ref.read(bluetoothServiceProvider);
    _dataSubscription = bluetooth.dataStream.listen((data) {
      debugPrint('Received: $data');
      if (data.contains('t=') && data.contains('h=')) {
        final parts = data.split(',').map((e) => e.split('=')).toList();
        ref.read(sensorDataProvider.notifier).state = {'Temperature': parts[0][1], 'Humidity': parts[1][1]};
      } else if (data.contains("msg=")) {
        if (data.isNotEmpty) {
          if (data.contains('bl')) {
            showPopupMessage("Barrier detected! Left move not allowed.");
          } else if (data.contains('br')) {
            showPopupMessage("Barrier detected! Right move not allowed.");
          } else if (data.contains('bf')) {
            showPopupMessage("Barrier detected! Forward move not allowed.");
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(connectionStateProvider);
    final connectedDevice = ref.watch(connectedDeviceProvider);
    final sensorData = ref.watch(sensorDataProvider);
    final bluetooth = ref.read(bluetoothServiceProvider);

    Future<void> handleConnectButton() async {
      if (isConnected) {
        bluetooth.disconnect();
        ref.read(connectionStateProvider.notifier).state = false;
        ref.read(connectedDeviceProvider.notifier).state = null;
      } else {
        if (await bluetooth.requestPermissions()) {
          final devices = await bluetooth.getPairedDevices();
          if (context.mounted) {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text('Select BT Device'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(devices[index].name ?? 'Unknown Device'),
                            onTap: () async {
                              if (bluetooth.isConnected) bluetooth.disconnect();
                              if (await bluetooth.connect(devices[index])) {
                                ref.read(connectionStateProvider.notifier).state = true;
                                ref.read(connectedDeviceProvider.notifier).state = devices[index].name;
                                if (context.mounted) Navigator.pop(context);
                              } else {
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(backgroundColor: Colors.red, content: Text('Failed to connect to ${devices[index].name}')),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Bluetooth permissions denied')));
          }
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Sensor Data Cards
          Row(
            spacing: 16,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text("${sensorData['Temperature'] ?? '--'}°C", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Temperature', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text("${sensorData['Humidity'] ?? '--'}%", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Humidity', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Spacer(),
          // Robot Controls
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            childAspectRatio: 1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              Container(),
              ControlButton(command: 'U', label: '▲', bluetooth: bluetooth),
              Container(),
              ControlButton(command: 'L', label: '◄', bluetooth: bluetooth),
              ControlButton(command: 'P', label: '⦿', bluetooth: bluetooth),
              ControlButton(command: 'R', label: '►', bluetooth: bluetooth),
              Container(),
              ControlButton(command: 'D', label: '▼', bluetooth: bluetooth),
              Container(),
            ],
          ),
          Spacer(),
          // Connect/Disconnect Button
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: handleConnectButton, child: Text(isConnected ? 'Disconnect ($connectedDevice)' : 'Connect')),
          ),
          SizedBox(height: 10),
          Text('Developed by Antara Noshin Nova', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

// Control Button Widget
class ControlButton extends ConsumerWidget {
  final String command;
  final String label;
  final BluetoothService bluetooth;
  const ControlButton({super.key, required this.command, required this.label, required this.bluetooth});

  @override
  Widget build(BuildContext context, ref) {
    final isConnected = ref.watch(connectionStateProvider);
    final isPumpOn = ref.watch(pumpStateProvider);
    final isUpPressed = ref.watch(upStateProvider);
    final isDownPressed = ref.watch(downStateProvider);
    final isLeftPressed = ref.watch(leftStateProvider);
    final isRightPressed = ref.watch(rightStateProvider);

    Future<void> send(String command) async {
      if (!isConnected) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Please connect to a BT device...')));
        return;
      }
      if (command == 'P') {
        ref.read(pumpStateProvider.notifier).state = !isPumpOn;
        bluetooth.sendCommand(command + (isPumpOn ? '0' : '1'));
        await FileHandler.writeData("PUMP ${isPumpOn ? 'OFF' : 'ON'}");
        return;
      } else if (command == 'U') {
        ref.read(upStateProvider.notifier).state = true;
      } else if (command == 'D') {
        ref.read(downStateProvider.notifier).state = true;
      } else if (command == 'L') {
        ref.read(leftStateProvider.notifier).state = true;
      } else if (command == 'R') {
        ref.read(rightStateProvider.notifier).state = true;
      } else {
        ref.read(upStateProvider.notifier).state = false;
        ref.read(downStateProvider.notifier).state = false;
        ref.read(leftStateProvider.notifier).state = false;
        ref.read(rightStateProvider.notifier).state = false;
      }
      bluetooth.sendCommand(command);
    }

    final Color buttonColor;
    if (command == 'P') {
      buttonColor = isPumpOn ? Colors.lightGreen : Colors.redAccent;
    } else if (command == 'U') {
      buttonColor = isUpPressed ? Theme.of(context).primaryColor : Colors.grey;
    } else if (command == 'D') {
      buttonColor = isDownPressed ? Theme.of(context).primaryColor : Colors.grey;
    } else if (command == 'L') {
      buttonColor = isLeftPressed ? Theme.of(context).primaryColor : Colors.grey;
    } else if (command == 'R') {
      buttonColor = isRightPressed ? Theme.of(context).primaryColor : Colors.grey;
    } else {
      buttonColor = Theme.of(context).primaryColor;
    }

    return GestureDetector(
      onTapUp: (_) => command != 'P' ? send('S') : null,
      onTapDown: (_) => send(command),
      onTapCancel: () => command != 'P' ? send('S') : null,
      child: Container(
        decoration: BoxDecoration(color: buttonColor, borderRadius: BorderRadius.circular(25)),
        child: Center(child: Text(label, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))),
      ),
    );
  }
}
