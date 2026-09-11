import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:budget_app/models/ai_provider_settings.dart';
import 'package:budget_app/services/ai_llm_client.dart';

void main() {
  group('AiProviderSettings', () {
    test('round-trips JSON and migrates kind', () {
      const settings = AiProviderSettings(
        kind: AiProviderKind.gemini,
        geminiApiKey: 'gem-key',
        geminiModel: 'gemini-2.0-flash',
      );
      final restored = AiProviderSettings.fromJson(settings.toJson());
      expect(restored.kind, AiProviderKind.gemini);
      expect(restored.geminiApiKey, 'gem-key');
      expect(restored.isConfigured, isTrue);
    });

    test('local is configured with URL + model only', () {
      const settings = AiProviderSettings(kind: AiProviderKind.local);
      expect(settings.isConfigured, isTrue);
      expect(settings.activeApiKey, 'ollama');
    });

    test('openai requires key', () {
      expect(const AiProviderSettings().isConfigured, isFalse);
      expect(
        const AiProviderSettings(openAiApiKey: 'sk-test').isConfigured,
        isTrue,
      );
    });
  });

  group('AiLlmClient routing', () {
    test('posts to OpenAI chat completions', () async {
      Uri? seen;
      final client = AiLlmClient(
        client: MockClient((request) async {
          seen = request.url;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'hello openai'},
                },
              ],
            }),
            200,
          );
        }),
      );

      final text = await client.completeText(
        settings: const AiProviderSettings(openAiApiKey: 'sk-test'),
        systemPrompt: 'sys',
        userPrompt: 'hi',
      );
      expect(text, 'hello openai');
      expect(seen.toString(), contains('api.openai.com'));
    });

    test('posts to Gemini generateContent', () async {
      Uri? seen;
      final client = AiLlmClient(
        client: MockClient((request) async {
          seen = request.url;
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'hello gemini'},
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }),
      );

      final text = await client.completeText(
        settings: const AiProviderSettings(
          kind: AiProviderKind.gemini,
          geminiApiKey: 'gem-test',
        ),
        systemPrompt: 'sys',
        userPrompt: 'hi',
      );
      expect(text, 'hello gemini');
      expect(seen.toString(), contains('generativelanguage.googleapis.com'));
      expect(seen.toString(), contains('key=gem-test'));
    });

    test('posts to local OpenAI-compatible base URL', () async {
      Uri? seen;
      final client = AiLlmClient(
        client: MockClient((request) async {
          seen = request.url;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'hello local'},
                },
              ],
            }),
            200,
          );
        }),
      );

      final text = await client.completeText(
        settings: const AiProviderSettings(
          kind: AiProviderKind.local,
          localBaseUrl: 'http://192.168.1.5:11434/v1',
          localModel: 'llama3.2',
        ),
        systemPrompt: 'sys',
        userPrompt: 'hi',
      );
      expect(text, 'hello local');
      expect(
        seen.toString(),
        'http://192.168.1.5:11434/v1/chat/completions',
      );
    });

    test('throws setup hint when not configured', () async {
      final client = AiLlmClient(client: MockClient((_) async {
        fail('should not call network');
      }));
      expect(
        () => client.completeText(
          settings: const AiProviderSettings(),
          systemPrompt: 'sys',
          userPrompt: 'hi',
        ),
        throwsA(isA<AiLlmException>()),
      );
    });
  });
}
