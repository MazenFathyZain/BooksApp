import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/dependency_injection.dart';
import 'core/helpers/constants.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/localization_cubit.dart';
import 'core/routing/app_router.dart';
import 'core/routing/routes.dart';

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
          localeState is LocaleChanged ? localeState.locale : const Locale('en');

          return MaterialApp(
            locale: locale,
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),

            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            debugShowCheckedModeBanner: false,
            title: 'Books',
            theme: ThemeData(
              primarySwatch: Colors.brown,
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: Colors.brown,
                accentColor: Colors.brown, // for cursor and highlights
              ),
              scaffoldBackgroundColor: Colors.brown[50],
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white, // AppBar title and icons
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Colors.brown,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                ),
              ),
              textSelectionTheme: const TextSelectionThemeData(
                cursorColor: Colors.brown, // cursor color in TextField
                selectionColor: Colors.brown, // text selection highlight
                selectionHandleColor: Colors.brown, // handle color
              ),
              inputDecorationTheme: const InputDecorationTheme(
                labelStyle: TextStyle(color: Colors.brown), // label color
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.brown),
                ),
              ),
            ),

            initialRoute: isLoggedInUser
                ? (isAdmin ? Routes.dashboardScreen : Routes.homeScreen)
                : Routes.loginScreen,
            onGenerateRoute: appRouter.generateRoute,
          );
        },
      ),
    );
  }
}
