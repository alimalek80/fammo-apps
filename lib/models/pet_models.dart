// Models for all pet form options from API

class PetType {
  final int id;
  final String name;

  PetType({required this.id, required this.name});

  factory PetType.fromJson(Map<String, dynamic> json) {
    return PetType(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Gender {
  final int id;
  final String name;

  Gender({required this.id, required this.name});

  factory Gender.fromJson(Map<String, dynamic> json) {
    return Gender(
      id: json['id'],
      name: json['name'],
    );
  }
}

class AgeCategory {
  final int id;
  final String name;
  final PetType petType;
  final int order;

  AgeCategory({
    required this.id,
    required this.name,
    required this.petType,
    required this.order,
  });

  factory AgeCategory.fromJson(Map<String, dynamic> json) {
    return AgeCategory(
      id: json['id'],
      name: json['name'],
      petType: PetType.fromJson(json['pet_type']),
      order: json['order'],
    );
  }
}

class Breed {
  final int id;
  final String name;
  final PetType petType;

  Breed({
    required this.id,
    required this.name,
    required this.petType,
  });

  factory Breed.fromJson(Map<String, dynamic> json) {
    return Breed(
      id: json['id'],
      name: json['name'],
      petType: PetType.fromJson(json['pet_type']),
    );
  }
}

class FoodType {
  final int id;
  final String name;

  FoodType({required this.id, required this.name});

  factory FoodType.fromJson(Map<String, dynamic> json) {
    return FoodType(
      id: json['id'],
      name: json['name'],
    );
  }
}

class FoodFeeling {
  final int id;
  final String name;
  final String description;

  FoodFeeling({
    required this.id,
    required this.name,
    required this.description,
  });

  factory FoodFeeling.fromJson(Map<String, dynamic> json) {
    return FoodFeeling(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

class FoodImportance {
  final int id;
  final String name;

  FoodImportance({required this.id, required this.name});

  factory FoodImportance.fromJson(Map<String, dynamic> json) {
    return FoodImportance(
      id: json['id'],
      name: json['name'],
    );
  }
}

class BodyType {
  final int id;
  final String name;
  final String description;

  BodyType({
    required this.id,
    required this.name,
    required this.description,
  });

  factory BodyType.fromJson(Map<String, dynamic> json) {
    return BodyType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

class ActivityLevel {
  final int id;
  final String name;
  final String description;

  ActivityLevel({
    required this.id,
    required this.name,
    required this.description,
  });

  factory ActivityLevel.fromJson(Map<String, dynamic> json) {
    return ActivityLevel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

class FoodAllergy {
  final int id;
  final String name;

  FoodAllergy({required this.id, required this.name});

  factory FoodAllergy.fromJson(Map<String, dynamic> json) {
    return FoodAllergy(
      id: json['id'],
      name: json['name'],
    );
  }
}

class HealthIssue {
  final int id;
  final String name;

  HealthIssue({required this.id, required this.name});

  factory HealthIssue.fromJson(Map<String, dynamic> json) {
    return HealthIssue(
      id: json['id'],
      name: json['name'],
    );
  }
}

class TreatFrequency {
  final int id;
  final String name;
  final String description;

  TreatFrequency({
    required this.id,
    required this.name,
    required this.description,
  });

  factory TreatFrequency.fromJson(Map<String, dynamic> json) {
    return TreatFrequency(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

// Pet form data for submission
class PetFormData {
  String name;
  int? petType;
  int? gender;
  int? breed;
  bool unknownBreed;
  int? ageCategory;
  int? ageYears;
  int? ageMonths;
  int? ageWeeks;
  String? birthDate;
  double? weight;
  bool neutered;
  List<int> foodTypes;
  int? foodFeeling;
  int? foodImportance;
  int? bodyType;
  int? activityLevel;
  List<int> foodAllergies;
  List<int> healthIssues;
  int? treatFrequency;
  String? image;

  PetFormData({
    this.name = '',
    this.petType,
    this.gender,
    this.breed,
    this.unknownBreed = false,
    this.ageCategory,
    this.ageYears,
    this.ageMonths,
    this.ageWeeks,
    this.birthDate,
    this.weight,
    this.neutered = false,
    List<int>? foodTypes,
    this.foodFeeling,
    this.foodImportance,
    this.bodyType,
    this.activityLevel,
    List<int>? foodAllergies,
    List<int>? healthIssues,
    this.treatFrequency,
    this.image,
  })  : foodTypes = foodTypes ?? [],
        foodAllergies = foodAllergies ?? [],
        healthIssues = healthIssues ?? [];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'neutered': neutered,
      'unknown_breed': unknownBreed,
    };

    if (petType != null) data['pet_type'] = petType;
    if (gender != null) data['gender'] = gender;
    if (breed != null && !unknownBreed) data['breed'] = breed;
    if (ageCategory != null) data['age_category'] = ageCategory;
    if (ageYears != null) data['age_years'] = ageYears;
    if (ageMonths != null) data['age_months'] = ageMonths;
    if (ageWeeks != null) data['age_weeks'] = ageWeeks;
    if (birthDate != null) data['birth_date'] = birthDate;
    if (weight != null) data['weight'] = weight;
    if (foodTypes.isNotEmpty) data['food_types'] = foodTypes;
    if (foodFeeling != null) data['food_feeling'] = foodFeeling;
    if (foodImportance != null) data['food_importance'] = foodImportance;
    if (bodyType != null) data['body_type'] = bodyType;
    if (activityLevel != null) data['activity_level'] = activityLevel;
    if (foodAllergies.isNotEmpty) data['food_allergies'] = foodAllergies;
    if (healthIssues.isNotEmpty) data['health_issues'] = healthIssues;
    if (treatFrequency != null) data['treat_frequency'] = treatFrequency;
    if (image != null) data['image'] = image;

    return data;
  }
}
