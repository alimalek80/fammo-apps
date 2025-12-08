import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Clinic registration payload should succeed (non-500)', () async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'clinic_test_$timestamp@example.com';

    final payload = {
      "email": email,
      "password": "TestClinic123!",
      "password_confirm": "TestClinic123!",
      "first_name": "Ali",
      "last_name": "Malek",
      "clinic_name": "SuperVet Clinic",
      "address": "123 Main St, Istanbul",
      "city": "Istanbul",
      "phone": "+90 555 123 4567",
      "email_clinic": "contact@supervet.com",
      "website": "https://supervet.com",
      "instagram": "@supervetistanbul",
      "specializations": "Dogs, Cats, Birds",
      "bio": "SuperVet Clinic provides top care for all pets.",
      "clinic_eoi": true,
      "vet_name": "Dr. Orhan Demir",
      "degrees": "DVM, PhD",
      "certifications": "Board Certified",
      "latitude": 41.0082,
      "longitude": 28.9784,
      "working_hours": [
        {"day_of_week": 0, "is_closed": false, "open_time": "09:00", "close_time": "18:00"},
        {"day_of_week": 1, "is_closed": false, "open_time": "09:00", "close_time": "18:00"},
        {"day_of_week": 2, "is_closed": false, "open_time": "09:00", "close_time": "18:00"},
        {"day_of_week": 3, "is_closed": false, "open_time": "09:00", "close_time": "18:00"},
        {"day_of_week": 4, "is_closed": false, "open_time": "09:00", "close_time": "18:00"},
        {"day_of_week": 5, "is_closed": false, "open_time": "09:00", "close_time": "20:00"},
        {"day_of_week": 6, "is_closed": true, "open_time": null, "close_time": null}
      ]
    };

    final response = await http.post(
      Uri.parse('https://fammo.ai/api/v1/clinics/register/'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': 'en',
      },
      body: jsonEncode(payload),
    );

    // Log the raw response to help diagnose backend behaviour.
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    expect(response.statusCode, anyOf(200, 201),
        reason: 'Expected a successful clinic registration response');
  });
}
