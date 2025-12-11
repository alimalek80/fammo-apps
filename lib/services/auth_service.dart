import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config_service.dart';

class AuthService {
  final storage = const FlutterSecureStorage();

  // Get base URL from ConfigService
  Future<String> _getBaseUrl() async {
    return ConfigService.getBaseUrl();
  }

  // Get the current language code for API calls
  Future<String> _getLanguageCode() async {
    final lang = await storage.read(key: "language");
    return lang ?? "en"; // Default to English if not set
  }

  Future<bool> login(String email, String password) async {
    final baseUrl = await _getBaseUrl();
    final langCode = await _getLanguageCode();
    
    final url = Uri.parse("$baseUrl/api/v1/auth/token/");

    print('Attempting login to: $url');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": langCode,
        },
        body: jsonEncode({"email": email, "password": password}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await storage.write(key: "access", value: data["access"]);
        await storage.write(key: "refresh", value: data["refresh"]);
        
        // Store user info if provided
        if (data["user"] != null) {
          await storage.write(key: "user_email", value: data["user"]["email"]);
          await storage.write(key: "user_id", value: data["user"]["id"].toString());
        }

        print('Login successful');
        return true;
      }

      print('Login failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<String?> getAccessToken() async {
    return storage.read(key: "access");
  }

  Future<String?> getRefreshToken() async {
    return storage.read(key: "refresh");
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  Future<void> logout() async {
    await storage.delete(key: "access");
    await storage.delete(key: "refresh");
  }

  // Refresh access token using refresh token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh');
      if (refreshToken == null) {
        print('No refresh token available');
        return false;
      }

      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/api/v1/auth/token/refresh/');

      print('Attempting to refresh access token');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      print('Token refresh response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'access', value: data['access']);
        print('Access token refreshed successfully');
        return true;
      }

      print('Token refresh failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }
}