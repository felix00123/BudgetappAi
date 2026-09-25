import 'package:flutter/widgets.dart';

enum AppLanguage {
  en,
  es;

  String get code => name;

  Locale get locale => Locale(code);

  String get nativeName => this == AppLanguage.es ? 'Español' : 'English';

  /// Name in the other language so either speaker can recognize the choice.
  String get otherName => this == AppLanguage.es ? 'Spanish' : 'Inglés';

  String get flag => this == AppLanguage.es ? '🇩🇴' : '🇺🇸';

  static AppLanguage fromCode(String? code) {
    final normalized = code?.toLowerCase() ?? '';
    if (normalized.startsWith('es')) return AppLanguage.es;
    if (normalized.startsWith('en')) return AppLanguage.en;
    return fromDevice();
  }

  static AppLanguage fromDevice() {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return code == 'es' ? AppLanguage.es : AppLanguage.en;
  }
}
