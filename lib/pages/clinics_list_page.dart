import 'package:flutter/material.dart';
import '../models/clinic.dart';
import '../services/clinic_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'clinic_details_page.dart';
import 'home_page.dart';
import 'pets_list_page.dart';
import 'clinic_registration_page.dart';
import 'registration_type_page.dart';

class ClinicsListPage extends StatefulWidget {
  const ClinicsListPage({super.key});

  @override
  State<ClinicsListPage> createState() => _ClinicsListPageState();
}

class _ClinicsListPageState extends State<ClinicsListPage> {
  final ClinicService _clinicService = ClinicService();
  final LocationService _locationService = LocationService();
  List<Clinic> _clinics = [];
  List<Clinic> _filteredClinics = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCity;
  bool? _eoiFilter;
  Position? _userPosition;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
    });

    final hasPermission = await _locationService.requestPermission();
    
    if (hasPermission) {
      _locationPermissionGranted = true;
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        _userPosition = position;
      }
    }
    
    await _loadClinics();
  }

  Future<void> _loadClinics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final clinics = await _clinicService.listClinics(
        city: _selectedCity,
        eoi: _eoiFilter,
        verifiedEmail: true, // Only get clinics with verified email
      );
      
      // Sort by distance if user location is available
      if (_userPosition != null) {
        clinics.sort((a, b) {
          final distanceA = _calculateDistance(a);
          final distanceB = _calculateDistance(b);
          return distanceA.compareTo(distanceB);
        });
      }
      
      setState(() {
        _clinics = clinics;
        _filteredClinics = clinics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load clinics.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinic Directory'),
        backgroundColor: const Color(0xFF26B5A4),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(color: Color(0xFF95A5A6)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF95A5A6)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.tune, color: Color(0xFF95A5A6)),
                    onPressed: _showFilterDialog,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: _filterClinics,
              ),
            ),
            // --- Clinic Owner Box ---
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF26B5A4), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you a clinic owner?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Register your clinic to appear in our directory and manage your profile.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_business),
                      label: const Text('Register your clinic'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26B5A4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegistrationTypePage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadClinics,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _filteredClinics.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_hospital_outlined, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No clinics found',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadClinics,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                                itemCount: _filteredClinics.length,
                                itemBuilder: (context, index) {
                                  final clinic = _filteredClinics[index];
                                  return _buildClinicCard(clinic);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Stub for _filterClinics
  void _filterClinics(String query) {
    setState(() {
      _filteredClinics = _clinics
          .where((clinic) => clinic.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      // Re-sort by distance after filtering
      if (_userPosition != null) {
        _filteredClinics.sort((a, b) {
          final distanceA = _calculateDistance(a);
          final distanceB = _calculateDistance(b);
          return distanceA.compareTo(distanceB);
        });
      }
    });
  }

  // Stub for _calculateDistance
  double _calculateDistance(Clinic clinic) {
    if (_userPosition == null) return 0.0;
    // Replace with actual calculation if needed
    return Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      double.tryParse(clinic.latitude ?? '0') ?? 0.0,
      double.tryParse(clinic.longitude ?? '0') ?? 0.0,
    );
  }

  // Stub for _getUniqueCities
  List<String> _getUniqueCities() {
    final cities = _clinics.map((c) => c.city).toSet().toList();
    cities.sort();
    return cities;
  }

  Widget _buildClinicCard(Clinic clinic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClinicDetailsPage(clinicId: clinic.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                                return _buildDefaultLogo();
                              },
                            ),
                          )
                        : _buildDefaultLogo(),
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
                                        fontWeight: FontWeight.w600,
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
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Color(0xFFFFA500),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '4.8',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (clinic.clinicEoi)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF26B5A4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FAMO Partner',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          clinic.address.isNotEmpty ? clinic.address : clinic.city,
                          style: const TextStyle(
                            color: Color(0xFF7F8C8D),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Color(0xFF7F8C8D),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _userPosition != null
                                  ? _locationService.formatDistance(_calculateDistance(clinic))
                                  : 'Location unavailable',
                              style: const TextStyle(
                                color: Color(0xFF7F8C8D),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (clinic.phone.isNotEmpty) ...[
                              const Icon(
                                Icons.phone,
                                size: 14,
                                color: Color(0xFF7F8C8D),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                clinic.phone,
                            style: const TextStyle(
                              color: Color(0xFF7F8C8D),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    if (clinic.specializations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: clinic.specializations
                            .split(',')
                            .take(3)
                            .map((spec) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    spec.trim(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF7F8C8D),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF95A5A6),
                size: 24,
              ),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.local_hospital,
        size: 30,
        color: Color(0xFF26B5A4),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Clinics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Cities'),
                ),
                ..._getUniqueCities().map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(city),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                });
                _loadClinics();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<bool?>(
              value: _eoiFilter,
              decoration: InputDecoration(
                labelText: 'Partner Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('All Clinics'),
                ),
                DropdownMenuItem(
                  value: true,
                  child: Text('FAMO Partners Only'),
                ),
                DropdownMenuItem(
                  value: false,
                  child: Text('Non-Partners'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _eoiFilter = value;
                });
                _loadClinics();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
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
              _buildNavItem(Icons.home, 'Home', false),
              _buildNavItem(Icons.pets, 'Pets', false),
              _buildNavItem(Icons.location_on, 'Clinics', true),
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
      onTap: () {
        if (label == 'Home') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
          );
        } else if (label == 'Pets') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PetsListPage(),
            ),
          );
        }
        // Clinics is already active, Chat and Profile TODO
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
