import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/helpers/extension.dart';
import '../../../core/theming/app_colors.dart';
import '../data/chat_models.dart';
import '../data/chat_repo.dart';
import 'chat_formatting.dart';
import 'chat_screen.dart';

/// Admin inbox: every user's support conversation, newest first.
class AdminConversationsScreen extends StatefulWidget {
  const AdminConversationsScreen({super.key});

  @override
  State<AdminConversationsScreen> createState() =>
      _AdminConversationsScreenState();
}

class _AdminConversationsScreenState extends State<AdminConversationsScreen> {
  static const Duration _pollInterval = Duration(seconds: 10);

  final ChatRepo _repo = getIt<ChatRepo>();
  final TextEditingController _searchController = TextEditingController();
  List<ChatConversation> _conversations = const [];
  Timer? _pollTimer;
  Timer? _searchDebounce;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = _conversations.isEmpty;
        _error = null;
      });
    }
    try {
      final conversations = await _repo.getConversations(
        search: _searchController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _conversations = conversations;
        _isLoading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || silent) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = context.tr('chat_load_failed');
      });
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _open(ChatConversation conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ChatScreen(
              conversationId: conversation.id,
              title:
                  conversation.userName.isEmpty
                      ? conversation.userEmail
                      : conversation.userName,
              subtitle: conversation.userEmail,
            ),
      ),
    );
    if (mounted) {
      _load(silent: true);
    }
  }

  Future<void> _confirmDelete(ChatConversation conversation) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(context.tr('delete_conversation')),
            content: Text(context.tr('delete_conversation_confirmation')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(context.tr('delete')),
              ),
            ],
          ),
    );
    if (shouldDelete != true || !mounted) {
      return;
    }
    try {
      await _repo.deleteConversation(conversation.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _conversations =
            _conversations.where((item) => item.id != conversation.id).toList();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('error_occurred')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalUnread = _conversations.fold<int>(
      0,
      (sum, item) => sum + item.unreadForAdmin,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: Text(
          totalUnread > 0
              ? '${context.tr('user_messages')} ($totalUnread)'
              : context.tr('user_messages'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: context.tr('search_conversations'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.white,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final error = _error;
    if (error != null || _conversations.isEmpty) {
      // Scrollable so pull-to-refresh still works on the empty/error state.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
          Icon(
            error != null ? Icons.cloud_off : Icons.mark_chat_read_outlined,
            size: 56,
            color: error != null ? AppColors.error : AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            error ?? context.tr('no_conversations'),
            textAlign: TextAlign.center,
          ),
          if (error != null)
            Center(
              child: TextButton(
                onPressed: _load,
                child: Text(context.tr('retry')),
              ),
            ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _conversations.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final hasUnread = conversation.unreadForAdmin > 0;
        final name =
            conversation.userName.isEmpty
                ? conversation.userEmail
                : conversation.userName;
        final preview =
            conversation.lastSenderRole == 'admin'
                ? '${context.tr('you')}: ${conversation.lastMessage}'
                : conversation.lastMessage;

        return ListTile(
          onTap: () => _open(conversation),
          onLongPress: () => _confirmDelete(conversation),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              chatInitial(name),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              Text(
                chatListTime(context, conversation.lastMessageAt),
                style: TextStyle(
                  fontSize: 12,
                  color: hasUnread ? AppColors.primary : AppColors.textHint,
                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (hasUnread)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: Badge(
                    label: Text('${conversation.unreadForAdmin}'),
                    backgroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
