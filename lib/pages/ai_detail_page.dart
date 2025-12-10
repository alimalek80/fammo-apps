import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/config_service.dart';
import '../services/language_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIDetailPage extends StatefulWidget {
  final int id;
  final String type; // 'meal' or 'health'
  final String petName;

  const AIDetailPage({
    super.key,
    required this.id,
    required this.type,
    required this.petName,
  });

  @override
  State<AIDetailPage> createState() => _AIDetailPageState();
}

class _AIDetailPageState extends State<AIDetailPage> {
  final AuthService _authService = AuthService();
  final LanguageService _languageService = LanguageService();

  late Future<dynamic> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<dynamic> _loadDetail() async {
    try {
      final token = await _authService.getAccessToken();
      final config = await ConfigService.getConfig();
      final langCode = await _languageService.getLocalLanguage() ?? 'en';

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept-Language': langCode,
        'Authorization': 'Bearer $token',
      };

      String endpoint;
      if (widget.type == 'meal') {
        endpoint = '${config.baseUrl}/api/v1/ai/recommendations/${widget.id}/';
      } else {
        endpoint = '${config.baseUrl}/api/v1/ai/health-reports/${widget.id}/';
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load detail');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMeal = widget.type == 'meal';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text(isMeal ? 'Meal Plan' : 'Health Report'),
        backgroundColor: const Color(0xFF26B5A4),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: FutureBuilder<dynamic>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      snapshot.error.toString(),
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final data = snapshot.data;

          if (isMeal) {
            return _buildMealDetail(data);
          } else {
            return _buildHealthDetail(data);
          }
        },
      ),
    );
  }

  Widget _buildMealDetail(dynamic data) {
    final contentJson = data['content_json'] as Map<String, dynamic>? ?? {};
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
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.petName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(data['created_at']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Daily Calorie Requirement
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.fire_truck, color: Colors.orange.shade600, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Calorie Requirement',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$derKcal kcal',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Nutrient Targets
            if (nutrientTargets.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nutrient Targets',
                    style: TextStyle(
                      fontSize: 16,
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
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNutrientChip(
                          'Protein',
                          nutrientTargets['protein_percent']?.toString() ?? 'N/A',
                          Colors.red,
                        ),
                        _buildNutrientChip(
                          'Fat',
                          nutrientTargets['fat_percent']?.toString() ?? 'N/A',
                          Colors.yellow,
                        ),
                        _buildNutrientChip(
                          'Carbs',
                          nutrientTargets['carbs_percent']?.toString() ?? 'N/A',
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Meal Options
            if (options.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meal Options',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...options.map<Widget>((option) {
                    return _buildExpandableOption(option);
                  }).toList(),
                  const SizedBox(height: 20),
                ],
              ),

            // Feeding Schedule
            if (feedingSchedule.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Feeding Schedule',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: feedingSchedule
                          .asMap()
                          .entries
                          .map<Widget>((entry) {
                        final index = entry.key;
                        final schedule = entry.value;
                        final isLast = index == feedingSchedule.length - 1;

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF26B5A4),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      schedule['time'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      schedule['note'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Safety Notes
            if (safetyNotes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Safety Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: safetyNotes
                          .map<Widget>((note) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '• ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF2C3E50),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        note as String,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF2C3E50),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthDetail(dynamic data) {
    final summaryJson = data['summary_json'] as Map<String, dynamic>? ?? {};
    final healthSummary = summaryJson['health_summary'] ?? '';
    final breedRisks = (summaryJson['breed_risks'] as List<dynamic>?) ?? [];
    final weightAndDiet = summaryJson['weight_and_diet'] ?? '';
    final feedingTips = (summaryJson['feeding_tips'] as List<dynamic>?) ?? [];
    final activity = summaryJson['activity'] ?? '';
    final alerts = (summaryJson['alerts'] as List<dynamic>?) ?? [];

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
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pink.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.pink,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.petName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(data['created_at']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Health Summary
            if (healthSummary.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Health Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      healthSummary,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Breed Risks
            if (breedRisks.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Breed-Specific Risks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: breedRisks
                          .map<Widget>((risk) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '⚠️ ',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Expanded(
                                      child: Text(
                                        risk as String,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF2C3E50),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Weight and Diet
            if (weightAndDiet.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weight & Diet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      weightAndDiet,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Feeding Tips
            if (feedingTips.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Feeding Tips',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: feedingTips
                          .map<Widget>((tip) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '✓ ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        tip as String,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF2C3E50),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Activity
            if (activity.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity Recommendations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Text(
                      activity,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Alerts
            if (alerts.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Important Alerts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: alerts
                          .map<Widget>((alert) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '🔔 ',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Expanded(
                                      child: Text(
                                        alert as String,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF2C3E50),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7F8C8D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableOption(dynamic option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(
          expansionTileTheme: ExpansionTileThemeData(
            backgroundColor: Colors.green.shade50,
            collapsedBackgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
        child: ExpansionTile(
          title: Text(
            option['name'] ?? 'Option',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          subtitle: Text(
            option['overview'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7F8C8D),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (option['sections'] as List<dynamic>? ?? [])
                    .map<Widget>((section) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF26B5A4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...(section['items'] as List<dynamic>? ?? [])
                                  .map<Widget>((item) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '• ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF2C3E50),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                item as String,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF2C3E50),
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
