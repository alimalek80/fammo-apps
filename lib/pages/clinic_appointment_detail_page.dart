import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/appointment_models.dart';
import '../services/appointment_service.dart';
import '../widgets/paw_loading_indicator.dart';

class ClinicAppointmentDetailPage extends StatefulWidget {
  final int appointmentId;

  const ClinicAppointmentDetailPage({super.key, required this.appointmentId});

  @override
  State<ClinicAppointmentDetailPage> createState() =>
      _ClinicAppointmentDetailPageState();
}

class _ClinicAppointmentDetailPageState
    extends State<ClinicAppointmentDetailPage> {
  final AppointmentService _appointmentService = AppointmentService();

  bool _isLoading = true;
  bool _isUpdating = false;
  String _errorMessage = '';
  ClinicAppointmentItem? _appointment;

  @override
  void initState() {
    super.initState();
    _loadAppointmentDetail();
  }

  Future<void> _loadAppointmentDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final appointment = await _appointmentService.getClinicAppointmentDetail(
        widget.appointmentId,
      );
      setState(() {
        _appointment = appointment;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load appointment: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSMS(String phone) async {
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5F3),
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: const Color(0xFF26B5A4),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_appointment != null)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: _appointment!.referenceCode),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reference code copied')),
                );
              },
              tooltip: 'Copy reference code',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: PawLoadingIndicator())
          : _errorMessage.isNotEmpty
          ? _buildErrorView()
          : _appointment == null
          ? const Center(child: Text('Appointment not found'))
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
              onPressed: _loadAppointmentDetail,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final appointment = _appointment!;
    final dateObj = DateTime.parse(appointment.appointmentDate);
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(dateObj);
    final timeStr = appointment.appointmentTime.substring(0, 5);
    final isPending = appointment.status == 'PENDING';
    final isConfirmed = appointment.status == 'CONFIRMED';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Status header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: appointment.statusEnum.color.withOpacity(0.1),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        appointment.statusEnum.icon,
                        size: 48,
                        color: appointment.statusEnum.color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appointment.statusDisplay,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: appointment.statusEnum.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.referenceCode,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Date & Time
                _buildSectionCard(
                  title: 'Appointment',
                  icon: Icons.calendar_today,
                  children: [
                    _buildInfoRow('Date', formattedDate),
                    _buildInfoRow('Time', timeStr),
                    _buildInfoRow(
                      'Duration',
                      '${appointment.durationMinutes} minutes',
                    ),
                  ],
                ),

                // Pet info
                _buildSectionCard(
                  title: 'Pet',
                  icon: Icons.pets,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
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
                                      size: 35,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.pets,
                                  color: Color(0xFF26B5A4),
                                  size: 35,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.pet.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (appointment.pet.petType != null)
                                Text(
                                  appointment.pet.petType!,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              if (appointment.pet.breed != null)
                                Text(
                                  appointment.pet.breed!,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Owner info
                _buildSectionCard(
                  title: 'Pet Owner',
                  icon: Icons.person,
                  children: [
                    Text(
                      appointment.user.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _makePhoneCall(appointment.user.phone),
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('Call'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF26B5A4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _sendSMS(appointment.user.phone),
                            icon: const Icon(Icons.message, size: 18),
                            label: const Text('SMS'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF26B5A4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _sendEmail(appointment.user.email),
                            icon: const Icon(Icons.email, size: 18),
                            label: const Text('Email'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF26B5A4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Reason
                if (appointment.reason != null ||
                    (appointment.reasonText != null &&
                        appointment.reasonText!.isNotEmpty))
                  _buildSectionCard(
                    title: 'Reason for Visit',
                    icon: Icons.medical_services,
                    children: [
                      if (appointment.reason != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF26B5A4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            appointment.reason!.name,
                            style: const TextStyle(
                              color: Color(0xFF26B5A4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (appointment.reason!.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            appointment.reason!.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                      if (appointment.reasonText != null &&
                          appointment.reasonText!.isNotEmpty) ...[
                        if (appointment.reason != null)
                          const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Additional Details:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                appointment.reasonText!,
                                style: const TextStyle(
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                // Notes
                if (appointment.notes != null && appointment.notes!.isNotEmpty)
                  _buildSectionCard(
                    title: 'Notes from Owner',
                    icon: Icons.note,
                    backgroundColor: const Color(0xFFFFF8E1),
                    children: [
                      Text(
                        appointment.notes!,
                        style: const TextStyle(color: Color(0xFF2C3E50)),
                      ),
                    ],
                  ),

                // Created info
                _buildSectionCard(
                  title: 'Booking Info',
                  icon: Icons.info_outline,
                  children: [
                    _buildInfoRow(
                      'Booked on',
                      DateFormat(
                        'MMM d, yyyy HH:mm',
                      ).format(appointment.createdAt),
                    ),
                    if (appointment.confirmedAt != null)
                      _buildInfoRow(
                        'Confirmed on',
                        DateFormat(
                          'MMM d, yyyy HH:mm',
                        ).format(appointment.confirmedAt!),
                      ),
                  ],
                ),

                const SizedBox(height: 100), // Space for bottom buttons
              ],
            ),
          ),
        ),

        // Action buttons at bottom
        if (isPending || isConfirmed) _buildActionButtons(appointment),
      ],
    );
  }

  Widget _buildActionButtons(ClinicAppointmentItem appointment) {
    final isPending = appointment.status == 'PENDING';
    final isConfirmed = appointment.status == 'CONFIRMED';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isUpdating ? null : () => _showCancelDialog(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _confirmAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirm Appointment'),
                    ),
                  ),
                ],
              ),
            if (isConfirmed)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isUpdating ? null : _markNoShow,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('No Show'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isUpdating ? null : () => _showCancelDialog(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _completeAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Complete'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF26B5A4), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _confirmAppointment() async {
    setState(() => _isUpdating = true);
    try {
      await _appointmentService.confirmAppointment(widget.appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment confirmed'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _completeAppointment() async {
    setState(() => _isUpdating = true);
    try {
      await _appointmentService.completeAppointment(widget.appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment marked as completed'),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _markNoShow() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as No Show'),
        content: const Text(
          'Are you sure the pet owner did not show up for this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('Yes, No Show'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUpdating = true);
    try {
      await _appointmentService.markNoShow(widget.appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment marked as no show'),
            backgroundColor: Colors.grey,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for cancelling this appointment:',
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
            child: const Text('Keep Appointment'),
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
              await _cancelAppointment(reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(String reason) async {
    setState(() => _isUpdating = true);
    try {
      await _appointmentService.cancelAppointmentByClinic(
        widget.appointmentId,
        reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isUpdating = false);
      }
    }
  }
}
