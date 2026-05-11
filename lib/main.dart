import 'package:flutter/material.dart';
import 'book_app.dart';
import 'core/di/dependency_injection.dart';
import 'core/helpers/session_helper.dart';
import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupGetIt();
  await restoreSessionState();

  runApp(BookApp(appRouter: AppRouter()));
}
