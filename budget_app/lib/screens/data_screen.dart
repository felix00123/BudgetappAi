import 'package:flutter/material.dart';

import 'export_screen.dart';
import 'import_screen.dart';

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Import & Export'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Import', icon: Icon(Icons.upload_file_outlined)),
              Tab(text: 'Export', icon: Icon(Icons.download_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ImportScreen(),
            ExportScreen(showAppBar: false),
          ],
        ),
      ),
    );
  }
}
