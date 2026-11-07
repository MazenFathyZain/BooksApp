bool isLoggedInUser = false;
bool isAdmin = false;
String currentUserId = '';
String currentUserName = '';
String currentUserEmail = '';

void updateSessionState({
  required bool loggedIn,
  required bool admin,
  String userId = '',
  String name = '',
  String email = '',
}) {
  isLoggedInUser = loggedIn;
  isAdmin = admin;
  currentUserId = userId;
  currentUserName = name;
  currentUserEmail = email;
}

void clearSessionState() {
  updateSessionState(loggedIn: false, admin: false);
}

class AppConstants {
  static const String userToken = 'user_token';
  static const String userRole = 'user_roles';
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String localeKey = "selected_locale";
  static const String homeDisplayCoverOnly = 'home_display_cover_only';
  static const String appLogoAsset = 'assets/images/app_logo.png';
  static const String googleApiKey = 'AIzaSyCz1kA9c-lUb0bQCxeZa5IlQQ1n90ktKp0';
  static const String baseUrl = 'https://web21.odoofuture.com/api';
  static const String teamRequests = 'employee_team/get_leaves';
}
