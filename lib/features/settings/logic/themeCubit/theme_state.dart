// theme_state.dart
import 'package:flutter/material.dart';

class ThemeState {
  final ThemeMode themeMode;

  ThemeState({required this.themeMode});

  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(themeMode: themeMode ?? this.themeMode);
  }
}