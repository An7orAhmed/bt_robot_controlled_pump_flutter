import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bluetooth_service.dart';
import 'file_handler.dart';
import 'providers.dart';

class ControlTab extends ConsumerWidget {
  const ControlTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(connectionStateProvider);
    final connectedDevice = ref.watch(connectedDeviceProvider);
    final sensorData = ref.watch(sensorDataProvider);
    final bluetooth = ref.read(bluetoothServiceProvider);

    ref.listen(bluetoothServiceProvider, (_, service) {
      service.dataStream.listen((data) {
        if (data.contains('t=') && data.contains('h=')) {
          FileHandler.writeData(data);
          final parts = data.split(',').map((e) => e.split('=')).toList();
          ref.read(sensorDataProvider.notifier).state = {...sensorData, 'Temperature': parts[0][1], 'Humidity': parts[1][1]};
        }
      });
    });

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
                    title: Text('Select Bluetooth Device'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(devices[index].name ?? 'Unknown Device'),
                            onTap: () async {
                              if (await bluetooth.connect(devices[index])) {
                                ref.read(connectionStateProvider.notifier).state = true;
                                ref.read(connectedDeviceProvider.notifier).state = devices[index].name;
                                if (context.mounted) Navigator.pop(context);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text('Failed to connect to ${devices[index].name}')));
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel'))],
                  ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bluetooth permissions denied')));
          }
        }
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
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
                        Text(sensorData['Temperature'] ?? '-- °C', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                        Text(sensorData['Humidity'] ?? '-- %', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Humidity', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
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
              ControlButton(command: 'S', label: '⦿', bluetooth: bluetooth),
              ControlButton(command: 'R', label: '►', bluetooth: bluetooth),
              Container(),
              ControlButton(command: 'D', label: '▼', bluetooth: bluetooth),
              Container(),
            ],
          ),
          SizedBox(height: 16),
          // Pump and Sensor Buttons
          Row(
            spacing: 16,
            children: [
              Expanded(
                child: FilledButton(
                  onPressed:
                      isConnected
                          ? () {
                            final cmd = sensorData['Pump'] == 'ON' ? 'P0' : 'P1';
                            bluetooth.sendCommand(cmd);
                            FileHandler.writeData('Pump ${cmd == 'P1' ? 'ON' : 'OFF'}');
                            ref.read(sensorDataProvider.notifier).state = {...sensorData, 'Pump': cmd == 'P1' ? 'ON' : 'OFF'};
                          }
                          : null,
                  child: Text(sensorData['Pump'] == 'ON' ? 'Stop Pump' : 'Start Pump'),
                ),
              ),
              Expanded(child: FilledButton(onPressed: isConnected ? () => bluetooth.sendCommand('RS') : null, child: Text('Read Sensor'))),
            ],
          ),
          SizedBox(height: 16),
          // Connect/Disconnect Button
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: handleConnectButton, child: Text(isConnected ? 'Disconnect ($connectedDevice)' : 'Connect')),
          ),
        ],
      ),
    );
  }
}

// Control Button Widget
class ControlButton extends StatefulWidget {
  final String command;
  final String label;
  final BluetoothService bluetooth;

  const ControlButton({super.key, required this.command, required this.label, required this.bluetooth});

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  Timer? _timer;

  void _stop() {
    _timer?.cancel();
    if (widget.command != 'S') widget.bluetooth.sendCommand('S');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        widget.bluetooth.sendCommand(widget.command);
        _timer = Timer.periodic(Duration(milliseconds: 100), (_) {
          widget.bluetooth.sendCommand(widget.command);
        });
      },
      onTapUp: (_) => _stop(),
      onTapCancel: () => _stop(),
      child: Container(
        decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(25)),
        child: Center(child: Text(widget.label, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))),
      ),
    );
  }
}
