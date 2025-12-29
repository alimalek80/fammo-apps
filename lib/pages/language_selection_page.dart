import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/config_service.dart';
import '../services/language_service.dart';
import '../services/onboarding_service.dart';
import 'login_page.dart';
import 'onboarding_page.dart';

class LanguageSelectionPage extends StatefulWidget {
  final bool preventAutoNavigate;

  const LanguageSelectionPage({
    super.key,
    this.preventAutoNavigate = false,
  });

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> with TickerProviderStateMixin {
  final languageService = LanguageService();
  final onboardingService = OnboardingService();
  List<LanguageModel> languages = [];
  bool isLoading = true;

  late final AnimationController _pawController;
  late final AnimationController _logoShadowController;
  late final Animation<Color?> _logoShadowAnimation;
  late final AnimationController _footerFloatController;

  final List<Color> accentColors = const [
    Color(0xFF26B5A4),
    Color(0xFF6C63FF),
    Color(0xFFFFA726),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
  ];

  final Map<String, Color> languageAccentMap = const {
    'en': Color(0xFF26B5A4),
    'tr': Color(0xFFEF5350),
    'nl': Color(0xFFFFA726),
    'fi': Color(0xFF42A5F5),
  };

  final List<Map<String, String>> fallbackLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'tr', 'name': 'Turkish', 'nativeName': 'Türkçe'},
    {'code': 'nl', 'name': 'Dutch', 'nativeName': 'Nederlands'},
    {'code': 'fi', 'name': 'Finnish', 'nativeName': 'Suomi'},
  ];

  @override
  void initState() {
    super.initState();

    _pawController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _logoShadowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    const orange = Color(0xFFFFA726);
    const green = Color(0xFF26B5A4);
    const blue = Color(0xFF42A5F5);
    const red = Color(0xFFEF5350);

    _logoShadowAnimation = TweenSequence<Color?>([
      TweenSequenceItem(tween: ColorTween(begin: orange, end: green), weight: 1),
      TweenSequenceItem(tween: ColorTween(begin: green, end: blue), weight: 1),
      TweenSequenceItem(tween: ColorTween(begin: blue, end: red), weight: 1),
      TweenSequenceItem(tween: ColorTween(begin: red, end: orange), weight: 1),
    ]).animate(CurvedAnimation(parent: _logoShadowController, curve: Curves.easeInOut));

    _footerFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    loadLanguages();
    if (!widget.preventAutoNavigate) {
      checkIfLanguageAlreadySelected();
    }
  }

  Future<void> checkIfLanguageAlreadySelected() async {
    final selectedLanguage = await languageService.getLocalLanguage();
    if (selectedLanguage != null && mounted && !widget.preventAutoNavigate) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted && !widget.preventAutoNavigate) {
        final hasSeenOnboarding = await onboardingService.hasSeenOnboarding();
        if (hasSeenOnboarding) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
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
      setState(() {
        languages = fallbackLanguages
            .map((lang) => LanguageModel(
                  code: lang['code']!,
                  name: lang['name']!,
                  nativeName: lang['nativeName']!,
                ))
            .toList();
        isLoading = false;
      });
    }
  }

  Future<void> selectLanguage(String languageCode) async {
    await languageService.setLocalLanguage(languageCode);
    await onboardingService.markOnboardingAsNotSeen();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingPage()),
      );
    }
  }

  @override
  void dispose() {
    _pawController.dispose();
    _logoShadowController.dispose();
    _footerFloatController.dispose();
    super.dispose();
  }

  String getCountryFlag(String langCode) {
    switch (langCode) {
      case 'en':
        return '🇬🇧';
      case 'tr':
        return '🇹🇷';
      case 'nl':
        return '🇳🇱';
      case 'fi':
        return '🇫🇮';
      default:
        return '🇬🇧';
    }
  }

  String getWelcomeText(String langCode) {
    switch (langCode) {
      case 'en':
        return 'Welcome';
      case 'tr':
        return 'Hoş geldiniz';
      case 'nl':
        return 'Welkom';
      case 'fi':
        return 'Tervetuloa';
      default:
        return 'Welcome';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FutureBuilder<AppConfig>(
                  future: ConfigService.getConfig(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.assets['logo'] != null) {
                      final logoUrl = snapshot.data!.assets['logo']!;
                      return _buildAnimatedLogoShell(
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
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
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
                                      Text('Failed', style: TextStyle(fontSize: 12, color: Colors.red[700])),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return _buildAnimatedLogoShell(
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'AI-Powered Pet Health & Nutrition',
                  style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Icon(Icons.language, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Select your language',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const CircularProgressIndicator()
                else
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      children: languages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final lang = entry.value;
                        final accent = languageAccentMap[lang.code] ?? accentColors[index % accentColors.length];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildLanguageCard(
                            languageCode: lang.code,
                            countryFlag: getCountryFlag(lang.code),
                            title: lang.name,
                            subtitle: getWelcomeText(lang.code),
                            accentColor: accent,
                            onTap: () => selectLanguage(lang.code),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _floatingMascot('assets/dog_face_01.svg', 0.0),
                    const SizedBox(width: 16),
                    _floatingMascot('assets/cat_face_01.svg', 0.5),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required String languageCode,
    required String countryFlag,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final paws = _lightPaws(languageCode, accentColor);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFC13A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              ...paws,
              if (languageCode == 'nl')
                Positioned(
                  bottom: -10,
                  right: 30,
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Image.asset(
                      'assets/cat01.gif',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Country flag
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        countryFlag,
                        style: const TextStyle(
                          fontSize: 32,
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
            ],
          ),
        ),
      ),
    );
  }

  // Light paw overlay is generated deterministically from the language code so it stays put across rebuilds
  List<Widget> _lightPaws(String langCode, Color accentColor) {
    final rand = math.Random(langCode.hashCode ^ 0x9E3779B9);
    final count = 2 + rand.nextInt(3); // 2 to 4 paws

    const pawBase = Color(0xFF7A869A); // soft gray
    const virtualWidth = 320.0;
    const virtualHeight = 120.0;
    final placed = <Map<String, double>>[];

    Positioned buildPaw(int salt) {
      final r = math.Random(langCode.hashCode + salt);
      final isBig = r.nextBool();
      final size = isBig ? 32 + r.nextDouble() * 10 : 20 + r.nextDouble() * 8;
      final opacity = 0.06 + r.nextDouble() * 0.04;
      final angle = (r.nextDouble() * 0.6) - 0.3;
      final phase = r.nextDouble() * math.pi * 2;
      final amp = 2.0 + r.nextDouble() * 3.0;

      // Rejection sample to avoid overlap in a virtual canvas
      double fx = 0.5;
      double fy = 0.5;
      const attempts = 12;
      for (var i = 0; i < attempts; i++) {
        final x = 10 + r.nextDouble() * (virtualWidth - 20);
        final y = 8 + r.nextDouble() * (virtualHeight - 16);
        final overlaps = placed.any((p) {
          final dx = p['x']! - x;
          final dy = p['y']! - y;
          final minDist = (p['size']! + size) * 0.5 + 6; // add breathing room
          return (dx * dx + dy * dy) < (minDist * minDist);
        });
        if (!overlaps) {
          placed.add({'x': x, 'y': y, 'size': size});
          fx = x / virtualWidth;
          fy = y / virtualHeight;
          break;
        }
      }

      return Positioned.fill(
        child: AnimatedBuilder(
          animation: _pawController,
          builder: (context, child) {
            final t = _pawController.value;
            final dx = math.sin(t * math.pi * 2 + phase) * amp;
            final dy = math.cos(t * math.pi * 2 + phase * 0.7) * amp * 0.6;
            return Align(
              alignment: Alignment((fx * 2) - 1, (fy * 2) - 1),
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(
                  angle: angle,
                  child: Icon(
                    Icons.pets,
                    size: size,
                    color: pawBase.withOpacity(opacity),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return List<Widget>.generate(count, (i) => buildPaw(i * 31 + 7));
  }

  Color _logoShadowColor() => _logoShadowAnimation.value ?? accentColors.first;

  Widget _buildAnimatedLogoShell({required Widget child}) {
    return AnimatedBuilder(
      animation: _logoShadowController,
      builder: (context, _) {
        final shadowColor = _logoShadowColor();
        return Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }

  Widget _floatingMascot(String assetPath, double phase) {
    return AnimatedBuilder(
      animation: _footerFloatController,
      builder: (context, child) {
        final t = _footerFloatController.value;
        final dy = math.sin((t + phase) * math.pi * 2) * 4.0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SvgPicture.asset(
          assetPath,
          width: 36,
          height: 36,
        ),
      ),
    );
  }
}
