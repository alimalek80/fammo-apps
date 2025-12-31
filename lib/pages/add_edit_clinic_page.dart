import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/paw_loading_indicator.dart';
import '../models/clinic.dart';
import '../services/clinic_service.dart';

class AddEditClinicPage extends StatefulWidget {
  final Clinic? clinic; // null for add, non-null for edit

  const AddEditClinicPage({super.key, this.clinic});

  @override
  State<AddEditClinicPage> createState() => _AddEditClinicPageState();
}

class _AddEditClinicPageState extends State<AddEditClinicPage> {
  final _formKey = GlobalKey<FormState>();
  final ClinicService _clinicService = ClinicService();
  
  // Controllers
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _instagramController = TextEditingController();
  final _specializationsController = TextEditingController();
  final _bioController = TextEditingController();
  final _vetNameController = TextEditingController();
  final _degreesController = TextEditingController();
  final _certificationsController = TextEditingController();

  bool _isLoading = false;
  bool _clinicEoi = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  List<WorkingHoursSchedule> _workingHours = [];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _initializeWorkingHours();
    if (widget.clinic != null) {
      _loadClinicData();
    }
  }

  void _initializeWorkingHours() {
    _workingHours = List.generate(7, (index) {
      return WorkingHoursSchedule(
        dayOfWeek: index,
        dayName: WorkingHoursSchedule.getDayName(index),
        isClosed: index == 6, // Sunday closed by default
        openTime: index != 6 ? '09:00' : null,
        closeTime: index != 6 ? '18:00' : null,
      );
    });
  }

  void _loadClinicData() {
    final clinic = widget.clinic!;
    _nameController.text = clinic.name;
    _cityController.text = clinic.city;
    _addressController.text = clinic.address;
    _latitudeController.text = clinic.latitude ?? '';
    _longitudeController.text = clinic.longitude ?? '';
    _phoneController.text = clinic.phone;
    _emailController.text = clinic.email;
    _websiteController.text = clinic.website ?? '';
    _instagramController.text = clinic.instagram ?? '';
    _specializationsController.text = clinic.specializations;
    _bioController.text = clinic.bio;
    _clinicEoi = clinic.clinicEoi;

    if (clinic.vetProfile != null) {
      _vetNameController.text = clinic.vetProfile!.vetName;
      _degreesController.text = clinic.vetProfile!.degrees;
      _certificationsController.text = clinic.vetProfile!.certifications;
    }

    if (clinic.workingHoursSchedule != null && clinic.workingHoursSchedule!.isNotEmpty) {
      _workingHours = clinic.workingHoursSchedule!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _saveClinic() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final clinicData = {
        'name': _nameController.text,
        'city': _cityController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'specializations': _specializationsController.text,
        'bio': _bioController.text,
        'clinic_eoi': _clinicEoi,
      };

      if (_latitudeController.text.isNotEmpty) {
        clinicData['latitude'] = _latitudeController.text;
      }
      if (_longitudeController.text.isNotEmpty) {
        clinicData['longitude'] = _longitudeController.text;
      }
      if (_websiteController.text.isNotEmpty) {
        clinicData['website'] = _websiteController.text;
      }
      if (_instagramController.text.isNotEmpty) {
        clinicData['instagram'] = _instagramController.text;
      }

      // Add vet profile data if provided
      if (_vetNameController.text.isNotEmpty) {
        clinicData['vet_name'] = _vetNameController.text;
        clinicData['degrees'] = _degreesController.text;
        clinicData['certifications'] = _certificationsController.text;
      }

      Clinic savedClinic;
      if (widget.clinic == null) {
        // Register new clinic
        savedClinic = await _clinicService.registerClinic(clinicData);
      } else {
        // Update existing clinic
        await _clinicService.updateClinic(widget.clinic!.id, clinicData);
        savedClinic = widget.clinic!; // Use existing clinic for ID
      }

      // Update working hours
      if (_workingHours.isNotEmpty) {
        final workingHoursData = _workingHours.map((wh) => wh.toJson()).toList();
        await _clinicService.updateWorkingHours(savedClinic.id, workingHoursData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.clinic == null
                ? 'Clinic registered successfully! Please check your email for confirmation.'
                : 'Clinic updated successfully!'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clinic == null ? 'Register Clinic' : 'Edit Clinic'),
      ),
      body: _isLoading
          ? const Center(child: PawLoadingIndicator())
          : Form(
              key: _formKey,
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 3) {
                    setState(() {
                      _currentStep += 1;
                    });
                  } else {
                    _saveClinic();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() {
                      _currentStep -= 1;
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
                steps: [
                  Step(
                    title: const Text('Basic Information'),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                    content: _buildBasicInfoStep(),
                  ),
                  Step(
                    title: const Text('Contact & Location'),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                    content: _buildContactStep(),
                  ),
                  Step(
                    title: const Text('Veterinarian Info'),
                    isActive: _currentStep >= 2,
                    state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                    content: _buildVetProfileStep(),
                  ),
                  Step(
                    title: const Text('Working Hours'),
                    isActive: _currentStep >= 3,
                    state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                    content: _buildWorkingHoursStep(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      children: [
        // Logo/Image
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : widget.clinic?.logo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.clinic!.logo!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade600),
                            const SizedBox(height: 8),
                            Text('Add Logo', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Clinic Name *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.local_hospital),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter clinic name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _specializationsController,
          decoration: const InputDecoration(
            labelText: 'Specializations',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.medical_services),
            hintText: 'e.g., Dogs, Cats, Birds',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(
            labelText: 'About the Clinic',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            hintText: 'Brief description of your clinic',
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('EOI Partner Clinic'),
          subtitle: const Text('Check if you are part of the EOI program'),
          value: _clinicEoi,
          onChanged: (value) {
            setState(() {
              _clinicEoi = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildContactStep() {
    return Column(
      children: [
        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(
            labelText: 'City',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.place),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _latitudeController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _longitudeController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _websiteController,
          decoration: const InputDecoration(
            labelText: 'Website',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.language),
            hintText: 'https://example.com',
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _instagramController,
          decoration: const InputDecoration(
            labelText: 'Instagram',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.camera_alt),
            hintText: '@username',
          ),
        ),
      ],
    );
  }

  Widget _buildVetProfileStep() {
    return Column(
      children: [
        const Text(
          'Optional: Add veterinarian information',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _vetNameController,
          decoration: const InputDecoration(
            labelText: 'Veterinarian Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
            hintText: 'Dr. Jane Smith',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _degreesController,
          decoration: const InputDecoration(
            labelText: 'Degrees',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.school),
            hintText: 'DVM, PhD',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _certificationsController,
          decoration: const InputDecoration(
            labelText: 'Certifications',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.verified_user),
            hintText: 'Board Certified in Surgery',
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildWorkingHoursStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Set your clinic working hours',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._workingHours.map((wh) {
          return _buildWorkingHourRow(wh);
        }),
      ],
    );
  }

  Widget _buildWorkingHourRow(WorkingHoursSchedule wh) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  wh.dayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: !wh.isClosed,
                  onChanged: (value) {
                    setState(() {
                      final index = _workingHours.indexWhere((w) => w.dayOfWeek == wh.dayOfWeek);
                      _workingHours[index] = WorkingHoursSchedule(
                        id: wh.id,
                        dayOfWeek: wh.dayOfWeek,
                        dayName: wh.dayName,
                        isClosed: !value,
                        openTime: value ? (wh.openTime ?? '09:00') : null,
                        closeTime: value ? (wh.closeTime ?? '18:00') : null,
                      );
                    });
                  },
                ),
              ],
            ),
            if (!wh.isClosed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeField(
                      label: 'Open',
                      value: wh.openTime ?? '09:00',
                      onChanged: (value) {
                        setState(() {
                          final index = _workingHours.indexWhere((w) => w.dayOfWeek == wh.dayOfWeek);
                          _workingHours[index] = WorkingHoursSchedule(
                            id: wh.id,
                            dayOfWeek: wh.dayOfWeek,
                            dayName: wh.dayName,
                            isClosed: wh.isClosed,
                            openTime: value,
                            closeTime: wh.closeTime,
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeField(
                      label: 'Close',
                      value: wh.closeTime ?? '18:00',
                      onChanged: (value) {
                        setState(() {
                          final index = _workingHours.indexWhere((w) => w.dayOfWeek == wh.dayOfWeek);
                          _workingHours[index] = WorkingHoursSchedule(
                            id: wh.id,
                            dayOfWeek: wh.dayOfWeek,
                            dayName: wh.dayName,
                            isClosed: wh.isClosed,
                            openTime: wh.openTime,
                            closeTime: value,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Closed',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.access_time),
      ),
      keyboardType: TextInputType.datetime,
      onChanged: onChanged,
    );
  }
}
