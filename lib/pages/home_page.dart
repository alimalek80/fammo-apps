import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/pet_service.dart';
import '../services/clinic_service.dart';
import '../services/location_service.dart';
import '../services/config_service.dart';
import '../services/language_service.dart';
import '../models/clinic.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_localizations.dart';
import 'language_selection_page.dart';
import 'pet_detail_page.dart';
import 'add_pet_page.dart';
import 'pets_list_page.dart';
import 'clinics_list_page.dart';
import 'clinic_details_page.dart';
import 'ai_history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final PetService _petService = PetService();
  final ClinicService _clinicService = ClinicService();
  final LocationService _locationService = LocationService();
  
  UserProfile? _userProfile;
  List<Pet> _pets = [];
  List<Clinic> _nearbyClinics = [];
  Position? _userPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final profile = await _userService.getUserProfile();
    final pets = await _petService.getUserPets();
    
    // Get user location
    final position = await _locationService.getCurrentPosition();
    _userPosition = position;
    
    // Get nearby clinics using search endpoint
    try {
      List<Clinic> nearbyClinicsList = [];
      
      if (_userPosition != null) {
        // Use search endpoint with user location
        final token = await AuthService().getAccessToken();
        final config = await ConfigService.getConfig();
        final langCode = await LanguageService().getLocalLanguage() ?? 'en';
        
        if (token != null) {
          final headers = {
            'Content-Type': 'application/json',
            'Accept-Language': langCode,
            'Authorization': 'Bearer $token',
          };
          
          final searchBody = jsonEncode({
            'latitude': _userPosition!.latitude,
            'longitude': _userPosition!.longitude,
            'radius': 200, // 200 km radius to find more clinics
          });
          
          final response = await http.post(
            Uri.parse('${config.baseUrl}/api/v1/clinics/search/'),
            headers: headers,
            body: searchBody,
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final results = data['results'] as List<dynamic>? ?? [];
            
            // Convert to Clinic objects and take top 2
            nearbyClinicsList = results
                .take(2)
                .map((clinic) => Clinic.fromJson(clinic))
                .toList();
            
            print('Found ${results.length} clinics, showing ${nearbyClinicsList.length} nearest');
          } else {
            print('Search endpoint error: ${response.statusCode}');
            // Fallback to list endpoint
            final clinics = await _clinicService.listClinics();
            if (clinics.isNotEmpty) {
              nearbyClinicsList = clinics.take(2).toList();
            }
          }
        }
      } else {
        // No location available, use list endpoint
        final clinics = await _clinicService.listClinics();
        if (clinics.isNotEmpty) {
          nearbyClinicsList = clinics.take(2).toList();
        }
      }
      
      setState(() {
        _userProfile = profile;
        _pets = pets;
        _nearbyClinics = nearbyClinicsList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading clinics: $e');
      setState(() {
        _userProfile = profile;
        _pets = pets;
        _isLoading = false;
      });
    }
  }
  
  double _calculateDistance(Clinic clinic) {
    if (_userPosition == null) return 0;
    
    final clinicLat = double.tryParse(clinic.latitude ?? '0') ?? 0.0;
    final clinicLng = double.tryParse(clinic.longitude ?? '0') ?? 0.0;
    
    return _locationService.calculateDistance(
      _userPosition!.latitude,
      _userPosition!.longitude,
      clinicLat,
      clinicLng,
    );
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LanguageSelectionPage(preventAutoNavigate: true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5F3),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with logout
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF7F8C8D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _userProfile?.firstName ?? 'User',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('👋', style: TextStyle(fontSize: 24)),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Color(0xFF7F8C8D)),
                            onPressed: _handleLogout,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Let's take care of your pets today",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Actions
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildQuickAction('🥗', 'Nutrition\nPlan', Colors.green.shade100, () {
                            // Navigate to nutrition
                          }),
                          const SizedBox(width: 12),
                          _buildQuickAction('💗', 'Health\nReport', Colors.pink.shade50, () {
                            // Navigate to health
                          }),
                          const SizedBox(width: 12),
                          _buildQuickAction('📚', 'AI\nHistory', Colors.amber.shade50, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AIHistoryPage(),
                              ),
                            );
                          }),
                          const SizedBox(width: 12),
                          _buildQuickAction('📍', 'Clinics', Colors.blue.shade50, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ClinicsListPage(),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // My Pets
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Pets',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PetsListPage(),
                                ),
                              );
                              
                              if (result == true && mounted) {
                                _loadData();
                              }
                            },
                            child: const Row(
                              children: [
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: Color(0xFF26B5A4),
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right, color: Color(0xFF26B5A4), size: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Pets list
                      if (_pets.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'No pets yet. Add your first pet!',
                              style: TextStyle(color: Color(0xFF7F8C8D)),
                            ),
                          ),
                        )
                      else
                        ...(_pets.map((pet) => _buildPetCard(pet))),
                      
                      const SizedBox(height: 12),
                      // Add Pet Button
                      InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddPetPage(),
                            ),
                          );
                          
                          if (result == true && mounted) {
                            // Refresh pet list
                            _loadData();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              '+ Add Pet',
                              style: TextStyle(
                                color: Color(0xFF26B5A4),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Nearby Clinics
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nearby Clinics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ClinicsListPage(),
                                ),
                              );
                            },
                            child: const Row(
                              children: [
                                Text(
                                  'View All',
                                  style: TextStyle(
                                    color: Color(0xFF26B5A4),
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right, color: Color(0xFF26B5A4), size: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_nearbyClinics.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.location_off,
                                  size: 48,
                                  color: Color(0xFF7F8C8D),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No clinics found',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF7F8C8D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._nearbyClinics.map((clinic) => Column(
                          children: [
                            _buildClinicCard(clinic),
                            const SizedBox(height: 12),
                          ],
                        )).toList(),
                      const SizedBox(height: 80), // Bottom navigation spacing
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildQuickAction(String emoji, String label, Color bgColor, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2C3E50),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetCard(Pet pet) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetDetailPage(pet: pet),
          ),
        );
        
        if (result == true && mounted) {
          // Refresh pet list if edited
          _loadData();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Pet Image/Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5F3),
                borderRadius: BorderRadius.circular(12),
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
                        style: const TextStyle(fontSize: 32),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Pet Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          pet.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(pet.petIcon, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.displayBreed}${pet.displayAge.isNotEmpty ? ' • ${pet.displayAge}' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (pet.displayGender.isNotEmpty)
                    Text(
                      pet.displayGender,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF7F8C8D)),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicCard(Clinic clinic) {
    final distance = _userPosition != null
        ? _locationService.formatDistance(_calculateDistance(clinic))
        : '';
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClinicDetailsPage(clinicId: clinic.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
        children: [
          // Clinic Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: clinic.logo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      clinic.logo!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.local_hospital,
                          size: 30,
                          color: Color(0xFF26B5A4),
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.local_hospital,
                    size: 30,
                    color: Color(0xFF26B5A4),
                  ),
          ),
          const SizedBox(width: 16),
          // Clinic Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              clinic.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (clinic.adminApproved) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (clinic.clinicEoi)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF26B5A4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Partner',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  clinic.address.isNotEmpty ? clinic.address : clinic.city,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7F8C8D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (distance.isNotEmpty) ...[
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF7F8C8D)),
                      const SizedBox(width: 4),
                      Text(
                        distance,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (clinic.phone.isNotEmpty) ...[
                      const Icon(Icons.phone, size: 14, color: Color(0xFF7F8C8D)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          clinic.phone,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7F8C8D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Color(0xFF95A5A6)),
        ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', true),
              _buildNavItem(Icons.pets, 'Pets', false),
              _buildNavItem(Icons.location_on, 'Clinics', false),
              _buildNavItem(Icons.chat_bubble_outline, 'Chat', false),
              _buildNavItem(Icons.person_outline, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return InkWell(
      onTap: () async {
        if (label == 'Pets') {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PetsListPage(),
            ),
          );
          
          if (result == true && mounted) {
            _loadData();
          }
        } else if (label == 'Clinics') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ClinicsListPage(),
            ),
          );
        }
        // TODO: Navigate to other pages
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF26B5A4) : const Color(0xFF7F8C8D),
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFF26B5A4) : const Color(0xFF7F8C8D),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
