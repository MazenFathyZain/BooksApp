import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/constants.dart';

part 'localization_state.dart';

class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit() : super(LocaleInitial()) {
    _loadSavedLocale();
  }

  void changeLocale(String languageCode) async {
    final locale = Locale(languageCode);
    emit(LocaleChanged(locale));
    await _saveLocale(languageCode);
  }

  Future<void> _saveLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.localeKey, languageCode);
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(AppConstants.localeKey) ?? 'en';
    emit(LocaleChanged(Locale(savedLocale)));
  }
}
