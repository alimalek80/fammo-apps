import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static const String _notificationEnabledKey = 'notification_enabled';
  static const String _notificationPermissionAskedKey = 'notification_permission_asked';
  static const platform = MethodChannel('com.example.fammo_app/notifications');
  
  final _secureStorage = const FlutterSecureStorage();

  /// Initialize notification channels (Android only)
  Future<void> initializeNotificationChannels() async {
    try {
      await platform.invokeMethod('createNotificationChannels');
    } catch (e) {
      print('Error initializing notification channels: $e');
    }
  }

  /// Check if notifications are enabled
  Future<bool> isNotificationEnabled() async {
    try {
      final value = await _secureStorage.read(key: _notificationEnabledKey);
      // Default to true (enabled) if not set
      return value == null ? true : value == 'true';
    } catch (e) {
      print('Error reading notification setting: $e');
      return true; // Default to enabled
    }
  }

  /// Enable or disable notifications
  Future<void> setNotificationEnabled(bool enabled) async {
    try {
      await _secureStorage.write(
        key: _notificationEnabledKey,
        value: enabled.toString(),
      );
    } catch (e) {
      print('Error saving notification setting: $e');
      rethrow;
    }
  }

  /// Check if permission has been asked before
  Future<bool> hasPermissionBeenAsked() async {
    try {
      final value = await _secureStorage.read(key: _notificationPermissionAskedKey);
      return value == 'true';
    } catch (e) {
      print('Error reading permission asked status: $e');
      return false;
    }
  }

  /// Mark that permission has been asked
  Future<void> setPermissionAsked() async {
    try {
      await _secureStorage.write(
        key: _notificationPermissionAskedKey,
        value: 'true',
      );
    } catch (e) {
      print('Error saving permission asked status: $e');
      rethrow;
    }
  }

  /// Request notification permission
  Future<PermissionStatus> requestNotificationPermission() async {
    try {
      // First initialize channels
      await initializeNotificationChannels();
      
      final status = await Permission.notification.request();
      if (status.isDenied || status.isGranted || status.isDenied) {
        await setPermissionAsked();
      }
      return status;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Check current notification permission status
  Future<PermissionStatus> getNotificationPermissionStatus() async {
    try {
      return await Permission.notification.status;
    } catch (e) {
      print('Error checking notification permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Open notification settings
  Future<void> openNotificationSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('Error opening settings: $e');
      rethrow;
    }
  }
}
