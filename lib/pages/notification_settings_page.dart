import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/paw_loading_indicator.dart';
import '../services/notification_service.dart';
import '../services/language_service.dart';
import '../utils/app_localizations.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationService _notificationService = NotificationService();
  
  bool _notificationsEnabled = true;
  bool _isLoading = true;
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      // Initialize notification channels first
      await _notificationService.initializeNotificationChannels();
      
      final isEnabled = await _notificationService.isNotificationEnabled();
      final permissionStatus = await _notificationService.getNotificationPermissionStatus();
      final hasBeenAsked = await _notificationService.hasPermissionBeenAsked();

      setState(() {
        _notificationsEnabled = isEnabled;
        _permissionStatus = permissionStatus;
        _isLoading = false;
      });

      // If first time and notifications are enabled, request permission
      if (!hasBeenAsked && _notificationsEnabled) {
        _requestPermissionIfNeeded();
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPermissionIfNeeded() async {
    final status = await _notificationService.requestNotificationPermission();
    setState(() => _permissionStatus = status);
  }

  Future<void> _toggleNotifications(bool value) async {
    try {
      if (value && !_permissionStatus.isGranted) {
        // If user wants to enable notifications but permission not granted, request it
        final status = await _notificationService.requestNotificationPermission();
        setState(() => _permissionStatus = status);
        
        if (!status.isGranted) {
          // Permission denied, show warning but allow disabling
          if (mounted) {
            final languageCode = await LanguageService().getLocalLanguage() ?? 'en';
            final loc = AppLocalizations(languageCode);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.notificationPermissionDenied),
                action: SnackBarAction(
                  label: loc.settingsLabel,
                  onPressed: () async {
                    await _notificationService.openNotificationSettings();
                  },
                ),
              ),
            );
          }
          return;
        }
      }

      await _notificationService.setNotificationEnabled(value);
      setState(() => _notificationsEnabled = value);

      if (mounted) {
        final languageCode = await LanguageService().getLocalLanguage() ?? 'en';
        final loc = AppLocalizations(languageCode);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? loc.notificationsEnabled : loc.notificationsDisabled,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error toggling notifications: $e');
      if (mounted) {
        final languageCode = await LanguageService().getLocalLanguage() ?? 'en';
        final loc = AppLocalizations(languageCode);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorUpdatingNotifications)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: LanguageService().getLocalLanguage(),
      builder: (context, snapshot) {
        String languageCode = snapshot.data ?? 'en';
        AppLocalizations loc = AppLocalizations(languageCode);
        
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: true,
            centerTitle: true,
            title: Text(
              loc.notificationsTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
      body: _isLoading
          ? const Center(child: PawLoadingIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Main notification toggle
                  Container(
                    color: Colors.white,
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.pushNotifications,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _notificationsEnabled
                                        ? loc.notificationsEnabledDesc
                                        : loc.notificationsDisabledDesc,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF7F8C8D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Switch(
                              value: _notificationsEnabled,
                              onChanged: _toggleNotifications,
                              activeColor: const Color(0xFF26B5A4),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Permission status section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.permissionStatus,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPermissionStatusItem(
                          loc.systemNotifications,
                          _permissionStatus,
                          loc,
                        ),
                        if (!_permissionStatus.isGranted && _notificationsEnabled)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _notificationService.openNotificationSettings();
                              },
                              icon: const Icon(Icons.settings),
                              label: Text(loc.openSettings),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF26B5A4),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Information section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.aboutNotifications,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.notificationTypes,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildNotificationTypeItem(loc.petHealthReminders),
                        _buildNotificationTypeItem(loc.appointmentReminders),
                        _buildNotificationTypeItem(loc.messagesFromVets),
                        _buildNotificationTypeItem(loc.importantUpdates),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        );
      },
    );
  }

  Widget _buildPermissionStatusItem(String title, PermissionStatus status, AppLocalizations loc) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (status.isGranted) {
      statusColor = Colors.green;
      statusText = loc.granted;
      statusIcon = Icons.check_circle;
    } else if (status.isDenied) {
      statusColor = Colors.orange;
      statusText = loc.denied;
      statusIcon = Icons.cancel;
    } else if (status.isPermanentlyDenied) {
      statusColor = Colors.red;
      statusText = loc.permanentlyDenied;
      statusIcon = Icons.block;
    } else {
      statusColor = Colors.grey;
      statusText = loc.unknown;
      statusIcon = Icons.help;
    }

    return Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTypeItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.circle,
            size: 6,
            color: Color(0xFF7F8C8D),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7F8C8D),
            ),
          ),
        ],
      ),
    );
  }
}
