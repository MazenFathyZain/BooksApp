import 'package:flutter/widgets.dart';

import '../../../core/helpers/extension.dart';

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// 24-hour time, e.g. "09:05".
String chatTime(DateTime time) =>
    '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';

bool isSameChatDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Today", "Yesterday" or the date, for separators between days.
String chatDayLabel(BuildContext context, DateTime time) {
  final now = DateTime.now();
  if (isSameChatDay(time, now)) {
    return context.tr('today');
  }
  if (isSameChatDay(time, now.subtract(const Duration(days: 1)))) {
    return context.tr('yesterday');
  }
  return '${time.year}/${_twoDigits(time.month)}/${_twoDigits(time.day)}';
}

/// Short time for the conversation list: the time today, otherwise the date.
String chatListTime(BuildContext context, DateTime time) {
  final now = DateTime.now();
  if (isSameChatDay(time, now)) {
    return chatTime(time);
  }
  if (isSameChatDay(time, now.subtract(const Duration(days: 1)))) {
    return context.tr('yesterday');
  }
  return '${time.year}/${_twoDigits(time.month)}/${_twoDigits(time.day)}';
}

String chatInitial(String? name) {
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
}
