import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math' show cos, sqrt, asin;

class LocationService {
  final storage = const FlutterSecureStorage();

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately
      return false;
    }
    
    return true;
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Save location to storage
      await saveLocation(position.latitude, position.longitude);

      return position;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  // Save location to secure storage
  Future<void> saveLocation(double latitude, double longitude) async {
    await storage.write(key: 'user_latitude', value: latitude.toString());
    await storage.write(key: 'user_longitude', value: longitude.toString());
  }

  // Get saved location from storage
  Future<Map<String, double>?> getSavedLocation() async {
    final lat = await storage.read(key: 'user_latitude');
    final lng = await storage.read(key: 'user_longitude');

    if (lat != null && lng != null) {
      return {
        'latitude': double.parse(lat),
        'longitude': double.parse(lng),
      };
    }
    return null;
  }

  // Calculate distance between two coordinates in kilometers
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // Format distance for display
  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toInt()} m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  // Open app settings for permission
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Request location permission with dialog
  Future<bool> requestLocationPermissionWithDialog() async {
    var status = await Permission.location.status;
    
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    
    if (status.isPermanentlyDenied) {
      return false;
    }
    
    return status.isGranted;
  }
}
