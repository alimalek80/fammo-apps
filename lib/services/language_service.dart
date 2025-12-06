import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config_service.dart';

class LanguageModel {
  final String code;
  final String name;
  final String nativeName;

  LanguageModel({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      code: json['code'],
      name: json['name'],
      nativeName: json['native_name'],
    );
  }
}

class LanguageService {
  final storage = const FlutterSecureStorage();

  // Get base URL from ConfigService
  Future<String> _getBaseUrl() async {
    return ConfigService.getBaseUrl();
  }

  // Get available languages (no auth required, no language prefix needed)
  Future<List<LanguageModel>> getAvailableLanguages() async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse("$baseUrl/api/v1/languages/");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List<dynamic> data = responseData['languages'];
      return data.map((json) => LanguageModel.fromJson(json)).toList();
    }

    throw Exception('Failed to load languages');
  }

  // Get locally stored language preference
  Future<String?> getLocalLanguage() async {
    return await storage.read(key: "language");
  }

  // Save language locally
  Future<void> setLocalLanguage(String languageCode) async {
    await storage.write(key: "language", value: languageCode);
  }

  // Get user's language preference from backend (requires auth)
  Future<String?> getUserLanguage(String accessToken) async {
    final baseUrl = await _getBaseUrl();
    final langCode = await getLocalLanguage() ?? "en";
    final url = Uri.parse("$baseUrl/api/v1/me/language/");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $accessToken",
        "Accept-Language": langCode,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['language'];
    }

    return null;
  }

  // Set user's language preference on backend (requires auth)
  Future<bool> setUserLanguage(String accessToken, String languageCode) async {
    final baseUrl = await _getBaseUrl();
    final langCode = await getLocalLanguage() ?? "en";
    final url = Uri.parse("$baseUrl/api/v1/me/language/");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
        "Accept-Language": langCode,
      },
      body: jsonEncode({"language": languageCode}),
    );

    return response.statusCode == 200;
  }
}
