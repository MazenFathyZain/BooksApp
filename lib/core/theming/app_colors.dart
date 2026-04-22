import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF834513); // Saddle Brown
  static const Color primaryLight = Color(0xFFA0522D); // Sienna
  static const Color primaryDark = Color(0xFF5C2E0A);

  // Background Colors
  static const Color background = Color(0xFFF5F1E8); // Cream
  static const Color surface = Colors.white;
  static const Color surfaceLight = Color(0xFFFAF8F3);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);

  // Accent Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Interactive Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Opacity helpers
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // Primary with opacity variants
  static Color get primaryOpacity10 => primary.withOpacity(0.1);
  static Color get primaryOpacity20 => primary.withOpacity(0.2);
  static Color get primaryOpacity30 => primary.withOpacity(0.3);
  static Color get primaryOpacity50 => primary.withOpacity(0.5);
  static Color get primaryOpacity70 => primary.withOpacity(0.7);

  // White with opacity variants
  static Color get whiteOpacity20 => white.withOpacity(0.2);
  static Color get whiteOpacity70 => white.withOpacity(0.7);
}

// ============================================
// 2. app_localizations.dart - Localization Keys
// ============================================
// Path: lib/core/helpers/app_localizations.dart

class LocalizationKeys {
  // Home Screen
  static const String bookLibrary = 'book_library';
  static const String searchBooks = 'search_books';
  static const String searchInCategory = 'search_in_category';
  static const String categories = 'categories';
  static const String noBooksFound = 'no_books_found';
  static const String tryAdjustingFilters = 'try_adjusting_filters';
  static const String retry = 'retry';
  static const String by = 'by';

  // Actions
  static const String bookSaved = 'book_saved';
  static const String bookRemoved = 'book_removed';

  // Errors
  static const String errorOccurred = 'error_occurred';
  static const String loadingFailed = 'loading_failed';
}