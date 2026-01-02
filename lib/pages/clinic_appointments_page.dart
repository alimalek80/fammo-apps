import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_models.dart';
import '../services/appointment_service.dart';
import '../widgets/paw_loading_indicator.dart';
import 'clinic_appointment_detail_page.dart';

class ClinicAppointmentsPage extends StatefulWidget {
  const ClinicAppointmentsPage({super.key});

  @override
  State<ClinicAppointmentsPage> createState() => _ClinicAppointmentsPageState();
}

class _ClinicAppointmentsPageState extends State<ClinicAppointmentsPage>
    with SingleTickerProviderStateMixin {
  final AppointmentService _appointmentService = AppointmentService();
  late TabController _tabController;

  bool _isLoading = true;
  String _errorMessage = '';
  List<ClinicAppointmentItem> _appointments = [];

  String _currentFilter = 'all';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentFilter = _getFilterForTab(_tabController.index);
      });
      _loadAppointments();
    }
  }

  String _getFilterForTab(int index) {
    switch (index) {
      case 0:
        return 'PENDING';
      case 1:
        return 'CONFIRMED';
      case 2:
        return 'all';
      default:
        return 'all';
    }
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final appointments = await _appointmentService.getClinicAppointments(
        status: _currentFilter != 'all' ? _currentFilter : null,
        date: _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : null,
        upcoming: _tabController.index < 2 ? true : null,
      );

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load appointments: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
      _loadAppointments();
    }
  }

  void _clearDateFilter() {
    setState(() => _selectedDate = null);
    _loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5F3),
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: const Color(0xFF26B5A4),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'All'),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _selectedDate != null,
              child: const Icon(Icons.calendar_today),
            ),
            onPressed: _selectDate,
            tooltip: 'Filter by date',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date filter chip
          if (_selectedDate != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      DateFormat('MMM d, yyyy').format(_selectedDate!),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: _clearDateFilter,
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),

          // Appointments list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList(),
                _buildAppointmentsList(),
                _buildAppointmentsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    if (_isLoading) {
      return const Center(child: PawLoadingIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAppointments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_appointments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          return _buildAppointmentCard(_appointments[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_tabController.index) {
      case 0:
        message = 'No pending appointments';
        icon = Icons.hourglass_empty;
        break;
      case 1:
        message = 'No confirmed appointments';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'No appointments found';
        icon = Icons.calendar_today;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDate != null
                  ? 'No appointments on ${DateFormat('MMM d').format(_selectedDate!)}'
                  : 'New appointment requests will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(ClinicAppointmentItem appointment) {
    final dateObj = DateTime.parse(appointment.appointmentDate);
    final timeStr = appointment.appointmentTime.substring(0, 5);
    final isPending = appointment.status == 'PENDING';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ClinicAppointmentDetailPage(appointmentId: appointment.id),
          ),
        );
        if (result == true) {
          _loadAppointments();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPending
              ? Border.all(color: const Color(0xFFFFA500), width: 2)
              : null,
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
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: appointment.statusEnum.color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    appointment.statusEnum.icon,
                    color: appointment.statusEnum.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    appointment.statusDisplay,
                    style: TextStyle(
                      color: appointment.statusEnum.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    appointment.referenceCode,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Pet and owner info
                  Row(
                    children: [
                      // Pet image
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5F3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: appointment.pet.image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  appointment.pet.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.pets,
                                    color: Color(0xFF26B5A4),
                                  ),
                                ),
                              )
                            : const Icon(Icons.pets, color: Color(0xFF26B5A4)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment.pet.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              '${appointment.pet.petType ?? 'Pet'}${appointment.pet.breed != null ? ' • ${appointment.pet.breed}' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Owner: ${appointment.user.fullName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Date and time
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('EEE, MMM d').format(dateObj),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (appointment.reason != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.medical_services,
                            size: 16,
                            color: Color(0xFF26B5A4),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              appointment.reason!.name,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF26B5A4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Quick action buttons for pending
                  if (isPending) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showCancelDialog(appointment),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _confirmAppointment(appointment),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                            ),
                            child: const Text('Confirm'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAppointment(ClinicAppointmentItem appointment) async {
    try {
      await _appointmentService.confirmAppointment(appointment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment confirmed'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCancelDialog(ClinicAppointmentItem appointment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for declining this appointment:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(context);
              await _declineAppointment(appointment.id, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  Future<void> _declineAppointment(int id, String reason) async {
    try {
      await _appointmentService.cancelAppointmentByClinic(id, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment declined'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
