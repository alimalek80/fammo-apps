import 'dart:convert';
import 'package:http/http.dart' as http;

class AppConfig {
  final String baseUrl;
  final String staticUrl;
  final String mediaUrl;
  final Map<String, String> assets;
  final String apiVersion;

  AppConfig({
    required this.baseUrl,
    required this.staticUrl,
    required this.mediaUrl,
    required this.assets,
    required this.apiVersion,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      baseUrl: json['base_url'],
      staticUrl: json['static_url'],
      mediaUrl: json['media_url'],
      assets: Map<String, String>.from(json['assets']),
      apiVersion: json['api_version'],
    );
  }
}

class ConfigService {
  static AppConfig? _config;
  
  // Production URL
  static const String _prodUrl = 'https://fammo.ai';

  // Google web client ID used for obtaining an id_token on mobile. Replace with
  // the web client configured in Google Cloud (the same one Django Allauth uses).
    static const String googleWebClientId =
      '957466041070-qla7sp3ipeqrr6rh0p6fp9irj5o95mdl.apps.googleusercontent.com';
  
  // Development URLs
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8000';
  static const String _iOSSimulatorUrl = 'http://localhost:8000';

  static Future<AppConfig> getConfig() async {
    if (_config != null) return _config!;

    // Try production first
    try {
      print('Attempting to fetch config from: $_prodUrl');
      final response = await http.get(
        Uri.parse('$_prodUrl/api/v1/config/'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _config = AppConfig.fromJson(data);
        print('Successfully loaded config from production');
        return _config!;
      }
    } catch (e) {
      print('Error loading config from production ($_prodUrl): $e');
    }

    // Fallback to local development server (Android emulator)
    try {
      final localUrl = _androidEmulatorUrl; // Change to _iOSSimulatorUrl for iOS
      print('Attempting to fetch config from fallback: $localUrl');
      final response = await http.get(
        Uri.parse('$localUrl/api/v1/config/'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _config = AppConfig.fromJson(data);
        print('Successfully loaded config from fallback: $localUrl');
        return _config!;
      }
    } catch (e) {
      print('Error loading config from fallback: $e');
    }

    // Last resort: hardcoded fallback values
    print('Using hardcoded fallback config');
    _config = AppConfig(
      baseUrl: _prodUrl,
      staticUrl: '$_prodUrl/fammo/static/',
      mediaUrl: '$_prodUrl/fammo/media/',
      assets: {
        'logo': '$_prodUrl/fammo/static/images/logo.png',
        'favicon': '$_prodUrl/fammo/static/images/favicon.png',
        'placeholder_pet': '$_prodUrl/fammo/static/images/pet-waiting.gif',
      },
      apiVersion: '1.0.0',
    );
    return _config!;
  }

  static String buildMediaUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (relativePath.startsWith('http')) return relativePath;
    
    final baseUrl = _config?.baseUrl ?? _prodUrl;
    return '$baseUrl$relativePath';
  }

  static String getBaseUrl() {
    return _config?.baseUrl ?? _prodUrl;
  }

  static String getStaticUrl() {
    return _config?.staticUrl ?? '$_prodUrl/fammo/static/';
  }

  static String getMediaUrl() {
    return _config?.mediaUrl ?? '$_prodUrl/fammo/media/';
  }

  // Clear cached config (useful for testing or switching environments)
  static void clearConfig() {
    _config = null;
  }
}
