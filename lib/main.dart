import 'dart:developer';

import 'package:book/core/helpers/extension.dart';
import 'package:flutter/material.dart';
import 'book_app.dart';
import 'core/di/dependency_injection.dart';
import 'core/helpers/constants.dart';
import 'core/helpers/shared_pref_helper.dart';
import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupGetIt();

  await checkIfLoggedInUser();
  await checkRole();

  runApp(BookApp(appRouter: AppRouter()));
}

checkIfLoggedInUser() async {
  String? userToken =
  await SharedPrefHelper.getSecuredString(AppConstants.userToken);
  if (!userToken!.isNullOrEmpty()) {
    log(userToken);
    isLoggedInUser = true;
  } else {
    log("Null Token");
    isLoggedInUser = false;
  }

}
checkRole() async {
  String? role =
  await SharedPrefHelper.getSecuredString(AppConstants.userRole);
  if (role! == "user") {
    log(role);
    isAdmin = false;
  } else {
    log("Admin");
    isAdmin = true;
  }
}