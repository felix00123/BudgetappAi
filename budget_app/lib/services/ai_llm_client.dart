import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/ai_provider_settings.dart';

class AiLlmException implements Exception {
  const AiLlmException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thin multi-provider chat client: OpenAI, Gemini, and OpenAI-compatible local.
class AiLlmClient {
  AiLlmClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> completeText({
    required AiProviderSettings settings,
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 600,
  }) {
    _requireConfigured(settings);
    return switch (settings.kind) {
      AiProviderKind.cloud => _cloudText(
          settings: settings,
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        ),
      AiProviderKind.openAi || AiProviderKind.local => _openAiCompatibleText(
          settings: settings,
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        ),
      AiProviderKind.gemini => _geminiText(
          settings: settings,
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        ),
    };
  }

  Future<String> completeWithImage({
    required AiProviderSettings settings,
    required String systemPrompt,
    required String userPrompt,
    required Uint8List imageBytes,
    required String mimeType,
    double temperature = 0.1,
    int maxTokens = 400,
  }) {
    _requireConfigured(settings);
    return switch (settings.kind) {
      AiProviderKind.cloud => _cloudVision(
          settings: settings,
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          imageBytes: imageBytes,
          mimeType: mimeType,
          temperature: temperature,
          maxTokens: maxTokens,
        ),
      AiProviderKind.openAi || AiProviderKind.local => _openAiCompatibleVision(
          settings: settings,
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          imageBytes: imageBytes,
          mimeType: mimeType,
          temperature: temperature,
          maxTokens: maxTokens,
        ),
      AiProviderKind.gemini => _geminiVision(
          settings: settings,
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          imageBytes: imageBytes,
          mimeType: mimeType,
          temperature: temperature,
          maxTokens: maxTokens,
        ),
    };
  }

  void _requireConfigured(AiProviderSettings settings) {
    if (!settings.isConfigured) {
      throw AiLlmException(settings.setupHint);
    }
  }

  Uri _cloudUri(AiProviderSettings settings, String path) {
    final base = settings.cloudBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path');
  }

  Future<String> _cloudText({
    required AiProviderSettings settings,
    required String systemPrompt,
    required String userPrompt,
    required double temperature,
    required int maxTokens,
  }) async {
    final response = await _client.post(
      _cloudUri(settings, '/api/v1/ai/complete'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${settings.cloudToken}',
      },
      body: jsonEncode({
        'systemPrompt': systemPrompt,
        'userPrompt': userPrompt,
        'temperature': temperature,
        'maxTokens': maxTokens,
      }),
    );
    return _readCloudContent(response);
  }

  Future<String> _cloudVision({
    required AiProviderSettings settings,
    required String systemPrompt,
    required String userPrompt,
    required Uint8List imageBytes,
    required String mimeType,
    required double temperature,
    required int maxTokens,
  }) async {
    final response = await _client.post(
      _cloudUri(settings, '/api/v1/ai/complete-image'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${settings.cloudToken}',
      },
      body: jsonEncode({
        'systemPrompt': systemPrompt,
        'userPrompt': userPrompt,
        'imageBase64': base64Encode(imageBytes),
        'mimeType': mimeType,
        'temperature': temperature,
        'maxTokens': maxTokens,
      }),
    );
    return _readCloudContent(response);
  }

  String _readCloudContent(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiLlmException(
        'Cloud error (${response.statusCode}). Check that you are signed in.',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'];
    if (content is! String || content.trim().isEmpty) {
      throw const AiLlmException('Cloud returned an empty response.');
    }
    return content;
  }

  Uri _openAiCompatibleEndpoint(AiProviderSettings settings) {
    if (settings.kind == AiProviderKind.openAi) {
      return Uri.parse('https://api.openai.com/v1/chat/completions');
    }
    final base = settings.localBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.endsWith('/chat/completions')) return Uri.parse(base);
    if (base.endsWith('/v1')) {
      return Uri.parse('$base/chat/completions');
    }
    return Uri.parse('$base/v1/chat/completions');
  }

  Future<String> _openAiCompatibleText({
    required AiProviderSettings settings,
    required String systemPrompt,
    required String userPrompt,
    required double temperature,
    required int maxTokens,
  }) async {
    final response = await _client.post(
      _openAiCompatibleEndpoint(settings),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${settings.activeApiKey}',
      },
      body: jsonEncode({
        'model': settings.activeModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'max_tokens': maxTokens,
        'temperature': temperature,
      }),
    );
    return _readOpenAiContent(response, settings.label);
  }

  Future<String> _openAiCompatibleVision({
    required AiProviderSettings settings,
    required String systemPrompt,
    required String userPrompt,
    required Uint8List imageBytes,
    required String mimeType,
    required double temperature,
    required int maxTokens,
  }) async {
    final response = await _client.post(
      _openAiCompatibleEndpoint(settings),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${settings.activeApiKey}',
      },
      body: jsonEncode({
        'model': settings.activeModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': userPrompt},
              {
                'type': 'image_url',
                'image_url': {
                  'url':
                      'data:$mimeType;base64,${base64Encode(imageBytes)}',
                },
              },
            ],
          },
        ],
        'max_tokens': maxTokens,
        'temperature': temperature,
      }),
    );
    return _readOpenAiContent(response, settings.label);
  }

  String _readOpenAiContent(http.Response response, String label) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiLlmException(
        '$label error (${response.statusCode}). Check your key/URL/model.',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw AiLlmException('$label returned an empty response.');
    }
    final content = choices.first['message']['content'];
    if (content is! String || content.trim().isEmpty) {
      throw AiLlmException('$label returned an empty response.');
    }
    return content;
  }

  Future<String> _geminiText({
    required AiProviderSettings settings,
    required String systemPrompt,
    required String userPrompt,
    required double temperature,
    required int maxTokens,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '${settings.activeModel}:generateContent'
      '?key=${settings.geminiApiKey}',
    );
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': userPrompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
        },
      }),
    );
    return _readGeminiContent(response);
  }

  Future<String> _geminiVision({
    required AiProviderSettings settings,
    required String systemPrompt,
    required String userPrompt,
    required Uint8List imageBytes,
    required String mimeType,
    required double temperature,
    required int maxTokens,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '${settings.activeModel}:generateContent'
      '?key=${settings.geminiApiKey}',
    );
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': userPrompt},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Encode(imageBytes),
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
        },
      }),
    );
    return _readGeminiContent(response);
  }

  String _readGeminiContent(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiLlmException(
        'Gemini error (${response.statusCode}). Check your API key and model.',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw const AiLlmException('Gemini returned an empty response.');
    }
    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw const AiLlmException('Gemini returned an empty response.');
    }
    final text = parts.first['text'];
    if (text is! String || text.trim().isEmpty) {
      throw const AiLlmException('Gemini returned an empty response.');
    }
    return text;
  }
}
