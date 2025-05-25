import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'control_tab.dart';
import 'log_tab.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Robot Controlled Pump'),
          centerTitle: true,
          bottom: TabBar(tabs: [Tab(text: 'Control'), Tab(text: 'Logs')]),
        ),
        body: TabBarView(children: [ControlTab(), LogsTab()]),
      ),
    );
  }
}
