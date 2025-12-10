import 'package:flutter/material.dart';
import '../services/pet_service.dart';
import 'edit_pet_page.dart';
import 'meal_recommendation_page.dart';
import 'health_report_page.dart';

class PetDetailPage extends StatelessWidget {
  final Pet pet;

  const PetDetailPage({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and edit
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF2C3E50)),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPetPage(pet: pet),
                        ),
                      );
                      
                      if (result == true && context.mounted) {
                        // Refresh the pet list by popping back
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                ],
              ),
            ),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Pet Image
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5F3),
                        borderRadius: BorderRadius.circular(20),
                        image: pet.image != null
                            ? DecorationImage(
                                image: NetworkImage(pet.image!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: pet.image == null
                          ? Center(
                              child: Text(
                                pet.petIcon,
                                style: const TextStyle(fontSize: 80),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Pet Name
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Pet Type and Breed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          pet.petIcon,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pet.displayPetType.isNotEmpty ? pet.displayPetType : 'Pet',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pet.displayBreed,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Info Cards Container
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // Quick Info Cards Row
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                _buildInfoCard(
                                  icon: Icons.cake_outlined,
                                  label: 'Age',
                                  value: pet.displayAge,
                                  color: const Color(0xFF26B5A4),
                                ),
                                const SizedBox(width: 12),
                                _buildInfoCard(
                                  icon: Icons.monitor_weight_outlined,
                                  label: 'Weight',
                                  value: pet.weight != null ? '${pet.weight} kg' : 'N/A',
                                  color: const Color(0xFF26B5A4),
                                ),
                                const SizedBox(width: 12),
                                _buildInfoCard(
                                  icon: Icons.fitness_center_outlined,
                                  label: 'Activity Level',
                                  value: _getActivityLevel(),
                                  color: const Color(0xFF26B5A4),
                                ),
                              ],
                            ),
                          ),
                          
                          // Action Buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                _buildActionButton(
                                  icon: Icons.restaurant_outlined,
                                  label: 'Generate Nutrition Plan',
                                  color: const Color(0xFF26B5A4),
                                  onTap: () {
                                    _navigateToMealRecommendation(context);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildActionButton(
                                  icon: Icons.favorite_outline,
                                  label: 'Generate Health Report',
                                  color: const Color(0xFFFF8A65),
                                  onTap: () {
                                    _navigateToHealthReport(context);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildActionButton(
                                  icon: Icons.chat_bubble_outline,
                                  label: 'Ask AI about this pet',
                                  color: Colors.white,
                                  textColor: const Color(0xFF2C3E50),
                                  onTap: () {
                                    // TODO: Navigate to AI chat
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Allergies Section (Full width)
                    if (_hasAllergies())
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE0E0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFE57373),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Allergies',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _getAllergyChips(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    if (_hasAllergies())
                      const SizedBox(height: 16),
                    
                    // Current Diet Section (Full width)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.dinner_dining,
                              color: Color(0xFF26B5A4),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Current Diet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _getFoodTypeChips(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Body Type Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.accessibility_new,
                              color: Color(0xFF26B5A4),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Body Type',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getBodyType(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getBodyTypeDescription(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF26B5A4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Food Preference Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.restaurant,
                              color: Color(0xFF26B5A4),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Food Preference',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getFoodFeeling(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Treats Section
                    if (pet.treatFrequencyDetail != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.cookie_outlined,
                              color: Color(0xFF26B5A4),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Treats',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getTreatFrequency(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getTreatFrequencyDescription(),
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
                    ),
                    if (pet.treatFrequencyDetail != null)
                      const SizedBox(height: 16),
                    
                    // Health Issues Section
                    if (pet.healthIssuesDetail != null && pet.healthIssuesDetail!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.medical_services_outlined,
                                color: Color(0xFFFF9800),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Health Issues',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: pet.healthIssuesDetail!.map((issue) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            issue['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    if (pet.healthIssuesDetail != null && pet.healthIssuesDetail!.isNotEmpty)
                      const SizedBox(height: 16),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7F8C8D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: color != Colors.white
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: textColor ?? Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor ?? Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getActivityLevel() {
    if (pet.activityLevelDetail != null && pet.activityLevelDetail!['name'] != null) {
      return pet.activityLevelDetail!['name'];
    }
    return 'Not specified';
  }

  bool _hasAllergies() {
    return pet.foodAllergiesDetail != null && 
           pet.foodAllergiesDetail!.isNotEmpty;
  }

  List<Widget> _getAllergyChips() {
    if (pet.foodAllergiesDetail == null || pet.foodAllergiesDetail!.isEmpty) {
      return [];
    }
    
    return pet.foodAllergiesDetail!.map((allergy) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          allergy['name'] ?? '',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF2C3E50),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _getFoodTypeChips() {
    if (pet.foodTypesDetail == null || pet.foodTypesDetail!.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Not specified',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF26B5A4),
            ),
          ),
        ),
      ];
    }
    
    return pet.foodTypesDetail!.map((foodType) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          foodType['name'] ?? '',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF26B5A4),
          ),
        ),
      );
    }).toList();
  }

  String _getBodyType() {
    if (pet.bodyTypeDetail != null && pet.bodyTypeDetail!['name'] != null) {
      return pet.bodyTypeDetail!['name'];
    }
    return 'Not specified';
  }

  String _getBodyTypeDescription() {
    if (pet.bodyTypeDetail != null && pet.bodyTypeDetail!['description'] != null) {
      return pet.bodyTypeDetail!['description'];
    }
    return '';
  }

  String _getFoodFeeling() {
    if (pet.foodFeelingDetail != null && pet.foodFeelingDetail!['name'] != null) {
      return pet.foodFeelingDetail!['name'];
    }
    return 'Not specified';
  }

  String _getTreatFrequency() {
    if (pet.treatFrequencyDetail != null && pet.treatFrequencyDetail!['name'] != null) {
      return pet.treatFrequencyDetail!['name'];
    }
    return 'Not specified';
  }

  String _getTreatFrequencyDescription() {
    if (pet.treatFrequencyDetail != null && pet.treatFrequencyDetail!['description'] != null) {
      return pet.treatFrequencyDetail!['description'];
    }
    return '';
  }

  void _navigateToMealRecommendation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealRecommendationPage(
          petId: pet.id,
          petName: pet.name,
        ),
      ),
    );
  }

  void _navigateToHealthReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthReportPage(
          petId: pet.id,
          petName: pet.name,
        ),
      ),
    );
  }
}
