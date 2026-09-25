import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/budget_provider.dart';
import '../services/gmail_sync_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/clear_synced_data_button.dart';
import '../widgets/mail_brand_logos.dart';

/// Connect Gmail and import bank card-alert emails.
class GmailSyncScreen extends StatefulWidget {
  const GmailSyncScreen({super.key});

  @override
  State<GmailSyncScreen> createState() => _GmailSyncScreenState();
}

class _GmailSyncScreenState extends State<GmailSyncScreen> {
  bool _busy = false;
  String _liveStatus = '';
  DateTimeRange? _customRange;
  late final ValueNotifier<String> _status;

  @override
  void initState() {
    super.initState();
    _status = context.read<BudgetProvider>().gmailSync.status;
    _status.addListener(_onStatus);
  }

  @override
  void dispose() {
    _status.removeListener(_onStatus);
    super.dispose();
  }

  void _onStatus() {
    if (!mounted) return;
    setState(() => _liveStatus = _status.value);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final connected = provider.isGmailConnected;
    final email = provider.gmailAccountEmail;
    final lastSync = provider.lastGmailSyncAt;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const GmailLogo(size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Gmail bank sync',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Read-only access to Gmail. The app looks for card alerts '
                  '(purchase, withdrawal, payment, stated balance), imports '
                  'transactions, and stores stated card balances as history only.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                _StatusRow(
                  connected: connected,
                  email: email,
                  lastSync: lastSync,
                ),
                if (_liveStatus.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _liveStatus,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (!connected)
                  MailConnectButton(
                    brand: MailBrand.gmail,
                    busy: _busy,
                    onPressed: _connect,
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _sync(),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                    label: Text(_busy ? 'Syncing…' : 'Sync now'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pickRangeAndSync,
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(
                      _customRange == null
                          ? 'Sync a date range'
                          : 'Sync ${_formatRange(_customRange!)}',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _busy ? null : _disconnect,
                    icon: const Icon(Icons.link_off_rounded),
                    label: const Text('Disconnect Gmail'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.expense,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                ClearSyncedDataButton(busy: _busy),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Setup',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Enable the Gmail API in Google Cloud Console.\n'
                  '2. Create an OAuth client (Android package '
                  'com.budgetapp.budget_app + your SHA-1; iOS with reverse '
                  'client id in Info.plist).\n'
                  '3. Add the gmail.readonly scope on the consent screen.\n'
                  '4. For iOS builds, pass '
                  '--dart-define=GOOGLE_OAUTH_CLIENT_ID=your.apps.googleusercontent.com',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You can still paste a single email on the Bank email tab '
                  'if OAuth is not set up yet.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    try {
      final email = await context.read<BudgetProvider>().connectGmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected as $email'),
          backgroundColor: AppColors.income,
        ),
      );
    } on GmailSyncException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.expense),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not connect: $e'),
          backgroundColor: AppColors.expense,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Gmail?'),
        content: const Text(
          'Imported transactions stay in the app. You can reconnect later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await context.read<BudgetProvider>().disconnectGmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gmail disconnected')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickRangeAndSync() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (picked == null || !mounted) return;
    setState(() => _customRange = picked);
    await _sync(since: picked.start, until: picked.end.add(const Duration(days: 1)));
  }

  Future<void> _sync({DateTime? since, DateTime? until}) async {
    setState(() => _busy = true);
    try {
      final summary = await context.read<BudgetProvider>().syncGmail(
            since: since,
            until: until,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(summary.message),
          backgroundColor: AppColors.income,
        ),
      );
    } on GmailSyncException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.expense),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: AppColors.expense,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _liveStatus = '';
        });
      }
    }
  }

  String _formatRange(DateTimeRange range) {
    final fmt = DateFormat.MMMd();
    return '${fmt.format(range.start)} – ${fmt.format(range.end)}';
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.connected,
    required this.email,
    required this.lastSync,
  });

  final bool connected;
  final String? email;
  final DateTime? lastSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: connected
            ? AppColors.income.withValues(alpha: 0.08)
            : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: connected
              ? AppColors.income.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            connected ? 'Connected' : 'Not connected',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: connected ? AppColors.income : AppColors.textPrimary,
            ),
          ),
          if (email != null) ...[
            const SizedBox(height: 2),
            Text(email!, style: const TextStyle(color: AppColors.textSecondary)),
          ],
          if (lastSync != null) ...[
            const SizedBox(height: 2),
            Text(
              'Last sync ${formatShortDate(lastSync!)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
