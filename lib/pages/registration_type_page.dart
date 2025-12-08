import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'clinic_registration_page.dart';

class RegistrationTypePage extends StatelessWidget {
  const RegistrationTypePage({super.key});

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
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Choose Account Type',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Select how you would like to register',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF7F8C8D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Pet Owner Card
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _RegistrationTypeCard(
                    icon: Icons.pets,
                    title: 'Pet Owner',
                    description: 'Register as a pet owner to manage your pets and access veterinary services',
                    color: const Color(0xFF26B5A4),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Clinic Card
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _RegistrationTypeCard(
                    icon: Icons.local_hospital,
                    title: 'Clinic',
                    description: 'Register your veterinary clinic to connect with pet owners',
                    color: const Color(0xFF3498DB),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ClinicRegistrationPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegistrationTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _RegistrationTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF7F8C8D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
