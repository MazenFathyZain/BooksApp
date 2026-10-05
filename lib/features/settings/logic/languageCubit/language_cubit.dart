import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/helpers/constants.dart';
import '../../../../core/networking/dio_factory.dart';
import '../../../../core/localization/app_localizations.dart';
import 'language_state.dart';

class LanguageCubit extends Cubit<LanguageState> {
  LanguageCubit() : super(LanguageState(locale: const Locale('tg'))) {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(AppConstants.localeKey) ?? 'tg';
    final languageCode =
        AppLocalizations.supportedLanguageCodes.contains(savedLanguage)
            ? savedLanguage
            : 'tg';
    emit(LanguageState(locale: Locale(languageCode)));
  }

  Future<void> changeLanguage(String languageCode) async {
    if (!AppLocalizations.supportedLanguageCodes.contains(languageCode)) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.localeKey, languageCode);

    // Update Dio headers immediately
    await DioFactory.addDioHeaders();

    emit(LanguageState(locale: Locale(languageCode)));
  }

  bool isArabic() => state.locale.languageCode == 'ar';
  bool isEnglish() => state.locale.languageCode == 'en';
  bool isTajik() => state.locale.languageCode == 'tg';
  bool isRussian() => state.locale.languageCode == 'ru';
  bool isPersian() => state.locale.languageCode == 'fa';
}
