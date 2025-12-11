import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/language_service.dart';
import '../services/config_service.dart';
import '../services/onboarding_service.dart';
import 'onboarding_page.dart';
import 'login_page.dart';

class LanguageSelectionPage extends StatefulWidget {
  final bool preventAutoNavigate;
  
  const LanguageSelectionPage({
    super.key,
    this.preventAutoNavigate = false,
  });

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  final languageService = LanguageService();
  final onboardingService = OnboardingService();
  List<LanguageModel> languages = [];
  bool isLoading = true;

  // Fallback languages in case API fails
  final List<Map<String, String>> fallbackLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'tr', 'name': 'Turkish', 'nativeName': 'Türkçe'},
    {'code': 'nl', 'name': 'Dutch', 'nativeName': 'Nederlands'},
    {'code': 'fi', 'name': 'Finnish', 'nativeName': 'Suomi'},
  ];

  @override
  void initState() {
    super.initState();
    
    loadLanguages();
    // Only auto-navigate if preventAutoNavigate is false
    if (!widget.preventAutoNavigate) {
      checkIfLanguageAlreadySelected();
    }
  }

  Future<void> checkIfLanguageAlreadySelected() async {
    final selectedLanguage = await languageService.getLocalLanguage();
    if (selectedLanguage != null && mounted && !widget.preventAutoNavigate) {
      // Language already selected, check if onboarding has been seen
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted && !widget.preventAutoNavigate) {
        final hasSeenOnboarding = await onboardingService.hasSeenOnboarding();
        if (hasSeenOnboarding) {
          // Go directly to login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          // Show onboarding first
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingPage()),
          );
        }
      }
    }
  }

  Future<void> loadLanguages() async {
    try {
      final availableLanguages = await languageService.getAvailableLanguages();
      setState(() {
        languages = availableLanguages;
        isLoading = false;
      });
    } catch (e) {
      // If API fails, use fallback languages
      setState(() {
        languages = fallbackLanguages.map((lang) => LanguageModel(
          code: lang['code']!,
          name: lang['name']!,
          nativeName: lang['nativeName']!,
        )).toList();
        isLoading = false;
      });
    }
  }

  Future<void> selectLanguage(String languageCode) async {
    await languageService.setLocalLanguage(languageCode);
    
    // Clear onboarding status to show slides again when language changes
    await onboardingService.markOnboardingAsNotSeen();
    
    if (mounted) {
      // After selecting language, show onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingPage()),
      );
    }
  }

  String getCountryCode(String langCode) {
    switch (langCode) {
      case 'en':
        return 'GB';
      case 'tr':
        return 'TR';
      case 'nl':
        return 'NL';
      case 'fi':
        return 'FI';
      default:
        return 'GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7F4),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo from server
                FutureBuilder<AppConfig>(
                  future: ConfigService.getConfig(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.assets['logo'] != null) {
                      final logoUrl = snapshot.data!.assets['logo']!;
                      print('Loading logo from: $logoUrl');
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF26B5A4).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: logoUrl,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                print('Error loading logo: $error');
                                print('Failed URL: $url');
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error, color: Colors.red, size: 40),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Failed',
                                          style: TextStyle(fontSize: 12, color: Colors.red[700]),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }
                    // Loading
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Subtitle
                const Text(
                  'AI-Powered Pet Health & Nutrition',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Language selection label
                Row(
                  children: [
                    Icon(Icons.language, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Select your language',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Loading or Language cards (with staggered animation)
                if (isLoading)
                  const CircularProgressIndicator()
                else
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      children: languages.map((lang) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildLanguageCard(
                            countryCode: getCountryCode(lang.code),
                            title: lang.name,
                            subtitle: lang.nativeName,
                            onTap: () => selectLanguage(lang.code),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // Footer emojis
                const Text(
                  '🐕 🐈 💚',
                  style: TextStyle(fontSize: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required String countryCode,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Country flag circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    countryCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Language names
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
