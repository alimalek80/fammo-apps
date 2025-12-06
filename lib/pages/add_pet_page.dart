import 'package:flutter/material.dart';
import '../services/pet_service.dart';
import '../models/pet_models.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _petService = PetService();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageYearsController = TextEditingController();
  final _ageMonthsController = TextEditingController();
  final _ageWeeksController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _loadingOptions = true;
  int _currentStep = 0;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Form options
  List<PetType> _petTypes = [];
  List<Gender> _genders = [];
  List<Breed> _breeds = [];
  List<AgeCategory> _ageCategories = [];
  List<FoodType> _foodTypes = [];
  List<FoodFeeling> _foodFeelings = [];
  List<FoodImportance> _foodImportance = [];
  List<BodyType> _bodyTypes = [];
  List<ActivityLevel> _activityLevels = [];
  List<FoodAllergy> _foodAllergies = [];
  List<HealthIssue> _healthIssues = [];
  List<TreatFrequency> _treatFrequencies = [];

  // Form data
  final PetFormData _formData = PetFormData();

  @override
  void initState() {
    super.initState();
    _loadFormOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _ageYearsController.dispose();
    _ageMonthsController.dispose();
    _ageWeeksController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadFormOptions() async {
    setState(() => _loadingOptions = true);

    try {
      // Load all options in parallel
      final results = await Future.wait([
        _petService.getPetTypes(),
        _petService.getGenders(),
        _petService.getFoodTypes(),
        _petService.getFoodFeelings(),
        _petService.getFoodImportance(),
        _petService.getBodyTypes(),
        _petService.getActivityLevels(),
        _petService.getFoodAllergies(),
        _petService.getHealthIssues(),
        _petService.getTreatFrequencies(),
      ]);

      setState(() {
        _petTypes = results[0] as List<PetType>;
        _genders = results[1] as List<Gender>;
        _foodTypes = results[2] as List<FoodType>;
        _foodFeelings = results[3] as List<FoodFeeling>;
        _foodImportance = results[4] as List<FoodImportance>;
        _bodyTypes = results[5] as List<BodyType>;
        _activityLevels = results[6] as List<ActivityLevel>;
        _foodAllergies = results[7] as List<FoodAllergy>;
        _healthIssues = results[8] as List<HealthIssue>;
        _treatFrequencies = results[9] as List<TreatFrequency>;
        _loadingOptions = false;
      });
    } catch (e) {
      print('Error loading form options: $e');
      setState(() => _loadingOptions = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      // Show bottom sheet to choose camera or gallery
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Color(0xFF4ECDC4),
                      ),
                    ),
                    title: const Text(
                      'Take Photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: Color(0xFF4ECDC4),
                      ),
                    ),
                    title: const Text(
                      'Choose from Gallery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
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
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<void> _onPetTypeSelected(int? petTypeId) async {
    if (petTypeId == null) return;

    setState(() {
      _formData.petType = petTypeId;
      _formData.breed = null;
      _formData.ageCategory = null;
    });

    // Load breeds and age categories for selected pet type
    try {
      final results = await Future.wait([
        _petService.getBreeds(petTypeId: petTypeId),
        _petService.getAgeCategories(petTypeId: petTypeId),
      ]);

      setState(() {
        _breeds = results[0] as List<Breed>;
        _ageCategories = results[1] as List<AgeCategory>;
      });
    } catch (e) {
      print('Error loading breeds and age categories: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      _formData.name = _nameController.text;
      if (_weightController.text.isNotEmpty) {
        _formData.weight = double.tryParse(_weightController.text);
      }
      if (_ageYearsController.text.isNotEmpty) {
        _formData.ageYears = int.tryParse(_ageYearsController.text);
      }
      if (_ageMonthsController.text.isNotEmpty) {
        _formData.ageMonths = int.tryParse(_ageMonthsController.text);
      }
      if (_ageWeeksController.text.isNotEmpty) {
        _formData.ageWeeks = int.tryParse(_ageWeeksController.text);
      }

      final pet = await _petService.createPet(_formData, imageFile: _selectedImage);

      if (!mounted) return;

      if (pet != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet added successfully!')),
        );
        Navigator.pop(context, true); // Return true to refresh pet list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add pet. Please try again.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Pet',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loadingOptions
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4ECDC4)))
          : Column(
              children: [
                // Progress Indicator
                _buildProgressIndicator(),
                
                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: _buildCurrentStep(),
                      ),
                    ),
                  ),
                ),
                
                // Bottom Button
                _buildBottomButton(),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildProgressSegment(0),
          const SizedBox(width: 8),
          _buildProgressSegment(1),
          const SizedBox(width: 8),
          _buildProgressSegment(2),
        ],
      ),
    );
  }

  Widget _buildProgressSegment(int step) {
    final isActive = step <= _currentStep;
    return Expanded(
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4ECDC4) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Photo
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
                if (_selectedImage != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Species
        const Text(
          'Species',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSpeciesCard(
                icon: '🐕',
                label: 'Dog',
                isSelected: _formData.petType == 1,
                onTap: () => _onPetTypeSelected(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSpeciesCard(
                icon: '😺',
                label: 'Cat',
                isSelected: _formData.petType == 2,
                onTap: () => _onPetTypeSelected(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Pet Name
        const Text(
          'Pet Name',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'e.g., Luna',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter pet name';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        // Breed
        const Text(
          'Breed',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        if (_formData.petType != null && _breeds.isNotEmpty)
          DropdownButtonFormField<int>(
            value: _formData.breed,
            decoration: InputDecoration(
              hintText: 'e.g., Golden Retriever',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: _breeds.map((breed) {
              return DropdownMenuItem(
                value: breed.id,
                child: Text(breed.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _formData.breed = value);
            },
          )
        else
          TextFormField(
            controller: _breedController,
            decoration: InputDecoration(
              hintText: 'e.g., Golden Retriever',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _formData.unknownBreed,
          onChanged: (value) {
            setState(() {
              _formData.unknownBreed = value ?? false;
              if (_formData.unknownBreed) {
                _formData.breed = null;
              }
            });
          },
          title: const Text(
            'Unknown/Mixed Breed',
            style: TextStyle(fontSize: 14),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: const Color(0xFF4ECDC4),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Age Category
        if (_ageCategories.isNotEmpty) ...[
          const Text(
            'Age Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _ageCategories.map((category) {
              final isSelected = _formData.ageCategory == category.id;
              return _buildChipButton(
                label: category.name,
                isSelected: isSelected,
                onTap: () => setState(() => _formData.ageCategory = category.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Age - Conditional based on age category
        const Text(
          'Age',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        if (_formData.ageCategory != null &&
            _ageCategories.any((cat) => cat.id == _formData.ageCategory && cat.order == 0))
          // Show Months and Weeks for order 0 (Puppy/Kitten)
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _ageMonthsController.text.isNotEmpty 
                      ? int.tryParse(_ageMonthsController.text) 
                      : null,
                  decoration: InputDecoration(
                    labelText: _ageMonthsController.text.isNotEmpty ? 'Months' : null,
                    labelStyle: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF4ECDC4),
                    ),
                    hintText: 'Months',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: List.generate(13, (index) => index)
                      .map((month) => DropdownMenuItem(
                            value: month,
                            child: Text(month.toString()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _ageMonthsController.text = value?.toString() ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _ageWeeksController.text.isNotEmpty 
                      ? int.tryParse(_ageWeeksController.text) 
                      : null,
                  decoration: InputDecoration(
                    labelText: _ageWeeksController.text.isNotEmpty ? 'Weeks' : null,
                    labelStyle: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF4ECDC4),
                    ),
                    hintText: 'Weeks',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: List.generate(53, (index) => index)
                      .map((week) => DropdownMenuItem(
                            value: week,
                            child: Text(week.toString()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _ageWeeksController.text = value?.toString() ?? '';
                    });
                  },
                ),
              ),
            ],
          )
        else
          // Show Years and Months for other categories
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _ageYearsController.text.isNotEmpty 
                      ? int.tryParse(_ageYearsController.text) 
                      : null,
                  decoration: InputDecoration(
                    labelText: _ageYearsController.text.isNotEmpty ? 'Years' : null,
                    labelStyle: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF4ECDC4),
                    ),
                    hintText: 'Years',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: List.generate(101, (index) => index)
                      .map((year) => DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _ageYearsController.text = value?.toString() ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _ageMonthsController.text.isNotEmpty 
                      ? int.tryParse(_ageMonthsController.text) 
                      : null,
                  decoration: InputDecoration(
                    labelText: _ageMonthsController.text.isNotEmpty ? 'Months' : null,
                    labelStyle: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF4ECDC4),
                    ),
                    hintText: 'Months',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: List.generate(13, (index) => index)
                      .map((month) => DropdownMenuItem(
                            value: month,
                            child: Text(month.toString()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _ageMonthsController.text = value?.toString() ?? '';
                    });
                  },
                ),
              ),
            ],
          ),
        const SizedBox(height: 24),

        // Weight
        const Text(
          'Weight (kg)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'e.g., 25',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Gender
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _genders.take(2).map((gender) {
            final isSelected = _formData.gender == gender.id;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: gender.id == _genders.first.id ? 12 : 0,
                ),
                child: _buildOptionButton(
                  label: gender.name,
                  isSelected: isSelected,
                  onTap: () => setState(() => _formData.gender = gender.id),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _formData.neutered,
          onChanged: (value) {
            setState(() => _formData.neutered = value ?? false);
          },
          title: const Text(
            'Neutered/Spayed',
            style: TextStyle(fontSize: 14),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: const Color(0xFF4ECDC4),
        ),
        const SizedBox(height: 24),

        // Activity Level
        const Text(
          'Activity Level',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _activityLevels.map((level) {
            final isSelected = _formData.activityLevel == level.id;
            return _buildActivityCard(
              label: level.name,
              description: level.description,
              isSelected: isSelected,
              onTap: () => setState(() => _formData.activityLevel = level.id),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Body Type
        const Text(
          'Body Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _bodyTypes.map((type) {
            final isSelected = _formData.bodyType == type.id;
            return _buildChipButton(
              label: type.name,
              isSelected: isSelected,
              onTap: () => setState(() => _formData.bodyType = type.id),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Current Diet (Food Types)
        const Text(
          'Current Diet',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _foodTypes.map((type) {
            final isSelected = _formData.foodTypes.contains(type.id);
            return _buildChipButton(
              label: type.name,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _formData.foodTypes.remove(type.id);
                  } else {
                    _formData.foodTypes.add(type.id);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Food Preference - How they feel about food
        if (_foodFeelings.isNotEmpty) ...[
          const Text(
            'Food Preference',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _foodFeelings.map((feeling) {
              final isSelected = _formData.foodFeeling == feeling.id;
              return _buildChipButton(
                label: feeling.name,
                isSelected: isSelected,
                onTap: () => setState(() => _formData.foodFeeling = feeling.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // What's important about their food
        if (_foodImportance.isNotEmpty) ...[
          const Text(
            'Food Importance',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _foodImportance.map((importance) {
              final isSelected = _formData.foodImportance == importance.id;
              return _buildChipButton(
                label: importance.name,
                isSelected: isSelected,
                onTap: () => setState(() => _formData.foodImportance = importance.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Treats (Treat Frequency)
        if (_treatFrequencies.isNotEmpty) ...[
          const Text(
            'Treats',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _treatFrequencies.map((frequency) {
              final isSelected = _formData.treatFrequency == frequency.id;
              return _buildChipButton(
                label: frequency.name,
                isSelected: isSelected,
                onTap: () => setState(() => _formData.treatFrequency = frequency.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Food Allergies
        if (_foodAllergies.isNotEmpty) ...[
          const Text(
            'Food Allergies',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _foodAllergies.map((allergy) {
              final isSelected = _formData.foodAllergies.contains(allergy.id);
              return _buildChipButton(
                label: allergy.name,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _formData.foodAllergies.remove(allergy.id);
                    } else {
                      _formData.foodAllergies.add(allergy.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Health Issues
        if (_healthIssues.isNotEmpty) ...[
          const Text(
            'Health Issues',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _healthIssues.map((issue) {
              final isSelected = _formData.healthIssues.contains(issue.id);
              return _buildChipButton(
                label: issue.name,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _formData.healthIssues.remove(issue.id);
                    } else {
                      _formData.healthIssues.add(issue.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Notes
        const Text(
          'Notes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Any additional notes about your pet...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleButtonPress,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _currentStep == 2 ? 'Save' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeciesCard({
    required String icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4ECDC4) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF4ECDC4) : const Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4ECDC4) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? const Color(0xFF4ECDC4) : const Color(0xFF2C3E50),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 52) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4ECDC4) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF4ECDC4) : const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4ECDC4) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? const Color(0xFF4ECDC4) : const Color(0xFF2C3E50),
          ),
        ),
      ),
    );
  }

  void _handleButtonPress() {
    if (_currentStep < 2) {
      if (_currentStep == 0) {
        if (!_formKey.currentState!.validate()) return;
        if (_formData.petType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a species')),
          );
          return;
        }
      }
      setState(() => _currentStep++);
    } else {
      _submitForm();
    }
  }
}
