import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;
  String? _exportedPath;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final filteredCount = provider.filterTransactions(
      startDate: _startDate,
      endDate: _endDate != null
          ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
          : null,
    ).length;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Export to Excel'))
          : null,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.table_chart_rounded, color: AppColors.primary),
                      SizedBox(width: 12),
                      Text(
                        'Excel Report',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Generate an Excel file with all your transactions, '
                    'including a daily summary grouped by date.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$filteredCount transactions will be exported',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Date Range (optional)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _DatePickerTile(
            label: 'Start Date',
            date: _startDate,
            onTap: () => _pickDate(isStart: true),
            onClear: () => setState(() => _startDate = null),
          ),
          const SizedBox(height: 8),
          _DatePickerTile(
            label: 'End Date',
            date: _endDate,
            onTap: () => _pickDate(isStart: false),
            onClear: () => setState(() => _endDate = null),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('This Month'),
                onPressed: () {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = DateTime(now.year, now.month, 1);
                    _endDate = now;
                  });
                },
              ),
              ActionChip(
                label: const Text('Last 30 Days'),
                onPressed: () {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = now.subtract(const Duration(days: 30));
                    _endDate = now;
                  });
                },
              ),
              ActionChip(
                label: const Text('All Time'),
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _isExporting ? null : () => _export(context),
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.file_download_outlined),
            label: Text(_isExporting ? 'Generating...' : 'Export Excel'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          if (_exportedPath != null) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.income.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.income),
                        SizedBox(width: 8),
                        Text(
                          'Export successful!',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _exportedPath!.split('/').last,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context
                          .read<BudgetProvider>()
                          .shareExportedFile(_exportedPath!),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share File'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Report includes:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...[
            'Summary with total income, expenses, and balance',
            'All transactions with date, type, category, and amount',
            'Daily summary grouped by date',
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.primary)),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _export(BuildContext context) async {
    setState(() {
      _isExporting = true;
      _exportedPath = null;
    });

    try {
      final provider = context.read<BudgetProvider>();
      final path = await provider.exportToExcel(
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() => _exportedPath = path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel file generated successfully!'),
            backgroundColor: AppColors.income,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: date != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today_rounded),
        ),
        child: Text(
          date != null ? formatDate(date!) : 'Not set',
          style: TextStyle(
            color: date != null
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
