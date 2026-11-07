import 'package:book/core/routing/routes.dart';
import 'package:book/features/admin/ui/admin_books_screen.dart';
import 'package:book/features/admin/ui/admin_categories_screen.dart';
import 'package:book/features/admin/ui/admin_dashboard_screen.dart';
import 'package:book/features/admin/ui/admin_users_screen.dart';
import 'package:book/features/auth/ui/register_screen.dart';
import 'package:book/features/bookDetails/logic/book_details_cubit.dart';
import 'package:book/features/bookDetails/ui/book_details_screen.dart';
import 'package:book/features/bookDetails/ui/pdf_viewer_screen.dart';
import 'package:book/features/bookDetails/ui/widgets/audio_player_screen.dart';
import 'package:book/features/bookDetails/ui/widgets/word_viewer_screen.dart';
import 'package:book/features/chat/ui/admin_conversations_screen.dart';
import 'package:book/features/chat/ui/chat_screen.dart';
import 'package:book/features/dashboard/logic/dashboard_cubit.dart';
import 'package:book/features/dashboard/ui/dashboard_screen.dart';
import 'package:book/features/downloads/ui/downloaded_books_screen.dart';
import 'package:book/features/favorite/logic/favorite_cubit.dart';
import 'package:book/features/favorite/ui/favorite_screen.dart';
import 'package:book/features/home/logic/home_cubit.dart';
import 'package:book/features/settings/ui/settingsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/logic/auth_cubit.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/home/ui/home_screen.dart';
import '../di/dependency_injection.dart';

class AppRouter {
  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.loginScreen:
        return MaterialPageRoute(
          builder: (BuildContext context) {
            return BlocProvider(
              create: (context) => getIt<AuthCubit>(),
              child: LoginScreen(),
            );
          },
          settings: settings,
        );
      case Routes.settingsScreen:
        return MaterialPageRoute(
          builder: (BuildContext context) {
            return BlocProvider(
              create: (context) => getIt<AuthCubit>(),
              child: SettingsScreen(),
            );
          },
          settings: settings,
        );
      case Routes.registerScreen:
        return MaterialPageRoute(
          builder: (BuildContext context) {
            return BlocProvider(
              create: (context) => getIt<AuthCubit>(),
              child: RegisterScreen(),
            );
          },
          settings: settings,
        );
      case Routes.homeScreen:
        return MaterialPageRoute(
          builder: (BuildContext context) {
            return BlocProvider(
              create: (context) => getIt<HomeCubit>(),
              child: HomeScreen(),
            );
          },
          settings: settings,
        );
      case Routes.dashboardScreen:
        final returnToHomeAfterSave = settings.arguments as bool? ?? false;
        return MaterialPageRoute(
          builder: (BuildContext context) {
            return BlocProvider(
              create: (context) => getIt<DashboardCubit>(),
              child: DashboardScreen(
                returnToHomeAfterSave: returnToHomeAfterSave,
              ),
            );
          },
          settings: settings,
        );
      case Routes.bookDetailsScreen:
        return MaterialPageRoute(
          builder: (BuildContext context) {
            return BlocProvider(
              create: (context) => getIt<BookDetailsCubit>(),
              child: BookDetailsScreen(),
            );
          },
          settings: settings,
        );
      case Routes.pdf:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final pdfUrl = args['pdfUrl'] as String? ?? '';
        final title = args['title'] as String?;
        final isLocal = args['isLocal'] as bool? ?? false;
        final bookId = args['bookId'] as String?;
        return MaterialPageRoute(
          builder: (BuildContext context) {
            return PdfViewerScreen(
              pdfPath: pdfUrl,
              isLocal: isLocal,
              bookTitle: title,
              bookId: bookId,
            );
          },
          settings: settings,
        );
      case Routes.favoriteBooksScreen:
        return MaterialPageRoute(
          builder: (BuildContext context) {
            return BlocProvider(
              create: (context) => getIt<FavoriteCubit>(),
              child: FavoriteScreen(),
            );
          },
          settings: settings,
        );
      case Routes.downloadedBooksScreen:
        return MaterialPageRoute(
          builder: (BuildContext context) {
            return const DownloadedBooksScreen();
          },
          settings: settings,
        );
      case Routes.adminDashboardScreen:
        return MaterialPageRoute(
          builder: (BuildContext context) => const AdminDashboardScreen(),
          settings: settings,
        );
      case Routes.adminUsersScreen:
        final initialRole = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder:
              (BuildContext context) =>
                  AdminUsersScreen(initialRole: initialRole),
          settings: settings,
        );
      case Routes.adminCategoriesScreen:
        return MaterialPageRoute(
          builder: (BuildContext context) => const AdminCategoriesScreen(),
          settings: settings,
        );
      case Routes.adminBooksScreen:
        return MaterialPageRoute(
          builder: (BuildContext context) => const AdminBooksScreen(),
          settings: settings,
        );
      case Routes.chatScreen:
        return MaterialPageRoute(
          builder: (BuildContext context) => const ChatScreen(),
          settings: settings,
        );
      case Routes.adminConversationsScreen:
        return MaterialPageRoute(
          builder: (BuildContext context) => const AdminConversationsScreen(),
          settings: settings,
        );
      case "/audio_player":
        return MaterialPageRoute(
          builder: (BuildContext context) {
            return AudioPlayerScreen();
          },
          settings: settings,
        );
      case "/word_viewer":
        return MaterialPageRoute(
          builder: (BuildContext context) {
            return WordViewerScreen();
          },
          settings: settings,
        );
      default:
        return null;
    }
  }
}
