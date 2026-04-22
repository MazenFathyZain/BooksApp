import 'package:flutter/material.dart';

import '../di/dependency_injection.dart';
import '../localization/app_localizations.dart';
import '../localization/localization_cubit.dart';

extension Navigation on BuildContext {
  Future<dynamic> pushNamed(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic> pushReplacementNamed(String routeName, {Object? arguments}) {
    return Navigator.of(this)
        .pushReplacementNamed(routeName, arguments: arguments);
  }

  Future<dynamic> pushNamedAndRemoveUntil(String routeName,
      {Object? arguments, required RoutePredicate predicate}) {
    return Navigator.of(this)
        .pushNamedAndRemoveUntil(routeName, predicate, arguments: arguments);
  }

  void pop() => Navigator.of(this).pop;
}
extension StringExtension on String? {
  bool isNullOrEmpty() => this == null || this == "";
}
extension ListExtension<T> on List<T>? {
  bool isNullOrEmpty() => this == null || this!.isEmpty;
}

extension LocalizationExtension on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this)?.translate(key) ?? key;
  }

  AppLocalizations? get localizations => AppLocalizations.of(this);

  // Get current language code
  String get currentLanguage {
    final localeState = getIt<LocaleCubit>().state;
    if (localeState is LocaleChanged) {
      return localeState.locale.languageCode;
    }
    return 'en'; // default
  }

  // Check if current language is Arabic
  bool get isArabic => currentLanguage == 'ar';

  // Check if current language is English
  bool get isEnglish => currentLanguage == 'en';

  // Get current language display name
  String get currentLanguageName {
    return currentLanguage == 'ar' ? tr('arabic') : tr('english');
  }
}