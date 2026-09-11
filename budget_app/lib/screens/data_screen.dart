import 'package:flutter/material.dart';

import 'email_import_screen.dart';
import 'export_screen.dart';
import 'gmail_sync_screen.dart';
import 'import_screen.dart';
import 'outlook_sync_screen.dart';

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Import & Export'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Excel', icon: Icon(Icons.upload_file_outlined)),
              Tab(text: 'Gmail', icon: Icon(Icons.mail_outline_rounded)),
              Tab(text: 'Outlook', icon: Icon(Icons.email_outlined)),
              Tab(
                text: 'Bank email',
                icon: Icon(Icons.mark_email_read_outlined),
              ),
              Tab(text: 'Export', icon: Icon(Icons.download_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ImportScreen(),
            GmailSyncScreen(),
            OutlookSyncScreen(),
            EmailImportScreen(),
            ExportScreen(showAppBar: false),
          ],
        ),
      ),
    );
  }
}
