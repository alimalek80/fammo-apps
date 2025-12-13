import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'config_service.dart';
import 'auth_service.dart';
import 'language_service.dart';
import '../models/pet_models.dart';

class Pet {
  final int id;
  final String name;
  final int petType;
  final int? breed;
  final int? ageCategory;
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
  final int? bodyType;
  final int? activityLevel;
  final int? foodFeeling;
  final int? treatFrequency;
  final List<int>? foodTypes;
  final List<int>? foodAllergies;
  final List<int>? healthIssues;
  final Map<String, dynamic>? petTypeDetail;
  final Map<String, dynamic>? genderDetail;
  final Map<String, dynamic>? breedDetail;
  final Map<String, dynamic>? ageCategoryDetail;
  final Map<String, dynamic>? bodyTypeDetail;
  final Map<String, dynamic>? activityLevelDetail;
  final Map<String, dynamic>? foodFeelingDetail;
  final Map<String, dynamic>? treatFrequencyDetail;
  final List<dynamic>? foodTypesDetail;
  final List<dynamic>? foodAllergiesDetail;
  final List<dynamic>? healthIssuesDetail;

  Pet({
    required this.id,
    required this.name,
    required this.petType,
    this.breed,
    this.ageCategory,
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
    this.bodyType,
    this.activityLevel,
    this.foodFeeling,
    this.treatFrequency,
    this.foodTypes,
    this.foodAllergies,
    this.healthIssues,
    this.petTypeDetail,
    this.genderDetail,
    this.breedDetail,
    this.ageCategoryDetail,
    this.bodyTypeDetail,
    this.activityLevelDetail,
    this.foodFeelingDetail,
    this.treatFrequencyDetail,
    this.foodTypesDetail,
    this.foodAllergiesDetail,
    this.healthIssuesDetail,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      petType: json['pet_type'] ?? 1,
      breed: json['breed'],
      ageCategory: json['age_category'],
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
      bodyType: json['body_type'],
      activityLevel: json['activity_level'],
      foodFeeling: json['food_feeling'],
      treatFrequency: json['treat_frequency'],
      foodTypes: json['food_types'] != null 
          ? List<int>.from(json['food_types']) 
          : null,
      foodAllergies: json['food_allergies'] != null 
          ? List<int>.from(json['food_allergies']) 
          : null,
      healthIssues: json['health_issues'] != null 
          ? List<int>.from(json['health_issues']) 
          : null,
      petTypeDetail: json['pet_type_detail'],
      genderDetail: json['gender_detail'],
      breedDetail: json['breed_detail'],
      ageCategoryDetail: json['age_category_detail'],
      bodyTypeDetail: json['body_type_detail'],
      activityLevelDetail: json['activity_level_detail'],
      foodFeelingDetail: json['food_feeling_detail'],
      treatFrequencyDetail: json['treat_frequency_detail'],
      foodTypesDetail: json['food_types_detail'],
      foodAllergiesDetail: json['food_allergies_detail'],
      healthIssuesDetail: json['health_issues_detail'],
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
  final LanguageService _languageService = LanguageService();

  // Helper method to get language code for Accept-Language header
  Future<String> _getLanguageCode() async {
    return await _languageService.getLocalLanguage() ?? 'en';
  }

  // Fetch all pet types
  Future<List<PetType>> getPetTypes() async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();
    final langCode = await _getLanguageCode();

    if (accessToken == null) return [];

    final url = Uri.parse('$baseUrl/api/v1/pet-types/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PetType.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching pet types: $e');
      return [];
    }
  }

  // Fetch all genders
  Future<List<Gender>> getGenders() async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();
    final langCode = await _getLanguageCode();

    if (accessToken == null) return [];

    final url = Uri.parse('$baseUrl/api/v1/genders/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Gender.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching genders: $e');
      return [];
    }
  }

  // Fetch age categories (optionally filtered by pet type)
  Future<List<AgeCategory>> getAgeCategories({int? petTypeId}) async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();
    final langCode = await _getLanguageCode();

    if (accessToken == null) return [];

    String urlString = '$baseUrl/api/v1/age-categories/';
    if (petTypeId != null) {
      urlString += '?pet_type=$petTypeId';
    }
    final url = Uri.parse(urlString);

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AgeCategory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching age categories: $e');
      return [];
    }
  }

  // Fetch breeds (optionally filtered by pet type)
  Future<List<Breed>> getBreeds({int? petTypeId}) async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();
    final langCode = await _getLanguageCode();

    if (accessToken == null) return [];

    String urlString = '$baseUrl/api/v1/breeds/';
    if (petTypeId != null) {
      urlString += '?pet_type=$petTypeId';
    }
    final url = Uri.parse(urlString);

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Breed.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching breeds: $e');
      return [];
    }
  }

  // Fetch food types
  Future<List<FoodType>> getFoodTypes() async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();
    final langCode = await _getLanguageCode();

    if (accessToken == null) return [];

    final url = Uri.parse('$baseUrl/api/v1/food-types/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => FoodType.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching food types: $e');
      return [];
    }
  }

  // Fetch food feelings
  Future<List<FoodFeeling>> getFoodFeelings() async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();
    final langCode = await _getLanguageCode();

    if (accessToken == null) return [];

    final url = Uri.parse('$baseUrl/api/v1/food-feelings/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => FoodFeeling.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching food feelings: $e');
      return [];
    }
  }

  // Fetch food importance
  Future<List<FoodImportance>> getFoodImportance() async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();
    final langCode = await _getLanguageCode();

    if (accessToken == null) return [];

    final url = Uri.parse('$baseUrl/api/v1/food-importance/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => FoodImportance.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching food importance: $e');
      return [];
    }
  }

  // Fetch body types
  Future<List<BodyType>> getBodyTypes() async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();
    final langCode = await _getLanguageCode();

    if (accessToken == null) return [];

    final url = Uri.parse('$baseUrl/api/v1/body-types/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => BodyType.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching body types: $e');
      return [];
    }
  }

  // Fetch activity levels
  Future<List<ActivityLevel>> getActivityLevels() async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();
    final langCode = await _getLanguageCode();

    if (accessToken == null) return [];

    final url = Uri.parse('$baseUrl/api/v1/activity-levels/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ActivityLevel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching activity levels: $e');
      return [];
    }
  }

  // Fetch food allergies
  Future<List<FoodAllergy>> getFoodAllergies() async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();
    final langCode = await _getLanguageCode();

    if (accessToken == null) return [];

    final url = Uri.parse('$baseUrl/api/v1/food-allergies/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => FoodAllergy.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching food allergies: $e');
      return [];
    }
  }

  // Fetch health issues
  Future<List<HealthIssue>> getHealthIssues() async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();
    final langCode = await _getLanguageCode();

    if (accessToken == null) return [];

    final url = Uri.parse('$baseUrl/api/v1/health-issues/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => HealthIssue.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching health issues: $e');
      return [];
    }
  }

  // Fetch treat frequencies
  Future<List<TreatFrequency>> getTreatFrequencies() async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();
    final langCode = await _getLanguageCode();

    if (accessToken == null) return [];

    final url = Uri.parse('$baseUrl/api/v1/treat-frequencies/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TreatFrequency.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching treat frequencies: $e');
      return [];
    }
  }

  // Create new pet
  Future<Pet?> createPet(PetFormData formData, {File? imageFile}) async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();
    final langCode = await _getLanguageCode();

    if (accessToken == null) return null;

    final url = '$baseUrl/api/v1/pets/';

    try {
      if (imageFile != null) {
        // Use Dio for multipart request with image upload
        final dio = Dio();
        final jsonData = formData.toJson();
        print('Form data to send: $jsonData');
        
        // Prepare form data
        final formDataDio = FormData();
        
        // Add image file
        formDataDio.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(imageFile.path),
        ));
        
        // Add non-list fields
        jsonData.forEach((key, value) {
          if (value != null && value is! List) {
            formDataDio.fields.add(MapEntry(key, value.toString()));
          }
        });
        
        // Add list fields - Dio supports multiple entries with the same key
        if (jsonData['food_types'] != null && jsonData['food_types'] is List) {
          final list = jsonData['food_types'] as List;
          for (var item in list) {
            formDataDio.fields.add(MapEntry('food_types', item.toString()));
          }
          print('Adding food_types: $list');
        }
        
        if (jsonData['food_allergies'] != null && jsonData['food_allergies'] is List) {
          final list = jsonData['food_allergies'] as List;
          for (var item in list) {
            formDataDio.fields.add(MapEntry('food_allergies', item.toString()));
          }
          print('Adding food_allergies: $list');
        }
        
        if (jsonData['health_issues'] != null && jsonData['health_issues'] is List) {
          final list = jsonData['health_issues'] as List;
          for (var item in list) {
            formDataDio.fields.add(MapEntry('health_issues', item.toString()));
          }
          print('Adding health_issues: $list');
        }
        
        final response = await dio.post(
          url,
          data: formDataDio,
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Accept-Language': langCode,
            },
          ),
        );
        
        print('Create pet with image status: ${response.statusCode}');
        print('Create pet with image response: ${response.data}');
        
        if (response.statusCode == 201) {
          return Pet.fromJson(response.data);
        }
      } else {
        // Use JSON request without image
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'Accept-Language': langCode,
          },
          body: jsonEncode(formData.toJson()),
        );

        print('Create pet status: ${response.statusCode}');
        print('Create pet response: ${response.body}');

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return Pet.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      print('Error creating pet: $e');
      return null;
    }
  }

  // Update existing pet
  Future<Pet?> updatePet(int petId, PetFormData formData, {File? imageFile}) async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();
    final langCode = await _getLanguageCode();

    if (accessToken == null) return null;

    final url = '$baseUrl/api/v1/pets/$petId/';

    try {
      if (imageFile != null) {
        // Use Dio for multipart request with image upload
        final dio = Dio();
        final jsonData = formData.toJson();
        print('Update form data to send: $jsonData');
        
        // Prepare form data
        final formDataDio = FormData();
        
        // Add image file
        formDataDio.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(imageFile.path),
        ));
        
        // Add non-list fields
        jsonData.forEach((key, value) {
          if (value != null && value is! List) {
            formDataDio.fields.add(MapEntry(key, value.toString()));
          }
        });
        
        // Add list fields - Dio supports multiple entries with the same key
        if (jsonData['food_types'] != null && jsonData['food_types'] is List) {
          final list = jsonData['food_types'] as List;
          for (var item in list) {
            formDataDio.fields.add(MapEntry('food_types', item.toString()));
          }
          print('Adding food_types: $list');
        }
        
        if (jsonData['food_allergies'] != null && jsonData['food_allergies'] is List) {
          final list = jsonData['food_allergies'] as List;
          for (var item in list) {
            formDataDio.fields.add(MapEntry('food_allergies', item.toString()));
          }
          print('Adding food_allergies: $list');
        }
        
        if (jsonData['health_issues'] != null && jsonData['health_issues'] is List) {
          final list = jsonData['health_issues'] as List;
          for (var item in list) {
            formDataDio.fields.add(MapEntry('health_issues', item.toString()));
          }
          print('Adding health_issues: $list');
        }
        
        final response = await dio.put(
          url,
          data: formDataDio,
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Accept-Language': langCode,
            },
          ),
        );
        
        print('Update pet with image status: ${response.statusCode}');
        print('Update pet with image response: ${response.data}');
        
        if (response.statusCode == 200) {
          return Pet.fromJson(response.data);
        }
      } else {
        // Use JSON request without image
        final response = await http.put(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'Accept-Language': langCode,
          },
          body: jsonEncode(formData.toJson()),
        );

        print('Update pet status: ${response.statusCode}');
        print('Update pet response: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return Pet.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      print('Error updating pet: $e');
      return null;
    }
  }

  Future<List<Pet>> getUserPets() async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();
    final langCode = await _getLanguageCode();

    if (accessToken == null) return [];

    final url = Uri.parse('$baseUrl/api/v1/pets/');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept-Language': langCode,
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

  Future<bool> deletePet(int petId) async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) return false;

    final url = '$baseUrl/api/v1/pets/$petId/';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('Delete pet status: ${response.statusCode}');
      print('Delete pet response: ${response.body}');

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Error deleting pet: $e');
      return false;
    }
  }
}
