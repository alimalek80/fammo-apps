import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import 'auth_service.dart';

class Pet {
  final int id;
  final String name;
  final String petType;
  final String? breed;
  final int? ageYears;
  final String? gender;
  final String? photo;

  Pet({
    required this.id,
    required this.name,
    required this.petType,
    this.breed,
    this.ageYears,
    this.gender,
    this.photo,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      name: json['name'],
      petType: json['pet_type'] ?? 'Dog',
      breed: json['breed'],
      ageYears: json['age_years'],
      gender: json['gender'],
      photo: json['photo'],
    );
  }

  String get displayBreed => breed ?? 'Unknown breed';
  
  String get displayAge {
    if (ageYears == null) return '';
    return '$ageYears year${ageYears! > 1 ? 's' : ''}';
  }

  String get petIcon {
    switch (petType.toLowerCase()) {
      case 'dog':
        return '🐕';
      case 'cat':
        return '😺';
      case 'bird':
        return '🦜';
      default:
        return '🐾';
    }
  }
}

class PetService {
  final AuthService _authService = AuthService();

  Future<List<Pet>> getUserPets() async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) return [];

    final url = Uri.parse('$baseUrl/api/v1/pets/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('Get pets status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Pet.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching pets: $e');
      return [];
    }
  }
}
