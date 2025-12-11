import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/clinic_service.dart';
import '../services/auth_service.dart';
import '../models/clinic.dart';

class EditClinicProfilePage extends StatefulWidget {
  final int clinicId;
  final String clinicName;

  const EditClinicProfilePage({
    required this.clinicId,
    required this.clinicName,
  });

  @override
  State<EditClinicProfilePage> createState() => _EditClinicProfilePageState();
}

class _EditClinicProfilePageState extends State<EditClinicProfilePage> {
  final ClinicService _clinicService = ClinicService();
  final AuthService _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _instagramController;
  late TextEditingController _specializationsController;
  late TextEditingController _bioController;
  late TextEditingController _vetNameController;
  late TextEditingController _degreesController;
  late TextEditingController _certificationsController;

  bool _isLoading = true;
  bool _isSaving = false;
  Clinic? _clinic;
  File? _logoFile;
  String? _logoUrl;

  // Validation state
  final Map<String, String?> _fieldErrors = {
    'name': null,
    'city': null,
    'address': null,
    'phone': null,
    'email': null,
    'website': null,
    'instagram': null,
    'specializations': null,
    'bio': null,
    'vetName': null,
    'degrees': null,
    'certifications': null,
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadClinicData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _cityController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
    _instagramController = TextEditingController();
    _specializationsController = TextEditingController();
    _bioController = TextEditingController();
    _vetNameController = TextEditingController();
    _degreesController = TextEditingController();
    _certificationsController = TextEditingController();
  }

  Future<void> _loadClinicData() async {
    try {
      final clinic = await _clinicService.getClinicDetails(widget.clinicId);
      setState(() {
        _clinic = clinic;
        _populateControllers(clinic);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading clinic data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _populateControllers(Clinic clinic) {
    _nameController.text = clinic.name;
    _cityController.text = clinic.city;
    _addressController.text = clinic.address;
    _phoneController.text = clinic.phone;
    _emailController.text = clinic.email;
    _websiteController.text = clinic.website ?? '';
    _instagramController.text = clinic.instagram ?? '';
    _specializationsController.text = clinic.specializations;
    _bioController.text = clinic.bio;
    _logoUrl = clinic.logo; // Store existing logo URL
    if (clinic.vetProfile != null) {
      _vetNameController.text = clinic.vetProfile!.vetName;
      _degreesController.text = clinic.vetProfile!.degrees;
      _certificationsController.text = clinic.vetProfile!.certifications;
    }
  }

  // Validate all fields
  bool _validateFields() {
    bool isValid = true;

    // Clear previous errors
    _fieldErrors.forEach((key, _) => _fieldErrors[key] = null);

    // Validate clinic name
    if (_nameController.text.isEmpty) {
      _fieldErrors['name'] = 'Clinic name is required';
      isValid = false;
    }

    // Validate city
    if (_cityController.text.isEmpty) {
      _fieldErrors['city'] = 'City is required';
      isValid = false;
    }

    // Validate address
    if (_addressController.text.isEmpty) {
      _fieldErrors['address'] = 'Address is required';
      isValid = false;
    }

    // Validate phone (basic format check)
    if (_phoneController.text.isEmpty) {
      _fieldErrors['phone'] = 'Phone is required';
      isValid = false;
    } else if (_phoneController.text.length < 10) {
      _fieldErrors['phone'] = 'Phone must be at least 10 digits';
      isValid = false;
    }

    // Validate email
    if (_emailController.text.isEmpty) {
      _fieldErrors['email'] = 'Email is required';
      isValid = false;
    } else if (!_isValidEmail(_emailController.text)) {
      _fieldErrors['email'] = 'Please enter a valid email address';
      isValid = false;
    }

    // Website is optional but validate format if provided
    if (_websiteController.text.isNotEmpty &&
        !_isValidUrl(_websiteController.text)) {
      _fieldErrors['website'] = 'Please enter a valid URL (e.g., https://example.com)';
      isValid = false;
    }

    // Instagram is optional - no validation needed

    // Validate specializations
    if (_specializationsController.text.isEmpty) {
      _fieldErrors['specializations'] = 'Specializations are required';
      isValid = false;
    }

    // Validate bio
    if (_bioController.text.isEmpty) {
      _fieldErrors['bio'] = 'Clinic bio is required';
      isValid = false;
    } else if (_bioController.text.length < 10) {
      _fieldErrors['bio'] = 'Bio must be at least 10 characters';
      isValid = false;
    }

    // Vet fields are optional - no validation needed for vetName, degrees, certifications

    return isValid;
  }

  // Email validation helper
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // URL validation helper
  bool _isValidUrl(String url) {
    try {
      Uri.parse(url);
      return url.startsWith('http://') || url.startsWith('https://');
    } catch (_) {
      return false;
    }
  }

  // Pick logo image from device
  Future<void> _pickLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _logoFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
    super.dispose();
  }

  Future<void> _saveClinic() async {
    // Validate all fields first
    if (!_validateFields()) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors below'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedClinic = _clinic!.copyWith(
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        instagram: _instagramController.text.trim(),
        specializations: _specializationsController.text.trim(),
        bio: _bioController.text.trim(),
      );

      // Update clinic - the ClinicService already handles parsing
      // No need to parse response here since API doesn't return full clinic object
      await _clinicService.updateClinic(
        widget.clinicId,
        updatedClinic.toJson(),
      );

      // Upload logo if a new one was selected
      if (_logoFile != null) {
        await _clinicService.uploadClinicLogo(widget.clinicId, _logoFile!);
      }

      // Update vet profile if available
      if (_clinic!.vetProfile != null) {
        final vetProfileData = {
          'vet_name': _vetNameController.text.trim(),
          'degrees': _degreesController.text.trim(),
          'certifications': _certificationsController.text.trim(),
        };
        await _clinicService.updateVetProfile(widget.clinicId, vetProfileData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clinic profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: true,
          centerTitle: true,
          title: const Text(
            'Edit Clinic Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_clinic == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: true,
          title: const Text('Edit Clinic Profile'),
        ),
        body: const Center(child: Text('Failed to load clinic data')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        centerTitle: true,
        title: Text(
          'Edit ${widget.clinicName}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clinic Basic Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Clinic Name',
                      hint: 'Enter clinic name',
                      icon: Icons.store_outlined,
                      fieldKey: 'name',
                      isRequired: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'Enter city',
                      icon: Icons.location_city_outlined,
                      fieldKey: 'city',
                      isRequired: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter address',
                      icon: Icons.location_on_outlined,
                      fieldKey: 'address',
                      isRequired: true,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Logo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinic Logo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Logo preview
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFEBEBEB),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFF5F5F5),
                        ),
                        child: _logoFile != null
                            ? Image.file(
                                _logoFile!,
                                fit: BoxFit.cover,
                              )
                            : _logoUrl != null && _logoUrl!.isNotEmpty
                                ? Image.network(
                                    _logoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 40,
                                          color: Color(0xFFCCCCCC),
                                        ),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 40,
                                      color: Color(0xFFCCCCCC),
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _pickLogo,
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Change Logo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF26B5A4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (_logoFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _logoFile = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Remove New Logo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Contact Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter phone number',
                      icon: Icons.phone_outlined,
                      fieldKey: 'phone',
                      isRequired: true,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter email address',
                      icon: Icons.email_outlined,
                      fieldKey: 'email',
                      isRequired: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _websiteController,
                      label: 'Website',
                      hint: 'Enter website URL',
                      icon: Icons.public_outlined,
                      fieldKey: 'website',
                      isRequired: false,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _instagramController,
                      label: 'Instagram',
                      hint: 'Enter Instagram handle',
                      icon: Icons.camera_alt_outlined,
                      fieldKey: 'instagram',
                      isRequired: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Clinic Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinic Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _specializationsController,
                      label: 'Specializations',
                      hint: 'e.g., Cats, Dogs, Nutrition',
                      icon: Icons.pets_outlined,
                      fieldKey: 'specializations',
                      isRequired: true,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _bioController,
                      label: 'Clinic Bio',
                      hint: 'Describe your clinic',
                      icon: Icons.description_outlined,
                      fieldKey: 'bio',
                      isRequired: true,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Veterinarian Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Veterinarian Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _vetNameController,
                      label: 'Vet Name',
                      hint: 'Enter veterinarian name',
                      icon: Icons.person_outlined,
                      fieldKey: 'vetName',
                      isRequired: false,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _degreesController,
                      label: 'Degrees',
                      hint: 'e.g., DVM, MSc Nutrition',
                      icon: Icons.school_outlined,
                      fieldKey: 'degrees',
                      isRequired: false,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _certificationsController,
                      label: 'Certifications',
                      hint: 'e.g., AVMA, CVMA',
                      icon: Icons.card_membership_outlined,
                      fieldKey: 'certifications',
                      isRequired: false,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveClinic,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26B5A4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String fieldKey,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final hasError = _fieldErrors[fieldKey] != null;
    final errorMessage = _fieldErrors[fieldKey];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: (_) {
            // Clear error when user starts typing
            setState(() {
              _fieldErrors[fieldKey] = null;
            });
          },
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF7F8C8D),
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : const Color(0xFFEBEBEB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : const Color(0xFFEBEBEB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : const Color(0xFF26B5A4),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            errorText: null, // We're handling errors ourselves below
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
