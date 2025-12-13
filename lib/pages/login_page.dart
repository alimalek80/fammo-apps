import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/config_service.dart';
import '../services/biometric_service.dart';
import '../utils/app_localizations.dart';
import 'language_selection_page.dart';
import 'registration_type_page.dart';
import 'home_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  final String? prefilledEmail;
  
  const LoginPage({super.key, this.prefilledEmail});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final auth = AuthService();
  final languageService = LanguageService();
  final biometricService = BiometricService();

  String message = "";
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  AppLocalizations? _localizations;

  @override
  void initState() {
    super.initState();
    _loadLocalizations();
    _checkBiometricAvailability();
    // Pre-fill email if provided
    if (widget.prefilledEmail != null) {
      emailCtrl.text = widget.prefilledEmail!;
    }
  }

  Future<void> _loadLocalizations() async {
    final langCode = await languageService.getLocalLanguage() ?? 'en';
    setState(() {
      _localizations = AppLocalizations(langCode);
    });
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final available = await biometricService.canCheckDeviceCredential();
      final enabled = await biometricService.isBiometricLoginEnabled();
      print('DEBUG: Biometric Available: $available, Enabled: $enabled');
      if (mounted) {
        setState(() {
          _biometricAvailable = available;
          _biometricEnabled = enabled;
        });
      }
    } catch (e) {
      print('DEBUG: Error checking biometric: $e');
    }
  }

  Future<void> handleLogin() async {
    final localizations = _localizations ?? AppLocalizations('en');
    setState(() {
      isLoading = true;
      message = localizations.loggingIn;
    });

    try {
      // Get current language for Accept-Language header
      final currentLanguage = await languageService.getLocalLanguage() ?? 'en';
      final ok = await auth.login(emailCtrl.text, passwordCtrl.text);
      
      if (ok) {
        // Save credentials to system credential manager
        await auth.saveCredentialsToSystem(emailCtrl.text, passwordCtrl.text);
        
        // Sync language preference to backend after successful login
        final accessToken = await auth.getAccessToken();
        final localLanguage = await languageService.getLocalLanguage();
        
        if (accessToken != null && localLanguage != null) {
          await languageService.setUserLanguage(accessToken, localLanguage);
        }
        
        // Offer to enable biometric login if available and not already enabled
        if (_biometricAvailable && !_biometricEnabled && accessToken != null) {
          // Show dialog and wait for it to complete
          if (mounted) {
            await _showBiometricSetupDialogAsync(emailCtrl.text, accessToken);
          }
        }
        
        setState(() {
          isLoading = false;
          message = localizations.loginSuccess;
        });
        
        // Navigate to home page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        setState(() {
          isLoading = false;
          message = localizations.loginFailed;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        message = "${localizations.error}: $e";
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    final localizations = _localizations ?? AppLocalizations('en');
    
    try {
      setState(() {
        isLoading = true;
        message = localizations.authenticateWithBiometric;
      });

      // Authenticate with biometric
      final authenticated = await biometricService.authenticateWithDeviceCredentials(
        reason: localizations.authenticateWithBiometric,
      );

      if (authenticated) {
        // Get saved token and email
        final savedToken = await biometricService.getBiometricToken();
        final savedEmail = await biometricService.getBiometricEmail();
        
        if (savedToken != null && savedEmail != null) {
          // Store the token in auth service for session
          await auth.storage.write(key: "access", value: savedToken);
          
          setState(() {
            message = localizations.biometricSuccess;
            isLoading = false;
          });
          
          // Navigate to home page
          if (mounted) {
            await Future.delayed(const Duration(milliseconds: 500));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else {
          setState(() {
            message = localizations.biometricFailed;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          message = localizations.biometricFailed;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        message = "${localizations.error}: $e";
      });
    }
  }

  void _showBiometricSetupDialog(String email, String token) {
    final localizations = _localizations ?? AppLocalizations('en');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.biometricAvailable),
        content: Text(localizations.enableBiometric),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () async {
              await biometricService.enableBiometricLogin(email, token);
              setState(() {
                _biometricEnabled = true;
              });
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBiometricSetupDialogAsync(String email, String token) async {
    final localizations = _localizations ?? AppLocalizations('en');
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(localizations.biometricAvailable),
        content: Text(localizations.enableBiometric),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) {
                Navigator.pop(context, false);
              }
            },
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () async {
              await biometricService.enableBiometricLogin(email, token);
              setState(() {
                _biometricEnabled = true;
              });
              if (mounted) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
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
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LanguageSelectionPage(
                            preventAutoNavigate: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                // Logo
                FutureBuilder<AppConfig>(
                  future: ConfigService.getConfig(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.assets['logo'] != null) {
                      final logoUrl = snapshot.data!.assets['logo']!;
                      return Container(
                        width: 100,
                        height: 100,
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
                          child: CachedNetworkImage(
                            imageUrl: logoUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.pets,
                              size: 50,
                              color: Color(0xFF26B5A4),
                            ),
                          ),
                        ),
                      );
                    }
                    return Container(
                      width: 100,
                      height: 100,
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
                      child: const Icon(
                        Icons.pets,
                        size: 50,
                        color: Color(0xFF26B5A4),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Log In title
                Text(
                  _localizations?.login ?? 'Log In',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Email field
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      hintText: _localizations?.email ?? 'Email',
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF7F8C8D)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password field
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: TextField(
                    controller: passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: _localizations?.password ?? 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7F8C8D)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF7F8C8D),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Forgot Password link
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: Text(
                      _localizations?.forgotPassword ?? 'Forgot Password?',
                      style: const TextStyle(
                        color: Color(0xFF26B5A4),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Login button
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26B5A4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _localizations?.login ?? 'Log In',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                
                // Error message
                if (message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: message.contains('🎉') ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Biometric login button
                if (_biometricAvailable)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _handleBiometricLogin,
                      icon: const Icon(Icons.fingerprint, size: 24),
                      label: Text(
                        _localizations?.biometricLogin ?? 'Biometric Login',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF26B5A4),
                        side: const BorderSide(color: Color(0xFF26B5A4), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Or continue with
                Text(
                  _localizations?.orContinueWith ?? 'Or continue with',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Social login buttons
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Row(
                    children: [
                      // Google button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: Implement Google login
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://fonts.gstatic.com/s/i/productlogos/googleg/v6/24px.svg',
                                width: 24,
                                height: 24,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.login, color: Color(0xFF2C3E50));
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _localizations?.google ?? 'Google',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Apple button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: Implement Apple login
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.apple, color: Color(0xFF2C3E50), size: 24),
                              const SizedBox(width: 8),
                              Text(
                                _localizations?.apple ?? 'Apple',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _localizations?.dontHaveAccount ?? "Don't have an account? ",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegistrationTypePage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _localizations?.signUp ?? 'Sign Up',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF26B5A4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
