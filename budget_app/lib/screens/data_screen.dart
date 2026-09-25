import 'package:flutter/material.dart';

import '../providers/locale_controller.dart';
import 'email_import_screen.dart';
import 'export_screen.dart';
import 'gmail_sync_screen.dart';
import 'import_screen.dart';
import 'outlook_sync_screen.dart';

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.importAndExport),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.excel, icon: const Icon(Icons.upload_file_outlined)),
              Tab(text: l10n.gmail, icon: const Icon(Icons.mail_outline_rounded)),
              Tab(text: l10n.outlook, icon: const Icon(Icons.email_outlined)),
              Tab(
                text: l10n.bankEmail,
                icon: const Icon(Icons.mark_email_read_outlined),
              ),
              Tab(text: l10n.export, icon: const Icon(Icons.download_outlined)),
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
