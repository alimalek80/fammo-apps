import 'package:flutter/material.dart';
import '../services/pet_service.dart';
import '../models/pet_models.dart';
import 'dart:io';

class EditPetPage extends StatefulWidget {
  final Pet pet;

  const EditPetPage({super.key, required this.pet});

  @override
  State<EditPetPage> createState() => _EditPetPageState();
}

class _EditPetPageState extends State<EditPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _petService = PetService();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageYearsController = TextEditingController();
  final _ageMonthsController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _loadingOptions = true;
  int _currentStep = 0;
  File? _selectedImage;

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
  late PetFormData _formData;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
    _loadFormOptions();
  }

  void _initializeFormData() {
    _formData = PetFormData(
      name: widget.pet.name,
      petType: widget.pet.petType,
      gender: widget.pet.gender,
      breed: widget.pet.breed,
      unknownBreed: widget.pet.unknownBreed,
      ageYears: widget.pet.ageYears,
      ageMonths: widget.pet.ageMonths,
      ageWeeks: widget.pet.ageWeeks,
      birthDate: widget.pet.birthDate,
      weight: widget.pet.weight,
      neutered: widget.pet.neutered,
    );

    _nameController.text = widget.pet.name;
    if (widget.pet.weight != null) {
      _weightController.text = widget.pet.weight.toString();
    }
    if (widget.pet.ageYears != null) {
      _ageYearsController.text = widget.pet.ageYears.toString();
    }
    if (widget.pet.ageMonths != null) {
      _ageMonthsController.text = widget.pet.ageMonths.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _ageYearsController.dispose();
    _ageMonthsController.dispose();
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
      });

      // Load breeds and age categories for current pet type
      if (_formData.petType != null) {
        await _loadPetTypeRelatedData(_formData.petType!);
      }

      setState(() => _loadingOptions = false);
    } catch (e) {
      print('Error loading form options: $e');
      setState(() => _loadingOptions = false);
    }
  }

  Future<void> _loadPetTypeRelatedData(int petTypeId) async {
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

  Future<void> _onPetTypeSelected(int? petTypeId) async {
    if (petTypeId == null) return;

    setState(() {
      _formData.petType = petTypeId;
      _formData.breed = null;
      _formData.ageCategory = null;
    });

    await _loadPetTypeRelatedData(petTypeId);
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

      final pet = await _petService.updatePet(widget.pet.id, _formData);

      if (!mounted) return;

      if (pet != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet updated successfully!')),
        );
        Navigator.pop(context, true); // Return true to refresh pet list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update pet. Please try again.')),
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
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Pet',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loadingOptions
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Pet Name
                  _buildSectionTitle('Basic Information'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Pet Name',
                    hint: 'Enter pet name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter pet name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pet Type
                  _buildDropdown<int>(
                    label: 'Pet Type',
                    value: _formData.petType,
                    items: _petTypes.map((type) {
                      return DropdownMenuItem(
                        value: type.id,
                        child: Text(type.name),
                      );
                    }).toList(),
                    onChanged: _onPetTypeSelected,
                    validator: (value) {
                      if (value == null) return 'Please select pet type';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Gender
                  _buildDropdown<int>(
                    label: 'Gender',
                    value: _formData.gender,
                    items: _genders.map((gender) {
                      return DropdownMenuItem(
                        value: gender.id,
                        child: Text(gender.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _formData.gender = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Unknown Breed Checkbox
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
                    title: const Text('Unknown/Mixed Breed'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Breed (if not unknown)
                  if (!_formData.unknownBreed && _breeds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDropdown<int>(
                      label: 'Breed',
                      value: _formData.breed,
                      items: _breeds.map((breed) {
                        return DropdownMenuItem(
                          value: breed.id,
                          child: Text(breed.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _formData.breed = value);
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Age Category
                  if (_ageCategories.isNotEmpty) ...[
                    _buildDropdown<int>(
                      label: 'Age Category',
                      value: _formData.ageCategory,
                      items: _ageCategories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _formData.ageCategory = value);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Age
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _ageYearsController,
                          label: 'Age (Years)',
                          hint: '0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _ageMonthsController,
                          label: 'Age (Months)',
                          hint: '0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Weight
                  _buildTextField(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    hint: 'Enter weight',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Neutered
                  CheckboxListTile(
                    value: _formData.neutered,
                    onChanged: (value) {
                      setState(() => _formData.neutered = value ?? false);
                    },
                    title: const Text('Neutered/Spayed'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),

                  // Food & Health Section
                  _buildSectionTitle('Food & Health'),
                  const SizedBox(height: 12),

                  // Food Types (Multi-select)
                  _buildMultiSelectChips(
                    label: 'Food Types',
                    options: _foodTypes,
                    selectedIds: _formData.foodTypes,
                    onChanged: (id, selected) {
                      setState(() {
                        if (selected) {
                          _formData.foodTypes.add(id);
                        } else {
                          _formData.foodTypes.remove(id);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Food Feeling
                  if (_foodFeelings.isNotEmpty)
                    _buildDropdown<int>(
                      label: 'How does your pet feel about food?',
                      value: _formData.foodFeeling,
                      items: _foodFeelings.map((feeling) {
                        return DropdownMenuItem(
                          value: feeling.id,
                          child: Text(feeling.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _formData.foodFeeling = value);
                      },
                    ),
                  const SizedBox(height: 16),

                  // Food Importance
                  if (_foodImportance.isNotEmpty)
                    _buildDropdown<int>(
                      label: 'Food Importance',
                      value: _formData.foodImportance,
                      items: _foodImportance.map((importance) {
                        return DropdownMenuItem(
                          value: importance.id,
                          child: Text(importance.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _formData.foodImportance = value);
                      },
                    ),
                  const SizedBox(height: 16),

                  // Body Type
                  if (_bodyTypes.isNotEmpty)
                    _buildDropdown<int>(
                      label: 'Body Type',
                      value: _formData.bodyType,
                      items: _bodyTypes.map((type) {
                        return DropdownMenuItem(
                          value: type.id,
                          child: Text(type.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _formData.bodyType = value);
                      },
                    ),
                  const SizedBox(height: 16),

                  // Activity Level
                  if (_activityLevels.isNotEmpty)
                    _buildDropdown<int>(
                      label: 'Activity Level',
                      value: _formData.activityLevel,
                      items: _activityLevels.map((level) {
                        return DropdownMenuItem(
                          value: level.id,
                          child: Text(level.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _formData.activityLevel = value);
                      },
                    ),
                  const SizedBox(height: 16),

                  // Food Allergies (Multi-select)
                  _buildMultiSelectChips(
                    label: 'Food Allergies',
                    options: _foodAllergies,
                    selectedIds: _formData.foodAllergies,
                    onChanged: (id, selected) {
                      setState(() {
                        if (selected) {
                          _formData.foodAllergies.add(id);
                        } else {
                          _formData.foodAllergies.remove(id);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Health Issues (Multi-select)
                  _buildMultiSelectChips(
                    label: 'Health Issues',
                    options: _healthIssues,
                    selectedIds: _formData.healthIssues,
                    onChanged: (id, selected) {
                      setState(() {
                        if (selected) {
                          _formData.healthIssues.add(id);
                        } else {
                          _formData.healthIssues.remove(id);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Treat Frequency
                  if (_treatFrequencies.isNotEmpty)
                    _buildDropdown<int>(
                      label: 'Treat Frequency',
                      value: _formData.treatFrequency,
                      items: _treatFrequencies.map((freq) {
                        return DropdownMenuItem(
                          value: freq.id,
                          child: Text(freq.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _formData.treatFrequency = value);
                      },
                    ),
                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3E50),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
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
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
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
      ],
    );
  }

  Widget _buildMultiSelectChips<T>({
    required String label,
    required List<T> options,
    required List<int> selectedIds,
    required void Function(int id, bool selected) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final id = (option as dynamic).id as int;
            final name = (option as dynamic).name as String;
            final isSelected = selectedIds.contains(id);

            return FilterChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (selected) => onChanged(id, selected),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF4ECDC4).withOpacity(0.3),
              checkmarkColor: const Color(0xFF2C3E50),
              labelStyle: TextStyle(
                color: isSelected
                    ? const Color(0xFF2C3E50)
                    : const Color(0xFF7F8C8D),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
