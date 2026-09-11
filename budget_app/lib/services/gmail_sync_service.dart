import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;

import '../models/parsed_bank_email.dart';
import 'bank_email_parser.dart';
import 'gmail_message.dart';
import 'gmail_request_queue.dart';

class GmailSyncException implements Exception {
  const GmailSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GmailSyncFetchResult {
  const GmailSyncFetchResult({
    required this.accountEmail,
    required this.emails,
    required this.messagesChecked,
    required this.message,
  });

  final String? accountEmail;
  final List<ParsedBankEmail> emails;
  final int messagesChecked;
  final String message;
}

/// Connects to Gmail with Google Sign-In and pulls Dominican bank alerts.
///
/// Configure OAuth clients in Google Cloud Console (Gmail API + OAuth consent
/// with `gmail.readonly`). Pass iOS client id via:
/// `--dart-define=GOOGLE_OAUTH_CLIENT_ID=...`
/// Android uses the OAuth Android client for `com.budgetapp.budget_app`.
class GmailSyncService {
  GmailSyncService({
    GoogleSignIn? signIn,
    GmailRequestQueue? queue,
  }) : _signIn = signIn ?? GoogleSignIn.instance,
       _queue = queue ?? GmailRequestQueue();

  static const scopes = [gmail.GmailApi.gmailReadonlyScope];

  static const _clientId = String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID');
  static const _serverClientId =
      String.fromEnvironment('GOOGLE_OAUTH_SERVER_CLIENT_ID');

  /// Same bank-alert search ClearPath uses.
  static const purchaseSearch =
      '{from:alertas@bhd.com.do from:no-reply@apap.com.do '
      'from:notificaciones@banreservas.com subject:transacciones '
      'subject:notificaciones subject:consumo subject:purchase '
      'subject:transaction subject:approved subject:compra '
      'subject:aprobada subject:autorizada subject:retiro subject:pago '
      'subject:deposito "card ending" "tarjeta terminada" '
      '"consumo realizado" "transaccion realizada" "tarjeta de debito" '
      '"retiro en cajero" "deposito de sueldo" "payment approved" '
      '"cash withdrawal"}';

  final GoogleSignIn _signIn;
  final GmailRequestQueue _queue;
  final status = ValueNotifier<String>('');

  bool _initialized = false;
  bool _syncActive = false;
  GoogleSignInAccount? _account;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await _signIn.initialize(
      clientId: _clientId.isEmpty ? null : _clientId,
      serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    );
    _initialized = true;

    try {
      final restored = await _signIn.attemptLightweightAuthentication();
      if (restored != null) _account = restored;
    } catch (_) {
      // No previous session — user must connect manually.
    }
  }

  Future<bool> isConnected() async {
    await ensureInitialized();
    return _account != null;
  }

  Future<String?> connectedEmail() async {
    await ensureInitialized();
    return _account?.email;
  }

  Future<String> connect() async {
    await ensureInitialized();
    status.value = 'Opening Google sign-in...';

    try {
      final account = await _signIn.authenticate(scopeHint: scopes);
      _account = account;

      status.value = 'Requesting Gmail access...';
      await account.authorizationClient.authorizeScopes(scopes);

      status.value = 'Gmail connected';
      return account.email;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const GmailSyncException('Google sign-in was cancelled.');
      }
      throw GmailSyncException(
        e.description ?? 'Google sign-in failed (${e.code.name}).',
      );
    }
  }

  Future<void> disconnect() async {
    await ensureInitialized();
    await _signIn.disconnect();
    _account = null;
    status.value = '';
  }

  Future<GmailSyncFetchResult> syncBankEmails({
    DateTime? since,
    DateTime? until,
    bool scanAllMessages = false,
  }) async {
    if (_syncActive) {
      throw const GmailSyncException('A Gmail sync is already running.');
    }
    _syncActive = true;
    try {
      return await _sync(
        since: since,
        until: until,
        scanAllMessages: scanAllMessages,
      );
    } finally {
      _syncActive = false;
    }
  }

  Future<GmailSyncFetchResult> _sync({
    DateTime? since,
    DateTime? until,
    required bool scanAllMessages,
  }) async {
    await ensureInitialized();
    final account = _account;
    if (account == null) {
      throw const GmailSyncException(
        'Gmail is not connected. Tap Connect Gmail first.',
      );
    }

    status.value = 'Authorizing Gmail...';
    final authorization =
        await account.authorizationClient.authorizationForScopes(scopes) ??
            await account.authorizationClient.authorizeScopes(scopes);

    final client = authorization.authClient(scopes: scopes);
    try {
      final api = gmail.GmailApi(client);

      status.value = 'Checking Gmail connection...';
      final profile = await _request(() => api.users.getProfile('me'));
      final accountEmail = profile.emailAddress ?? account.email;

      final queryParts = <String>[];
      if (since != null) queryParts.add('after:${gmailDateQuery(since)}');
      if (until != null) queryParts.add('before:${gmailDateQuery(until)}');
      if (!scanAllMessages) queryParts.add(purchaseSearch);

      final messageItems = <gmail.Message>[];
      String? pageToken;
      do {
        status.value =
            'Finding bank emails (${messageItems.length} found)...';
        final page = await _request(
          () => api.users.messages.list(
            'me',
            maxResults: 200,
            pageToken: pageToken,
            q: queryParts.join(' '),
          ),
        );
        for (final message in page.messages ?? const <gmail.Message>[]) {
          if (message.id != null) messageItems.add(message);
        }
        pageToken = page.nextPageToken;
      } while (pageToken != null && pageToken.isNotEmpty);

      final parsed = <ParsedBankEmail>[];
      var checked = 0;
      for (final item in messageItems) {
        final id = item.id;
        if (id == null) continue;
        status.value =
            'Reading email ${checked + 1} of ${messageItems.length}...';
        final full = await _request(
          () => api.users.messages.get('me', id, format: 'full'),
        );

        final receivedAt = gmailInternalDate(full);
        final result = parseBankEmail(
          from: gmailHeader(full, 'from'),
          subject: gmailHeader(full, 'subject'),
          body: gmailBodyText(full),
          receivedAt: receivedAt,
        );

        if (!result.isEmpty) {
          parsed.add(
            ParsedBankEmail(
              messageId: id,
              result: result,
              receivedAt: receivedAt,
            ),
          );
        }
        checked++;
      }

      status.value =
          '${messageItems.length} emails checked; ${parsed.length} with bank data';

      return GmailSyncFetchResult(
        accountEmail: accountEmail,
        emails: parsed,
        messagesChecked: messageItems.length,
        message: parsed.isEmpty
            ? 'No supported bank emails found in that range'
            : '${parsed.length} bank email${parsed.length == 1 ? '' : 's'} ready to import',
      );
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('quota exceeded') ||
          message.contains('rate limit') ||
          message.contains('userratelimitexceeded')) {
        throw const GmailSyncException(
          'Gmail is limiting requests after automatic retries. Try again shortly.',
        );
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<T> _request<T>(Future<T> Function() call) =>
      _queue.run(call, onStatus: (value) => status.value = value);
}

/// Formats a date the way Gmail's `after:` / `before:` operators expect.
String gmailDateQuery(DateTime date) {
  final value = date.toUtc();
  return '${value.year.toString().padLeft(4, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.day.toString().padLeft(2, '0')}';
}
