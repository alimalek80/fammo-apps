import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/config_service.dart';
import '../services/language_service.dart';

class HealthReportPage extends StatefulWidget {
  final int petId;
  final String petName;

  const HealthReportPage({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  State<HealthReportPage> createState() => _HealthReportPageState();
}

class _HealthReportPageState extends State<HealthReportPage> {
  late Future<Map<String, dynamic>> _healthFuture;
  final languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    _healthFuture = _generateHealthReport();
  }

  Future<Map<String, dynamic>> _generateHealthReport() async {
    try {
      final config = await ConfigService.getConfig();
      final langCode = await languageService.getLocalLanguage() ?? 'en';
      
      // Get the auth token
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access');

      print('Generating health report for pet ID: ${widget.petId}');
      print('Endpoint: ${config.baseUrl}/api/v1/ai/health-reports/generate-report/');
      print('Token: ${token != null ? 'Present' : 'Missing'}');

      final headers = {
        'Content-Type': 'application/json',
        'Accept-Language': langCode,
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/v1/ai/health-reports/generate-report/'),
        headers: headers,
        body: jsonEncode({'pet_id': widget.petId}),
      );

      print('Health report response status: ${response.statusCode}');
      print('Health report response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login again.');
      } else if (response.statusCode == 429) {
        throw Exception('Monthly limit reached. You can generate 1 health report per month.');
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['detail'] ?? errorBody['message'] ?? 'Failed to generate health report';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Failed to generate health report: ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  void _regenerateReport() {
    setState(() {
      _healthFuture = _generateHealthReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('Health Report'),
        backgroundColor: const Color(0xFF26B5A4),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _healthFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating health report...'),
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
                    onPressed: _regenerateReport,
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

          final healthData = snapshot.data!;
          final summaryJson = healthData['summary_json'] as Map<String, dynamic>?;

          if (summaryJson == null) {
            return const Center(child: Text('Invalid health data'));
          }

          final healthSummary = summaryJson['health_summary'] ?? '';
          final breedRisks = summaryJson['breed_risks'] as List<dynamic>? ?? [];
          final weightAndDiet = summaryJson['weight_and_diet'] ?? '';
          final feedingTips = summaryJson['feeding_tips'] as List<dynamic>? ?? [];
          final activity = summaryJson['activity'] ?? '';
          final alerts = summaryJson['alerts'] as List<dynamic>? ?? [];

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
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF26B5A4).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Color(0xFF26B5A4),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Health Report for ${widget.petName}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Health Summary
                  if (healthSummary.isNotEmpty) ...[
                    const Text(
                      'Health Summary',
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
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF26B5A4),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              healthSummary,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2C3E50),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Breed Risks
                  if (breedRisks.isNotEmpty) ...[
                    const Text(
                      'Breed-Specific Risks',
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
                        color: const Color(0xFFFFE0E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(breedRisks.length, (index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFE57373),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      breedRisks[index],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF2C3E50),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (index < breedRisks.length - 1)
                                const SizedBox(height: 12),
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Weight and Diet
                  if (weightAndDiet.isNotEmpty) ...[
                    const Text(
                      'Weight & Diet',
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.scale,
                            color: Color(0xFF26B5A4),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              weightAndDiet,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2C3E50),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Feeding Tips
                  if (feedingTips.isNotEmpty) ...[
                    const Text(
                      'Feeding Tips',
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
                        children: List.generate(feedingTips.length, (index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF26B5A4),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      feedingTips[index],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF2C3E50),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (index < feedingTips.length - 1)
                                const SizedBox(height: 12),
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Activity
                  if (activity.isNotEmpty) ...[
                    const Text(
                      'Activity',
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.directions_run,
                            color: Color(0xFF26B5A4),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              activity,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2C3E50),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Alerts
                  if (alerts.isNotEmpty) ...[
                    const Text(
                      'Important Alerts',
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
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(alerts.length, (index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.priority_high,
                                    color: Color(0xFFFF9800),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      alerts[index],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF2C3E50),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (index < alerts.length - 1)
                                const SizedBox(height: 12),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Regenerate Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _regenerateReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26B5A4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Generate New Report'),
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
}
