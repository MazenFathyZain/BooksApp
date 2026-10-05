import 'package:flutter/material.dart';

import 'extension.dart';

class BookLanguage {
  final String code;
  final String apiValue;
  final String translationKey;

  const BookLanguage({
    required this.code,
    required this.apiValue,
    required this.translationKey,
  });
}

const bookLanguages = [
  BookLanguage(code: 'tg', apiValue: 'Tajik', translationKey: 'tajik'),
  BookLanguage(code: 'ar', apiValue: 'Arabic', translationKey: 'arabic'),
  BookLanguage(code: 'fa', apiValue: 'Persian', translationKey: 'persian'),
  BookLanguage(code: 'en', apiValue: 'English', translationKey: 'english'),
  BookLanguage(code: 'ru', apiValue: 'Russian', translationKey: 'russian'),
];

String bookLanguageApiValueFromCode(String code) {
  return bookLanguages
      .firstWhere(
        (language) => language.code == code,
        orElse: () => bookLanguages.first,
      )
      .apiValue;
}

String localizedBookLanguageName(BuildContext context, BookLanguage language) {
  return context.tr(language.translationKey);
}
