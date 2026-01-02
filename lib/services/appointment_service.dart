import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/appointment_models.dart';
import 'config_service.dart';

class AppointmentService {
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

  // ==================== USER SIDE ====================

  /// Get list of appointment reasons
  Future<List<AppointmentReason>> getAppointmentReasons() async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/v1/appointments/reasons/");

      final response = await http.get(url, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AppointmentReason.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load appointment reasons: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error getting appointment reasons: $e');
      rethrow;
    }
  }

  /// Get available dates for a clinic
  Future<AvailableDatesResponse> getAvailableDates(
    int clinicId, {
    String? startDate,
    int days = 14,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final queryParams = <String, String>{'days': days.toString()};
      if (startDate != null) {
        queryParams['start_date'] = startDate;
      }

      final uri = Uri.parse(
        "$baseUrl/api/v1/clinics/$clinicId/available-dates/",
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await _getHeaders(requireAuth: true),
      );

      if (response.statusCode == 200) {
        return AvailableDatesResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to load available dates: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error getting available dates: $e');
      rethrow;
    }
  }

  /// Get available time slots for a specific date
  Future<AvailableSlotsResponse> getAvailableSlots(
    int clinicId,
    String date, {
    int duration = 30,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final uri =
          Uri.parse(
            "$baseUrl/api/v1/clinics/$clinicId/available-slots/",
          ).replace(
            queryParameters: {'date': date, 'duration': duration.toString()},
          );

      final response = await http.get(
        uri,
        headers: await _getHeaders(requireAuth: true),
      );

      if (response.statusCode == 200) {
        return AvailableSlotsResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to load available slots: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error getting available slots: $e');
      rethrow;
    }
  }

  /// Create a new appointment
  Future<CreateAppointmentResponse> createAppointment(
    CreateAppointmentRequest request,
  ) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/v1/appointments/create/");

      final response = await http.post(
        url,
        headers: await _getHeaders(requireAuth: true),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        return CreateAppointmentResponse.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData.toString());
      }
    } catch (e) {
      print('Error creating appointment: $e');
      rethrow;
    }
  }

  /// Get list of user's appointments
  Future<List<AppointmentListItem>> getMyAppointments({
    String? status,
    bool? upcoming,
    int? pet,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final queryParams = <String, String>{};

      if (status != null) queryParams['status'] = status;
      if (upcoming != null) queryParams['upcoming'] = upcoming.toString();
      if (pet != null) queryParams['pet'] = pet.toString();

      final uri = Uri.parse(
        "$baseUrl/api/v1/appointments/",
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: await _getHeaders(requireAuth: true),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AppointmentListItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load appointments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting appointments: $e');
      rethrow;
    }
  }

  /// Get appointment details
  Future<AppointmentDetail> getAppointmentDetail(int appointmentId) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse("$baseUrl/api/v1/appointments/$appointmentId/");

      final response = await http.get(
        url,
        headers: await _getHeaders(requireAuth: true),
      );

      if (response.statusCode == 200) {
        return AppointmentDetail.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to load appointment detail: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error getting appointment detail: $e');
      rethrow;
    }
  }

  /// Cancel user's appointment
  Future<void> cancelAppointment(int appointmentId, {String? reason}) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse(
        "$baseUrl/api/v1/appointments/$appointmentId/cancel/",
      );

      final body = <String, dynamic>{};
      if (reason != null && reason.isNotEmpty) {
        body['cancellation_reason'] = reason;
      }

      final response = await http.post(
        url,
        headers: await _getHeaders(requireAuth: true),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to cancel appointment');
      }
    } catch (e) {
      print('Error cancelling appointment: $e');
      rethrow;
    }
  }

  // ==================== CLINIC SIDE ====================

  /// Get list of clinic's appointments (for clinic owners)
  Future<List<ClinicAppointmentItem>> getClinicAppointments({
    String? status,
    String? date,
    bool? upcoming,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final queryParams = <String, String>{};

      if (status != null) queryParams['status'] = status;
      if (date != null) queryParams['date'] = date;
      if (upcoming != null) queryParams['upcoming'] = upcoming.toString();

      final uri = Uri.parse(
        "$baseUrl/api/v1/clinics/my/appointments/",
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: await _getHeaders(requireAuth: true),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => ClinicAppointmentItem.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to load clinic appointments: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error getting clinic appointments: $e');
      rethrow;
    }
  }

  /// Get clinic appointment details
  Future<ClinicAppointmentItem> getClinicAppointmentDetail(
    int appointmentId,
  ) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse(
        "$baseUrl/api/v1/clinics/my/appointments/$appointmentId/",
      );

      final response = await http.get(
        url,
        headers: await _getHeaders(requireAuth: true),
      );

      if (response.statusCode == 200) {
        return ClinicAppointmentItem.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to load clinic appointment detail: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error getting clinic appointment detail: $e');
      rethrow;
    }
  }

  /// Update appointment status (for clinic owners)
  Future<void> updateAppointmentStatus(
    int appointmentId,
    String status, {
    String? cancellationReason,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse(
        "$baseUrl/api/v1/clinics/my/appointments/$appointmentId/update/",
      );

      final body = <String, dynamic>{'status': status};
      if (cancellationReason != null && cancellationReason.isNotEmpty) {
        body['cancellation_reason'] = cancellationReason;
      }

      final response = await http.patch(
        url,
        headers: await _getHeaders(requireAuth: true),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ?? 'Failed to update appointment status',
        );
      }
    } catch (e) {
      print('Error updating appointment status: $e');
      rethrow;
    }
  }

  /// Confirm an appointment (convenience method)
  Future<void> confirmAppointment(int appointmentId) async {
    await updateAppointmentStatus(appointmentId, 'CONFIRMED');
  }

  /// Cancel appointment by clinic (convenience method)
  Future<void> cancelAppointmentByClinic(
    int appointmentId,
    String reason,
  ) async {
    await updateAppointmentStatus(
      appointmentId,
      'CANCELLED_CLINIC',
      cancellationReason: reason,
    );
  }

  /// Mark appointment as completed (convenience method)
  Future<void> completeAppointment(int appointmentId) async {
    await updateAppointmentStatus(appointmentId, 'COMPLETED');
  }

  /// Mark appointment as no-show (convenience method)
  Future<void> markNoShow(int appointmentId) async {
    await updateAppointmentStatus(appointmentId, 'NO_SHOW');
  }
}
