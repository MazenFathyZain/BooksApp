import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF0B5A2A);
  static const Color primaryLight = Color(0xFF7DBC3F);
  static const Color primaryDark = Color(0xFF053C1C);
  static const Color secondary = Color(0xFFC79630);
  static const Color secondaryLight = Color(0xFFE2C173);

  // Background Colors
  static const Color background = Color(0xFFF7F4EC);
  static const Color surface = Colors.white;
  static const Color surfaceLight = Color(0xFFFCFAF4);
  static const Color border = Color(0xFFE6D8BA);

  // Text Colors
  static const Color textPrimary = Color(0xFF173220);
  static const Color textSecondary = Color(0xFF5E695C);
  static const Color textHint = Color(0xFF919A8F);

  // Accent Colors
  static const Color success = Color(0xFF2E8B57);
  static const Color error = Color(0xFFD9534F);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Interactive Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Opacity helpers
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // Primary with opacity variants
  static Color get primaryOpacity10 => primary.withValues(alpha: 0.1);
  static Color get primaryOpacity20 => primary.withValues(alpha: 0.2);
  static Color get primaryOpacity30 => primary.withValues(alpha: 0.3);
  static Color get primaryOpacity50 => primary.withValues(alpha: 0.5);
  static Color get primaryOpacity70 => primary.withValues(alpha: 0.7);

  // Secondary with opacity variants
  static Color get secondaryOpacity10 => secondary.withValues(alpha: 0.1);
  static Color get secondaryOpacity20 => secondary.withValues(alpha: 0.2);

  // White with opacity variants
  static Color get whiteOpacity20 => white.withValues(alpha: 0.2);
  static Color get whiteOpacity70 => white.withValues(alpha: 0.7);
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
