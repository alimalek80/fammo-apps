import 'package:flutter/material.dart';
import 'pages/language_selection_page.dart';
import 'pages/login_page.dart';
import 'pages/clinics_list_page.dart';
import 'pages/my_clinic_page.dart';
import 'pages/add_edit_clinic_page.dart';
import 'services/language_service.dart';
import 'services/config_service.dart';
import 'services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load app configuration from server
  await ConfigService.getConfig();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
  }

  void _initializeDeepLinks() {
    _deepLinkService.initialize((Uri uri) {
      print('Deep link received: $uri');
      
      if (uri.scheme == 'fammo' && uri.host == 'login') {
        bool activated = uri.queryParameters['activated'] == 'true';
        String? email = uri.queryParameters['email'];

        if (activated && email != null) {
          // Show success dialog and navigate to login
          Future.delayed(const Duration(milliseconds: 500), () {
            if (navigatorKey.currentContext != null) {
              _showActivationSuccess(navigatorKey.currentContext!, email);
            }
          });
        }
      }
    });
  }

  void _showActivationSuccess(BuildContext context, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Account Activated!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Your account has been activated successfully. You can now log in with your credentials.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF7F8C8D),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to login page with email pre-filled
                  navigatorKey.currentState?.pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => LoginPage(prefilledEmail: email),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26B5A4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Go to Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'FAMMO App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/language': (context) => const LanguageSelectionPage(),
        '/login': (context) => const LoginPage(),
        '/clinics': (context) => const ClinicsListPage(),
        '/my-clinic': (context) => const MyClinicPage(),
        '/add-clinic': (context) => const AddEditClinicPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    checkLanguageAndNavigate();
  }

  Future<void> checkLanguageAndNavigate() async {
    // Check if user has selected a language
    final selectedLanguage = await languageService.getLocalLanguage();

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      // Always show language selection first
      // If language is selected, it will automatically navigate to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LanguageSelectionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFE0F7F4),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
