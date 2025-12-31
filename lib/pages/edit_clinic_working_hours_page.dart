import 'package:flutter/material.dart';
import '../widgets/paw_loading_indicator.dart';
import '../services/clinic_service.dart';
import '../models/clinic.dart';

class EditClinicWorkingHoursPage extends StatefulWidget {
  final int clinicId;
  final String clinicName;
  final List<WorkingHoursSchedule>? workingHours;

  const EditClinicWorkingHoursPage({
    required this.clinicId,
    required this.clinicName,
    this.workingHours,
  });

  @override
  State<EditClinicWorkingHoursPage> createState() =>
      _EditClinicWorkingHoursPageState();
}

class _EditClinicWorkingHoursPageState extends State<EditClinicWorkingHoursPage> {
  final ClinicService _clinicService = ClinicService();
  late List<WorkingHoursSchedule> _workingHours;
  bool _isSaving = false;
  bool _isLoading = true;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkingHours();
  }

  Future<void> _loadWorkingHours() async {
    try {
      final clinic = await _clinicService.getClinicDetails(widget.clinicId);
      if (mounted) {
        setState(() {
          _workingHours = clinic.workingHoursSchedule ?? _initializeDefaultHours();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading working hours: $e');
      if (mounted) {
        setState(() {
          _workingHours = _initializeDefaultHours();
          _isLoading = false;
        });
      }
    }
  }

  List<WorkingHoursSchedule> _initializeDefaultHours() {
    return List.generate(7, (index) {
      return WorkingHoursSchedule(
        dayOfWeek: index,
        dayName: _daysOfWeek[index],
        isClosed: index >= 5, // Close on Saturday and Sunday by default
        openTime: '09:00:00',
        closeTime: '18:00:00',
      );
    });
  }

  Future<void> _saveWorkingHours() async {
    setState(() => _isSaving = true);

    try {
      final workingHoursData = _workingHours.map((wh) => wh.toJson()).toList();
      await _clinicService.updateWorkingHours(widget.clinicId, workingHoursData);

      // Fetch updated clinic details to ensure UI is in sync
      await _clinicService.getClinicDetails(widget.clinicId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Working hours updated successfully!'),
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

  Future<void> _selectTime(
    BuildContext context,
    int index,
    bool isOpenTime,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTimeOfDay(
        isOpenTime ? _workingHours[index].openTime ?? '09:00:00' : _workingHours[index].closeTime ?? '18:00:00',
      ),
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
      setState(() {
        if (isOpenTime) {
          _workingHours[index] = _workingHours[index].copyWith(
            openTime: formattedTime,
          );
        } else {
          _workingHours[index] = _workingHours[index].copyWith(
            closeTime: formattedTime,
          );
        }
      });
    }
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  @override
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
            'Edit Working Hours',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        body: const Center(
          child: PawLoadingIndicator(),
        ),
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
          'Edit Working Hours',
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
                      'Working Hours for ${widget.clinicName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _workingHours.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final day = _workingHours[index];
                        return _buildDayCard(context, index, day);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveWorkingHours,
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
                          child: PawLoadingIndicator(size: 20),
                        )
                      : const Text(
                          'Save Working Hours',
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

  Widget _buildDayCard(
    BuildContext context,
    int index,
    WorkingHoursSchedule day,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day.dayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Switch(
                value: !day.isClosed,
                onChanged: (value) {
                  setState(() {
                    _workingHours[index] =
                        day.copyWith(isClosed: !value);
                  });
                },
                activeColor: const Color(0xFF26B5A4),
              ),
            ],
          ),
          if (!day.isClosed) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(context, index, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFEBEBEB),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Open',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (day.openTime ?? '09:00:00').substring(0, 5),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(context, index, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFEBEBEB),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (day.closeTime ?? '18:00:00').substring(0, 5),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Closed',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
