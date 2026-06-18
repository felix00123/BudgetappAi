import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/import_row.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isGeneratingTemplate = false;
  bool _isImporting = false;
  ImportResult? _preview;
  String? _templatePath;

  @override
  Widget build(BuildContext context) {
    return ListView(
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
                    Icon(Icons.upload_file_rounded, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text(
                      'Import from Excel',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Download the template, fill in your income and expenses, '
                  'then import the file here.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isGeneratingTemplate ? null : _downloadTemplate,
                  icon: _isGeneratingTemplate
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.description_outlined),
                  label: Text(
                    _isGeneratingTemplate ? 'Creating template...' : 'Download Template',
                  ),
                ),
                if (_templatePath != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Template saved: ${_templatePath!.split('/').last}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context
                        .read<BudgetProvider>()
                        .shareExportedFile(_templatePath!),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share Template'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: AppColors.primary.withValues(alpha: 0.05),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Template includes:', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('• Instructions sheet with column rules'),
                Text('• Transactions sheet with sample rows'),
                Text('• Categories and Accounts reference sheets'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _isImporting ? null : _pickAndPreview,
          icon: const Icon(Icons.folder_open_outlined),
          label: const Text('Choose Excel File'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        if (_preview != null) ...[
          const SizedBox(height: 24),
          _PreviewSection(
            preview: _preview!,
            isImporting: _isImporting,
            onImport: _confirmImport,
            onClear: () => setState(() => _preview = null),
          ),
        ],
      ],
    );
  }

  Future<void> _downloadTemplate() async {
    setState(() {
      _isGeneratingTemplate = true;
      _templatePath = null;
    });

    try {
      final path = await context.read<BudgetProvider>().generateImportTemplate();
      setState(() => _templatePath = path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template created! You can share or fill it in Excel.'),
            backgroundColor: AppColors.income,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create template: $e'), backgroundColor: AppColors.expense),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingTemplate = false);
    }
  }

  Future<void> _pickAndPreview() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read file. Try again.'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final preview = context.read<BudgetProvider>().previewImport(
          bytes: bytes,
          fileName: file.name,
        );

    setState(() => _preview = preview);
  }

  Future<void> _confirmImport() async {
    if (_preview == null || !_preview!.hasValidRows) return;

    setState(() => _isImporting = true);

    try {
      final transactions =
          _preview!.validRows.map((r) => r.transaction!).toList();
      final count =
          await context.read<BudgetProvider>().importTransactions(transactions);

      if (mounted) {
        setState(() => _preview = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $count transaction${count == 1 ? '' : 's'} successfully!'),
            backgroundColor: AppColors.income,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: AppColors.expense),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({
    required this.preview,
    required this.isImporting,
    required this.onImport,
    required this.onClear,
  });

  final ImportResult preview;
  final bool isImporting;
  final VoidCallback onImport;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview: ${preview.fileName}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _CountChip(
              label: '${preview.validCount} valid',
              color: AppColors.income,
            ),
            const SizedBox(width: 8),
            if (preview.invalidCount > 0)
              _CountChip(
                label: '${preview.invalidCount} errors',
                color: AppColors.expense,
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (preview.validRows.isNotEmpty) ...[
          const Text('Ready to import', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...preview.validRows.take(5).map((row) => _ImportRowTile(row: row, isError: false)),
          if (preview.validCount > 5)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '+ ${preview.validCount - 5} more rows',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
        ],
        if (preview.invalidRows.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Rows with errors', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...preview.invalidRows.take(5).map((row) => _ImportRowTile(row: row, isError: true)),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isImporting ? null : onClear,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: preview.hasValidRows && !isImporting ? onImport : null,
                child: isImporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Import ${preview.validCount}'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

class _ImportRowTile extends StatelessWidget {
  const _ImportRowTile({required this.row, required this.isError});

  final ImportRow row;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    if (isError) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: AppColors.expense.withValues(alpha: 0.06),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.error_outline, color: AppColors.expense, size: 20),
          title: Text('Row ${row.rowNumber}'),
          subtitle: Text(
            row.error ?? 'Unknown error',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    }

    final t = row.transaction!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Icon(
          t.type == TransactionType.income
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          color: t.type == TransactionType.income ? AppColors.income : AppColors.expense,
        ),
        title: Text(t.title),
        subtitle: Text(formatDate(t.date)),
        trailing: Text(
          formatCurrency(t.amount),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: t.type == TransactionType.income ? AppColors.income : AppColors.expense,
          ),
        ),
      ),
    );
  }
}
