import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';
import '../helpers/constants.dart';
import '../networking/dio_factory.dart';

part 'localization_state.dart';

class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit({Locale? initialLocale})
    : super(LocaleChanged(initialLocale ?? const Locale('tg')));

  static Future<LocaleCubit> create() async {
    final locale = await _loadSavedLocale();
    return LocaleCubit(initialLocale: locale);
  }

  void changeLocale(String languageCode) async {
    if (!AppLocalizations.supportedLanguageCodes.contains(languageCode)) {
      return;
    }

    final locale = Locale(languageCode);
    await _saveLocale(languageCode);
    await DioFactory.addDioHeaders();
    emit(LocaleChanged(locale));
  }

  Future<void> _saveLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.localeKey, languageCode);
  }

  static Future<Locale> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(AppConstants.localeKey) ?? 'tg';
    final languageCode =
        AppLocalizations.supportedLanguageCodes.contains(savedLocale)
            ? savedLocale
            : 'tg';
    return Locale(languageCode);
  }
}
