import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/pets_list_page.dart';
import '../pages/clinics_list_page.dart';
import '../pages/profile_page.dart';
import '../services/language_service.dart';
import '../utils/app_localizations.dart';

class BottomNavBar extends StatelessWidget {
  final String activePage;

  const BottomNavBar({
    required this.activePage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
          child: FutureBuilder<String?>(
            future: LanguageService().getLocalLanguage(),
            builder: (context, snapshot) {
              String languageCode = snapshot.data ?? 'en';
              AppLocalizations loc = AppLocalizations(languageCode);
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context,
                    Icons.home,
                    loc.home,
                    'Home',
                    activePage == 'Home',
                  ),
                  _buildNavItem(
                    context,
                    Icons.pets,
                    loc.pets,
                    'Pets',
                    activePage == 'Pets',
                  ),
                  _buildNavItem(
                    context,
                    Icons.location_on,
                    loc.clinics,
                    'Clinics',
                    activePage == 'Clinics',
                  ),
                  _buildNavItem(
                    context,
                    Icons.chat_bubble_outline,
                    loc.chat,
                    'Chat',
                    activePage == 'Chat',
                  ),
                  _buildNavItem(
                    context,
                    Icons.person_outline,
                    loc.profile,
                    'Profile',
                    activePage == 'Profile',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String localizedLabel,
    String pageKey,
    bool isActive,
  ) {
    return InkWell(
      onTap: () {
        if (pageKey == 'Home' && activePage != 'Home') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
          );
        } else if (pageKey == 'Pets' && activePage != 'Pets') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PetsListPage(),
            ),
          );
        } else if (pageKey == 'Clinics' && activePage != 'Clinics') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ClinicsListPage(),
            ),
          );
        } else if (pageKey == 'Profile' && activePage != 'Profile') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfilePage(),
            ),
          );
        }
        // Chat is TODO
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive
                ? const Color(0xFF26B5A4)
                : const Color(0xFF7F8C8D),
          ),
          const SizedBox(height: 4),
          Text(
            localizedLabel,
            style: TextStyle(
              fontSize: 11,
              color: isActive
                  ? const Color(0xFF26B5A4)
                  : const Color(0xFF7F8C8D),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
