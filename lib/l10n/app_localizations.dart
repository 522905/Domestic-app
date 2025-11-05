import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;
  late final Map<String, dynamic> _localizedStrings;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  static List<LocalizationsDelegate<dynamic>> get localizationsDelegates => const <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  Future<bool> load() async {
    final Set<String> supportedLanguageCodes =
    supportedLocales.map((Locale locale) => locale.languageCode).toSet();
    final String requestedLanguageCode = supportedLanguageCodes.contains(locale.languageCode)
        ? locale.languageCode
        : 'en';

    final List<String> lookupOrder = <String>[requestedLanguageCode];
    if (!lookupOrder.contains('en')) {
      lookupOrder.add('en');
    }

    for (final String languageCode in lookupOrder) {
      final String assetPath = 'lib/l10n/app_$languageCode.arb';
      try {
        final String jsonString = await rootBundle.loadString(assetPath);
        final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        _localizedStrings = Map<String, dynamic>.from(jsonMap);
        return true;
      } on FlutterError catch (error) {
        if (error.message.contains('Unable to load asset')) {
          continue;
        }
        rethrow;
      }
    }

    _localizedStrings = <String, dynamic>{};
    debugPrint('AppLocalizations: Failed to load localization assets for $lookupOrder');
    return false;
  }

  String translate(String key, {Map<String, String> params = const <String, String>{}}) {
    final dynamic value = _localizedStrings[key];
    if (value is! String) {
      return key;
    }

    var translated = value;
    params.forEach((paramKey, paramValue) {
      translated = translated.replaceAll('{$paramKey}', paramValue);
    });
    return translated;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any((Locale supportedLocale) => supportedLocale.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
