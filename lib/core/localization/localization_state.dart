part of 'localization_cubit.dart';

abstract class LocaleState {}

class LocaleInitial extends LocaleState {}

class LocaleChanged extends LocaleState {
  final Locale locale;
  LocaleChanged(this.locale);
}
