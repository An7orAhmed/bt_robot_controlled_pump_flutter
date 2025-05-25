import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_handler.dart';
import 'providers.dart';

class LogsTab extends ConsumerWidget {
  const LogsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logFiles = ref.watch(logFilesProvider);

    return logFiles.when(
      data: (files) {
        if (files.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.info, size: 48, color: Colors.grey), SizedBox(height: 8), Text('No data recorded')],
            ),
          );
        }
        return ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final fileName = files[index];
            return ListTile(
              title: Text('Date: $fileName'),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('Confirm Delete'),
                          content: Text('Are you sure you want to delete $fileName?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                            TextButton(
                              onPressed: () async {
                                await FileHandler.deleteFile(fileName);
                                ref.invalidate(logFilesProvider);
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                  );
                },
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => LogDetailPage(fileName: fileName)));
              },
            );
          },
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

// Log Detail Page
class LogDetailPage extends StatelessWidget {
  final String fileName;

  const LogDetailPage({super.key, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(fileName)),
      body: FutureBuilder<List<String>>(
        future: FileHandler.readData(fileName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('Timestamp')),
                DataColumn(label: Text('Temperature')),
                DataColumn(label: Text('Humidity')),
                DataColumn(label: Text('Event')),
              ],
              rows:
                  snapshot.data!.map((line) {
                    final parts = line.split(': ');
                    final timestamp = parts[0];
                    final data = parts[1];
                    bool isPumpEvent = data.contains('Pump');
                    return DataRow(
                      color: isPumpEvent ? WidgetStateProperty.all(Colors.yellow.withAlpha(30)) : null,
                      cells: [
                        DataCell(Text(timestamp)),
                        DataCell(
                          Text(
                            isPumpEvent
                                ? ''
                                : data.contains('t=')
                                ? data.split(',')[0].split('=')[1]
                                : '',
                          ),
                        ),
                        DataCell(
                          Text(
                            isPumpEvent
                                ? ''
                                : data.contains('h=')
                                ? data.split(',')[1].split('=')[1]
                                : '',
                          ),
                        ),
                        DataCell(Text(isPumpEvent ? data : '')),
                      ],
                    );
                  }).toList(),
            ),
          );
        },
      ),
    );
  }
}
