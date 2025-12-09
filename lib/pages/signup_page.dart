import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/config_service.dart';
import '../services/language_service.dart';
import '../utils/app_localizations.dart';

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

  String message = '';
  bool isLoading = false;
  String _selectedRole = 'petowner'; // 'petowner' or 'clinicowner'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  AppLocalizations? _localizations;

  AppLocalizations get localizations => _localizations ?? AppLocalizations('en');

  @override
  void initState() {
    super.initState();
    _loadLocalizations();
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocalizations() async {
    final langCode = await languageService.getLocalLanguage() ?? 'en';
    setState(() {
      _localizations = AppLocalizations(langCode);
    });
  }

  Future<void> handleSignUp() async {
    final localizations = this.localizations;

    if (passwordCtrl.text != confirmPasswordCtrl.text) {
      setState(() {
        message = localizations.passwordMismatch;
      });
      return;
    }

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
      final baseUrl = ConfigService.getBaseUrl();
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

  Future<void> _showSuccessDialog(AppLocalizations localizations) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(localizations.signUpSuccess),
        content: Text(localizations.checkEmail),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(localizations.logIn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = this.localizations;

    return Scaffold(
      backgroundColor: const Color(0xFFE0F7F4),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                Text(
                  localizations.signUp,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 32),
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
                        if (message.isNotEmpty && !message.contains('...'))
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: message.contains('dYZ%') ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
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
