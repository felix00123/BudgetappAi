import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_language.dart';
import '../l10n/l10n.dart';
import '../services/storage_service.dart';

class LocaleController extends ChangeNotifier {
  LocaleController(this._storage) {
    language = AppLanguage.fromCode(_storage.localeCode);
    _apply();
  }

  final StorageService _storage;

  late AppLanguage language;

  Locale get locale => language.locale;

  L10n get l10n => L10n(language);

  static const supportedLocales = [Locale('en'), Locale('es')];

  Future<void> setLanguage(AppLanguage value) async {
    final changed = language != value;
    language = value;
    await _storage.setLocaleCode(value.code);
    if (!changed) return;
    _apply();
    notifyListeners();
  }

  void _apply() {
    Intl.defaultLocale = language.code;
  }

  static Future<void> preload() {
    return Future.wait([
      initializeDateFormatting('en'),
      initializeDateFormatting('es'),
    ]);
  }
}

extension L10nContext on BuildContext {
  L10n get l10n {
    try {
      return Provider.of<LocaleController>(this, listen: true).l10n;
    } on ProviderNotFoundException {
      return L10n(AppLanguage.fromCode(Intl.defaultLocale));
    }
  }

  LocaleController? get localeController {
    try {
      return Provider.of<LocaleController>(this, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
  }
}
