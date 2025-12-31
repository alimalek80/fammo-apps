import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/paw_loading_indicator.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: ConfigService.googleWebClientId,
    serverClientId: ConfigService.googleWebClientId,
  );

  String message = "";
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _isGoogleLoading = false;
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
      final ok = await auth.login(emailCtrl.text, passwordCtrl.text);
      
      if (ok) {
        await _completeLoginFlow(
          localizations,
          emailForBiometric: emailCtrl.text,
          passwordToSave: passwordCtrl.text,
        );
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

  Future<void> _handleGoogleSignIn() async {
    final localizations = _localizations ?? AppLocalizations('en');
    setState(() {
      isLoading = true;
      _isGoogleLoading = true;
      message = localizations.loggingIn;
    });

    try {
      // Ensure previous session is cleared so the chooser appears.
      try {
        await _googleSignIn.disconnect();
        await _googleSignIn.signOut();
      } catch (_) {}

      final account = await _googleSignIn.signIn();
      if (account == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
            _isGoogleLoading = false;
            message = localizations.loginFailed;
          });
        }
        return;
      }

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Google sign-in did not return an id_token');
      }

      final ok = await auth.loginWithGoogleIdToken(idToken);

      if (ok) {
        await _completeLoginFlow(
          localizations,
          emailForBiometric: account.email,
        );
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            _isGoogleLoading = false;
            message = localizations.loginFailed;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          _isGoogleLoading = false;
          message = "${localizations.error}: $e";
        });
      }
    }
  }

  Future<void> _completeLoginFlow(
    AppLocalizations localizations, {
    String? emailForBiometric,
    String? passwordToSave,
  }) async {
    final accessToken = await auth.getAccessToken();
    final localLanguage = await languageService.getLocalLanguage();

    if (accessToken != null && localLanguage != null) {
      await languageService.setUserLanguage(accessToken, localLanguage);
    }

    if (passwordToSave != null && emailForBiometric != null) {
      await auth.saveCredentialsToSystem(emailForBiometric, passwordToSave);
    }

    if (_biometricAvailable && !_biometricEnabled && accessToken != null && emailForBiometric != null) {
      if (mounted) {
        await _showBiometricSetupDialogAsync(emailForBiometric, accessToken);
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
        _isGoogleLoading = false;
        message = localizations.loginSuccess;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
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
    const backgroundDog = Color(0xFFFFC13A);
    return Scaffold(
      backgroundColor: backgroundDog,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  height: 150,
                  child: Image.asset(
                    'assets/dog01.gif',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 260),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
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
                        const Spacer(),
                        Transform.rotate(
                          angle: 0.785398, // 45 degrees in radians
                          child: FutureBuilder<AppConfig>(
                            future: ConfigService.getConfig(),
                            builder: (context, snapshot) {
                              final shadowColor = const Color(0xFF2C3E50).withOpacity(0.16);
                              if (snapshot.hasData && snapshot.data!.assets['logo'] != null) {
                                final logoUrl = snapshot.data!.assets['logo']!;
                                return Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: shadowColor,
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: CachedNetworkImage(
                                      imageUrl: logoUrl,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => const Center(
                                        child: PawLoadingIndicator(),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(
                                        Icons.pets,
                                        size: 36,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: shadowColor,
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.pets,
                                  size: 36,
                                  color: Color(0xFF2C3E50),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _localizations?.login ?? 'Log In',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: PawLoadingIndicator(size: 24),
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
                    Text(
                      _localizations?.orContinueWith ?? 'Or continue with',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: (_isGoogleLoading || isLoading)
                                  ? null
                                  : _handleGoogleSignIn,
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
                                  if (_isGoogleLoading)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: PawLoadingIndicator(size: 20),
                                    )
                                  else ...[
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
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCC5500),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              _localizations?.signUp ?? 'Sign Up',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
