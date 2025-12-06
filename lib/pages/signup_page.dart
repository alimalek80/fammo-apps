import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/language_service.dart';
import '../services/config_service.dart';
import '../utils/app_localizations.dart';
import 'login_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final languageService = LanguageService();

  String message = "";
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  AppLocalizations? _localizations;

  @override
  void initState() {
    super.initState();
    _loadLocalizations();
  }

  Future<void> _loadLocalizations() async {
    final langCode = await languageService.getLocalLanguage() ?? 'en';
    setState(() {
      _localizations = AppLocalizations(langCode);
    });
  }

  Future<void> handleSignUp() async {
    final localizations = _localizations ?? AppLocalizations('en');
    
    // Validate passwords match
    if (passwordCtrl.text != confirmPasswordCtrl.text) {
      setState(() {
        message = localizations.passwordMismatch;
      });
      return;
    }

    // Validate terms agreement
    if (!_agreedToTerms) {
      setState(() {
        message = localizations.agreeTermsRequired;
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = localizations.signingUp;
    });

    try {
      final baseUrl = await ConfigService.getBaseUrl();
      final langCode = await languageService.getLocalLanguage() ?? 'en';
      final url = Uri.parse("$baseUrl/api/v1/auth/signup/");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": langCode,
        },
        body: jsonEncode({
          "email": emailCtrl.text,
          "password": passwordCtrl.text,
          "password_confirm": confirmPasswordCtrl.text,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        
        // Show success dialog
        if (mounted) {
          _showSuccessDialog(localizations);
        }
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          isLoading = false;
          message = "${localizations.signUpFailed}\n${errorData.toString()}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        message = "${localizations.error}: $e";
      });
    }
  }

  void _showSuccessDialog(AppLocalizations localizations) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isResending = false;
            String resendMessage = '';

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
                  Expanded(
                    child: Text(
                      localizations.signUpSuccess,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.checkEmail,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                  if (resendMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        resendMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: resendMessage.contains('✓') ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                // Resend button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isResending ? null : () async {
                      setState(() {
                        isResending = true;
                        resendMessage = '';
                      });

                      try {
                        final baseUrl = await ConfigService.getBaseUrl();
                        final langCode = await languageService.getLocalLanguage() ?? 'en';
                        final url = Uri.parse("$baseUrl/api/v1/auth/resend-activation/");

                        final response = await http.post(
                          url,
                          headers: {
                            "Content-Type": "application/json",
                            "Accept-Language": langCode,
                          },
                          body: jsonEncode({
                            "email": emailCtrl.text,
                          }),
                        );

                        setState(() {
                          isResending = false;
                          if (response.statusCode == 200) {
                            resendMessage = '✓ ${localizations.resendSuccess}';
                          } else {
                            resendMessage = localizations.resendFailed;
                          }
                        });
                      } catch (e) {
                        setState(() {
                          isResending = false;
                          resendMessage = localizations.resendFailed;
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF26B5A4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: isResending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF26B5A4),
                            ),
                          )
                        : Text(
                            localizations.resendActivation,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF26B5A4),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                // Go to login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
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
                    child: Text(
                      localizations.logIn,
                      style: const TextStyle(
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = _localizations ?? AppLocalizations('en');
    
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
                      Navigator.pop(context);
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
                
                // Sign Up title
                Text(
                  localizations.signUp,
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
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: localizations.email,
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
                      hintText: localizations.password,
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
                const SizedBox(height: 16),
                
                // Confirm Password field
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: TextField(
                    controller: confirmPasswordCtrl,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: localizations.confirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7F8C8D)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF7F8C8D),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
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
                const SizedBox(height: 16),
                
                // Terms checkbox
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreedToTerms = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF26B5A4),
                      ),
                      Expanded(
                        child: Text(
                          localizations.agreeToTerms,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Sign up button
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleSignUp,
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
                            localizations.signUp,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                
                // Error message
                if (message.isNotEmpty && !message.contains('...'))
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: message.contains('🎉') ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Or continue with
                Text(
                  localizations.orContinueWith,
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
                            // TODO: Implement Google sign up
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
                                localizations.google,
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
                            // TODO: Implement Apple sign up
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
                                localizations.apple,
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
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      localizations.alreadyHaveAccount,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        localizations.logIn,
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
