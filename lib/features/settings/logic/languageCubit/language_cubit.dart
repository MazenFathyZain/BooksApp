// language_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/networking/dio_factory.dart';
import 'language_state.dart';

// language_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/networking/dio_factory.dart';
import 'language_state.dart';

class LanguageCubit extends Cubit<LanguageState> {
  LanguageCubit() : super(LanguageState(locale: const Locale('ar'))) {
    _loadSavedLanguage();
  }

  static const String _languageKey = 'selected_language';

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey) ?? 'ar';
    emit(LanguageState(locale: Locale(savedLanguage)));
  }

  Future<void> changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);

    // Update Dio headers immediately
    await DioFactory.addDioHeaders();

    emit(LanguageState(locale: Locale(languageCode)));
  }

  bool isArabic() => state.locale.languageCode == 'ar';
  bool isEnglish() => state.locale.languageCode == 'en';
  bool isTajik() => state.locale.languageCode == 'tg';
  bool isRussian() => state.locale.languageCode == 'ru';
}