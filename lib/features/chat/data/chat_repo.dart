import 'package:dio/dio.dart';

import '../../../core/networking/api_constants.dart';
import 'chat_models.dart';

/// Talks to the `/api/chat` endpoints. Users only reach their own
/// conversation; the admin endpoints need an admin token.
class ChatRepo {
  final Dio _dio;

  ChatRepo(this._dio);

  static const String _base = '${ApiConstants.apiBaseUrl}chat';

  Map<String, dynamic> _pageQuery({DateTime? after, DateTime? before}) => {
    if (after != null) 'after': after.toUtc().toIso8601String(),
    if (before != null) 'before': before.toUtc().toIso8601String(),
  };

  // ---------------- User ----------------

  Future<ChatThread> getMyThread({DateTime? after, DateTime? before}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/me',
      queryParameters: _pageQuery(after: after, before: before),
    );
    return ChatThread.fromJson(response.data ?? const {});
  }

  Future<ChatMessage> sendMyMessage(String text) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/me/messages',
      data: {'text': text},
    );
    return ChatMessage.fromJson(response.data ?? const {});
  }

  Future<int> getMyUnreadCount() async {
    final response = await _dio.get<Map<String, dynamic>>('$_base/me/unread');
    return (response.data?['unread'] as num?)?.toInt() ?? 0;
  }

  // ---------------- Admin ----------------

  Future<List<ChatConversation>> getConversations({String search = ''}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/conversations',
      queryParameters: {if (search.trim().isNotEmpty) 'search': search.trim()},
    );
    final items = response.data?['conversations'];
    if (items is! List) {
      return const [];
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(ChatConversation.fromJson)
        .toList();
  }

  Future<ChatThread> getConversationThread(
    String conversationId, {
    DateTime? after,
    DateTime? before,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/conversations/$conversationId/messages',
      queryParameters: _pageQuery(after: after, before: before),
    );
    return ChatThread.fromJson(response.data ?? const {});
  }

  Future<ChatMessage> sendAdminMessage(
    String conversationId,
    String text,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/conversations/$conversationId/messages',
      data: {'text': text},
    );
    return ChatMessage.fromJson(response.data ?? const {});
  }

  Future<void> deleteConversation(String conversationId) async {
    await _dio.delete<void>('$_base/conversations/$conversationId');
  }

  Future<int> getAdminUnreadCount() async {
    final response = await _dio.get<Map<String, dynamic>>('$_base/unread');
    return (response.data?['unread'] as num?)?.toInt() ?? 0;
  }
}
