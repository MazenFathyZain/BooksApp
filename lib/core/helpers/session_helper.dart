import 'constants.dart';
import 'shared_pref_helper.dart';

Future<void> restoreSessionState() async {
  final token = await SharedPrefHelper.getSecuredString(AppConstants.userToken);
  final role = await SharedPrefHelper.getSecuredString(AppConstants.userRole);

  updateSessionState(
    loggedIn: token.isNotEmpty,
    admin: token.isNotEmpty && role.toLowerCase() == 'admin',
    userId: await SharedPrefHelper.getSecuredString(AppConstants.userId),
    name: await SharedPrefHelper.getSecuredString(AppConstants.userName),
    email: await SharedPrefHelper.getSecuredString(AppConstants.userEmail),
  );
}

Future<void> clearSession() async {
  await SharedPrefHelper.clearAllSecuredData();
  clearSessionState();
}
