/// A single message in a support conversation between a user and the admins.
class ChatMessage {
  final String id;
  final String senderRole; // 'user' or 'admin'
  final String text;
  final DateTime createdAt;

  /// True while the message is being sent and has no server id yet.
  final bool isPending;

  /// True when sending failed; the user can tap to retry.
  final bool hasFailed;

  const ChatMessage({
    required this.id,
    required this.senderRole,
    required this.text,
    required this.createdAt,
    this.isPending = false,
    this.hasFailed = false,
  });

  bool get isFromAdmin => senderRole == 'admin';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? 'user',
      text: json['text']?.toString() ?? '',
      createdAt: parseChatDate(json['createdAt']),
    );
  }

  ChatMessage copyWith({bool? isPending, bool? hasFailed}) {
    return ChatMessage(
      id: id,
      senderRole: senderRole,
      text: text,
      createdAt: createdAt,
      isPending: isPending ?? this.isPending,
      hasFailed: hasFailed ?? this.hasFailed,
    );
  }
}

/// A user's conversation as listed in the admin inbox.
class ChatConversation {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastSenderRole;
  final int unreadForAdmin;

  const ChatConversation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderRole,
    required this.unreadForAdmin,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map<String, dynamic> ? user : const {};
    return ChatConversation(
      id: json['_id']?.toString() ?? '',
      userId: userMap['_id']?.toString() ?? user?.toString() ?? '',
      userName: userMap['name']?.toString() ?? '',
      userEmail: userMap['email']?.toString() ?? '',
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageAt: parseChatDate(json['lastMessageAt']),
      lastSenderRole: json['lastSenderRole']?.toString() ?? 'user',
      unreadForAdmin: (json['unreadForAdmin'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Messages page returned by the server.
class ChatThread {
  final ChatConversation? conversation;
  final List<ChatMessage> messages;
  final bool hasMore;

  const ChatThread({
    required this.conversation,
    required this.messages,
    required this.hasMore,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    final conversation = json['conversation'];
    final messages = json['messages'];
    return ChatThread(
      conversation:
          conversation is Map<String, dynamic>
              ? ChatConversation.fromJson(conversation)
              : null,
      messages:
          messages is List
              ? messages
                  .whereType<Map<String, dynamic>>()
                  .map(ChatMessage.fromJson)
                  .toList()
              : const [],
      hasMore: json['hasMore'] == true,
    );
  }
}

DateTime parseChatDate(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '')?.toLocal() ??
      DateTime.now();
}
