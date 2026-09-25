import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:budget_app/l10n/app_language.dart';
import 'package:budget_app/l10n/l10n.dart';
import 'package:budget_app/utils/formatters.dart';

void main() {
  test('English and Spanish catalogs differ on core chrome', () {
    const en = L10n(AppLanguage.en);
    const es = L10n(AppLanguage.es);

    expect(en.continueButton, 'Continue');
    expect(es.continueButton, 'Continuar');
    expect(en.navHome, 'Home');
    expect(es.navHome, 'Inicio');
    expect(en.captureTitle, isNot(es.captureTitle));
    expect(en.languageTitle, contains('Language'));
    expect(en.languageTitle, contains('Idioma'));
  });

  test('formatDuration follows Intl.defaultLocale', () {
    Intl.defaultLocale = 'en';
    expect(formatDuration(1), '1 month');
    expect(formatDuration(14), '1 year, 2 months');

    Intl.defaultLocale = 'es';
    expect(formatDuration(1), '1 mes');
    expect(formatDuration(14), '1 año, 2 meses');
  });
}
