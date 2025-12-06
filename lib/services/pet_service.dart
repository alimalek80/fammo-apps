import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import 'auth_service.dart';

class Pet {
  final int id;
  final String name;
  final int petType;
  final int? breed;
  final int? ageYears;
  final int? ageMonths;
  final int? ageWeeks;
  final String? ageDisplay;
  final int? gender;
  final String? image;
  final double? weight;
  final bool neutered;
  final String? birthDate;
  final bool unknownBreed;
  final Map<String, dynamic>? petTypeDetail;
  final Map<String, dynamic>? genderDetail;
  final Map<String, dynamic>? breedDetail;
  final Map<String, dynamic>? ageCategoryDetail;

  Pet({
    required this.id,
    required this.name,
    required this.petType,
    this.breed,
    this.ageYears,
    this.ageMonths,
    this.ageWeeks,
    this.ageDisplay,
    this.gender,
    this.image,
    this.weight,
    required this.neutered,
    this.birthDate,
    required this.unknownBreed,
    this.petTypeDetail,
    this.genderDetail,
    this.breedDetail,
    this.ageCategoryDetail,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      petType: json['pet_type'] ?? 1,
      breed: json['breed'],
      ageYears: json['age_years'],
      ageMonths: json['age_months'],
      ageWeeks: json['age_weeks'],
      ageDisplay: json['age_display'],
      gender: json['gender'],
      image: json['image'],
      weight: json['weight'] != null 
          ? double.tryParse(json['weight'].toString()) 
          : null,
      neutered: json['neutered'] ?? false,
      birthDate: json['birth_date'],
      unknownBreed: json['unknown_breed'] ?? false,
      petTypeDetail: json['pet_type_detail'],
      genderDetail: json['gender_detail'],
      breedDetail: json['breed_detail'],
      ageCategoryDetail: json['age_category_detail'],
    );
  }

  String get displayBreed {
    if (unknownBreed) return 'Mixed breed';
    if (breedDetail != null && breedDetail!['name'] != null) {
      return breedDetail!['name'];
    }
    return 'Unknown breed';
  }
  
  String get displayAge {
    // Use the age_display from API if available
    if (ageDisplay != null && ageDisplay!.isNotEmpty) {
      return ageDisplay!;
    }
    
    // Fallback to calculating from years and months
    if (ageYears == null && ageMonths == null) return 'Age unknown';
    
    List<String> ageParts = [];
    if (ageYears != null && ageYears! > 0) {
      ageParts.add('$ageYears year${ageYears! > 1 ? 's' : ''}');
    }
    if (ageMonths != null && ageMonths! > 0) {
      ageParts.add('$ageMonths month${ageMonths! > 1 ? 's' : ''}');
    }
    
    return ageParts.isEmpty ? 'Age unknown' : ageParts.join(' ');
  }
  
  String get displayGender {
    if (genderDetail != null && genderDetail!['name'] != null) {
      return genderDetail!['name'];
    }
    return '';
  }

  String get displayPetType {
    if (petTypeDetail != null && petTypeDetail!['name'] != null) {
      return petTypeDetail!['name'];
    }
    return '';
  }

  String get petIcon {
    // 1 = Dog, 2 = Cat (based on your data)
    switch (petType) {
      case 1:
        return '🐕';
      case 2:
        return '😺';
      case 3:
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
        final data = jsonDecode(response.body);
        print('Pets response data: $data');
        
        // Handle both list and paginated response formats
        List<dynamic> petsData;
        if (data is List) {
          petsData = data;
        } else if (data is Map && data.containsKey('results')) {
          petsData = data['results'];
        } else {
          petsData = [];
        }
        
        return petsData.map((json) => Pet.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching pets: $e');
      return [];
    }
  }
}
