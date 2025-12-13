import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import 'auth_service.dart';

class UserProfile {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? address;
  final String? city;
  final String? zipCode;
  final String? country;
  final String? language;
  final double? latitude;
  final double? longitude;
  final bool isClinicOwner;
  final List<OwnedClinic> ownedClinics;
  final bool locationConsent;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.address,
    this.city,
    this.zipCode,
    this.country,
    this.language,
    this.latitude,
    this.longitude,
    this.isClinicOwner = false,
    this.ownedClinics = const [],
    this.locationConsent = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['user']['email'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      zipCode: json['zip_code'],
      country: json['country'],
      language: json['preferred_language'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isClinicOwner: json['is_clinic_owner'] ?? false,
      ownedClinics: json['owned_clinics'] != null
          ? (json['owned_clinics'] as List)
              .map((c) => OwnedClinic.fromJson(c))
              .toList()
          : [],
      locationConsent: json['location_consent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'address': address,
      'city': city,
      'zip_code': zipCode,
      'country': country,
      'location_consent': locationConsent,
      'preferred_language': language,
    };
  }

  String get fullName {
    if (firstName.isEmpty && lastName.isEmpty) {
      return email.split('@')[0];
    }
    return '$firstName $lastName'.trim();
  }
}

class OwnedClinic {
  final int id;
  final String name;

  OwnedClinic({required this.id, required this.name});

  factory OwnedClinic.fromJson(Map<String, dynamic> json) {
    return OwnedClinic(
      id: json['id'],
      name: json['name'],
    );
  }
}

class UserService {
  final AuthService _authService = AuthService();

  Future<UserProfile?> getUserProfile() async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) return null;

    final url = Uri.parse('$baseUrl/api/v1/me/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('Get user profile status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('User profile data: $data');
        print('First name from data: ${data['first_name']}');
        return UserProfile.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<UserProfile?> updateUserProfile(UserProfile profile) async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) return null;

    final url = Uri.parse('$baseUrl/api/v1/me/');

    try {
      final bodyData = profile.toJson();
      print('Sending update request to: $url');
      print('Request body: ${jsonEncode(bodyData)}');
      
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyData),
      );

      print('Update user profile status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) {
      return {
        'pets_count': 0,
        'meal_reports_count': 0,
        'health_reports_count': 0,
      };
    }

    try {
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      // Fetch pets count
      final petsResponse = await http.get(
        Uri.parse('$baseUrl/api/v1/pets/'),
        headers: headers,
      );

      // Fetch health reports count
      final healthResponse = await http.get(
        Uri.parse('$baseUrl/api/v1/ai/health-reports/'),
        headers: headers,
      );

      // Fetch meal recommendations count
      final mealResponse = await http.get(
        Uri.parse('$baseUrl/api/v1/ai/recommendations/'),
        headers: headers,
      );

      int petsCount = 0;
      int healthReportsCount = 0;
      int mealReportsCount = 0;

      // Parse pets count
      if (petsResponse.statusCode == 200) {
        final petsData = jsonDecode(petsResponse.body);
        if (petsData is List) {
          petsCount = petsData.length;
        }
      }

      // Parse health reports count
      if (healthResponse.statusCode == 200) {
        final healthData = jsonDecode(healthResponse.body);
        if (healthData is List) {
          healthReportsCount = healthData.length;
        }
      }

      // Parse meal recommendations count
      if (mealResponse.statusCode == 200) {
        final mealData = jsonDecode(mealResponse.body);
        if (mealData is List) {
          mealReportsCount = mealData.length;
        }
      }

      print('User stats - Pets: $petsCount, Health Reports: $healthReportsCount, Meal Reports: $mealReportsCount');

      return {
        'pets_count': petsCount,
        'meal_reports_count': mealReportsCount,
        'health_reports_count': healthReportsCount,
      };
    } catch (e) {
      print('Error fetching user stats: $e');
      // Return default values if error occurs
      return {
        'pets_count': 0,
        'meal_reports_count': 0,
        'health_reports_count': 0,
      };
    }
  }
}
