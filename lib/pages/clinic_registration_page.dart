import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/config_service.dart';
import '../services/language_service.dart';


class ClinicRegistrationPage extends StatefulWidget {
  const ClinicRegistrationPage({Key? key}) : super(key: key);
  @override
  _ClinicRegistrationPageState createState() => _ClinicRegistrationPageState();
}

class _ClinicRegistrationPageState extends State<ClinicRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  String _message = "";
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final languageService = LanguageService();

  // Account fields for clinic owner
  final _ownerEmailController = TextEditingController();
  final _ownerPasswordController = TextEditingController();
  final _ownerConfirmPasswordController = TextEditingController();
  final _ownerFirstNameController = TextEditingController();
  final _ownerLastNameController = TextEditingController();

  // Clinic registration controllers
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _instagramController = TextEditingController();
  final _specializationsController = TextEditingController();
  final _bioController = TextEditingController();
  final _vetNameController = TextEditingController();
  final _degreesController = TextEditingController();
  final _certificationsController = TextEditingController();

  // Location
  double? latitude;
  double? longitude;
  bool isLoadingLocation = false;

  // Logo
  File? logoFile;

  // Working hours
  List<TimeOfDay?> openTimes = List.generate(7, (_) => TimeOfDay(hour: 9, minute: 0));
  List<TimeOfDay?> closeTimes = List.generate(7, (_) => TimeOfDay(hour: 17, minute: 0));
  List<bool> isClosed = List.generate(7, (_) => false);
  List<String> dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  // Clinic EOI
  bool clinicEoi = false;

  final storage = FlutterSecureStorage();

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _specializationsController.dispose();
    _bioController.dispose();
    _vetNameController.dispose();
    _degreesController.dispose();
    _certificationsController.dispose();
    _ownerEmailController.dispose();
    _ownerPasswordController.dispose();
    _ownerConfirmPasswordController.dispose();
    _ownerFirstNameController.dispose();
    _ownerLastNameController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingLocation = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          // Limit to 6 decimals to satisfy backend validation
          latitude = double.parse(position.latitude.toStringAsFixed(6));
          longitude = double.parse(position.longitude.toStringAsFixed(6));
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location captured successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    } finally {
      setState(() => isLoadingLocation = false);
    }
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        logoFile = File(image.path);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, int dayIndex, bool isOpenTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpenTime ? openTimes[dayIndex]! : closeTimes[dayIndex]!,
    );
    
    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          openTimes[dayIndex] = picked;
        } else {
          closeTimes[dayIndex] = picked;
        }
      });
    }
  }

  Future<void> _uploadLogo(int clinicId, String accessToken) async {
    if (logoFile == null) return;
    
    try {
      final config = await ConfigService.getConfig();
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('${config.baseUrl}/api/v1/clinics/$clinicId/'),
      );
      
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.files.add(
        await http.MultipartFile.fromPath('logo', logoFile!.path),
      );
      
      await request.send();
    } catch (e) {
      print('Logo upload failed: $e');
    }
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate passwords match
    if (_ownerPasswordController.text != _ownerConfirmPasswordController.text) {
      setState(() {
        _message = "Passwords do not match.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = "Registering your clinic...";
    });

    try {
      final config = await ConfigService.getConfig();
      final langCode = await languageService.getLocalLanguage() ?? 'en';
      final clinicName = _nameController.text.trim();
      final latValue = latitude != null ? double.parse(latitude!.toStringAsFixed(6)) : null;
      final lngValue = longitude != null ? double.parse(longitude!.toStringAsFixed(6)) : null;

      // Working hours payload
      final workingHours = <Map<String, dynamic>>[];
      for (int i = 0; i < 7; i++) {
        workingHours.add({
          'day_of_week': i,
          'is_closed': isClosed[i],
          'open_time': isClosed[i]
              ? null
              : '${openTimes[i]!.hour.toString().padLeft(2, '0')}:${openTimes[i]!.minute.toString().padLeft(2, '0')}',
          'close_time': isClosed[i]
              ? null
              : '${closeTimes[i]!.hour.toString().padLeft(2, '0')}:${closeTimes[i]!.minute.toString().padLeft(2, '0')}',
        });
      }

      // Build payload to mirror the working Postman request
      final clinicData = <String, dynamic>{
        'email': _ownerEmailController.text.trim(),
        'password': _ownerPasswordController.text,
        'password_confirm': _ownerConfirmPasswordController.text,
        'first_name': _ownerFirstNameController.text.trim().isNotEmpty
            ? _ownerFirstNameController.text.trim()
            : 'Clinic',
        'last_name': _ownerLastNameController.text.trim().isNotEmpty
            ? _ownerLastNameController.text.trim()
            : 'Owner',
        'clinic_name': clinicName,
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email_clinic': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'specializations': _specializationsController.text.trim(),
        'bio': _bioController.text.trim(),
        'clinic_eoi': clinicEoi,
        'vet_name': _vetNameController.text.trim(),
        'degrees': _degreesController.text.trim(),
        'certifications': _certificationsController.text.trim(),
        if (latValue != null) 'latitude': latValue,
        if (lngValue != null) 'longitude': lngValue,
        'working_hours': workingHours,
      };

      final clinicResponse = await http.post(
        Uri.parse('${config.baseUrl}/api/v1/clinics/register/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': langCode,
        },
        body: jsonEncode(clinicData),
      );

      // Debug: Print request details
      print('Clinic Registration Request:');
      print('URL: ${config.baseUrl}/api/v1/clinics/register/');
      print('Headers: ${{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': langCode,
      }}');
      print('Body: ${jsonEncode(clinicData)}');

      print('Response Status: ${clinicResponse.statusCode}');
      print('Response Body: ${clinicResponse.body}');

      if (clinicResponse.statusCode != 201 && clinicResponse.statusCode != 200) {
        try {
          final error = jsonDecode(clinicResponse.body);
          throw Exception(
            'Clinic registration failed: HTTP ${clinicResponse.statusCode} -> ${error.toString()}',
          );
        } catch (e) {
          throw Exception(
            'Clinic registration failed: HTTP ${clinicResponse.statusCode} -> ${clinicResponse.body}',
          );
        }
      }

      final clinic = jsonDecode(clinicResponse.body);

      // Upload logo if selected (PATCH after registration)
      if (logoFile != null && clinic['id'] != null) {
        await _uploadLogo(clinic['id'], ''); // No access token needed
      }

      setState(() {
        _isLoading = false;
        _message = "Registration successful! Please check your email for confirmation.";
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = "Registration failed: ${e.toString()}";
      });
    }
  }



  Widget _buildStep1() {
    // Basic Clinic Information
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
        ),
        const SizedBox(height: 24),
        
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Clinic Name *',
            hintText: 'Happy Paws Veterinary Clinic',
            prefixIcon: const Icon(Icons.local_hospital),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLength: 160,
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _cityController,
          decoration: InputDecoration(
            labelText: 'City',
            hintText: 'Amsterdam',
            prefixIcon: const Icon(Icons.location_city),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLength: 80,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Address',
            hintText: 'Street, Number, Postal Code',
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLines: 2,
          maxLength: 220,
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GPS Location', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (latitude != null && longitude != null)
                  Text('${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}')
                else
                  const Text('No location captured', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: isLoadingLocation 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
                  label: const Text('Get Current Location'),
                  onPressed: isLoadingLocation ? null : _getCurrentLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    // Contact Information
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
        ),
        const SizedBox(height: 24),
        
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '+31 20 123 4567',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLength: 40,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Clinic Email',
            hintText: 'info@clinic.com',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _websiteController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'Website',
            hintText: 'https://www.clinic.com',
            prefixIcon: const Icon(Icons.language),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty && !value.startsWith('http')) {
              return 'Must start with http:// or https://';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _instagramController,
          decoration: InputDecoration(
            labelText: 'Instagram',
            hintText: '@clinicname',
            prefixIcon: const Icon(Icons.camera_alt),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLength: 120,
        ),
      ],
    );
  }

  Widget _buildStep3() {
    // Clinic Details
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Clinic Details',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
        ),
        const SizedBox(height: 24),
        
        TextFormField(
          controller: _specializationsController,
          decoration: InputDecoration(
            labelText: 'Specializations',
            hintText: 'Dogs, Cats, Rabbits, Birds, Emergency Care',
            helperText: 'Comma-separated list',
            prefixIcon: const Icon(Icons.pets),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLines: 2,
          maxLength: 200,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _bioController,
          decoration: InputDecoration(
            labelText: 'About the Clinic',
            hintText: 'Tell us about your clinic, services, and what makes you special...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLines: 5,
          maxLength: 1000,
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Clinic Logo', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (logoFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(logoFile!, height: 100, width: 100, fit: BoxFit.cover),
                  )
                else
                  const Text('No logo selected', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Upload Logo'),
                  onPressed: _pickLogo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    // Working Hours
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Working Hours',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Set your clinic opening hours for each day',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
        
        ...List.generate(7, (index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dayNames[index],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Text('Closed', style: TextStyle(fontSize: 14)),
                          Switch(
                            value: isClosed[index],
                            onChanged: (value) => setState(() => isClosed[index] = value),
                            activeColor: const Color(0xFF3498DB),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  if (!isClosed[index]) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Open', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _selectTime(context, index, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(openTimes[index]!.format(context), style: const TextStyle(fontSize: 15)),
                                      const Icon(Icons.access_time, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Close', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _selectTime(context, index, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(closeTimes[index]!.format(context), style: const TextStyle(fontSize: 15)),
                                      const Icon(Icons.access_time, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep5() {
    // Veterinarian Information
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Veterinarian Information',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Optional: Add information about the primary veterinarian',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 24),
        
        TextFormField(
          controller: _vetNameController,
          decoration: InputDecoration(
            labelText: 'Veterinarian Name',
            hintText: 'Dr. Emma van der Berg',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLength: 120,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _degreesController,
          decoration: InputDecoration(
            labelText: 'Academic Degrees',
            hintText: 'DVM, MSc Veterinary Medicine',
            prefixIcon: const Icon(Icons.school),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLength: 200,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _certificationsController,
          decoration: InputDecoration(
            labelText: 'Professional Certifications',
            hintText: 'Board Certified in Small Animal Medicine',
            prefixIcon: const Icon(Icons.verified),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLines: 2,
          maxLength: 240,
        ),
        const SizedBox(height: 16),
        
        SwitchListTile(
          title: const Text('Join FAMMO Pilot Program'),
          subtitle: const Text('Express interest in participating'),
          value: clinicEoi,
          onChanged: (value) => setState(() => clinicEoi = value),
          activeColor: const Color(0xFF3498DB),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE0F7F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Clinic Registration',
          style: TextStyle(color: Color(0xFF2C3E50)),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: List.generate(6, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentStep ? const Color(0xFF3498DB) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Center(
                        child: FutureBuilder<AppConfig>(
                          future: ConfigService.getConfig(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.assets['logo'] != null) {
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: CachedNetworkImage(
                                    imageUrl: snapshot.data!.assets['logo']!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            }
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.local_hospital, size: 40, color: Color(0xFF3498DB)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Step 0: Account creation fields
                      if (_currentStep == 0) ...[
                        const Text(
                          'Account Information',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _ownerFirstNameController,
                                decoration: InputDecoration(
                                  labelText: 'First Name',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _ownerLastNameController,
                                decoration: InputDecoration(
                                  labelText: 'Last Name',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ownerEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email *',
                            hintText: 'owner@clinic.com',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ownerPasswordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password *',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ownerConfirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password *',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ],
                      if (_currentStep == 1) _buildStep1(),
                      if (_currentStep == 2) _buildStep2(),
                      if (_currentStep == 3) _buildStep3(),
                      if (_currentStep == 4) _buildStep4(),
                      if (_currentStep == 5) _buildStep5(),
                      
                      const SizedBox(height: 32),
                      
                      // Navigation buttons
                      Row(
                        children: [
                          if (_currentStep > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _currentStep--),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: Color(0xFF3498DB)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Back'),
                              ),
                            ),
                          if (_currentStep > 0) const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () {
                                if (_currentStep < 5) {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() => _currentStep++);
                                  }
                                } else {
                                  _handleRegistration();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3498DB),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _currentStep < 5 ? 'Next' : 'Register Clinic',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Message
                      if (_message.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _message,
                            style: TextStyle(
                              fontSize: 14,
                              color: _message.contains('success') || _message.contains('successful')
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Already have an account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF3498DB),
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
            ],
          ),
        ),
      ),
    );
  }
}
