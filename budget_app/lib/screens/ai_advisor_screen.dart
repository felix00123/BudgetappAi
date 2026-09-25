import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_provider_settings.dart';
import '../models/chat_message.dart';
import '../providers/budget_provider.dart';
import '../providers/locale_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_nav_bar.dart';

class AiAdvisorScreen extends StatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.advisorTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _clearChat(context),
            tooltip: l10n.clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<BudgetProvider>(
              builder: (context, provider, _) {
                if (provider.chatMessages.isEmpty) {
                  return _WelcomeView(
                    suggestions: context.l10n.advisorSuggestions,
                    onSuggestionTap: (s) {
                      _controller.text = s;
                      _sendMessage(provider);
                    },
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.chatMessages.length +
                      (provider.isAiThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.chatMessages.length) {
                      return const _TypingIndicator();
                    }
                    return _ChatBubble(message: provider.chatMessages[index]);
                  },
                );
              },
            ),
          ),
          _ChatInput(
            controller: _controller,
            onSend: () {
              final provider = context.read<BudgetProvider>();
              _sendMessage(provider);
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage(BudgetProvider provider) {
    final text = _controller.text.trim();
    if (text.isEmpty || provider.isAiThinking) return;
    _controller.clear();
    provider.sendChatMessage(text);
  }

  void _clearChat(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearChatTitle),
        content: Text(l10n.clearChatBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              context.read<BudgetProvider>().clearChat();
              Navigator.pop(ctx);
            },
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    final provider = context.read<BudgetProvider>();
    final initial = provider.aiSettings;
    var kind = initial.kind;
    final openAiKey = TextEditingController(text: initial.openAiApiKey ?? '');
    final geminiKey = TextEditingController(text: initial.geminiApiKey ?? '');
    final localUrl = TextEditingController(text: initial.localBaseUrl);
    final localModel = TextEditingController(text: initial.localModel);
    final openAiModel = TextEditingController(text: initial.openAiModel);
    final geminiModel = TextEditingController(text: initial.geminiModel);
    final localApiKey = TextEditingController(text: initial.localApiKey ?? '');
    final cloudUrl = TextEditingController(
      text: initial.cloudBaseUrl.trim().isEmpty
          ? defaultCloudBaseUrl()
          : initial.cloudBaseUrl,
    );
    final cloudName = TextEditingController(text: '');
    final cloudEmail = TextEditingController(text: initial.cloudEmail ?? '');
    final cloudPassword = TextEditingController();
    final cloudPasswordConfirm = TextEditingController();
    var registerAccount = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Advisor works offline with local analysis. Add your own '
                  'OpenAI, Gemini, or local (Ollama) endpoint for richer answers '
                  'and receipt/voice capture.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Provider',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final option in const [
                      (AiProviderKind.openAi, 'OpenAI'),
                      (AiProviderKind.gemini, 'Gemini'),
                      (AiProviderKind.local, 'Local'),
                      (AiProviderKind.cloud, 'Cloud'),
                    ])
                      ChoiceChip(
                        label: Text(option.$2),
                        selected: kind == option.$1,
                        onSelected: (_) => setModalState(() => kind = option.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (kind == AiProviderKind.openAi) ...[
                  TextField(
                    controller: openAiKey,
                    decoration: const InputDecoration(
                      labelText: 'OpenAI API key',
                      hintText: 'sk-...',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: openAiModel,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      hintText: 'gpt-4o-mini',
                    ),
                  ),
                ],
                if (kind == AiProviderKind.gemini) ...[
                  TextField(
                    controller: geminiKey,
                    decoration: const InputDecoration(
                      labelText: 'Gemini API key',
                      hintText: 'AIza...',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: geminiModel,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      hintText: 'gemini-2.0-flash',
                    ),
                  ),
                ],
                if (kind == AiProviderKind.local) ...[
                  TextField(
                    controller: localUrl,
                    decoration: const InputDecoration(
                      labelText: 'Base URL (OpenAI-compatible)',
                      hintText: 'http://192.168.1.10:11434/v1',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: localModel,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      hintText: 'llama3.2',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: localApiKey,
                    decoration: const InputDecoration(
                      labelText: 'API key (optional)',
                      hintText: 'Usually blank for Ollama',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'On a phone, use your computer\'s LAN IP — not 127.0.0.1.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (kind == AiProviderKind.cloud) ...[
                  TextField(
                    controller: cloudUrl,
                    decoration: const InputDecoration(
                      labelText: 'API URL',
                      hintText: 'http://localhost:8080',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cloudEmail,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cloudPassword,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Leave blank to keep the current session',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Create account'),
                    value: registerAccount,
                    onChanged: (value) =>
                        setModalState(() => registerAccount = value),
                  ),
                  if (registerAccount) ...[
                    TextField(
                      controller: cloudName,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cloudPasswordConfirm,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                      ),
                      obscureText: true,
                    ),
                  ],
                  if (initial.cloudToken != null &&
                      initial.cloudToken!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        await provider.signOutOfCloud();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Sign out'),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (kind == AiProviderKind.cloud &&
                          cloudPassword.text.isNotEmpty) {
                        try {
                          await provider.signInToCloud(
                            name: cloudName.text.trim().isEmpty
                                ? cloudEmail.text.trim()
                                : cloudName.text.trim(),
                            email: cloudEmail.text.trim(),
                            password: cloudPassword.text,
                            passwordConfirmation: registerAccount
                                ? cloudPasswordConfirm.text
                                : cloudPassword.text,
                            baseUrl: cloudUrl.text.trim().isEmpty
                                ? defaultCloudBaseUrl()
                                : cloudUrl.text.trim(),
                            register: registerAccount,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (error) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        }
                        return;
                      }
                      final settings = AiProviderSettings(
                        kind: kind,
                        openAiApiKey: openAiKey.text.trim().isEmpty
                            ? null
                            : openAiKey.text.trim(),
                        geminiApiKey: geminiKey.text.trim().isEmpty
                            ? null
                            : geminiKey.text.trim(),
                        localBaseUrl: localUrl.text.trim().isEmpty
                            ? 'http://127.0.0.1:11434/v1'
                            : localUrl.text.trim(),
                        localApiKey: localApiKey.text.trim().isEmpty
                            ? null
                            : localApiKey.text.trim(),
                        openAiModel: openAiModel.text.trim().isEmpty
                            ? 'gpt-4o-mini'
                            : openAiModel.text.trim(),
                        geminiModel: geminiModel.text.trim().isEmpty
                            ? 'gemini-2.0-flash'
                            : geminiModel.text.trim(),
                        localModel: localModel.text.trim().isEmpty
                            ? 'llama3.2'
                            : localModel.text.trim(),
                        cloudBaseUrl: cloudUrl.text.trim().isEmpty
                            ? defaultCloudBaseUrl()
                            : cloudUrl.text.trim(),
                        cloudEmail: cloudEmail.text.trim().isEmpty
                            ? null
                            : cloudEmail.text.trim(),
                      );
                      await provider.setAiSettings(settings);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      openAiKey.dispose();
      geminiKey.dispose();
      localUrl.dispose();
      localModel.dispose();
      openAiModel.dispose();
      geminiModel.dispose();
      localApiKey.dispose();
      cloudUrl.dispose();
      cloudName.dispose();
      cloudEmail.dispose();
      cloudPassword.dispose();
      cloudPasswordConfirm.dispose();
    });
  }
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({
    required this.suggestions,
    required this.onSuggestionTap,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.advisorWelcomeTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.advisorWelcomeBody,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.l10n.tryAsking,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => onSuggestionTap(s),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Text(s),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: const Icon(
                Icons.psychology_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: const Icon(
              Icons.psychology_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const SizedBox(
              width: 40,
              height: 16,
              child: Center(
                child: Text(
                  '...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        AppNavBar.reservedHeight(context) + 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: context.l10n.askFinancesHint,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}
