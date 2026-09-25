import 'package:flutter/foundation.dart';

enum AiProviderKind { openAi, gemini, local, cloud }

String defaultCloudBaseUrl() {
  if (kIsWeb) return 'http://localhost:8080';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}

/// User-chosen LLM backend for advisor + receipt/voice capture.
class AiProviderSettings {
  const AiProviderSettings({
    this.kind = AiProviderKind.openAi,
    this.openAiApiKey,
    this.geminiApiKey,
    this.localBaseUrl = 'http://127.0.0.1:11434/v1',
    this.localApiKey,
    this.openAiModel = 'gpt-4o-mini',
    this.geminiModel = 'gemini-2.0-flash',
    this.localModel = 'llama3.2',
    this.cloudBaseUrl = '',
    this.cloudEmail,
    this.cloudToken,
  });

  final AiProviderKind kind;
  final String? openAiApiKey;
  final String? geminiApiKey;

  /// OpenAI-compatible base, e.g. Ollama `http://192.168.1.10:11434/v1`.
  final String localBaseUrl;
  final String? localApiKey;
  final String openAiModel;
  final String geminiModel;
  final String localModel;
  final String cloudBaseUrl;
  final String? cloudEmail;

  /// Kept in memory and secure storage. Not written to the Hive JSON.
  final String? cloudToken;

  String get activeModel => switch (kind) {
        AiProviderKind.openAi => openAiModel,
        AiProviderKind.gemini => geminiModel,
        AiProviderKind.local => localModel,
        AiProviderKind.cloud => 'hosted',
      };

  String? get activeApiKey => switch (kind) {
        AiProviderKind.openAi => openAiApiKey,
        AiProviderKind.gemini => geminiApiKey,
        AiProviderKind.local =>
          (localApiKey == null || localApiKey!.trim().isEmpty)
              ? 'ollama'
              : localApiKey,
        AiProviderKind.cloud => cloudToken,
      };

  bool get isConfigured {
    switch (kind) {
      case AiProviderKind.openAi:
        return openAiApiKey != null && openAiApiKey!.trim().isNotEmpty;
      case AiProviderKind.gemini:
        return geminiApiKey != null && geminiApiKey!.trim().isNotEmpty;
      case AiProviderKind.local:
        return localBaseUrl.trim().isNotEmpty && localModel.trim().isNotEmpty;
      case AiProviderKind.cloud:
        return cloudBaseUrl.trim().isNotEmpty &&
            cloudToken != null &&
            cloudToken!.trim().isNotEmpty;
    }
  }

  String get label => switch (kind) {
        AiProviderKind.openAi => 'OpenAI',
        AiProviderKind.gemini => 'Gemini',
        AiProviderKind.local => 'Local (Ollama)',
        AiProviderKind.cloud => 'Cloud',
      };

  String get setupHint => switch (kind) {
        AiProviderKind.openAi =>
          'Add your OpenAI API key in AI Advisor settings.',
        AiProviderKind.gemini =>
          'Add your Gemini API key in AI Advisor settings.',
        AiProviderKind.local =>
          'Set a local OpenAI-compatible URL (e.g. Ollama) in AI Advisor settings.',
        AiProviderKind.cloud =>
          'Sign in to your cloud account in AI Advisor settings.',
      };

  AiProviderSettings copyWith({
    AiProviderKind? kind,
    String? openAiApiKey,
    String? geminiApiKey,
    String? localBaseUrl,
    String? localApiKey,
    String? openAiModel,
    String? geminiModel,
    String? localModel,
    String? cloudBaseUrl,
    String? cloudEmail,
    String? cloudToken,
    bool clearOpenAiKey = false,
    bool clearGeminiKey = false,
    bool clearLocalApiKey = false,
    bool clearCloudToken = false,
  }) =>
      AiProviderSettings(
        kind: kind ?? this.kind,
        openAiApiKey:
            clearOpenAiKey ? null : (openAiApiKey ?? this.openAiApiKey),
        geminiApiKey:
            clearGeminiKey ? null : (geminiApiKey ?? this.geminiApiKey),
        localBaseUrl: localBaseUrl ?? this.localBaseUrl,
        localApiKey:
            clearLocalApiKey ? null : (localApiKey ?? this.localApiKey),
        openAiModel: openAiModel ?? this.openAiModel,
        geminiModel: geminiModel ?? this.geminiModel,
        localModel: localModel ?? this.localModel,
        cloudBaseUrl: cloudBaseUrl ?? this.cloudBaseUrl,
        cloudEmail: cloudEmail ?? this.cloudEmail,
        cloudToken: clearCloudToken ? null : (cloudToken ?? this.cloudToken),
      );

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'openAiApiKey': openAiApiKey,
        'geminiApiKey': geminiApiKey,
        'localBaseUrl': localBaseUrl,
        'localApiKey': localApiKey,
        'openAiModel': openAiModel,
        'geminiModel': geminiModel,
        'localModel': localModel,
        'cloudBaseUrl': cloudBaseUrl,
        'cloudEmail': cloudEmail,
      };

  factory AiProviderSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AiProviderSettings();
    final kindName = json['kind'] as String?;
    final kind = AiProviderKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => AiProviderKind.openAi,
    );
    return AiProviderSettings(
      kind: kind,
      openAiApiKey: json['openAiApiKey'] as String?,
      geminiApiKey: json['geminiApiKey'] as String?,
      localBaseUrl: (json['localBaseUrl'] as String?)?.trim().isNotEmpty == true
          ? json['localBaseUrl'] as String
          : 'http://127.0.0.1:11434/v1',
      localApiKey: json['localApiKey'] as String?,
      openAiModel: (json['openAiModel'] as String?)?.trim().isNotEmpty == true
          ? json['openAiModel'] as String
          : 'gpt-4o-mini',
      geminiModel: (json['geminiModel'] as String?)?.trim().isNotEmpty == true
          ? json['geminiModel'] as String
          : 'gemini-2.0-flash',
      localModel: (json['localModel'] as String?)?.trim().isNotEmpty == true
          ? json['localModel'] as String
          : 'llama3.2',
      cloudBaseUrl: (json['cloudBaseUrl'] as String?)?.trim().isNotEmpty == true
          ? json['cloudBaseUrl'] as String
          : defaultCloudBaseUrl(),
      cloudEmail: json['cloudEmail'] as String?,
    );
  }
}
