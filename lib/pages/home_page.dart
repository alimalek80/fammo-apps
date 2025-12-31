import 'package:flutter/material.dart';
import '../widgets/paw_loading_indicator.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/pet_service.dart';
import '../services/clinic_service.dart';
import '../services/location_service.dart';
import '../services/config_service.dart';
import '../services/language_service.dart';
import '../services/notification_service.dart';
import '../models/clinic.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_localizations.dart';
import 'language_selection_page.dart';
import 'pet_detail_page.dart';
import 'add_pet_page.dart';
import 'pets_list_page.dart';
import 'clinics_list_page.dart';
import 'clinic_details_page.dart';
import 'ai_history_page.dart';
import '../widgets/bottom_nav_bar.dart';
import 'profile_page.dart';

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
  final NotificationService _notificationService = NotificationService();

  UserProfile? _userProfile;
  List<Pet> _pets = [];
  List<Clinic> _nearbyClinics = [];
  Position? _userPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermissionIfNeeded();
    _loadData();
  }

  /// Request notification permission on first app launch
  Future<void> _requestNotificationPermissionIfNeeded() async {
    try {
      final hasBeenAsked = await _notificationService.hasPermissionBeenAsked();

      if (!hasBeenAsked) {
        // Request permission on first app launch
        await _notificationService.requestNotificationPermission();
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final profile = await _userService.getUserProfile();
    final pets = await _petService.getUserPets();

    // Get user location
    final position = await _locationService.getCurrentPosition();
    _userPosition = position;

    print(
      'User position: lat=${_userPosition?.latitude}, lon=${_userPosition?.longitude}',
    );

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
            'radius': 2, // 2 km radius for nearby clinics
            'show_all': true, // include clinics regardless of admin approval
          });

          print('Search body: $searchBody');

          final response = await http.post(
            Uri.parse('${config.baseUrl}/api/v1/clinics/search/'),
            headers: headers,
            body: searchBody,
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final results = data['results'] as List<dynamic>? ?? [];

            // Debug: Print raw clinic data
            for (var clinic in results.take(3)) {
              print(
                'Clinic: ${clinic['name']}, lat=${clinic['latitude']}, lon=${clinic['longitude']}, email_confirmed=${clinic['email_confirmed']}',
              );
            }

            List<dynamic> effectiveResults = results;

            // If nothing within 2 km, retry with 5 km before falling back
            if (effectiveResults.isEmpty) {
              print('No clinics within 2 km, retrying with 5 km radius');
              final retryBody = jsonEncode({
                'latitude': _userPosition!.latitude,
                'longitude': _userPosition!.longitude,
                'radius': 5,
                'show_all': true,
              });

              final retryResponse = await http.post(
                Uri.parse('${config.baseUrl}/api/v1/clinics/search/'),
                headers: headers,
                body: retryBody,
              );

              if (retryResponse.statusCode == 200) {
                final retryData = jsonDecode(retryResponse.body);
                effectiveResults = retryData['results'] as List<dynamic>? ?? [];

                for (var clinic in effectiveResults.take(3)) {
                  print(
                    'Retry clinic: ${clinic['name']}, lat=${clinic['latitude']}, lon=${clinic['longitude']}, email_confirmed=${clinic['email_confirmed']}',
                  );
                }
              } else {
                print(
                  'Retry search endpoint error: ${retryResponse.statusCode}',
                );
              }
            }

            // Convert, filter by email_confirmed, sort by distance, and take top 4
            final filteredClinics = effectiveResults
                .map((clinic) => Clinic.fromJson(clinic))
                .where((clinic) => clinic.emailConfirmed)
                .toList();

            filteredClinics.sort(
              (a, b) => _calculateDistance(a).compareTo(_calculateDistance(b)),
            );

            nearbyClinicsList = filteredClinics.take(4).toList();

            if (nearbyClinicsList.isEmpty) {
              print(
                'No nearby clinics found after search, falling back to list endpoint',
              );
              final clinics = await _clinicService.listClinics(showAll: true);

              final sortedClinics =
                  clinics.where((clinic) => clinic.emailConfirmed).toList()
                    ..sort(
                      (a, b) => _calculateDistance(
                        a,
                      ).compareTo(_calculateDistance(b)),
                    );

              nearbyClinicsList = sortedClinics.take(4).toList();
            }

            // Debug: Print parsed clinic distances
            for (var clinic in nearbyClinicsList) {
              final dist = _calculateDistance(clinic);
              print(
                'Parsed clinic: ${clinic.name}, lat=${clinic.latitude}, lon=${clinic.longitude}, distance=${dist}km',
              );
            }

            print(
              'Found ${effectiveResults.length} clinics, showing ${nearbyClinicsList.length} nearest',
            );
          } else {
            print('Search endpoint error: ${response.statusCode}');
            // Fallback to list endpoint
            final clinics = await _clinicService.listClinics();
            if (clinics.isNotEmpty) {
              nearbyClinicsList = clinics
                  .where((clinic) => clinic.emailConfirmed)
                  .take(2)
                  .toList();
            }
          }
        }
      } else {
        // No location available, use list endpoint
        final clinics = await _clinicService.listClinics();
        if (clinics.isNotEmpty) {
          nearbyClinicsList = clinics
              .where((clinic) => clinic.emailConfirmed)
              .take(2)
              .toList();
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

  double _parseCoordinate(String? value) {
    if (value == null) return 0.0;
    final normalized = value.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  double _calculateDistance(Clinic clinic) {
    if (_userPosition == null) return 0;

    final clinicLat = _parseCoordinate(clinic.latitude);
    final clinicLng = _parseCoordinate(clinic.longitude);

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
          builder: (context) =>
              const LanguageSelectionPage(preventAutoNavigate: true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations(
      _userProfile?.email ?? 'en',
    ); // This will be updated properly after we get language

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: PawLoadingIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.white,
                    pinned: true,
                    floating: false,
                    automaticallyImplyLeading: false,
                    expandedHeight: 120,
                    collapsedHeight: 80,
                    flexibleSpace: FlexibleSpaceBar(
                      background: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with logout
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FutureBuilder<String?>(
                                        future: LanguageService()
                                            .getLocalLanguage(),
                                        builder: (context, snapshot) {
                                          final lang = snapshot.data ?? 'en';
                                          final loc = AppLocalizations(lang);
                                          return Text(
                                            '${loc.hello},',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF7F8C8D),
                                            ),
                                          );
                                        },
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
                                          const Text(
                                            '👋',
                                            style: TextStyle(fontSize: 24),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.logout,
                                      color: Color(0xFF7F8C8D),
                                    ),
                                    onPressed: _handleLogout,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              FutureBuilder<String?>(
                                future: LanguageService().getLocalLanguage(),
                                builder: (context, snapshot) {
                                  final lang = snapshot.data ?? 'en';
                                  final loc = AppLocalizations(lang);
                                  return Text(
                                    loc.explore,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF7F8C8D),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Actions
                      FutureBuilder<String?>(
                        future: LanguageService().getLocalLanguage(),
                        builder: (context, snapshot) {
                          final lang = snapshot.data ?? 'en';
                          final loc = AppLocalizations(lang);
                          return Text(
                            loc.quickActions,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<String?>(
                        future: LanguageService().getLocalLanguage(),
                        builder: (context, snapshot) {
                          final lang = snapshot.data ?? 'en';
                          final loc = AppLocalizations(lang);
                          return Row(
                            children: [
                              _buildQuickAction(
                                'assets/pet-nutrition.svg',
                                loc.nutritionPlan,
                                () {
                                  // Navigate to nutrition
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildQuickAction(
                                'assets/pet-health.svg',
                                loc.healthReport,
                                () {
                                  // Navigate to health
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildQuickAction(
                                'assets/ai-history.svg',
                                loc.aiHistory,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AIHistoryPage(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildQuickAction(
                                'assets/clinics.svg',
                                loc.clinics,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ClinicsListPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // My Pets
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FutureBuilder<String?>(
                            future: LanguageService().getLocalLanguage(),
                            builder: (context, snapshot) {
                              final lang = snapshot.data ?? 'en';
                              final loc = AppLocalizations(lang);
                              return Text(
                                loc.yourPets,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              );
                            },
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
                            child: FutureBuilder<String?>(
                              future: LanguageService().getLocalLanguage(),
                              builder: (context, snapshot) {
                                final lang = snapshot.data ?? 'en';
                                final loc = AppLocalizations(lang);
                                return Row(
                                  children: [
                                    Text(
                                      loc.edit,
                                      style: const TextStyle(
                                        color: Color(0xFFCC5500),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFFCC5500),
                                      size: 20,
                                    ),
                                  ],
                                );
                              },
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
                          child: Center(
                            child: FutureBuilder<String?>(
                              future: LanguageService().getLocalLanguage(),
                              builder: (context, snapshot) {
                                final lang = snapshot.data ?? 'en';
                                final loc = AppLocalizations(lang);
                                return Text(
                                  loc.addFirstPet,
                                  style: const TextStyle(
                                    color: Color(0xFF7F8C8D),
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      else
                        ...(_pets.map(
                          (pet) => FutureBuilder<String?>(
                            future: LanguageService().getLocalLanguage(),
                            builder: (context, snapshot) {
                              final lang = snapshot.data ?? 'en';
                              final loc = AppLocalizations(lang);
                              return _buildPetCard(pet, loc);
                            },
                          ),
                        )),

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
                          child: Center(
                            child: FutureBuilder<String?>(
                              future: LanguageService().getLocalLanguage(),
                              builder: (context, snapshot) {
                                final lang = snapshot.data ?? 'en';
                                final loc = AppLocalizations(lang);
                                return Text(
                                  '+ ${loc.addNewPet}',
                                  style: const TextStyle(
                                    color: Color(0xFFCC5500),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Nearby Clinics
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FutureBuilder<String?>(
                            future: LanguageService().getLocalLanguage(),
                            builder: (context, snapshot) {
                              final lang = snapshot.data ?? 'en';
                              final loc = AppLocalizations(lang);
                              return Text(
                                loc.nearbyClinics,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              );
                            },
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
                            child: FutureBuilder<String?>(
                              future: LanguageService().getLocalLanguage(),
                              builder: (context, snapshot) {
                                final lang = snapshot.data ?? 'en';
                                final loc = AppLocalizations(lang);
                                return Row(
                                  children: [
                                    Text(
                                      loc.seeAll,
                                      style: const TextStyle(
                                        color: Color(0xFFCC5500),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFFCC5500),
                                      size: 20,
                                    ),
                                  ],
                                );
                              },
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
                        ..._nearbyClinics
                            .map(
                              (clinic) => Column(
                                children: [
                                  _buildClinicCard(clinic),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            )
                            .toList(),
                      const SizedBox(height: 80), // Bottom navigation spacing
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: const BottomNavBar(activePage: 'Home'),
    );
  }

  Widget _buildQuickAction(String assetPath, String label, VoidCallback onTap) {
    const circleColor = Color(0xFFF5C01D); // Matches bottom nav background
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          constraints: const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  assetPath,
                  height: 24,
                  width: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2C3E50),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedAge(Pet pet, AppLocalizations loc) {
    // Use the age_display from API if it's in the correct language (future enhancement)
    // For now, format locally with localization

    if (pet.ageYears == null && pet.ageMonths == null && pet.ageWeeks == null) {
      return '${loc.age} unknown';
    }

    List<String> ageParts = [];

    if (pet.ageYears != null && pet.ageYears! > 0) {
      if (pet.ageYears == 1) {
        ageParts.add('${pet.ageYears} ${loc.year}');
      } else {
        ageParts.add('${pet.ageYears} ${loc.years}');
      }
    }

    if (pet.ageMonths != null && pet.ageMonths! > 0) {
      if (pet.ageMonths == 1) {
        ageParts.add('${pet.ageMonths} ${loc.month}');
      } else {
        ageParts.add('${pet.ageMonths} ${loc.months}');
      }
    }

    if (pet.ageWeeks != null &&
        pet.ageWeeks! > 0 &&
        (pet.ageYears == null || pet.ageYears! == 0) &&
        (pet.ageMonths == null || pet.ageMonths! == 0)) {
      if (pet.ageWeeks == 1) {
        ageParts.add('${pet.ageWeeks} ${loc.week}');
      } else {
        ageParts.add('${pet.ageWeeks} ${loc.weeks}');
      }
    }

    return ageParts.isEmpty ? '${loc.age} unknown' : ageParts.join(' ');
  }

  Widget _buildPetCard(Pet pet, AppLocalizations loc) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PetDetailPage(pet: pet)),
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
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 3),
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
                    '${pet.displayBreed} • ${_getLocalizedAge(pet, loc)}',
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Color(0xFF7F8C8D),
                        ),
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
                        const Icon(
                          Icons.phone,
                          size: 14,
                          color: Color(0xFF7F8C8D),
                        ),
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
}
