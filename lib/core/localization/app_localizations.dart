import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLanguageCodes = ['en', 'ar', 'tg', 'ru', 'fa'];

  Map<String, String> _localizedStrings = {};
  Map<String, String> _fallbackStrings = {};

  Future<bool> load() async {
    final String jsonString = await rootBundle.loadString(
      'assets/translations/${locale.languageCode}.json',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    final fallbackLangCode = locale.languageCode == 'tg' ? 'en' : 'tg';
    try {
      final String fallbackJsonString = await rootBundle.loadString(
        'assets/translations/$fallbackLangCode.json',
      );
      final Map<String, dynamic> fallbackJsonMap = json.decode(
        fallbackJsonString,
      );
      _fallbackStrings = fallbackJsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
    } catch (_) {
      _fallbackStrings = {};
    }

    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? _fallbackStrings[key] ?? key;
  }

  // Helper method for easy access
  String get(String key) => translate(key);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLanguageCodes.contains(
      locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
