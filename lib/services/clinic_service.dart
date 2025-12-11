import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/clinic.dart';
import 'config_service.dart';

class ClinicService {
  final storage = const FlutterSecureStorage();

  Future<String> _getBaseUrl() async {
    return ConfigService.getBaseUrl();
  }

  Future<String> _getLanguageCode() async {
    final lang = await storage.read(key: "language");
    return lang ?? "en";
  }

  Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final langCode = await _getLanguageCode();
    final headers = {
      "Content-Type": "application/json",
      "Accept-Language": langCode,
    };

    if (requireAuth) {
      final token = await storage.read(key: "access");
      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    return headers;
  }

  // 1. List All Active Clinics
  Future<List<Clinic>> listClinics({
    bool? showAll,
    String? city,
    bool? eoi,
    bool? verifiedEmail,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse("$baseUrl/api/v1/clinics/").replace(
        queryParameters: {
          if (showAll != null) 'show_all': showAll.toString(),
          if (city != null) 'city': city,
          if (eoi != null) 'eoi': eoi.toString(),
          if (verifiedEmail != null) 'verified_email': verifiedEmail.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Clinic.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load clinics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error listing clinics: $e');
      rethrow;
    }
  }

  // 2. Register New Clinic
  Future<Clinic> registerClinic(Map<String, dynamic> clinicData) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/v1/clinics/");

      final response = await http.post(
        url,
        headers: await _getHeaders(requireAuth: true),
        body: jsonEncode(clinicData),
      );

      if (response.statusCode == 201) {
        return Clinic.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to register clinic: $errorData');
      }
    } catch (e) {
      print('Error registering clinic: $e');
      rethrow;
    }
  }

  // 3. Get My Clinic
  Future<Clinic?> getMyClinic() async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/v1/clinics/my/");

      final response = await http.get(
        url,
        headers: await _getHeaders(requireAuth: true),
      );

      if (response.statusCode == 200) {
        return Clinic.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null; // No clinic registered
      } else {
        throw Exception('Failed to get my clinic: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting my clinic: $e');
      rethrow;
    }
  }

  // 4. Get Clinic Details
  Future<Clinic> getClinicDetails(int clinicId) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/v1/clinics/$clinicId/");

      final response = await http.get(
        url,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return Clinic.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get clinic details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting clinic details: $e');
      rethrow;
    }
  }

  // 5. Update Clinic (PATCH for partial update)
  Future<void> updateClinic(int clinicId, Map<String, dynamic> updates) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/v1/clinics/$clinicId/");

      print('Updating clinic at: $url');
      print('Request body: ${jsonEncode(updates)}');

      final response = await http.patch(
        url,
        headers: await _getHeaders(requireAuth: true),
        body: jsonEncode(updates),
      );

      print('Update clinic status: ${response.statusCode}');
      print('Update clinic response: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to update clinic: $errorData');
      }
      // Success - no need to return anything since API response is partial
    } catch (e) {
      print('Error updating clinic: $e');
      rethrow;
    }
  }

  // 5.5 Update Working Hours
  Future<void> updateWorkingHours(
    int clinicId,
    List<Map<String, dynamic>> workingHours,
  ) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/v1/clinics/$clinicId/working-hours/");

      print('Updating working hours at: $url');
      print('Request body: ${jsonEncode(workingHours)}');

      final response = await http.patch(
        url,
        headers: await _getHeaders(requireAuth: true),
        body: jsonEncode(workingHours),
      );

      print('Update working hours status: ${response.statusCode}');
      print('Update working hours response: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to update working hours: $errorData');
      }
    } catch (e) {
      print('Error updating working hours: $e');
      rethrow;
    }
  }

  // 5.6 Upload Clinic Logo
  Future<void> uploadClinicLogo(int clinicId, File logoFile) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/v1/clinics/$clinicId/");

      print('Uploading logo at: $url');

      final request = http.MultipartRequest('PATCH', url);
      request.headers.addAll(await _getHeaders(requireAuth: true));
      request.files.add(
        await http.MultipartFile.fromPath('logo', logoFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Upload logo status: ${response.statusCode}');
      print('Upload logo response: $responseBody');

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(responseBody);
        throw Exception('Failed to upload logo: $errorData');
      }
    } catch (e) {
      print('Error uploading logo: $e');
      rethrow;
    }
  }

  // 6. Delete Clinic
  Future<bool> deleteClinic(int clinicId) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/v1/clinics/$clinicId/");

      final response = await http.delete(
        url,
        headers: await _getHeaders(requireAuth: true),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to delete clinic: $errorData');
      }
    } catch (e) {
      print('Error deleting clinic: $e');
      rethrow;
    }
  }

  // 7. Get Clinic Working Hours
  Future<List<WorkingHoursSchedule>> getWorkingHours(int clinicId) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/v1/clinics/$clinicId/working-hours/");

      final response = await http.get(
        url,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => WorkingHoursSchedule.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get working hours: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting working hours: $e');
      rethrow;
    }
  }

  // 8. Update Clinic Working Hours (Bulk)
  // 9. Get Vet Profile
  Future<VetProfile?> getVetProfile(int clinicId) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/v1/clinics/$clinicId/vet-profile/");

      final response = await http.get(
        url,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return VetProfile.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get vet profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting vet profile: $e');
      rethrow;
    }
  }

  // 10. Update Vet Profile
  Future<void> updateVetProfile(
    int clinicId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/v1/clinics/$clinicId/vet-profile/");

      print('Updating vet profile at: $url');
      print('Request body: ${jsonEncode(profileData)}');

      final response = await http.patch(
        url,
        headers: await _getHeaders(requireAuth: true),
        body: jsonEncode(profileData),
      );

      print('Update vet profile status: ${response.statusCode}');
      print('Update vet profile response: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to update vet profile: $errorData');
      }
    } catch (e) {
      print('Error updating vet profile: $e');
      rethrow;
    }
  }

  // 11. Search Clinics
  Future<Map<String, dynamic>> searchClinics({
    String? search,
    double? latitude,
    double? longitude,
    double? radius,
    bool? eoi,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/v1/clinics/search/");

      final body = <String, dynamic>{};
      if (search != null) body['search'] = search;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (radius != null) body['radius'] = radius;
      if (eoi != null) body['eoi'] = eoi;

      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'count': data['count'],
          'results': (data['results'] as List)
              .map((json) => Clinic.fromJson(json))
              .toList(),
        };
      } else {
        throw Exception('Failed to search clinics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching clinics: $e');
      rethrow;
    }
  }

  // 12. Confirm Clinic Email
  Future<Map<String, dynamic>> confirmEmail(String token) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/v1/clinics/confirm-email/$token/");

      final response = await http.get(
        url,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to confirm email: $errorData');
      }
    } catch (e) {
      print('Error confirming email: $e');
      rethrow;
    }
  }
}
