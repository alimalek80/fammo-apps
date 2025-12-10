import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/config_service.dart';
import '../services/language_service.dart';

class MealRecommendationPage extends StatefulWidget {
  final int petId;
  final String petName;

  const MealRecommendationPage({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  State<MealRecommendationPage> createState() => _MealRecommendationPageState();
}

class _MealRecommendationPageState extends State<MealRecommendationPage> {
  late Future<Map<String, dynamic>> _mealFuture;
  final languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    _mealFuture = _generateMealRecommendation();
  }

  Future<Map<String, dynamic>> _generateMealRecommendation() async {
    try {
      final config = await ConfigService.getConfig();
      final langCode = await languageService.getLocalLanguage() ?? 'en';
      
      // Get the auth token
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access');

      print('Generating meal recommendation for pet ID: ${widget.petId}');
      print('Endpoint: ${config.baseUrl}/api/v1/ai/recommendations/generate-meal/');
      print('Token: ${token != null ? 'Present' : 'Missing'}');

      final headers = {
        'Content-Type': 'application/json',
        'Accept-Language': langCode,
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/v1/ai/recommendations/generate-meal/'),
        headers: headers,
        body: jsonEncode({'pet_id': widget.petId}),
      );

      print('Meal recommendation response status: ${response.statusCode}');
      print('Meal recommendation response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login again.');
      } else if (response.statusCode == 429) {
        throw Exception('Monthly limit reached. You can generate 3 meal recommendations per month.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['detail'] ?? errorBody['message'] ?? 'Failed to generate meal recommendation';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Failed to generate meal recommendation: ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  void _regenerateMeal() {
    setState(() {
      _mealFuture = _generateMealRecommendation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('Nutrition Plan'),
        backgroundColor: const Color(0xFF26B5A4),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _mealFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating nutrition plan...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      snapshot.error.toString(),
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _regenerateMeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26B5A4),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final mealData = snapshot.data!;
          final contentJson = mealData['content_json'] as Map<String, dynamic>?;

          if (contentJson == null) {
            return const Center(child: Text('Invalid meal data'));
          }

          final derKcal = contentJson['der_kcal'] ?? 0;
          final nutrientTargets = contentJson['nutrient_targets'] as Map<String, dynamic>? ?? {};
          final options = contentJson['options'] as List<dynamic>? ?? [];
          final feedingSchedule = contentJson['feeding_schedule'] as List<dynamic>? ?? [];
          final safetyNotes = contentJson['safety_notes'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF26B5A4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF26B5A4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nutrition Plan for ${widget.petName}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF26B5A4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Daily Calorie Requirement: $derKcal kcal',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nutrient Targets
                  if (nutrientTargets.isNotEmpty) ...[
                    const Text(
                      'Nutrient Targets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildNutrientRow('Protein', nutrientTargets['protein_percent']),
                          const SizedBox(height: 12),
                          _buildNutrientRow('Fat', nutrientTargets['fat_percent']),
                          const SizedBox(height: 12),
                          _buildNutrientRow('Carbs', nutrientTargets['carbs_percent']),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Meal Options
                  if (options.isNotEmpty) ...[
                    const Text(
                      'Meal Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...options.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> option = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildMealOption(option, index + 1),
                      );
                    }),
                  ],

                  // Feeding Schedule
                  if (feedingSchedule.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Feeding Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: feedingSchedule.map((schedule) {
                          final time = schedule['time'] ?? '';
                          final note = schedule['note'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF26B5A4),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    time,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    note,
                                    style: const TextStyle(
                                      color: Color(0xFF7F8C8D),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Safety Notes
                  if (safetyNotes.isNotEmpty) ...[
                    const Text(
                      'Safety Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: safetyNotes.map((note) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(right: 12, top: 2),
                                  child: Icon(Icons.info, size: 18, color: Colors.orange),
                                ),
                                Expanded(
                                  child: Text(
                                    note,
                                    style: const TextStyle(
                                      color: Color(0xFF2C3E50),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Regenerate Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _regenerateMeal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26B5A4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Generate New Plan'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutrientRow(String label, dynamic value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF7F8C8D),
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF26B5A4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value ?? 'N/A',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF26B5A4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealOption(Map<String, dynamic> option, int index) {
    final name = option['name'] ?? 'Meal Option $index';
    final overview = option['overview'] ?? '';
    final sections = option['sections'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    overview,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...sections.map((section) {
                    final title = section['title'] ?? '';
                    final items = section['items'] as List<dynamic>? ?? [];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 16, bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF26B5A4),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF7F8C8D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
