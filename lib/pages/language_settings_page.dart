import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/paw_loading_indicator.dart';
import '../services/language_service.dart';
import '../services/config_service.dart';
import '../services/onboarding_service.dart';
import 'language_selection_page.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  final languageService = LanguageService();
  final onboardingService = OnboardingService();
  
  List<LanguageModel> languages = [];
  String? selectedLanguage;
  String? initialLanguage;
  bool isLoading = true;
  bool languageChanged = false;

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
    _loadLanguagesAndCurrentSelection();
  }

  Future<void> _loadLanguagesAndCurrentSelection() async {
    try {
      final availableLanguages = await languageService.getAvailableLanguages();
      final currentLanguage = await languageService.getLocalLanguage();
      
      setState(() {
        languages = availableLanguages;
        selectedLanguage = currentLanguage ?? 'en';
        initialLanguage = currentLanguage ?? 'en';
        isLoading = false;
      });
    } catch (e) {
      // If API fails, use fallback languages
      final currentLanguage = await languageService.getLocalLanguage();
      setState(() {
        languages = fallbackLanguages.map((lang) => LanguageModel(
          code: lang['code']!,
          name: lang['name']!,
          nativeName: lang['nativeName']!,
        )).toList();
        selectedLanguage = currentLanguage ?? 'en';
        initialLanguage = currentLanguage ?? 'en';
        isLoading = false;
      });
    }
  }

  Future<void> _selectLanguage(String languageCode) async {
    if (languageCode == selectedLanguage) {
      // Language already selected
      return;
    }

    setState(() {
      selectedLanguage = languageCode;
      languageChanged = languageCode != initialLanguage;
    });
    
    // Save the selected language
    await languageService.setLocalLanguage(languageCode);
    
    // Clear onboarding status to show slides again when language changes
    await onboardingService.markOnboardingAsNotSeen();
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

  void _restartApp() {
    // Restart the app by pushing a new MaterialApp
    // This will rebuild the entire app with the new language
    // For a more complete restart, we could use an app restart library,
    // but for now we'll navigate to the main app
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        centerTitle: true,
        title: const Text(
          'Language',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: PawLoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Header section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.language,
                              color: const Color(0xFF26B5A4),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Select your language',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose your preferred language for the app',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Language options
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: List.generate(
                        languages.length,
                        (index) {
                          final lang = languages[index];
                          final isSelected = selectedLanguage == lang.code;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildLanguageCard(
                              countryCode: getCountryCode(lang.code),
                              title: lang.name,
                              subtitle: lang.nativeName,
                              isSelected: isSelected,
                              onTap: () => _selectLanguage(lang.code),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Info section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEBEBEB),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color(0xFF7F8C8D),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            languageChanged
                                ? 'Language changed. Restart the app to apply changes.'
                                : 'Select a language to change the app language',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF7F8C8D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Restart button (shown only when language has changed)
                  if (languageChanged)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _restartApp,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Restart App'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF26B5A4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildLanguageCard({
    required String countryCode,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF26B5A4)
                  : const Color(0xFFEBEBEB),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? const Color(0xFFF0FFFE)
                : Colors.white,
          ),
          child: Row(
            children: [
              // Country code circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF26B5A4).withOpacity(0.1)
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    countryCode,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF26B5A4)
                          : const Color(0xFF2C3E50),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF26B5A4)
                            : const Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? const Color(0xFF26B5A4).withOpacity(0.7)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Selection indicator
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF26B5A4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                )
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
