import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';

import '../models/transaction.dart';
import '../providers/app_navigation.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/loans_screen.dart';

/// Deep links and shortcuts that open flows from outside the app.
class ExternalLaunchService {
  ExternalLaunchService._();

  static const incomeUri = 'budgetapp://add/income';
  static const expenseUri = 'budgetapp://add/expense';

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _linkSubscription;
  static bool _initialized = false;
  static Uri? _pendingUri;
  static Uri? _lastHandledUri;
  static DateTime? _lastHandledAt;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _setupQuickActions();

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _pendingUri = initialUri;
      }

      _linkSubscription = _appLinks.uriLinkStream.listen(_handleUri);
    } catch (_) {
      // Deep links are unavailable on unsupported platforms.
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flushPendingUri();
    });
  }

  static void dispose() {
    _linkSubscription?.cancel();
  }

  static void flushPendingLaunch() {
    _flushPendingUri();
  }

  static Future<void> _setupQuickActions() async {
    // Quick actions are only implemented on Android/iOS. Skipping the call on
    // web/desktop avoids a MissingPluginException that would crash startup.
    if (kIsWeb) return;

    try {
      const quickActions = QuickActions();

      await quickActions.initialize((shortcutType) {
        switch (shortcutType) {
          case 'add_income':
            openAddTransaction(TransactionType.income);
          case 'add_expense':
            openAddTransaction(TransactionType.expense);
        }
      });

      await quickActions.setShortcutItems(const [
        ShortcutItem(
          type: 'add_income',
          localizedTitle: 'Add Income',
          localizedSubtitle: 'Log money in',
        ),
        ShortcutItem(
          type: 'add_expense',
          localizedTitle: 'Add Expense',
          localizedSubtitle: 'Log money out',
        ),
      ]);
    } catch (_) {
      // Missing on unit tests / unsupported platforms.
    }
  }

  static void _handleUri(Uri? uri) {
    if (uri == null || uri.scheme != 'budgetapp') return;

    final now = DateTime.now();
    if (_lastHandledUri == uri &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastHandledUri = uri;
    _lastHandledAt = now;

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingUri = uri;
      return;
    }

    _dispatchUri(uri);
  }

  static void _flushPendingUri() {
    if (_pendingUri == null) return;
    final uri = _pendingUri;
    _pendingUri = null;
    _handleUri(uri);
  }

  static void _dispatchUri(Uri uri) {
    if (uri.host == 'add') {
      final type = parseTransactionType(uri);
      if (type != null) openAddTransaction(type);
      return;
    }

    if (uri.host == 'open' && uri.pathSegments.isNotEmpty) {
      final kind = uri.pathSegments.first;
      switch (kind) {
        case 'goal':
          openGoalsTab();
        case 'loan':
          openLoansTab();
      }
    }
  }

  static TransactionType? parseTransactionType(Uri? uri) {
    if (uri == null) return null;
    if (uri.scheme != 'budgetapp') return null;
    if (uri.host != 'add') return null;

    final segment = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.first
        : uri.path.replaceFirst('/', '');

    switch (segment) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      default:
        return null;
    }
  }

  static void openAddTransaction(TransactionType type) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => AddTransactionScreen(initialType: type),
        ),
      );
    });
  }

  static void openGoalsTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        context.read<AppNavigation>().navigateTo(2);
      }
      navigatorKey.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => const GoalsScreen()),
      );
    });
  }

  static void openLoansTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        context.read<AppNavigation>().navigateTo(3);
      }
      navigatorKey.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => const LoansScreen()),
      );
    });
  }
}
