import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import 'auth_service.dart';
import 'http_helper.dart';
import '../models/chat_models.dart';

/// Service for managing chat sessions and messages with the AI
class ChatService {
  static final ChatService _instance = ChatService._internal();

  final HttpHelper _httpHelper = HttpHelper();
  final AuthService _authService = AuthService();

  // Longer timeout for AI chat responses (2 minutes)
  static const Duration _chatTimeout = Duration(minutes: 2);

  ChatService._internal();

  factory ChatService() {
    return _instance;
  }

  /// Get or create active chat session
  Future<ChatSession?> getActiveSession() async {
    try {
      final config = await ConfigService.getConfig();
      final url = Uri.parse('${config.baseUrl}/api/v1/chat/active/');

      final response = await _httpHelper.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatSession.fromJson(data);
      } else {
        print('Failed to get active session: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting active session: $e');
      return null;
    }
  }

  /// List all chat sessions
  Future<List<ChatSession>> listSessions() async {
    try {
      final config = await ConfigService.getConfig();
      final url = Uri.parse('${config.baseUrl}/api/v1/chat/sessions/');

      final response = await _httpHelper.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => ChatSession.fromJson(json)).toList();
      } else {
        print('Failed to list sessions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error listing sessions: $e');
      return [];
    }
  }

  /// Get a specific session with messages
  Future<ChatSession?> getSession(int sessionId) async {
    try {
      final config = await ConfigService.getConfig();
      final url = Uri.parse(
        '${config.baseUrl}/api/v1/chat/sessions/$sessionId/',
      );

      final response = await _httpHelper.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatSession.fromJson(data);
      } else {
        print('Failed to get session: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting session: $e');
      return null;
    }
  }

  /// Create a new chat session
  Future<ChatSession?> createNewSession() async {
    try {
      final config = await ConfigService.getConfig();
      final url = Uri.parse('${config.baseUrl}/api/v1/chat/sessions/new/');

      final response = await _httpHelper.post(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ChatSession.fromJson(data);
      } else {
        print('Failed to create session: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error creating session: $e');
      return null;
    }
  }

  /// Send a message to the AI
  /// At least one of message or imageData must be provided
  /// Uses a longer timeout since AI responses can take time
  Future<SendMessageResponse?> sendMessage({
    String? message,
    String? imageData,
    int? sessionId,
  }) async {
    if (message == null && imageData == null) {
      print('Error: At least one of message or imageData must be provided');
      return null;
    }

    try {
      final config = await ConfigService.getConfig();
      final url = Uri.parse('${config.baseUrl}/api/v1/chat/send/');

      final body = <String, dynamic>{};
      if (message != null && message.isNotEmpty) {
        body['message'] = message;
      }
      if (imageData != null && imageData.isNotEmpty) {
        body['image_data'] = imageData;
      }
      if (sessionId != null) {
        body['session_id'] = sessionId;
      }

      // Use custom client with longer timeout for AI chat
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final client = http.Client();
      try {
        final response = await client
            .post(url, headers: headers, body: jsonEncode(body))
            .timeout(_chatTimeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('Chat API response: $data');
          return SendMessageResponse.fromJson(data);
        } else {
          print(
            'Failed to send message: ${response.statusCode} - ${response.body}',
          );
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e, stackTrace) {
      print('Error sending message: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Delete a chat session
  Future<bool> deleteSession(int sessionId) async {
    try {
      final config = await ConfigService.getConfig();
      final url = Uri.parse(
        '${config.baseUrl}/api/v1/chat/sessions/$sessionId/',
      );

      final response = await _httpHelper.delete(url);

      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting session: $e');
      return false;
    }
  }

  /// Clear all messages in a session
  Future<bool> clearSession(int sessionId) async {
    try {
      final config = await ConfigService.getConfig();
      final url = Uri.parse(
        '${config.baseUrl}/api/v1/chat/sessions/$sessionId/clear/',
      );

      final response = await _httpHelper.post(url);

      return response.statusCode == 200;
    } catch (e) {
      print('Error clearing session: $e');
      return false;
    }
  }

  /// Delete a specific message
  Future<bool> deleteMessage(int messageId) async {
    try {
      final config = await ConfigService.getConfig();
      final url = Uri.parse(
        '${config.baseUrl}/api/v1/chat/messages/$messageId/',
      );

      final response = await _httpHelper.delete(url);

      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }
}
