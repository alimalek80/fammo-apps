import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/paw_loading_indicator.dart';
import '../models/onboarding_model.dart';
import '../services/onboarding_service.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final onboardingService = OnboardingService();
  
  List<OnboardingModel> slides = [];
  bool isLoading = true;
  int currentPage = 0;

  late final AnimationController _bgPawController;
  late final List<_PawParticle> _pawParticles;

  @override
  void initState() {
    super.initState();
    _bgPawController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pawParticles = _generatePaws();
    loadOnboardingSlides();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgPawController.dispose();
    super.dispose();
  }

  Future<void> loadOnboardingSlides() async {
    try {
      final loadedSlides = await onboardingService.getOnboardingSlides();
      setState(() {
        slides = loadedSlides;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading onboarding: $e')),
        );
      }
    }
  }

  Future<void> handleNext() async {
    if (currentPage < slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Last slide, mark as seen and navigate to login
      await onboardingService.markOnboardingAsSeen();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  Future<void> handleSkip() async {
    await onboardingService.markOnboardingAsSeen();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: PawLoadingIndicator(),
        ),
      );
    }

    if (slides.isEmpty) {
      // If no slides, go directly to login
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });
      return const SizedBox();
    }

    final Color buttonColor = _colorForSlide(currentPage, slides.length);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            _buildPawBackground(),
            Column(
              children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: handleSkip,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
              ),
            ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        currentPage = index;
                      });
                    },
                    itemCount: slides.length,
                    itemBuilder: (context, index) {
                      final slide = slides[index];
                      final accent = _colorForSlide(index, slides.length);
                      final isActive = currentPage == index;
                      return _buildSlide(slide, accent, isActive);
                    },
                  ),
                ),

                // Page indicator
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (index) {
                        final c = _colorForSlide(index, slides.length);
                        final active = currentPage == index;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active ? c : c.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Next/Get Started button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentPage == slides.length - 1
                                ? 'Get Started'
                                : slides[currentPage].buttonText,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingModel slide, Color accentColor, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Stack(
        children: [
          // Animated paw overlay tied to slide activity
          Positioned.fill(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutQuad,
              offset: isActive ? Offset.zero : const Offset(-0.25, 0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 450),
                opacity: isActive ? 0.08 : 0.0,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24, bottom: 32),
                    child: Icon(
                      Icons.pets,
                      size: 140,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.22),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: CachedNetworkImage(
                    imageUrl: slide.iconUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: PawLoadingIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.image, size: 80, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Title uses same accent as the slide's action button
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                slide.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7F8C8D),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorForSlide(int index, int length) {
    if (index == 0) return const Color(0xFFFFA726); // orange
    if (index == 1) return const Color(0xFFEF5350); // red
    if (index == 2) return const Color(0xFF26B5A4); // third slide green
    if (index == length - 1) return const Color(0xFF42A5F5); // sky blue for last (when beyond 3 slides)
    return const Color(0xFF26B5A4); // default green
  }

  Widget _buildPawBackground() {
    return AnimatedBuilder(
      animation: _bgPawController,
      builder: (context, _) {
        final t = _bgPawController.value;
        return IgnorePointer(
          child: Opacity(
            opacity: 0.14,
            child: Stack(
              children: _pawParticles.map((p) {
                final dx = math.sin(t * math.pi * 2 + p.phase) * p.amp;
                final dy = math.cos(t * math.pi * 2 + p.phase * 0.7) * p.amp * 0.6;
                return Positioned.fill(
                  child: Align(
                    alignment: Alignment(
                      (p.base.dx * 2 - 1),
                      (p.base.dy * 2 - 1),
                    ),
                    child: Transform.translate(
                      offset: Offset(dx, dy),
                      child: Transform.rotate(
                        angle: p.angle,
                        child: Icon(
                          Icons.pets,
                          size: p.size,
                          color: const Color(0xFF7A869A),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  List<_PawParticle> _generatePaws() {
    const pawCount = 8;
    final rand = math.Random(1337);
    return List.generate(pawCount, (i) {
      final base = Offset(rand.nextDouble(), rand.nextDouble());
      final size = 18 + rand.nextDouble() * 14; // 18..32
      final angle = (rand.nextDouble() * 0.8) - 0.4;
      final phase = rand.nextDouble() * math.pi * 2;
      final amp = 4 + rand.nextDouble() * 5; // gentle drift
      return _PawParticle(base: base, size: size, angle: angle, phase: phase, amp: amp);
    });
  }
}

class _PawParticle {
  final Offset base;
  final double size;
  final double angle;
  final double phase;
  final double amp;

  _PawParticle({required this.base, required this.size, required this.angle, required this.phase, required this.amp});
}
