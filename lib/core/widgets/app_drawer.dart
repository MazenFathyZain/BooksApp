import 'package:flutter/material.dart';
import '../helpers/extension.dart';
import '../helpers/constants.dart';
import '../helpers/shared_pref_helper.dart';
import '../helpers/session_helper.dart';
import '../routing/routes.dart';
import '../theming/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<String?> checkIsLoggedIn() async {
    return await SharedPrefHelper.getSecuredString(AppConstants.userToken);
  }

  Future<Map<String, String>> getUserData() async {
    return {'name': "", 'email': ""};
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: Column(
        children: [
          // Header Section
          FutureBuilder<Map<String, String>>(
            future: getUserData(),
            builder: (context, snapshot) {
              final userData = snapshot.data ?? {'name': '', 'email': ''};
              final isLoading = snapshot.connectionState == ConnectionState.waiting;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: AppColors.white.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.person_outline,
                              size: 50,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.menu_book,
                              size: 14,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isLoading
                          ? context.tr('loading')
                          : userData['name']!.isEmpty
                          ? context.tr('guest_user')
                          : userData['name']!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading
                          ? '...'
                          : userData['email']!.isEmpty
                          ? context.tr('browse_books')
                          : userData['email']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.home_outlined,
                  title: context.tr('home'),
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.homeScreen,
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context: context,
                  icon: Icons.bookmark_outline_rounded,
                  title: context.tr('saved_books'),
                  isDarkMode: isDarkMode,
                  onTap: () async {
                    Navigator.of(context).pop();
                    if (!isLoggedInUser) {
                      final shouldLogin = await showDialog<bool>(
                        context: context,
                        builder:
                            (dialogContext) => AlertDialog(
                              title: Text(context.tr('login_required')),
                              content: Text(
                                context.tr('login_to_view_saved_books'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(dialogContext, false),
                                  child: Text(context.tr('cancel')),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(dialogContext, true),
                                  child: Text(context.tr('login')),
                                ),
                              ],
                            ),
                      );

                      if (shouldLogin == true && context.mounted) {
                        Navigator.pushNamed(context, Routes.loginScreen);
                      }
                      return;
                    }

                    Navigator.pushNamed(context, Routes.favoriteBooksScreen);
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: context.tr('settings'),
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, Routes.settingsScreen);
                  },
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context: context,
                  icon: Icons.help_outline,
                  title: context.tr('help'),
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, "");
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Divider(height: 1),
                ),

                // Login/Logout Item
                FutureBuilder<String?>(
                  future: checkIsLoggedIn(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    }

                    final token = snapshot.data;
                    final isLoggedIn = token != null && token.isNotEmpty;

                    return _buildMenuItem(
                      context: context,
                      icon: isLoggedIn ? Icons.logout_outlined : Icons.login_outlined,
                      title: context.tr(isLoggedIn ? 'logout' : 'login'),
                      isDarkMode: isDarkMode,
                      iconColor: isLoggedIn ? AppColors.error : AppColors.success,
                      onTap: () async {
                        Navigator.of(context).pop();
                        if (isLoggedIn) {
                          // Show confirmation dialog before logout
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(context.tr('logout')),
                              content: Text(context.tr('logout_confirmation')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(context.tr('cancel')),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                  child: Text(context.tr('logout')),
                                ),
                              ],
                            ),
                          );

                          if (shouldLogout == true) {
                            await clearSession();
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                Routes.loginScreen,
                                (route) => false,
                              );
                            }
                          }
                        } else {
                          Navigator.pushNamed(context, Routes.loginScreen);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),


        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDarkMode,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[400],
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hoverColor: AppColors.primary.withValues(alpha: 0.05),
      ),
    );
  }
}

// ============================================
// Add these localization keys
// ============================================

/*
// Add to LocalizationKeys class:
class LocalizationKeys {
  static const String home = 'home';
  static const String favorites = 'favorites';
  static const String settings = 'settings';
  static const String help = 'help';
  static const String login = 'login';
  static const String logout = 'logout';
  static const String logoutConfirmation = 'logout_confirmation';
  static const String cancel = 'cancel';
  static const String loading = 'loading';
  static const String guestUser = 'guest_user';
  static const String browseBooks = 'browse_books';
  static const String appName = 'app_name';
  static const String appVersion = 'app_version';
}

// Add to en.json:
{
  "home": "Home",
  "favorites": "Favorites",
  "settings": "Settings",
  "help": "Help & Support",
  "login": "Login",
  "logout": "Logout",
  "logout_confirmation": "Are you sure you want to logout?",
  "cancel": "Cancel",
  "loading": "Loading...",
  "guest_user": "Guest User",
  "browse_books": "Browse and read books",
  "app_name": "Book Library",
  "app_version": "Version 1.0.0"
}

// Add to ar.json:
{
  "home": "الرئيسية",
  "favorites": "المفضلة",
  "settings": "الإعدادات",
  "help": "المساعدة والدعم",
  "login": "تسجيل الدخول",
  "logout": "تسجيل الخروج",
  "logout_confirmation": "هل أنت متأكد من تسجيل الخروج؟",
  "cancel": "إلغاء",
  "loading": "جاري التحميل...",
  "guest_user": "مستخدم ضيف",
  "browse_books": "تصفح واقرأ الكتب",
  "app_name": "مكتبة الكتب",
  "app_version": "الإصدار 1.0.0"
}
*/

// ============================================
// Add these routes to your Routes class
// ============================================

/*
class Routes {
  static const String homeScreen = '/home';
  static const String favoritesScreen = '/favorites';
  static const String settingsScreen = '/settings';
  static const String helpScreen = '/help';
  static const String loginScreen = '/login';
}
*/

// ============================================
// Add these to AppConstants if not exists
// ============================================

/*
class AppConstants {
  static const String userToken = 'userToken';
  static const String userName = 'userName';
  static const String userEmail = 'userEmail';
}
*/
