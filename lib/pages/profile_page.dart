import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../utils/app_localizations.dart';
import 'edit_profile_page.dart';
import 'edit_clinic_profile_page.dart';
import 'edit_clinic_working_hours_page.dart';
import 'pets_list_page.dart';
import 'change_password_page.dart';
import 'notification_settings_page.dart';
import 'language_settings_page.dart';
import '../widgets/bottom_nav_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  
  UserProfile? _userProfile;
  bool _isLoading = true;
  int _petsCount = 0;
  int _mealReportsCount = 0;
  int _healthReportsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _userService.getUserProfile();
      
      // Fetch real stats data
      final statsData = await _userService.getUserStats();
      
      setState(() {
        _userProfile = profile;
        _petsCount = statsData['pets_count'] ?? 0;
        _mealReportsCount = statsData['meal_reports_count'] ?? 0;
        _healthReportsCount = statsData['health_reports_count'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: LanguageService().getLocalLanguage(),
      builder: (context, snapshot) {
        String languageCode = snapshot.data ?? 'en';
        AppLocalizations loc = AppLocalizations(languageCode);
        
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: true,
            centerTitle: true,
            title: Text(
              loc.profile,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userProfile == null
                  ? Center(child: Text(loc.failedToLoadProfile))
                  : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Column(
                          children: [
                            // Profile Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FFFE),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF26B5A4),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _userProfile!.firstName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // User Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_userProfile!.firstName} ${_userProfile!.lastName}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _userProfile!.email,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF7F8C8D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Expand Arrow
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF7F8C8D),
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Stats Row
                            Row(
                              children: [
                                _buildStatItem(_petsCount.toString(), loc.pets, loc),
                                const SizedBox(width: 16),
                                _buildStatItem(_mealReportsCount.toString(), loc.mealReports, loc),
                                const SizedBox(width: 16),
                                _buildStatItem(_healthReportsCount.toString(), loc.healthReports, loc),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Account Section
                      _buildSection(
                        title: loc.account,
                        children: [
                          _buildMenuItemWithIcon(
                            icon: Icons.person_outline,
                            title: loc.editProfile,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfilePage(
                                    profile: _userProfile!,
                                  ),
                                ),
                              );
                              if (result == true && mounted) {
                                _loadUserProfile();
                              }
                            },
                          ),
                          _buildMenuItemWithIcon(
                            icon: Icons.pets,
                            title: loc.managePets,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PetsListPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItemWithIcon(
                            icon: Icons.lock_outline,
                            title: loc.changePassword,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChangePasswordPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Clinic Section (for clinic owners)
                      if (_userProfile!.isClinicOwner && _userProfile!.ownedClinics.isNotEmpty)
                        Column(
                          children: [
                            _buildSection(
                              title: loc.clinic,
                              children: [
                                _buildMenuItemWithIcon(
                                  icon: Icons.store_outlined,
                                  title: loc.editClinicProfile,
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditClinicProfilePage(
                                          clinicId:
                                              _userProfile!.ownedClinics[0].id,
                                          clinicName:
                                              _userProfile!.ownedClinics[0]
                                                  .name,
                                        ),
                                      ),
                                    );
                                    if (result == true && mounted) {
                                      _loadUserProfile();
                                    }
                                  },
                                ),
                                _buildMenuItemWithIcon(
                                  icon: Icons.schedule_outlined,
                                  title: loc.editWorkingHours,
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditClinicWorkingHoursPage(
                                          clinicId:
                                              _userProfile!.ownedClinics[0].id,
                                          clinicName:
                                              _userProfile!.ownedClinics[0]
                                                  .name,
                                          workingHours: null,
                                        ),
                                      ),
                                    );
                                    if (result == true && mounted) {
                                      _loadUserProfile();
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      // Settings Section
                      _buildSection(
                        title: loc.settings,
                        children: [
                          _buildMenuItemWithIcon(
                            icon: Icons.notifications_outlined,
                            title: loc.notifications,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationSettingsPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuItemWithIcon(
                            icon: Icons.language_outlined,
                            title: loc.language,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LanguageSettingsPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Legal Section
                      _buildSection(
                        title: loc.legal,
                        children: [
                          _buildMenuItemWithIcon(
                            icon: Icons.shield_outlined,
                            title: loc.privacyPolicy,
                            onTap: () {
                              print('Privacy Policy tapped');
                            },
                          ),
                          _buildMenuItemWithIcon(
                            icon: Icons.description_outlined,
                            title: loc.termsOfService,
                            onTap: () {
                              print('Terms of Service tapped');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Logout Button
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleLogout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            side: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                loc.logOut,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Version Text
                      Text(
                        'FAMMO v1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
          bottomNavigationBar: const BottomNavBar(activePage: 'Profile'),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7F8C8D),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: List.generate(
                children.length,
                (index) => Column(
                  children: [
                    children[index],
                    if (index < children.length - 1)
                      const Divider(
                        height: 1,
                        color: Color(0xFFEBEBEB),
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemWithIcon({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF7F8C8D),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFF95A5A6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String number, String label, AppLocalizations loc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _getStatColor(label, loc),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatColor(String label, AppLocalizations loc) {
    if (label == loc.pets) {
      return const Color(0xFFD4F1E8);
    } else if (label == loc.mealReports) {
      return const Color(0xFFFFE5D9);
    } else if (label == loc.healthReports) {
      return const Color(0xFFFFF5D9);
    } else {
      return const Color(0xFFE8E8E8);
    }
  }
}
