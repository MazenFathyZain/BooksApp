// theme_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState(themeMode: ThemeMode.light)) {
    _loadSavedTheme();
  }

  static const String _themeKey = 'selected_theme';

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey) ?? 'light';
    final themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    emit(ThemeState(themeMode: themeMode));
  }

  Future<void> changeTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
    emit(ThemeState(themeMode: mode));
  }

  Future<void> toggleTheme() async {
    final newMode = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await changeTheme(newMode);
  }

  bool isDarkMode() => state.themeMode == ThemeMode.dark;
  bool isLightMode() => state.themeMode == ThemeMode.light;
}