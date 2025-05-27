import 'package:flutter/material.dart';

import 'file_handler.dart';

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

          if (snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          }

          return ListView.separated(
            itemBuilder: (BuildContext context, int index) {
              final line = snapshot.data![index];
              final parts = line.split(': ');
              final timestamp = parts[0];
              final data = parts[1];
              if (data.contains("PUMP")) {
                return ListTile(
                  title: Text(data, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(timestamp),
                  tileColor: data.contains("ON") ? Colors.lightGreen.withAlpha(30) : Colors.red.withAlpha(30),
                );
              }

              return ListTile(title: Text(data, style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(timestamp));
            },
            separatorBuilder: (BuildContext context, int index) {
              return Divider(color: Colors.grey.shade300, height: 1);
            },
            itemCount: snapshot.data!.length,
          );
        },
      ),
    );
  }
}
