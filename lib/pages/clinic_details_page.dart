import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/paw_loading_indicator.dart';
import '../models/clinic.dart';
import '../services/clinic_service.dart';
import 'book_appointment_page.dart';

class ClinicDetailsPage extends StatefulWidget {
  final int clinicId;

  const ClinicDetailsPage({super.key, required this.clinicId});

  @override
  State<ClinicDetailsPage> createState() => _ClinicDetailsPageState();
}

class _ClinicDetailsPageState extends State<ClinicDetailsPage> {
  final ClinicService _clinicService = ClinicService();
  Clinic? _clinic;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadClinicDetails();
  }

  Future<void> _loadClinicDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final clinic = await _clinicService.getClinicDetails(widget.clinicId);
      setState(() {
        _clinic = clinic;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load clinic details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make phone call')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send email')),
        );
      }
    }
  }

  void _navigateToBookAppointment() {
    if (_clinic == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookAppointmentPage(clinic: _clinic!),
      ),
    );
  }

  Future<void> _openMap() async {
    if (_clinic?.latitude != null && _clinic?.longitude != null) {
      final lat = _clinic!.latitude;
      final lng = _clinic!.longitude;
      
      // Use Google Maps URL that works on all platforms
      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      
      try {
        final canLaunch = await canLaunchUrl(uri);
        if (canLaunch) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Try without checking
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open maps: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not available')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5F3),
      body: _isLoading
          ? const Center(child: PawLoadingIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadClinicDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _clinic == null
                  ? const Center(child: Text('Clinic not found'))
                  : CustomScrollView(
                      slivers: [
                        // App Bar with Image
                        SliverAppBar(
                          expandedHeight: 200,
                          pinned: true,
                          backgroundColor: const Color(0xFF26B5A4),
                          leading: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          actions: [
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.share, color: Color(0xFF2C3E50)),
                              ),
                              onPressed: () {
                                if (_clinic != null) {
                                  final shareText = '''Check out ${_clinic!.name}!

${_clinic!.address.isNotEmpty ? _clinic!.address + '\n' : ''}${_clinic!.phone.isNotEmpty ? 'Phone: ' + _clinic!.phone + '\n' : ''}${_clinic!.email.isNotEmpty ? 'Email: ' + _clinic!.email : ''}''';
                                  Share.share(shareText);
                                }
                              },
                            ),
                          ],
                          flexibleSpace: FlexibleSpaceBar(
                            background: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF26B5A4),
                                    Color(0xFFE8F5F3),
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 60),
                                  // Clinic Logo
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _clinic!.logo != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: Image.network(
                                              _clinic!.logo!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.local_hospital,
                                                  size: 50,
                                                  color: Color(0xFF26B5A4),
                                                );
                                              },
                                            ),
                                          )
                                        : const Icon(
                                            Icons.local_hospital,
                                            size: 50,
                                            color: Color(0xFF26B5A4),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Content
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              // Clinic Name and Rating
                              Container(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Text(
                                      _clinic!.name,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (_clinic!.adminApproved)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4CAF50),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(
                                                  Icons.verified,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Trusted',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (_clinic!.adminApproved && _clinic!.clinicEoi)
                                          const SizedBox(width: 8),
                                        if (_clinic!.clinicEoi)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF26B5A4),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(
                                                  Icons.card_membership,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'FAMMO Partner',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                size: 16,
                                                color: Color(0xFFFFA500),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '4.8',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2C3E50),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Quick Action Buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildActionButton(
                                          Icons.phone,
                                          'Call',
                                          () {
                                            if (_clinic!.phone.isNotEmpty) {
                                              _makePhoneCall(_clinic!.phone);
                                            }
                                          },
                                        ),
                                        _buildActionButton(
                                          Icons.navigation,
                                          'Get Directions',
                                          _openMap,
                                        ),
                                        _buildActionButton(
                                          Icons.language,
                                          'Website',
                                          () {
                                            if (_clinic!.website != null && _clinic!.website!.isNotEmpty) {
                                              _launchUrl(_clinic!.website!);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Book Appointment Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _navigateToBookAppointment(),
                                        icon: const Icon(Icons.calendar_month, color: Colors.white),
                                        label: const Text(
                                          'Book Appointment',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF26B5A4),
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Address Section
                              _buildInfoCard(
                                icon: Icons.location_on,
                                title: _clinic!.address.isNotEmpty 
                                    ? _clinic!.address 
                                    : _clinic!.city,
                                subtitle: _clinic!.address.isNotEmpty 
                                    ? _clinic!.city 
                                    : null,
                              ),
                              
                              // Phone Section
                              if (_clinic!.phone.isNotEmpty)
                                _buildInfoCard(
                                  icon: Icons.phone,
                                  title: _clinic!.phone,
                                  onTap: () => _makePhoneCall(_clinic!.phone),
                                ),
                              
                              // Email Section
                              if (_clinic!.email.isNotEmpty)
                                _buildInfoCard(
                                  icon: Icons.email,
                                  title: _clinic!.email,
                                  onTap: () => _sendEmail(_clinic!.email),
                                ),
                              
                              // Instagram Section
                              if (_clinic!.instagram != null && _clinic!.instagram!.isNotEmpty)
                                _buildInfoCard(
                                  icon: Icons.camera_alt,
                                  title: _clinic!.instagram!,
                                  onTap: () {
                                    final username = _clinic!.instagram!.replaceAll('@', '');
                                    _launchUrl('https://www.instagram.com/$username');
                                  },
                                ),
                              
                              // Services Section
                              if (_clinic!.specializations.isNotEmpty)
                                _buildSectionCard(
                                  title: 'Services',
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _clinic!.specializations
                                        .split(',')
                                        .map((service) => Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8F5F3),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: const Color(0xFF26B5A4),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                service.trim(),
                                                style: const TextStyle(
                                                  color: Color(0xFF26B5A4),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              
                              // Species Section
                              _buildSectionCard(
                                title: 'Species',
                                child: Row(
                                  children: [
                                    _buildSpeciesChip('🐕', 'Dog'),
                                    const SizedBox(width: 12),
                                    _buildSpeciesChip('🐱', 'Cat'),
                                  ],
                                ),
                              ),
                              
                              // Working Hours Section
                              if (_clinic!.formattedWorkingHours != null && _clinic!.formattedWorkingHours!.isNotEmpty)
                                _buildSectionCard(
                                  title: 'Working Hours',
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _clinic!.formattedWorkingHours!.map((hours) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Color(0xFF26B5A4),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                hours,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF2C3E50),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              
                              // Referral Link Section
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5F3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Referral Link',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Share this link with friends and get rewards when they sign up!',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF7F8C8D),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _clinic!.referralCodes != null && _clinic!.referralCodes!.isNotEmpty
                                                    ? 'fammo.app/ref/${_clinic!.referralCodes!.first.code}'
                                                    : 'fammo.app/ref/${_clinic!.slug}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF2C3E50),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                // TODO: Copy to clipboard
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Link copied to clipboard'),
                                                    backgroundColor: Color(0xFF26B5A4),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF26B5A4),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.copy,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
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
          children: [
            Icon(icon, color: const Color(0xFF26B5A4), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF26B5A4), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSpeciesChip(String emoji, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }
}
