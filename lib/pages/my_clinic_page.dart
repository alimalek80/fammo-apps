import 'package:flutter/material.dart';
import '../widgets/paw_loading_indicator.dart';
import '../models/clinic.dart';
import '../services/clinic_service.dart';
import 'add_edit_clinic_page.dart';
import 'clinic_details_page.dart';

class MyClinicPage extends StatefulWidget {
  const MyClinicPage({super.key});

  @override
  State<MyClinicPage> createState() => _MyClinicPageState();
}

class _MyClinicPageState extends State<MyClinicPage> {
  final ClinicService _clinicService = ClinicService();
  Clinic? _myClinic;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMyClinic();
  }

  Future<void> _loadMyClinic() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final clinic = await _clinicService.getMyClinic();
      setState(() {
        _myClinic = clinic;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load clinic: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteClinic() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Clinic'),
        content: const Text(
          'Are you sure you want to delete your clinic? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || _myClinic == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _clinicService.deleteClinic(_myClinic!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clinic deleted successfully')),
        );
        setState(() {
          _myClinic = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete clinic: $e')),
        );
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
        title: const Text('My Clinic'),
        actions: [
          if (_myClinic != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditClinicPage(clinic: _myClinic),
                    ),
                  ).then((value) {
                    if (value == true) {
                      _loadMyClinic();
                    }
                  });
                } else if (value == 'delete') {
                  _deleteClinic();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit Clinic'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Clinic', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: PawLoadingIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMyClinic,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _myClinic == null
                  ? _buildNoClinicView()
                  : RefreshIndicator(
                      onRefresh: _loadMyClinic,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusBanner(),
                            _buildClinicHeader(),
                            _buildQuickStats(),
                            _buildActionButtons(),
                            _buildClinicInfo(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildNoClinicView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: 120,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              'No Clinic Registered',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You haven\'t registered a clinic yet. Register your veterinary clinic to get started!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditClinicPage(),
                  ),
                ).then((value) {
                  if (value == true) {
                    _loadMyClinic();
                  }
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Register Clinic'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (!_myClinic!.emailConfirmed) {
      statusText = 'Email Not Confirmed - Please check your email';
      statusColor = Colors.orange;
      statusIcon = Icons.email;
    } else if (!_myClinic!.adminApproved) {
      statusText = 'Pending Admin Approval';
      statusColor = Colors.blue;
      statusIcon = Icons.pending;
    } else if (!_myClinic!.isActiveClinic) {
      statusText = 'Clinic Inactive';
      statusColor = Colors.red;
      statusIcon = Icons.info;
    } else {
      statusText = 'Clinic Active';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: statusColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_myClinic!.logo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _myClinic!.logo!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultLogo();
                },
              ),
            )
          else
            _buildDefaultLogo(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _myClinic!.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_myClinic!.isVerified)
                      const Icon(Icons.verified, color: Colors.blue, size: 24),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _myClinic!.city,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (_myClinic!.clinicEoi) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'EOI Partner',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Verified',
              _myClinic!.isVerified ? 'Yes' : 'No',
              _myClinic!.isVerified ? Icons.check_circle : Icons.cancel,
              _myClinic!.isVerified ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Email',
              _myClinic!.emailConfirmed ? 'Confirmed' : 'Pending',
              _myClinic!.emailConfirmed ? Icons.check_circle : Icons.pending,
              _myClinic!.emailConfirmed ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Status',
              _myClinic!.isActiveClinic ? 'Active' : 'Inactive',
              _myClinic!.isActiveClinic ? Icons.check_circle : Icons.cancel,
              _myClinic!.isActiveClinic ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClinicDetailsPage(clinicId: _myClinic!.id),
                  ),
                );
              },
              icon: const Icon(Icons.visibility),
              label: const Text('View Public Page'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditClinicPage(clinic: _myClinic),
                  ),
                ).then((value) {
                  if (value == true) {
                    _loadMyClinic();
                  }
                });
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Info'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Contact Information', [
            if (_myClinic!.phone.isNotEmpty) _buildInfoRow(Icons.phone, 'Phone', _myClinic!.phone),
            if (_myClinic!.email.isNotEmpty) _buildInfoRow(Icons.email, 'Email', _myClinic!.email),
            if (_myClinic!.website != null && _myClinic!.website!.isNotEmpty)
              _buildInfoRow(Icons.language, 'Website', _myClinic!.website!),
            if (_myClinic!.instagram != null && _myClinic!.instagram!.isNotEmpty)
              _buildInfoRow(Icons.camera_alt, 'Instagram', _myClinic!.instagram!),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection('Location', [
            _buildInfoRow(Icons.location_city, 'City', _myClinic!.city),
            if (_myClinic!.address.isNotEmpty)
              _buildInfoRow(Icons.place, 'Address', _myClinic!.address),
          ]),
          if (_myClinic!.specializations.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoSection('Specializations', [
              _buildInfoRow(Icons.medical_services, 'Services', _myClinic!.specializations),
            ]),
          ],
          if (_myClinic!.activeReferralCode != null) ...[
            const SizedBox(height: 16),
            _buildReferralCodeSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Your Referral Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _myClinic!.activeReferralCode!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    // TODO: Copy to clipboard
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.local_hospital,
        size: 40,
        color: Colors.blue.shade700,
      ),
    );
  }
}
