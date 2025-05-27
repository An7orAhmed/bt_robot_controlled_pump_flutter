import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_handler.dart';
import 'log_details_screen.dart';
import 'providers.dart';

class LogsTab extends ConsumerWidget {
  const LogsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logFiles = ref.watch(logFilesProvider);
    ref.invalidate(logFilesProvider); // Ensure the provider is refreshed

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
        return ListView.separated(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final fileName = files[index];
            return ListTile(
              title: Text(fileName.split('.').first),
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
          separatorBuilder: (BuildContext context, int index) {
            return Divider(color: Colors.grey.shade300, height: 1);
          },
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}