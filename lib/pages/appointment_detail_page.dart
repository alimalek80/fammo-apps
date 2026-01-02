import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/appointment_models.dart';
import '../services/appointment_service.dart';
import '../widgets/paw_loading_indicator.dart';

class AppointmentDetailPage extends StatefulWidget {
  final int appointmentId;

  const AppointmentDetailPage({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  final AppointmentService _appointmentService = AppointmentService();

  bool _isLoading = true;
  bool _isCancelling = false;
  String _errorMessage = '';
  AppointmentDetail? _appointment;

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
      final appointment = await _appointmentService.getAppointmentDetail(
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

  Future<void> _openMap(String? lat, String? lng) async {
    if (lat != null && lng != null) {
      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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

    return SingleChildScrollView(
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
            title: 'Date & Time',
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
                    width: 60,
                    height: 60,
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.pet.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (appointment.pet.petType != null)
                          Text(
                            '${appointment.pet.petType}${appointment.pet.breed != null ? ' • ${appointment.pet.breed}' : ''}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Clinic info
          _buildSectionCard(
            title: 'Clinic',
            icon: Icons.local_hospital,
            children: [
              Text(
                appointment.clinic.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (appointment.clinic.address.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.clinic.address,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makePhoneCall(appointment.clinic.phone),
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF26B5A4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openMap(
                        appointment.clinic.latitude,
                        appointment.clinic.longitude,
                      ),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Directions'),
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
          if (appointment.reason != null || appointment.reasonText != null)
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
                  const SizedBox(height: 8),
                ],
                if (appointment.reasonText != null &&
                    appointment.reasonText!.isNotEmpty)
                  Text(
                    appointment.reasonText!,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
              ],
            ),

          // Notes
          if (appointment.notes != null && appointment.notes!.isNotEmpty)
            _buildSectionCard(
              title: 'Additional Notes',
              icon: Icons.note,
              children: [
                Text(
                  appointment.notes!,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),

          // Cancellation info
          if (appointment.cancellationReason.isNotEmpty)
            _buildSectionCard(
              title: 'Cancellation Reason',
              icon: Icons.cancel,
              backgroundColor: Colors.red.withOpacity(0.05),
              children: [
                Text(
                  appointment.cancellationReason,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),

          // Timeline
          _buildSectionCard(
            title: 'Timeline',
            icon: Icons.timeline,
            children: [
              _buildTimelineItem(
                'Created',
                DateFormat('MMM d, yyyy HH:mm').format(appointment.createdAt),
                isFirst: true,
              ),
              if (appointment.confirmedAt != null)
                _buildTimelineItem(
                  'Confirmed',
                  DateFormat(
                    'MMM d, yyyy HH:mm',
                  ).format(appointment.confirmedAt!),
                ),
              if (appointment.cancelledAt != null)
                _buildTimelineItem(
                  'Cancelled',
                  DateFormat(
                    'MMM d, yyyy HH:mm',
                  ).format(appointment.cancelledAt!),
                  isLast: true,
                ),
            ],
          ),

          // Cancel button
          if (appointment.canCancel)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCancelling ? null : _showCancelDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Cancel Appointment',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ),

          const SizedBox(height: 32),
        ],
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

  Widget _buildTimelineItem(
    String title,
    String time, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF26B5A4),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: const Color(0xFF26B5A4).withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                time,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
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
            const Text('Are you sure you want to cancel this appointment?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelAppointment(reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(String reason) async {
    setState(() => _isCancelling = true);

    try {
      await _appointmentService.cancelAppointment(
        widget.appointmentId,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: Colors.green,
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
        setState(() => _isCancelling = false);
      }
    }
  }
}
