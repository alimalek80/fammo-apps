import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  
  factory BiometricService() {
    return _instance;
  }
  
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();

  // Check if device supports biometric authentication
  Future<bool> canAuthenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      print('DEBUG: canCheckBiometrics: $canCheck');
      return canCheck;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  // Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      print('DEBUG: Available biometrics: $biometrics');
      return biometrics;
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  // Check if device is capable of device credential authentication
  Future<bool> canCheckDeviceCredential() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      print('DEBUG: canCheckDeviceCredential - canCheckBiometrics: $canCheck');
      return canCheck;
    } catch (e) {
      print('Error checking device credential: $e');
      return false;
    }
  }

  // Authenticate using biometrics
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          useErrorDialogs: useErrorDialogs,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Error during biometric authentication: $e');
      return false;
    }
  }

  // Authenticate using device credentials (biometric or PIN/password)
  Future<bool> authenticateWithDeviceCredentials({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      final result = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          useErrorDialogs: useErrorDialogs,
          sensitiveTransaction: true,
        ),
      );
      print('DEBUG: authenticate result: $result');
      return result;
    } catch (e) {
      print('Error during device credential authentication: $e');
      return false;
    }
  }

  // Save biometric login credentials (email and token)
  Future<void> saveBiometricEmail(String email) async {
    try {
      await _secureStorage.write(key: 'biometric_email', value: email);
    } catch (e) {
      print('Error saving biometric email: $e');
    }
  }

  // Get saved biometric email
  Future<String?> getBiometricEmail() async {
    try {
      return await _secureStorage.read(key: 'biometric_email');
    } catch (e) {
      print('Error getting biometric email: $e');
      return null;
    }
  }

  // Save access token for biometric login
  Future<void> saveBiometricToken(String token) async {
    try {
      await _secureStorage.write(key: 'biometric_token', value: token);
    } catch (e) {
      print('Error saving biometric token: $e');
    }
  }

  // Get saved access token
  Future<String?> getBiometricToken() async {
    try {
      return await _secureStorage.read(key: 'biometric_token');
    } catch (e) {
      print('Error getting biometric token: $e');
      return null;
    }
  }

  // Clear biometric token
  Future<void> clearBiometricToken() async {
    try {
      await _secureStorage.delete(key: 'biometric_token');
    } catch (e) {
      print('Error clearing biometric token: $e');
    }
  }

  // Enable biometric login for current user
  Future<void> enableBiometricLogin(String email, String token) async {
    try {
      await _secureStorage.write(key: 'biometric_enabled', value: 'true');
      await saveBiometricEmail(email);
      await saveBiometricToken(token);
    } catch (e) {
      print('Error enabling biometric login: $e');
    }
  }

  // Disable biometric login
  Future<void> disableBiometricLogin() async {
    try {
      await _secureStorage.delete(key: 'biometric_enabled');
      await _secureStorage.delete(key: 'biometric_email');
      await _secureStorage.delete(key: 'biometric_token');
    } catch (e) {
      print('Error disabling biometric login: $e');
    }
  }

  // Check if biometric login is enabled
  Future<bool> isBiometricLoginEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: 'biometric_enabled');
      return enabled == 'true';
    } catch (e) {
      print('Error checking biometric login status: $e');
      return false;
    }
  }

  // Get biometric type name for display
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }
}
