import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/helpers/extension.dart';
import '../../../core/theming/app_colors.dart';
import '../data/chat_models.dart';
import '../data/chat_repo.dart';
import 'chat_formatting.dart';

/// A support conversation.
///
/// Without [conversationId] it is the signed-in user's own conversation with
/// the administration. With it, an admin is replying to that user.
class ChatScreen extends StatefulWidget {
  final String? conversationId;
  final String? title;
  final String? subtitle;

  const ChatScreen({super.key, this.conversationId, this.title, this.subtitle});

  bool get isAdminView => conversationId != null;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  static const Duration _pollInterval = Duration(seconds: 4);
  static const int _maxLength = 2000;

  final ChatRepo _repo = getIt<ChatRepo>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Oldest first.
  final List<ChatMessage> _messages = [];
  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isLoadingOlder = false;
  bool _isPolling = false;
  bool _hasMore = false;
  bool _canSend = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_handleScroll);
    _textController.addListener(() {
      final canSend = _textController.text.trim().isNotEmpty;
      if (canSend != _canSend) {
        setState(() => _canSend = canSend);
      }
    });
    _loadInitial();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Don't keep polling the server while the app is in the background.
    if (state == AppLifecycleState.resumed) {
      _poll();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel();
    }
  }

  Future<ChatThread> _fetch({DateTime? after, DateTime? before}) {
    final conversationId = widget.conversationId;
    return conversationId == null
        ? _repo.getMyThread(after: after, before: before)
        : _repo.getConversationThread(
          conversationId,
          after: after,
          before: before,
        );
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final thread = await _fetch();
      if (!mounted) {
        return;
      }
      setState(() {
        _messages
          ..clear()
          ..addAll(thread.messages);
        _hasMore = thread.hasMore;
        _isLoading = false;
      });
      _startPolling();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = _errorText(error);
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  DateTime? get _newestServerMessageTime {
    for (final message in _messages.reversed) {
      if (!message.isPending && !message.hasFailed) {
        return message.createdAt;
      }
    }
    return null;
  }

  Future<void> _poll() async {
    if (_isPolling || _isLoading || _loadError != null) {
      return;
    }
    _isPolling = true;
    try {
      final after = _newestServerMessageTime;
      final thread = await _fetch(after: after);
      if (!mounted) {
        return;
      }
      _mergeNewMessages(thread.messages);
      if (after == null) {
        _hasMore = thread.hasMore;
      }
    } catch (_) {
      // Polling is best effort; the next tick tries again.
    } finally {
      _isPolling = false;
    }
  }

  void _mergeNewMessages(List<ChatMessage> incoming) {
    final knownIds = _messages.map((message) => message.id).toSet();
    final fresh = incoming.where((message) => !knownIds.contains(message.id));
    if (fresh.isEmpty) {
      return;
    }
    setState(() {
      // Keep unsent/failed messages at the bottom, after the server's ones.
      final local = _messages.where((m) => m.isPending || m.hasFailed).toList();
      _messages
        ..removeWhere((m) => m.isPending || m.hasFailed)
        ..addAll(fresh)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt))
        ..addAll(local);
    });
  }

  void _handleScroll() {
    // The list is reversed, so the end of the scroll is the oldest message.
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadOlder();
    }
  }

  Future<void> _loadOlder() async {
    if (_isLoadingOlder || !_hasMore || _messages.isEmpty) {
      return;
    }
    setState(() => _isLoadingOlder = true);
    try {
      final thread = await _fetch(before: _messages.first.createdAt);
      if (!mounted) {
        return;
      }
      final knownIds = _messages.map((message) => message.id).toSet();
      setState(() {
        _messages.insertAll(
          0,
          thread.messages.where((message) => !knownIds.contains(message.id)),
        );
        _hasMore = thread.hasMore;
        _isLoadingOlder = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingOlder = false);
      }
    }
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _textController.clear();

    final pending = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      senderRole: widget.isAdminView ? 'admin' : 'user',
      text: text,
      createdAt: DateTime.now(),
      isPending: true,
    );
    setState(() => _messages.add(pending));
    _scrollToBottom();
    await _deliver(pending);
  }

  Future<void> _deliver(ChatMessage pending) async {
    try {
      final conversationId = widget.conversationId;
      final sent =
          conversationId == null
              ? await _repo.sendMyMessage(pending.text)
              : await _repo.sendAdminMessage(conversationId, pending.text);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.removeWhere((m) => m.id == pending.id || m.id == sent.id);
        // Insert before any other unsent messages.
        final firstLocal = _messages.indexWhere(
          (m) => m.isPending || m.hasFailed,
        );
        _messages.insert(firstLocal < 0 ? _messages.length : firstLocal, sent);
      });
      // A user's first message creates the conversation; start polling it.
      if (_pollTimer == null || !_pollTimer!.isActive) {
        _startPolling();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        final index = _messages.indexWhere((m) => m.id == pending.id);
        if (index >= 0) {
          _messages[index] = pending.copyWith(
            isPending: false,
            hasFailed: true,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('chat_send_failed')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _retry(ChatMessage failed) {
    final pending = failed.copyWith(isPending: true, hasFailed: false);
    setState(() {
      final index = _messages.indexWhere((m) => m.id == failed.id);
      if (index >= 0) {
        _messages[index] = pending;
      }
    });
    _deliver(pending);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _errorText(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        return context.tr('login_to_contact_admin');
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return context.tr('chat_connection_error');
      }
    }
    return context.tr('chat_load_failed');
  }

  bool _isMine(ChatMessage message) =>
      widget.isAdminView ? message.isFromAdmin : !message.isFromAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.white.withValues(alpha: 0.18),
              child:
                  widget.isAdminView
                      ? Text(
                        chatInitial(widget.title),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                      : const Icon(
                        Icons.support_agent,
                        color: AppColors.white,
                        size: 22,
                      ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title ?? context.tr('app_administration'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.subtitle ?? context.tr('chat_reply_hint'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _buildBody(isDark)),
            if (_loadError == null && !_isLoading) _buildComposer(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final error = _loadError;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: AppColors.error),
              const SizedBox(height: 12),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: Text(context.tr('retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return _buildEmptyState(isDark);
    }

    final itemCount = _messages.length + (_isLoadingOlder ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        // Reversed list: index 0 is the newest message.
        final messageIndex = _messages.length - 1 - index;
        final message = _messages[messageIndex];
        final previous = messageIndex > 0 ? _messages[messageIndex - 1] : null;
        final showDay =
            previous == null ||
            !isSameChatDay(previous.createdAt, message.createdAt);

        return Column(
          children: [
            if (showDay)
              _DayChip(label: chatDayLabel(context, message.createdAt)),
            _MessageBubble(
              message: message,
              isMine: _isMine(message),
              isDark: isDark,
              senderLabel:
                  widget.isAdminView || !message.isFromAdmin
                      ? null
                      : context.tr('app_administration'),
              onRetry: message.hasFailed ? () => _retry(message) : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(
                widget.isAdminView ? 'no_messages_yet' : 'chat_empty_title',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            if (!widget.isAdminView) ...[
              const SizedBox(height: 8),
              Text(
                context.tr('chat_empty_subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 5,
              maxLength: _maxLength,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: context.tr('type_message'),
                counterText: '',
                filled: true,
                fillColor:
                    isDark
                        ? AppColors.white.withValues(alpha: 0.06)
                        : AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _canSend ? AppColors.primary : AppColors.textHint,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: context.tr('send'),
              onPressed: _canSend ? _send : null,
              // Icons.send mirrors itself in right-to-left languages.
              icon: const Icon(Icons.send, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;

  const _DayChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool isDark;
  final String? senderLabel;
  final VoidCallback? onRetry;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isDark,
    required this.senderLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;
    final background =
        isMine
            ? AppColors.primary
            : (isDark
                ? AppColors.white.withValues(alpha: 0.1)
                : AppColors.white);
    final foreground =
        isMine
            ? AppColors.white
            : (isDark ? AppColors.white : AppColors.textPrimary);
    const radius = Radius.circular(16);

    return Align(
      alignment:
          isMine
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
      child: GestureDetector(
        onTap: onRetry,
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: message.text));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('message_copied')),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadiusDirectional.only(
              topStart: radius,
              topEnd: radius,
              bottomStart: isMine ? radius : const Radius.circular(4),
              bottomEnd: isMine ? const Radius.circular(4) : radius,
            ),
            border:
                isMine || isDark ? null : Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (senderLabel != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    senderLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              Text(
                message.text,
                style: TextStyle(color: foreground, fontSize: 15, height: 1.35),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: foreground.withValues(alpha: 0.7),
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.hasFailed
                          ? Icons.error_outline
                          : message.isPending
                          ? Icons.schedule
                          : Icons.done,
                      size: 14,
                      color:
                          message.hasFailed
                              ? AppColors.secondaryLight
                              : foreground.withValues(alpha: 0.7),
                    ),
                  ],
                  if (message.hasFailed) ...[
                    const SizedBox(width: 4),
                    Text(
                      context.tr('tap_to_retry'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
