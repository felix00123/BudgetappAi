import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;

import '../models/parsed_bank_email.dart';
import 'bank_email_parser.dart';
import 'outlook_message.dart';

class OutlookSyncException implements Exception {
  const OutlookSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OutlookTokenStore {
  const OutlookTokenStore({
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.accountEmail,
  });

  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? accountEmail;

  bool get hasSession =>
      (refreshToken != null && refreshToken!.isNotEmpty) ||
      (accessToken != null &&
          accessToken!.isNotEmpty &&
          expiresAt != null &&
          expiresAt!.isAfter(DateTime.now().add(const Duration(minutes: 2))));
}

typedef OutlookTokenReader = Future<OutlookTokenStore> Function();
typedef OutlookTokenWriter = Future<void> Function(OutlookTokenStore tokens);

/// Connects to Outlook / Microsoft 365 mail via AppAuth + Microsoft Graph.
///
/// Configure an Azure App Registration (personal + organizational accounts)
/// with redirect `com.budgetappai.budgetapp://oauthredirect` and delegated
/// `Mail.Read`. Pass the client id with:
/// `--dart-define=MICROSOFT_CLIENT_ID=...`
class OutlookSyncService {
  OutlookSyncService({
    required OutlookTokenReader readTokens,
    required OutlookTokenWriter writeTokens,
    FlutterAppAuth? appAuth,
    http.Client? httpClient,
    GraphRequestQueue? queue,
  })  : _readTokens = readTokens,
        _writeTokens = writeTokens,
        _appAuth = appAuth ?? const FlutterAppAuth(),
        _http = httpClient ?? http.Client(),
        _queue = queue ?? GraphRequestQueue();

  static const clientId = String.fromEnvironment('MICROSOFT_CLIENT_ID');
  static const redirectUrl = String.fromEnvironment(
    'MICROSOFT_REDIRECT_URL',
    defaultValue: 'com.budgetappai.budgetapp://oauthredirect',
  );
  static const _authorizeUrl =
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
  static const _tokenUrl =
      'https://login.microsoftonline.com/common/oauth2/v2.0/token';
  static const _graphBase = 'https://graph.microsoft.com/v1.0';

  static const scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
    'https://graph.microsoft.com/Mail.Read',
  ];

  final OutlookTokenReader _readTokens;
  final OutlookTokenWriter _writeTokens;
  final FlutterAppAuth _appAuth;
  final http.Client _http;
  final GraphRequestQueue _queue;
  final status = ValueNotifier<String>('');

  bool _syncActive = false;

  bool get isConfigured => clientId.trim().isNotEmpty;

  Future<bool> isConnected() async {
    final tokens = await _readTokens();
    return tokens.hasSession;
  }

  Future<String?> connectedEmail() async {
    final tokens = await _readTokens();
    return tokens.accountEmail;
  }

  Future<String> connect() async {
    if (!isConfigured) {
      throw const OutlookSyncException(
        'Add MICROSOFT_CLIENT_ID (Azure App Registration) to the build first.',
      );
    }

    status.value = 'Opening Microsoft sign-in...';
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        clientId,
        redirectUrl,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: _authorizeUrl,
          tokenEndpoint: _tokenUrl,
        ),
        scopes: scopes,
        promptValues: ['select_account'],
      ),
    );

    final accessToken = result.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw const OutlookSyncException('Microsoft sign-in was cancelled.');
    }

    status.value = 'Checking Outlook profile...';
    final email = await _fetchProfileEmail(accessToken);
    await _writeTokens(
      OutlookTokenStore(
        accessToken: accessToken,
        refreshToken: result.refreshToken,
        expiresAt: result.accessTokenExpirationDateTime,
        accountEmail: email,
      ),
    );
    status.value = 'Outlook connected';
    return email;
  }

  Future<void> disconnect() async {
    await _writeTokens(const OutlookTokenStore());
    status.value = '';
  }

  Future<({String? accountEmail, List<ParsedBankEmail> emails, int messagesChecked, String message})>
      syncBankEmails({
    DateTime? since,
    DateTime? until,
  }) async {
    if (_syncActive) {
      throw const OutlookSyncException('An Outlook sync is already running.');
    }
    _syncActive = true;
    try {
      final accessToken = await _validAccessToken();
      status.value = 'Checking Outlook connection...';
      final accountEmail = await _fetchProfileEmail(accessToken);
      final stored = await _readTokens();
      await _writeTokens(
        OutlookTokenStore(
          accessToken: stored.accessToken ?? accessToken,
          refreshToken: stored.refreshToken,
          expiresAt: stored.expiresAt,
          accountEmail: accountEmail,
        ),
      );

      final search = outlookBankSearchQuery(since: since, until: until);
      status.value = 'Finding bank emails...';

      final messageIds = <String>[];
      String? nextLink =
          '$_graphBase/me/messages?\$search=${Uri.encodeQueryComponent('"$search"')}'
          '&\$select=id,subject,from,receivedDateTime,bodyPreview'
          '&\$top=50';

      while (nextLink != null) {
        final page = await _graphGet(nextLink, accessToken);
        final values = page['value'] as List? ?? const [];
        for (final item in values) {
          if (item is! Map<String, dynamic>) continue;
          final id = item['id'] as String?;
          if (id != null) messageIds.add(id);
        }
        nextLink = page['@odata.nextLink'] as String?;
        status.value = 'Finding bank emails (${messageIds.length} found)...';
      }

      final parsed = <ParsedBankEmail>[];
      var checked = 0;
      for (final id in messageIds) {
        status.value =
            'Reading email ${checked + 1} of ${messageIds.length}...';
        final full = await _graphGet(
          '$_graphBase/me/messages/$id'
          '?\$select=id,subject,from,receivedDateTime,body,bodyPreview',
          accessToken,
        );
        final fields = parseOutlookGraphMessage(full);
        if (fields == null) {
          checked++;
          continue;
        }
        final result = parseBankEmail(
          from: fields.from,
          subject: fields.subject,
          body: fields.body,
          receivedAt: fields.receivedAt,
        );
        if (!result.isEmpty) {
          parsed.add(
            ParsedBankEmail(
              messageId: fields.id,
              result: result,
              receivedAt: fields.receivedAt,
            ),
          );
        }
        checked++;
      }

      status.value =
          '${messageIds.length} emails checked; ${parsed.length} with bank data';

      return (
        accountEmail: accountEmail,
        emails: parsed,
        messagesChecked: messageIds.length,
        message: parsed.isEmpty
            ? 'No supported bank emails found in that range'
            : '${parsed.length} bank email${parsed.length == 1 ? '' : 's'} ready to import',
      );
    } finally {
      _syncActive = false;
    }
  }

  Future<String> _validAccessToken() async {
    final tokens = await _readTokens();
    if (tokens.accessToken != null &&
        tokens.accessToken!.isNotEmpty &&
        tokens.expiresAt != null &&
        tokens.expiresAt!
            .isAfter(DateTime.now().add(const Duration(minutes: 2)))) {
      return tokens.accessToken!;
    }

    if (!isConfigured) {
      throw const OutlookSyncException(
        'Add MICROSOFT_CLIENT_ID (Azure App Registration) to the build first.',
      );
    }
    final refresh = tokens.refreshToken;
    if (refresh == null || refresh.isEmpty) {
      throw const OutlookSyncException(
        'Outlook is not connected. Tap Connect Outlook first.',
      );
    }

    status.value = 'Refreshing Microsoft access...';
    final result = await _appAuth.token(
      TokenRequest(
        clientId,
        redirectUrl,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: _authorizeUrl,
          tokenEndpoint: _tokenUrl,
        ),
        refreshToken: refresh,
        scopes: scopes,
      ),
    );

    if (result.accessToken == null || result.accessToken!.isEmpty) {
      throw const OutlookSyncException(
        'Could not refresh Outlook access. Connect again.',
      );
    }

    await _writeTokens(
      OutlookTokenStore(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken ?? refresh,
        expiresAt: result.accessTokenExpirationDateTime,
        accountEmail: tokens.accountEmail,
      ),
    );
    return result.accessToken!;
  }

  Future<String> _fetchProfileEmail(String accessToken) async {
    final data = await _graphGet('$_graphBase/me', accessToken);
    final email = (data['mail'] as String?)?.trim().isNotEmpty == true
        ? data['mail'] as String
        : (data['userPrincipalName'] as String?)?.trim();
    if (email == null || email.isEmpty) {
      throw const OutlookSyncException(
        'Microsoft did not return an account email.',
      );
    }
    return email;
  }

  Future<Map<String, dynamic>> _graphGet(String url, String accessToken) {
    return _queue.run(() async {
      final response = await _http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          // Required for $search on messages.
          'ConsistencyLevel': 'eventual',
        },
      );
      if (response.statusCode == 429 || response.statusCode >= 500) {
        throw GraphHttpException(response.statusCode, response.body);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OutlookSyncException(
          'Outlook API error (${response.statusCode}). '
          '${_shortError(response.body)}',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const OutlookSyncException('Unexpected Outlook API response.');
      }
      return decoded;
    }, onStatus: (value) => status.value = value);
  }

  String _shortError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        return (decoded['error']['message'] as String?) ?? body;
      }
    } catch (_) {}
    if (body.length > 160) return '${body.substring(0, 160)}…';
    return body;
  }
}

class GraphHttpException implements Exception {
  GraphHttpException(this.status, this.body);

  final int status;
  final String body;
}

/// Serializes Graph reads with spacing and retries on 429/5xx.
class GraphRequestQueue {
  GraphRequestQueue({
    Future<void> Function(Duration)? sleep,
    DateTime Function()? now,
    int Function()? jitter,
    this.spacing = const Duration(milliseconds: 400),
    this.maxRetries = 5,
  }) : _sleep = sleep ?? Future<void>.delayed,
       _now = now ?? DateTime.now,
       _jitter = jitter ?? (() => Random().nextInt(500));

  final Future<void> Function(Duration) _sleep;
  final DateTime Function() _now;
  final int Function() _jitter;
  final Duration spacing;
  final int maxRetries;
  Future<void> _tail = Future<void>.value();
  DateTime? _nextRequest;

  Future<T> run<T>(
    Future<T> Function() request, {
    void Function(String)? onStatus,
  }) {
    final result = _tail.then((_) => _run(request, onStatus));
    _tail = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }

  Future<T> _run<T>(
    Future<T> Function() request,
    void Function(String)? onStatus,
  ) async {
    for (var attempt = 0; ; attempt++) {
      final remaining = _nextRequest?.difference(_now()) ?? Duration.zero;
      if (remaining > Duration.zero) await _sleep(remaining);
      _nextRequest = _now().add(spacing);
      try {
        return await request();
      } on GraphHttpException catch (error) {
        if (attempt >= maxRetries) rethrow;
        if (error.status != 429 && error.status < 500) rethrow;
        final wait = Duration(
          seconds: min(2 << attempt, 30),
          milliseconds: _jitter(),
        );
        onStatus?.call(
          'Outlook is busy. Retrying in ${wait.inSeconds}s '
          '(${attempt + 1}/$maxRetries)...',
        );
        await _sleep(wait);
      }
    }
  }
}
