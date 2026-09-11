import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../providers/budget_provider.dart';
import '../services/ai_capture_service.dart';
import '../theme/app_theme.dart';
import 'ai_expense_review_sheet.dart';

/// Shared entry points for receipt photos and spoken expenses.
class AiCaptureActions {
  AiCaptureActions._();

  static final _picker = ImagePicker();
  static final _speech = SpeechToText();

  /// Camera or gallery → AI draft → confirm sheet.
  static Future<void> captureReceipt(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    await _pickAndDraftReceipt(context, source);
  }

  /// Opens the camera immediately (home floating action).
  static Future<void> captureReceiptFromCamera(BuildContext context) {
    return _pickAndDraftReceipt(context, ImageSource.camera);
  }

  static Future<void> _pickAndDraftReceipt(
    BuildContext context,
    ImageSource source,
  ) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null || !context.mounted) return;

    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    final mime = _mimeForPath(file.path);
    final provider = context.read<BudgetProvider>();
    await _runDraft(
      context,
      () => provider.draftFromReceipt(
            Uint8List.fromList(bytes),
            mimeType: mime,
          ),
    );
  }

  /// On-device speech → AI draft → confirm sheet.
  static Future<void> captureVoice(BuildContext context) async {
    final provider = context.read<BudgetProvider>();
    if (!provider.isAiConfigured) {
      _showError(context, provider.aiSetupHint);
      return;
    }

    final available = await _speech.initialize(
      onError: (error) {
        debugPrint('Speech error: ${error.errorMsg}');
      },
    );
    if (!available) {
      if (context.mounted) {
        _showError(
          context,
          'Speech recognition is not available on this device.',
        );
      }
      return;
    }
    if (!context.mounted) return;

    final transcript = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _VoiceListenDialog(),
    );
    if (transcript == null || transcript.trim().isEmpty || !context.mounted) {
      return;
    }

    await _runDraft(
      context,
      () => provider.draftFromVoiceTranscript(transcript),
    );
  }

  static Future<void> _runDraft(
    BuildContext context,
    Future<dynamic> Function() buildDraft,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Reading with AI…')),
            ],
          ),
        ),
      ),
    );

    try {
      final draft = await buildDraft();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final saved = await showAiExpenseReviewSheet(context, draft: draft);
      if (saved && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense saved'),
            backgroundColor: AppColors.income,
          ),
        );
      }
    } on AiCaptureException catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showError(context, e.message);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showError(context, 'Something went wrong: $e');
    }
  }

  static String _mimeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.expense),
    );
  }
}

class _VoiceListenDialog extends StatefulWidget {
  const _VoiceListenDialog();

  @override
  State<_VoiceListenDialog> createState() => _VoiceListenDialogState();
}

class _VoiceListenDialogState extends State<_VoiceListenDialog> {
  final _speech = SpeechToText();
  String _words = '';
  bool _listening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final ready = await _speech.initialize();
    if (!ready) {
      if (mounted) {
        setState(() => _error = 'Could not start the microphone.');
      }
      return;
    }

    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() => _words = result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        localeId: 'es_DO',
      ),
    );
  }

  Future<void> _stop({bool submit = true}) async {
    await _speech.stop();
    if (!mounted) return;
    if (submit) {
      Navigator.pop(context, _words.trim());
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Say your expense'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _error ??
                (_listening
                    ? 'Listening… e.g. “Gasté 350 pesos en Uber”'
                    : 'Starting microphone…'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              _words.isEmpty ? '—' : _words,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _stop(submit: false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _words.trim().isEmpty ? null : () => _stop(),
          child: const Text('Use this'),
        ),
      ],
    );
  }
}
