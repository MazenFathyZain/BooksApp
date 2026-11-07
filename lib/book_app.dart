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
import 'core/theming/app_theme.dart';

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
            theme: appTheme,
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
