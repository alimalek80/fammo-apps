import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_models.dart';
import '../models/clinic.dart';
import '../services/appointment_service.dart';
import '../services/pet_service.dart';
import '../widgets/paw_loading_indicator.dart';

class BookAppointmentPage extends StatefulWidget {
  final Clinic clinic;

  const BookAppointmentPage({super.key, required this.clinic});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final PetService _petService = PetService();
  final TextEditingController _reasonTextController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // State
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';
  int _currentStep = 0;

  // Data
  List<Pet> _pets = [];
  List<AppointmentReason> _reasons = [];
  List<AvailableDate> _availableDates = [];
  List<String> _availableSlots = [];

  // Selections
  Pet? _selectedPet;
  AppointmentReason? _selectedReason;
  AvailableDate? _selectedDate;
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _reasonTextController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load pets and reasons in parallel
      final results = await Future.wait([
        _petService.getUserPets(),
        _appointmentService.getAppointmentReasons(),
        _appointmentService.getAvailableDates(widget.clinic.id, days: 30),
      ]);

      setState(() {
        _pets = results[0] as List<Pet>;
        _reasons = results[1] as List<AppointmentReason>;
        final datesResponse = results[2] as AvailableDatesResponse;
        _availableDates = datesResponse.availableDates;
        _isLoading = false;
      });

      if (_pets.isEmpty) {
        _showNoPetsDialog();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  void _showNoPetsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('No Pets Found'),
        content: const Text(
          'You need to add a pet before booking an appointment. '
          'Would you like to add a pet now?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              // Navigate to add pet page - you can implement this navigation
            },
            child: const Text('Add Pet'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadTimeSlots(String date) async {
    setState(() {
      _availableSlots = [];
      _selectedTime = null;
    });

    try {
      final slotsResponse = await _appointmentService.getAvailableSlots(
        widget.clinic.id,
        date,
      );
      setState(() {
        _availableSlots = slotsResponse.slots;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load time slots: $e')),
        );
      }
    }
  }

  Future<void> _submitAppointment() async {
    if (_selectedPet == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = CreateAppointmentRequest(
        clinic: widget.clinic.id,
        pet: _selectedPet!.id,
        appointmentDate: _selectedDate!.date,
        appointmentTime: _selectedTime!,
        reason: _selectedReason?.id,
        reasonText: _reasonTextController.text.isNotEmpty
            ? _reasonTextController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final response = await _appointmentService.createAppointment(request);

      if (mounted) {
        _showSuccessDialog(response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(CreateAppointmentResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Color(0xFF4CAF50),
          size: 64,
        ),
        title: const Text('Appointment Booked!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your appointment has been submitted successfully.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Reference Code',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    response.referenceCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF26B5A4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The clinic will review your request and confirm your appointment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true); // Return true to indicate success
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26B5A4),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5F3),
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: const Color(0xFF26B5A4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: PawLoadingIndicator())
          : _errorMessage.isNotEmpty
          ? _buildErrorView()
          : _buildContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Clinic info header
        _buildClinicHeader(),

        // Steps indicator
        _buildStepsIndicator(),

        // Step content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildCurrentStep(),
          ),
        ),

        // Navigation buttons
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildClinicHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Color(0xFF26B5A4)),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.clinic.logo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.clinic.logo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.local_hospital,
                        color: Color(0xFF26B5A4),
                      ),
                    ),
                  )
                : const Icon(Icons.local_hospital, color: Color(0xFF26B5A4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.clinic.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.clinic.address.isNotEmpty
                      ? widget.clinic.address
                      : widget.clinic.city,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsIndicator() {
    final steps = ['Pet', 'Date & Time', 'Reason', 'Confirm'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(steps.length, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          return Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF26B5A4) : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: const Color(0xFF26B5A4), width: 3)
                      : null,
                ),
                child: Center(
                  child: isActive && index < _currentStep
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? const Color(0xFF26B5A4) : Colors.grey[600],
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPetSelection();
      case 1:
        return _buildDateTimeSelection();
      case 2:
        return _buildReasonSelection();
      case 3:
        return _buildConfirmation();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPetSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select your pet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose which pet this appointment is for',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (_pets.isEmpty)
          _buildEmptyPetsMessage()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pets.length,
            itemBuilder: (context, index) {
              final pet = _pets[index];
              final isSelected = _selectedPet?.id == pet.id;
              return _buildPetCard(pet, isSelected);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyPetsMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.pets, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No pets found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You need to add a pet before booking an appointment',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Pet pet, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPet = pet),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF26B5A4) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: pet.image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        pet.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.pets,
                          color: Color(0xFF26B5A4),
                          size: 30,
                        ),
                      ),
                    )
                  : const Icon(Icons.pets, color: Color(0xFF26B5A4), size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.petTypeDetail?['name'] ?? 'Pet'} • ${pet.displayBreed}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF26B5A4), size: 28)
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey[400],
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select date and time',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose when you would like to visit',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Date selection
        const Text(
          'Available Dates',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),

        if (_availableDates.isEmpty)
          _buildNoAvailableDatesMessage()
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableDates.length,
              itemBuilder: (context, index) {
                final date = _availableDates[index];
                final isSelected = _selectedDate?.date == date.date;
                return _buildDateCard(date, isSelected);
              },
            ),
          ),

        const SizedBox(height: 24),

        // Time selection
        if (_selectedDate != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Times',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Text(
                '${_selectedDate!.openTime} - ${_selectedDate!.closeTime}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_availableSlots.isEmpty)
            _buildLoadingOrNoSlots()
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _availableSlots.map((slot) {
                final isSelected = _selectedTime == slot;
                return _buildTimeChip(slot, isSelected);
              }).toList(),
            ),
        ],
      ],
    );
  }

  Widget _buildNoAvailableDatesMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text(
            'No available dates',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'This clinic has no available dates in the next 30 days',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(AvailableDate date, bool isSelected) {
    final dateObj = DateTime.parse(date.date);
    final dayFormat = DateFormat('EEE');
    final dayNumFormat = DateFormat('d');
    final monthFormat = DateFormat('MMM');

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _selectedTime = null;
        });
        _loadTimeSlots(date.date);
      },
      child: Container(
        width: 75,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF26B5A4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF26B5A4) : Colors.grey[300]!,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayFormat.format(dateObj),
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayNumFormat.format(dateObj),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
            Text(
              monthFormat.format(dateObj),
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOrNoSlots() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.access_time, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No available time slots',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(String time, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTime = time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF26B5A4) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF26B5A4) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2C3E50),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildReasonSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reason for visit',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Help the clinic prepare for your visit',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Reason dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AppointmentReason>(
              value: _selectedReason,
              hint: const Text('Select a reason'),
              isExpanded: true,
              items: _reasons.map((reason) {
                return DropdownMenuItem(
                  value: reason,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reason.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedReason = value),
            ),
          ),
        ),

        if (_selectedReason != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF26B5A4),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedReason!.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Custom reason text
        const Text(
          'Additional details (optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonTextController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe your pet\'s symptoms or concerns...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Notes
        const Text(
          'Notes for the clinic (optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Any special requests or information...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmation() {
    final dateObj = _selectedDate != null
        ? DateTime.parse(_selectedDate!.date)
        : DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(dateObj);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm your appointment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please review the details before submitting',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        // Summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Clinic
              _buildSummaryRow(
                Icons.local_hospital,
                'Clinic',
                widget.clinic.name,
              ),
              const Divider(height: 24),

              // Pet
              _buildSummaryRow(
                Icons.pets,
                'Pet',
                _selectedPet?.name ?? 'Not selected',
              ),
              const Divider(height: 24),

              // Date & Time
              _buildSummaryRow(Icons.calendar_today, 'Date', formattedDate),
              const SizedBox(height: 12),
              _buildSummaryRow(
                Icons.access_time,
                'Time',
                _selectedTime ?? 'Not selected',
              ),

              if (_selectedReason != null) ...[
                const Divider(height: 24),
                _buildSummaryRow(
                  Icons.medical_services,
                  'Reason',
                  _selectedReason!.name,
                ),
              ],

              if (_reasonTextController.text.isNotEmpty) ...[
                const Divider(height: 24),
                _buildSummaryRow(
                  Icons.description,
                  'Details',
                  _reasonTextController.text,
                  multiLine: true,
                ),
              ],

              if (_notesController.text.isNotEmpty) ...[
                const Divider(height: 24),
                _buildSummaryRow(
                  Icons.note,
                  'Notes',
                  _notesController.text,
                  multiLine: true,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Notice
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFFF9800)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your appointment will be pending until the clinic confirms it.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    IconData icon,
    String label,
    String value, {
    bool multiLine = false,
  }) {
    return Row(
      crossAxisAlignment: multiLine
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF26B5A4), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final canGoNext = _canProceedToNextStep();
    final isLastStep = _currentStep == 3;

    return Container(
      padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _currentStep--);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF26B5A4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(color: Color(0xFF26B5A4)),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : canGoNext
                    ? () {
                        if (isLastStep) {
                          _submitAppointment();
                        } else {
                          setState(() => _currentStep++);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26B5A4),
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        isLastStep ? 'Book Appointment' : 'Continue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _selectedPet != null;
      case 1:
        return _selectedDate != null && _selectedTime != null;
      case 2:
        return true; // Reason is optional
      case 3:
        return true; // Already validated in previous steps
      default:
        return false;
    }
  }
}
