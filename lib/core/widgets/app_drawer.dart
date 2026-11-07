import 'package:flutter/material.dart';
import '../helpers/extension.dart';
import '../helpers/constants.dart';
import '../helpers/shared_pref_helper.dart';
import '../helpers/session_helper.dart';
import '../routing/routes.dart';
import '../theming/app_colors.dart';
import '../di/dependency_injection.dart';
import '../../features/chat/data/chat_repo.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<String?> checkIsLoggedIn() async {
    return await SharedPrefHelper.getSecuredString(AppConstants.userToken);
  }

  /// Unread support messages: user messages for admins, admin replies for
  /// users. Zero for guests or when offline.
  Future<int> getUnreadChatCount() async {
    if (!isLoggedInUser) {
      return 0;
    }
    try {
      final repo = getIt<ChatRepo>();
      return isAdmin
          ? await repo.getAdminUnreadCount()
          : await repo.getMyUnreadCount();
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: Column(
        children: [
          // Header Section
          _buildHeader(context),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
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
                if (isAdmin) ...[
                  const SizedBox(height: 4),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    title: context.tr('dashboard'),
                    isDarkMode: isDarkMode,
                    iconColor: AppColors.secondary,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, Routes.adminDashboardScreen);
                    },
                  ),
                ],
                const SizedBox(height: 4),
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
                const SizedBox(height: 4),
                _buildMenuItem(
                  context: context,
                  icon: Icons.download_done_rounded,
                  title: context.tr('downloaded_books'),
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, Routes.downloadedBooksScreen);
                  },
                ),
                const SizedBox(height: 4),
                FutureBuilder<int>(
                  future: getUnreadChatCount(),
                  builder: (context, snapshot) {
                    return _buildMenuItem(
                      context: context,
                      icon:
                          isAdmin
                              ? Icons.forum_outlined
                              : Icons.support_agent_outlined,
                      title: context.tr(
                        isAdmin ? 'user_messages' : 'contact_admin',
                      ),
                      isDarkMode: isDarkMode,
                      badgeCount: snapshot.data ?? 0,
                      onTap: () async {
                        Navigator.of(context).pop();
                        if (isAdmin) {
                          Navigator.pushNamed(
                            context,
                            Routes.adminConversationsScreen,
                          );
                          return;
                        }
                        if (!isLoggedInUser) {
                          final shouldLogin = await showDialog<bool>(
                            context: context,
                            builder:
                                (dialogContext) => AlertDialog(
                                  title: Text(context.tr('login_required')),
                                  content: Text(
                                    context.tr('login_to_contact_admin'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(
                                            dialogContext,
                                            false,
                                          ),
                                      child: Text(context.tr('cancel')),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(
                                            dialogContext,
                                            true,
                                          ),
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
                        Navigator.pushNamed(context, Routes.chatScreen);
                      },
                    );
                  },
                ),
                const SizedBox(height: 4),
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

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 8),
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
                      icon:
                          isLoggedIn
                              ? Icons.logout_outlined
                              : Icons.login_outlined,
                      title: context.tr(isLoggedIn ? 'logout' : 'login'),
                      isDarkMode: isDarkMode,
                      iconColor:
                          isLoggedIn ? AppColors.error : AppColors.success,
                      onTap: () async {
                        Navigator.of(context).pop();
                        if (isLoggedIn) {
                          // Show confirmation dialog before logout
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text(context.tr('logout')),
                                  content: Text(
                                    context.tr('logout_confirmation'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: Text(context.tr('cancel')),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
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

  Widget _buildHeader(BuildContext context) {
    final hasName = isLoggedInUser && currentUserName.isNotEmpty;
    final title =
        hasName
            ? currentUserName
            : context.tr(isLoggedInUser ? 'my_account' : 'guest_user');
    final subtitle =
        isLoggedInUser && currentUserEmail.isNotEmpty
            ? currentUserEmail
            : context.tr('browse_books');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 20,
        20,
        20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.white.withValues(alpha: 0.18),
            child:
                hasName
                    ? Text(
                      currentUserName.trim().characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                    : const Icon(
                      Icons.person_outline,
                      size: 30,
                      color: AppColors.white,
                    ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
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
    int badgeCount = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        trailing:
            badgeCount > 0
                ? Badge(
                  label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
                  backgroundColor: AppColors.error,
                )
                : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
