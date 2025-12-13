import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
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

  // Change Password
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final langCode = await _getLanguageCode();
      final token = await storage.read(key: 'access');

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'error': 'access_token_missing',
        };
      }

      final url = Uri.parse('$baseUrl/api/v1/auth/change-password/');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirm': newPasswordConfirm,
        }),
      );

      print('Change password status: ${response.statusCode}');
      print('Change password response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Password changed successfully',
        };
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? errorData['message'] ?? 'Invalid password',
          'error': errorData['error'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to change password: ${response.statusCode}',
          'error': 'http_error',
        };
      }
    } catch (e) {
      print('Error changing password: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'error': 'network_error',
      };
    }
  }

  // Forgot Password - Request Reset Email
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final langCode = await _getLanguageCode();

      final url = Uri.parse('$baseUrl/api/v1/auth/forgot-password/');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
        },
        body: jsonEncode({'email': email}),
      );

      print('Forgot password status: ${response.statusCode}');
      print('Forgot password response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset email has been sent',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send reset email: ${response.statusCode}',
          'error': 'http_error',
        };
      }
    } catch (e) {
      print('Error in forgot password: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'error': 'network_error',
      };
    }
  }

  // Reset Password - Using Token from Email
  Future<Map<String, dynamic>> resetPassword({
    required String uid,
    required String token,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final langCode = await _getLanguageCode();

      final url = Uri.parse('$baseUrl/api/v1/auth/reset-password/');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
        },
        body: jsonEncode({
          'uid': uid,
          'token': token,
          'password': password,
          'password_confirm': passwordConfirm,
        }),
      );

      print('Reset password status: ${response.statusCode}');
      print('Reset password response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset successfully',
        };
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Invalid or expired token',
          'error': errorData['error'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to reset password: ${response.statusCode}',
          'error': 'http_error',
        };
      }
    } catch (e) {
      print('Error resetting password: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'error': 'network_error',
      };
    }
  }

  // Save credentials to system credential manager (Samsung Pass, Google Password Manager, etc.)
  Future<void> saveCredentialsToSystem(String email, String password) async {
    try {
      // Use the credentials package approach via native code
      // For now, we'll use flutter_secure_storage which integrates with system credential managers
      await storage.write(key: "saved_email", value: email);
      await storage.write(key: "saved_password", value: password);
      print('Credentials saved to secure storage');
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }

  // Clear saved credentials
  Future<void> clearSavedCredentials() async {
    try {
      await storage.delete(key: "saved_email");
      await storage.delete(key: "saved_password");
      print('Saved credentials cleared');
    } catch (e) {
      print('Error clearing credentials: $e');
    }
  }
}