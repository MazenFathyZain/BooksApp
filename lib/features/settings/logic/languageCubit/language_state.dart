import 'package:flutter/material.dart';

class LanguageState {
  final Locale locale;

  LanguageState({required this.locale});

  LanguageState copyWith({Locale? locale}) {
    return LanguageState(locale: locale ?? this.locale);
  }
}