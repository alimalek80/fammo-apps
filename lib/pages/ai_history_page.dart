import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/config_service.dart';
import '../services/language_service.dart';
import '../services/pet_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ai_detail_page.dart';

class AIHistoryPage extends StatefulWidget {
  const AIHistoryPage({super.key});

  @override
  State<AIHistoryPage> createState() => _AIHistoryPageState();
}

class _AIHistoryPageState extends State<AIHistoryPage> {
  final AuthService _authService = AuthService();
  final LanguageService _languageService = LanguageService();
  final PetService _petService = PetService();
  
  List<dynamic> _allRecommendations = [];
  bool _isLoading = true;
  String? _selectedPet;
  String? _selectedType; // null = All, 'meal' = Meals, 'health' = Health Reports
  Map<int, dynamic> _petDetailsCache = {}; // Cache for pet details

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<dynamic> _getPetDetails(int petId) async {
    // Return from cache if available
    if (_petDetailsCache.containsKey(petId)) {
      return _petDetailsCache[petId];
    }

    try {
      final allPets = await _petService.getUserPets();
      for (var pet in allPets) {
        if (pet.id == petId) {
          _petDetailsCache[petId] = pet;
          return pet;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching pet details: $e');
      return null;
    }
  }

  Future<void> _loadHistoryData() async {
    setState(() => _isLoading = true);
    
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

      // Fetch health reports
      final healthResponse = await http.get(
        Uri.parse('${config.baseUrl}/api/v1/ai/health-reports/'),
        headers: headers,
      );

      // Fetch meal recommendations
      final mealResponse = await http.get(
        Uri.parse('${config.baseUrl}/api/v1/ai/recommendations/'),
        headers: headers,
      );

      if (healthResponse.statusCode == 200 && mealResponse.statusCode == 200) {
        final healthData = jsonDecode(healthResponse.body) as List<dynamic>;
        final mealData = jsonDecode(mealResponse.body) as List<dynamic>;

        // Combine and sort by date
        final combined = [...healthData, ...mealData];
        combined.sort((a, b) {
          final dateA = DateTime.parse(a['created_at']);
          final dateB = DateTime.parse(b['created_at']);
          return dateB.compareTo(dateA);
        });

        setState(() {
          _allRecommendations = combined;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getFilteredRecommendations() {
    var items = _allRecommendations;
    
    // Filter by pet
    if (_selectedPet != null) {
      items = items.where((item) => item['pet_name'] == _selectedPet).toList();
    }
    
    // Filter by type
    if (_selectedType != null) {
      items = items.where((item) {
        final isHealthReport = item.containsKey('summary_json') ||
                              _getRecommendationType(item).toLowerCase() == 'health';
        final isMeal = item.containsKey('content_json') ||
                      _getRecommendationType(item).toLowerCase() == 'meal';
        
        if (_selectedType == 'health') return isHealthReport;
        if (_selectedType == 'meal') return isMeal;
        return true;
      }).toList();
    }
    
    return items;
  }

  List<String> _getUniquePets() {
    final pets = _allRecommendations
        .map((item) => item['pet_name'] as String)
        .toSet()
        .toList();
    pets.sort();
    return pets;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getRecommendationType(dynamic item) {
    // Check for health report indicators
    if (item.containsKey('summary_json') || 
        item['type'] == 'health' ||
        item['recommendation_type']?.toString().toLowerCase().contains('health') == true) {
      return 'health';
    }
    
    // Check for meal recommendation indicators
    if (item.containsKey('content_json') || 
        item['type'] == 'meal' ||
        item['recommendation_type']?.toString().toLowerCase().contains('meal') == true) {
      return 'meal';
    }
    
    // Default fallback
    return item['recommendation_type'] ?? item['type'] ?? 'unknown';
  }

  Widget _buildHistoryCard(dynamic item) {
    final type = _getRecommendationType(item);
    final date = _formatDate(item['created_at']);
    final petName = item['pet_name'] ?? 'Unknown Pet';
    final petId = item['pet'];
    
    // More reliable type detection
    final isHealthReport = item.containsKey('summary_json') ||
                          type.toLowerCase() == 'health' ||
                          type == 'health';
    final isMeal = item.containsKey('content_json') ||
                  type.toLowerCase() == 'meal' ||
                  type == 'meal';

    Color bgColor;
    IconData icon;
    String displayType;
    String detailType;

    if (isHealthReport) {
      bgColor = Colors.pink.shade50;
      icon = Icons.favorite;
      displayType = 'Health Report';
      detailType = 'health';
    } else if (isMeal) {
      bgColor = Colors.green.shade50;
      icon = Icons.restaurant;
      displayType = 'Meal Plan';
      detailType = 'meal';
    } else {
      bgColor = Colors.blue.shade50;
      icon = Icons.info;
      displayType = 'Report';
      detailType = 'meal';
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIDetailPage(
              id: item['id'],
              type: detailType,
              petName: petName,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHealthReport
                ? Colors.pink.shade200
                : isMeal
                    ? Colors.green.shade200
                    : Colors.blue.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isHealthReport
                        ? Colors.pink.shade100
                        : isMeal
                            ? Colors.green.shade100
                            : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isHealthReport
                        ? Colors.pink.shade600
                        : isMeal
                            ? Colors.green.shade600
                            : Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
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
            const SizedBox(height: 12),
            Row(
              children: [
                FutureBuilder<dynamic>(
                  future: _getPetDetails(petId),
                  builder: (context, snapshot) {
                    final pet = snapshot.data;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pet image
                          if (pet?.image != null)
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                image: DecorationImage(
                                  image: NetworkImage(pet.image!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Text(
                              pet?.petIcon ?? '🐾',
                              style: const TextStyle(fontSize: 14),
                            ),
                          const SizedBox(width: 6),
                          Text(
                            petName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2C3E50),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF7F8C8D),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthGroup(String month, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            month,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF26B5A4),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: items.map((item) => _buildHistoryCard(item)).toList(),
          ),
        ),
      ],
    );
  }

  Map<String, List<dynamic>> _groupByMonth(List<dynamic> items) {
    final groups = <String, List<dynamic>>{};
    
    for (var item in items) {
      try {
        final date = DateTime.parse(item['created_at']);
        final monthKey = DateFormat('MMMM yyyy').format(date);
        
        groups.putIfAbsent(monthKey, () => []);
        groups[monthKey]!.add(item);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }
    
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredRecommendations();
    final groupedByMonth = _groupByMonth(filteredItems);
    final pets = _getUniquePets();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('AI History'),
        backgroundColor: const Color(0xFF26B5A4),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pet Filter
                  if (pets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filter by Pet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // All Pets chip
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: const Text('All Pets'),
                                    selected: _selectedPet == null,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedPet = null;
                                      });
                                    },
                                    backgroundColor: Colors.white,
                                    selectedColor: const Color(0xFF26B5A4),
                                    labelStyle: TextStyle(
                                      color: _selectedPet == null
                                          ? Colors.white
                                          : const Color(0xFF2C3E50),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                // Individual pet chips
                                ...pets.map((pet) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(pet),
                                      selected: _selectedPet == pet,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedPet = selected ? pet : null;
                                        });
                                      },
                                      backgroundColor: Colors.white,
                                      selectedColor: const Color(0xFF26B5A4),
                                      labelStyle: TextStyle(
                                        color: _selectedPet == pet
                                            ? Colors.white
                                            : const Color(0xFF2C3E50),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Type Filter
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filter by Type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // All Types chip
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: const Text('All Types'),
                                  selected: _selectedType == null,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedType = null;
                                    });
                                  },
                                  backgroundColor: Colors.white,
                                  selectedColor: const Color(0xFF26B5A4),
                                  labelStyle: TextStyle(
                                    color: _selectedType == null
                                        ? Colors.white
                                        : const Color(0xFF2C3E50),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              // Meal Plan chip
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: const Text('🍽️ Meal Plans'),
                                  selected: _selectedType == 'meal',
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedType = selected ? 'meal' : null;
                                    });
                                  },
                                  backgroundColor: Colors.green.shade50,
                                  selectedColor: Colors.green.shade600,
                                  labelStyle: TextStyle(
                                    color: _selectedType == 'meal'
                                        ? Colors.white
                                        : const Color(0xFF2C3E50),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              // Health Report chip
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: const Text('❤️ Health Reports'),
                                  selected: _selectedType == 'health',
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedType = selected ? 'health' : null;
                                    });
                                  },
                                  backgroundColor: Colors.pink.shade50,
                                  selectedColor: Colors.pink.shade600,
                                  labelStyle: TextStyle(
                                    color: _selectedType == 'health'
                                        ? Colors.white
                                        : const Color(0xFF2C3E50),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // History items grouped by month
                  if (filteredItems.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: const Color(0xFF7F8C8D).withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No history yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF7F8C8D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...groupedByMonth.entries
                        .map((entry) => _buildMonthGroup(entry.key, entry.value))
                        .toList(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
