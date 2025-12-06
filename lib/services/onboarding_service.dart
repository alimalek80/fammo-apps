import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config_service.dart';
import '../models/onboarding_model.dart';

class OnboardingService {
  final storage = const FlutterSecureStorage();

  Future<String> _getBaseUrl() async {
    return ConfigService.getBaseUrl();
  }

  Future<String> _getLanguageCode() async {
    final lang = await storage.read(key: "language");
    return lang ?? "en";
  }

  Future<List<OnboardingModel>> getOnboardingSlides() async {
    final baseUrl = await _getBaseUrl();
    final langCode = await _getLanguageCode();
    final url = Uri.parse("$baseUrl/api/v1/onboarding/");

    print('Fetching onboarding slides from: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          "Accept-Language": langCode,
        },
      );

      print('Onboarding response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final slides = data.map((json) => OnboardingModel.fromJson(json)).toList();
        
        // Sort by order
        slides.sort((a, b) => a.order.compareTo(b.order));
        
        print('Loaded ${slides.length} onboarding slides');
        return slides;
      }

      throw Exception('Failed to load onboarding slides');
    } catch (e) {
      print('Error loading onboarding slides: $e');
      throw e;
    }
  }

  Future<bool> hasSeenOnboarding() async {
    final seen = await storage.read(key: "onboarding_seen");
    return seen == "true";
  }

  Future<void> markOnboardingAsSeen() async {
    await storage.write(key: "onboarding_seen", value: "true");
  }

  Future<void> markOnboardingAsNotSeen() async {
    await storage.delete(key: "onboarding_seen");
  }
}
