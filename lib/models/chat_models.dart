/// Chat session model representing a conversation with the AI
class ChatSession {
  final int id;
  final String? title;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    this.title,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      messages: json['messages'] != null
          ? (json['messages'] as List)
                .map((m) => ChatMessage.fromJson(m))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }
}

/// Chat message model
class ChatMessage {
  final int id;
  final int sessionId;
  final String role; // 'user' or 'bot'
  final String? content;
  final String? imageUrl; // Image URL from server
  final String? imageData; // Base64 image data (for sending)
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    this.content,
    this.imageUrl,
    this.imageData,
    required this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'bot' || role == 'assistant';
  bool get hasImage =>
      (imageUrl != null && imageUrl!.isNotEmpty) ||
      (imageData != null && imageData!.isNotEmpty);

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sessionId: json['session'] ?? json['session_id'] ?? 0,
      role: json['role'] ?? 'user',
      // API returns 'text', but we also support 'content' for flexibility
      content: json['text'] ?? json['content'],
      imageUrl: json['image_url'],
      imageData: json['image_data'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session': sessionId,
      'role': role,
      'content': content,
      'image_data': imageData,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a temporary user message (before server response)
  static ChatMessage createUserMessage({
    required String? content,
    String? imageData,
  }) {
    return ChatMessage(
      id: -DateTime.now().millisecondsSinceEpoch,
      sessionId: 0,
      role: 'user',
      content: content,
      imageData: imageData,
      createdAt: DateTime.now(),
    );
  }

  /// Create a temporary loading message for AI response
  static ChatMessage createLoadingMessage() {
    return ChatMessage(
      id: -DateTime.now().millisecondsSinceEpoch - 1,
      sessionId: 0,
      role: 'assistant',
      content: null,
      createdAt: DateTime.now(),
    );
  }
}

/// Response from sending a message
class SendMessageResponse {
  final ChatMessage userMessage;
  final ChatMessage assistantMessage;
  final int sessionId;

  SendMessageResponse({
    required this.userMessage,
    required this.assistantMessage,
    required this.sessionId,
  });

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
    // API returns 'user_message' and 'bot_message'
    final userMessageData = json['user_message'];
    // Support both 'bot_message' and 'assistant_message' for flexibility
    final botMessageData = json['bot_message'] ?? json['assistant_message'];

    if (userMessageData == null || botMessageData == null) {
      throw FormatException(
        'Invalid response format. Expected user_message and bot_message. Got: ${json.keys.toList()}',
      );
    }

    return SendMessageResponse(
      userMessage: ChatMessage.fromJson(
        userMessageData as Map<String, dynamic>,
      ),
      assistantMessage: ChatMessage.fromJson(
        botMessageData as Map<String, dynamic>,
      ),
      sessionId: json['session_id'] ?? 0,
    );
  }
}
