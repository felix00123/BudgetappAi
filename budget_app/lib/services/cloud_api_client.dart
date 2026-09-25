import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/ai_provider_settings.dart';
import 'storage_service.dart';

class CloudApiException implements Exception {
  const CloudApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudApiClient {
  CloudApiClient({http.Client? client, FlutterSecureStorage? secureStorage})
      : _client = client ?? http.Client(),
        _secure = secureStorage ?? const FlutterSecureStorage();

  static const _tokenKey = 'cloud_api_token';

  final http.Client _client;
  final FlutterSecureStorage _secure;

  Future<String?> readToken() async {
    try {
      return await _secure.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeToken(String? token) async {
    try {
      if (token == null || token.isEmpty) {
        await _secure.delete(key: _tokenKey);
      } else {
        await _secure.write(key: _tokenKey, value: token);
      }
    } catch (_) {
      // Plugin missing in tests; the in-memory settings still hold the token.
    }
  }

  Future<AiProviderSettings> signIn({
    required AiProviderSettings settings,
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required bool register,
  }) async {
    final path = register ? '/api/v1/auth/register' : '/api/v1/auth/login';
    final body = {
      'email': email,
      'password': password,
      if (register) 'name': name,
      if (register) 'password_confirmation': passwordConfirmation,
    };
    final response = await _client.post(
      _uri(settings.cloudBaseUrl, path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final data = _decode(response);
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const CloudApiException('Cloud sign-in did not return a token.');
    }
    await writeToken(token);
    final user = data['user'] as Map<String, dynamic>?;
    return settings.copyWith(
      kind: AiProviderKind.cloud,
      cloudEmail: (user?['email'] as String?) ?? email,
      cloudToken: token,
    );
  }

  Future<void> signOut(AiProviderSettings settings) async {
    final token = settings.cloudToken;
    if (token != null && token.isNotEmpty) {
      await _client.post(
        _uri(settings.cloudBaseUrl, '/api/v1/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    }
    await writeToken(null);
  }

  Future<void> sync(StorageService storage, AiProviderSettings settings) async {
    final token = settings.cloudToken;
    if (token == null || token.isEmpty) return;

    final pending = await storage.pendingSyncPayload();
    final push = await _client.post(
      _uri(settings.cloudBaseUrl, '/api/v1/sync/push'),
      headers: _authHeaders(token),
      body: jsonEncode(pending),
    );
    _decode(push);
    await storage.clearPushedTombstones(pending);

    final since = storage.syncCursor;
    final query = since == null ? '' : '?since=${Uri.encodeQueryComponent(since)}';
    final pull = await _client.get(
      _uri(settings.cloudBaseUrl, '/api/v1/sync/pull$query'),
      headers: _authHeaders(token),
    );
    final data = _decode(pull);
    await storage.applyRemote(data);
    final serverTime = data['serverTime'] as String?;
    if (serverTime != null) {
      await storage.setSyncCursor(serverTime);
    }
  }

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Uri _uri(String base, String path) {
    final trimmed = base.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$trimmed$path');
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data['message'] as String? ??
          'Cloud request failed (${response.statusCode}).';
      throw CloudApiException(message);
    }
    return data;
  }
}
