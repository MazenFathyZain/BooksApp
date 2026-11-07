import 'package:flutter/material.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/helpers/extension.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theming/app_colors.dart';
import '../../chat/data/chat_repo.dart';
import '../../chat/ui/chat_formatting.dart';
import '../../home/data/models/books_response.dart';
import '../../home/ui/widgets/book_cover_image.dart';
import '../data/admin_models.dart';
import '../data/admin_repo.dart';
import 'admin_widgets.dart';

/// Home of the admin tools: the website's overview, plus links to manage books,
/// categories, users and messages.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminRepo _repo = getIt<AdminRepo>();
  AdminStats? _stats;
  int _unreadMessages = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stats = await _repo.getStats();
      // The message badge is a bonus: stats still show if it fails.
      final unread = await getIt<ChatRepo>().getAdminUnreadCount().catchError(
        (_) => _unreadMessages,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _stats = stats;
        _unreadMessages = unread;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _open(String route, {Object? arguments}) async {
    await Navigator.pushNamed(context, route, arguments: arguments);
    if (mounted) {
      _load();
    }
  }

  void _openBook(BooksResponse book) {
    final id = book.id;
    if (id != null && id.isNotEmpty) {
      _open(Routes.bookDetailsScreen, arguments: {'id': id, 'isSaved': false});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('dashboard'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(Routes.dashboardScreen, arguments: true),
        icon: const Icon(Icons.add),
        label: Text(context.tr('add_book')),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final stats = _stats;
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (stats == null) {
      return AdminStateView(
        icon: Icons.cloud_off,
        message: context.tr('error_occurred'),
        onRetry: () {
          setState(() => _isLoading = true);
          _load();
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _buildStats(stats),
        const SizedBox(height: 24),
        _SectionTitle(context.tr('quick_actions')),
        _ActionTile(
          icon: Icons.menu_book_outlined,
          title: context.tr('manage_books'),
          onTap: () => _open(Routes.adminBooksScreen),
        ),
        _ActionTile(
          icon: Icons.account_tree_outlined,
          title: context.tr('manage_categories'),
          onTap: () => _open(Routes.adminCategoriesScreen),
        ),
        _ActionTile(
          icon: Icons.group_outlined,
          title: context.tr('manage_users'),
          onTap: () => _open(Routes.adminUsersScreen),
        ),
        _ActionTile(
          icon: Icons.forum_outlined,
          title: context.tr('user_messages'),
          badge: _unreadMessages,
          onTap: () => _open(Routes.adminConversationsScreen),
        ),
        if (stats.recentBooks.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionTitle(context.tr('recent_books')),
          for (final book in stats.recentBooks)
            _RecentBookTile(book: book, onTap: () => _openBook(book)),
        ],
        if (stats.recentUsers.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionTitle(context.tr('recent_users')),
          for (final user in stats.recentUsers) _RecentUserTile(user: user),
        ],
      ],
    );
  }

  Widget _buildStats(AdminStats stats) {
    final cards = [
      _StatCard(
        icon: Icons.menu_book_rounded,
        label: context.tr('books_count'),
        value: stats.booksCount,
        onTap: () => _open(Routes.adminBooksScreen),
      ),
      _StatCard(
        icon: Icons.group_rounded,
        label: context.tr('users_count'),
        value: stats.usersCount,
        onTap: () => _open(Routes.adminUsersScreen),
      ),
      _StatCard(
        icon: Icons.account_tree_rounded,
        label: context.tr('categories'),
        value: stats.categoriesCount,
        onTap: () => _open(Routes.adminCategoriesScreen),
      ),
      _StatCard(
        icon: Icons.admin_panel_settings_rounded,
        label: context.tr('admins_count'),
        value: stats.adminsCount,
        onTap: () => _open(Routes.adminUsersScreen, arguments: 'admin'),
      ),
      _StatCard(
        icon: Icons.bookmark_rounded,
        label: context.tr('favorites_count'),
        value: stats.favoritesCount,
      ),
      _StatCard(
        icon: Icons.forum_rounded,
        label: context.tr('unread_messages'),
        value: _unreadMessages,
        onTap: () => _open(Routes.adminConversationsScreen),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.secondary, size: 24),
              const SizedBox(height: 10),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int badge;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge > 0)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Badge(
                  label: Text(badge > 99 ? '99+' : '$badge'),
                  backgroundColor: AppColors.error,
                ),
              ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              // chevron_right mirrors itself in right-to-left languages.
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentBookTile extends StatelessWidget {
  final BooksResponse book;
  final VoidCallback onTap;

  const _RecentBookTile({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: SizedBox(
          width: 36,
          height: 52,
          child: BookCoverImage(
            imageUrl: book.imageUrl,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Text(
          book.title ?? context.tr('no_title'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          book.author ?? context.tr('unknown'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _RecentUserTile extends StatelessWidget {
  final AdminUser user;

  const _RecentUserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            chatInitial(user.name),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: AdminRoleBadge(isAdmin: user.isAdmin),
      ),
    );
  }
}
