import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/dependency_injection.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/localization_cubit.dart';
import 'core/routing/app_router.dart';
import 'core/routing/routes.dart';
import 'core/theming/app_colors.dart';

class BookApp extends StatelessWidget {
  final AppRouter appRouter;
  const BookApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<LocaleCubit>.value(value: getIt<LocaleCubit>())],
      child: Builder(
        builder: (context) {
          final localeState = context.watch<LocaleCubit>().state;

          final Locale locale =
              localeState is LocaleChanged
                  ? localeState.locale
                  : const Locale('tg');

          return MaterialApp(

            locale: locale,
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
              Locale('tg'),
              Locale('ru'),
              Locale('fa'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              _TajikMaterialLocalizationsDelegate(),
              _TajikCupertinoLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              final textDirection =
                  locale.languageCode == 'ar' || locale.languageCode == 'fa'
                      ? TextDirection.rtl
                      : TextDirection.ltr;

              return Directionality(
                textDirection: textDirection,
                child: child ?? const SizedBox.shrink(),
              );
            },
            debugShowCheckedModeBanner: false,
            onGenerateTitle:
                (context) =>
                    AppLocalizations.of(context)?.translate('app_name') ??
                    "Kitobhonai ma'rifat",
            theme: ThemeData(

              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                surface: AppColors.surface,
                brightness: Brightness.light,

              ),

              scaffoldBackgroundColor: AppColors.background,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.white,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              textSelectionTheme: const TextSelectionThemeData(
                cursorColor: AppColors.primary,
                selectionColor: AppColors.secondary,
                selectionHandleColor: AppColors.primary,
              ),
              snackBarTheme: SnackBarThemeData(
                backgroundColor: AppColors.primaryDark,
                contentTextStyle: const TextStyle(color: AppColors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                behavior: SnackBarBehavior.floating,
              ),
              dividerTheme: DividerThemeData(
                color: AppColors.primary.withValues(alpha: 0.12),
                thickness: 1,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.surface,
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIconColor: AppColors.primary,
                suffixIconColor: AppColors.primary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.secondary,
                    width: 1.6,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 1.6,
                  ),
                ),
              ),
            ),
            initialRoute: Routes.homeScreen,
            onGenerateRoute: appRouter.generateRoute,
          );
        },
      ),
    );
  }
}

class _TajikMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _TajikMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tg';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return SynchronousFuture<MaterialLocalizations>(
      const DefaultMaterialLocalizations(),
    );
  }

  @override
  bool shouldReload(_TajikMaterialLocalizationsDelegate old) => false;
}

class _TajikCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _TajikCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tg';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return SynchronousFuture<CupertinoLocalizations>(
      const DefaultCupertinoLocalizations(),
    );
  }

  @override
  bool shouldReload(_TajikCupertinoLocalizationsDelegate old) => false;
}
