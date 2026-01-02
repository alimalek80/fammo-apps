// Models for appointment booking system

import 'dart:ui';
import 'package:flutter/material.dart';

/// Appointment reason for booking
class AppointmentReason {
  final int id;
  final String name;
  final String description;

  AppointmentReason({
    required this.id,
    required this.name,
    required this.description,
  });

  factory AppointmentReason.fromJson(Map<String, dynamic> json) {
    return AppointmentReason(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description};
  }
}

/// Available date for a clinic
class AvailableDate {
  final String date;
  final String dayName;
  final String openTime;
  final String closeTime;

  AvailableDate({
    required this.date,
    required this.dayName,
    required this.openTime,
    required this.closeTime,
  });

  factory AvailableDate.fromJson(Map<String, dynamic> json) {
    return AvailableDate(
      date: json['date'] ?? '',
      dayName: json['day_name'] ?? '',
      openTime: json['open_time'] ?? '',
      closeTime: json['close_time'] ?? '',
    );
  }
}

/// Available dates response from API
class AvailableDatesResponse {
  final int clinicId;
  final String clinicName;
  final List<AvailableDate> availableDates;

  AvailableDatesResponse({
    required this.clinicId,
    required this.clinicName,
    required this.availableDates,
  });

  factory AvailableDatesResponse.fromJson(Map<String, dynamic> json) {
    return AvailableDatesResponse(
      clinicId: json['clinic_id'] ?? 0,
      clinicName: json['clinic_name'] ?? '',
      availableDates:
          (json['available_dates'] as List?)
              ?.map((e) => AvailableDate.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Available slots response from API
class AvailableSlotsResponse {
  final String date;
  final bool isOpen;
  final List<String> slots;
  final WorkingHours? workingHours;

  AvailableSlotsResponse({
    required this.date,
    required this.isOpen,
    required this.slots,
    this.workingHours,
  });

  factory AvailableSlotsResponse.fromJson(Map<String, dynamic> json) {
    return AvailableSlotsResponse(
      date: json['date'] ?? '',
      isOpen: json['is_open'] ?? false,
      slots: (json['slots'] as List?)?.map((e) => e.toString()).toList() ?? [],
      workingHours: json['working_hours'] != null
          ? WorkingHours.fromJson(json['working_hours'])
          : null,
    );
  }
}

/// Working hours for a specific day
class WorkingHours {
  final String openTime;
  final String closeTime;

  WorkingHours({required this.openTime, required this.closeTime});

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      openTime: json['open_time'] ?? '',
      closeTime: json['close_time'] ?? '',
    );
  }
}

/// Appointment status enum
enum AppointmentStatus {
  pending('PENDING', 'Pending'),
  confirmed('CONFIRMED', 'Confirmed'),
  cancelledUser('CANCELLED_USER', 'Cancelled by User'),
  cancelledClinic('CANCELLED_CLINIC', 'Cancelled by Clinic'),
  completed('COMPLETED', 'Completed'),
  noShow('NO_SHOW', 'No Show');

  final String value;
  final String display;

  const AppointmentStatus(this.value, this.display);

  static AppointmentStatus fromString(String value) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AppointmentStatus.pending,
    );
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.pending:
        return const Color(0xFFFFA500); // Orange
      case AppointmentStatus.confirmed:
        return const Color(0xFF4CAF50); // Green
      case AppointmentStatus.cancelledUser:
      case AppointmentStatus.cancelledClinic:
        return const Color(0xFFF44336); // Red
      case AppointmentStatus.completed:
        return const Color(0xFF2196F3); // Blue
      case AppointmentStatus.noShow:
        return const Color(0xFF9E9E9E); // Gray
    }
  }

  IconData get icon {
    switch (this) {
      case AppointmentStatus.pending:
        return Icons.hourglass_empty;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.cancelledUser:
      case AppointmentStatus.cancelledClinic:
        return Icons.cancel;
      case AppointmentStatus.completed:
        return Icons.task_alt;
      case AppointmentStatus.noShow:
        return Icons.person_off;
    }
  }
}

/// Appointment list item for displaying in lists
class AppointmentListItem {
  final int id;
  final String referenceCode;
  final String petName;
  final String petType;
  final String clinicName;
  final String clinicAddress;
  final String appointmentDate;
  final String appointmentTime;
  final int durationMinutes;
  final String? reasonName;
  final String? reasonText;
  final String status;
  final String statusDisplay;
  final bool isUpcoming;
  final bool canCancel;
  final DateTime createdAt;

  AppointmentListItem({
    required this.id,
    required this.referenceCode,
    required this.petName,
    required this.petType,
    required this.clinicName,
    required this.clinicAddress,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.durationMinutes,
    this.reasonName,
    this.reasonText,
    required this.status,
    required this.statusDisplay,
    required this.isUpcoming,
    required this.canCancel,
    required this.createdAt,
  });

  factory AppointmentListItem.fromJson(Map<String, dynamic> json) {
    return AppointmentListItem(
      id: json['id'] ?? 0,
      referenceCode: json['reference_code'] ?? '',
      petName: json['pet_name'] ?? '',
      petType: json['pet_type'] ?? '',
      clinicName: json['clinic_name'] ?? '',
      clinicAddress: json['clinic_address'] ?? '',
      appointmentDate: json['appointment_date'] ?? '',
      appointmentTime: json['appointment_time'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 30,
      reasonName: json['reason_name'],
      reasonText: json['reason_text'],
      status: json['status'] ?? 'PENDING',
      statusDisplay: json['status_display'] ?? 'Pending',
      isUpcoming: json['is_upcoming'] ?? false,
      canCancel: json['can_cancel'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  AppointmentStatus get statusEnum => AppointmentStatus.fromString(status);
}

/// Pet info in appointment detail
class AppointmentPet {
  final int id;
  final String name;
  final String? petType;
  final String? breed;
  final String? image;

  AppointmentPet({
    required this.id,
    required this.name,
    this.petType,
    this.breed,
    this.image,
  });

  factory AppointmentPet.fromJson(Map<String, dynamic> json) {
    return AppointmentPet(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      petType: json['pet_type'],
      breed: json['breed'],
      image: json['image'],
    );
  }
}

/// User info in appointment detail
class AppointmentUser {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;

  AppointmentUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  factory AppointmentUser.fromJson(Map<String, dynamic> json) {
    return AppointmentUser(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

/// Clinic info in appointment detail
class AppointmentClinic {
  final int id;
  final String name;
  final String slug;
  final String city;
  final String address;
  final String? latitude;
  final String? longitude;
  final String phone;
  final String email;
  final String? website;
  final String? instagram;
  final String specializations;
  final String? logo;
  final bool isVerified;
  final bool emailConfirmed;
  final bool adminApproved;
  final bool isActiveClinic;
  final String? referralCode;

  AppointmentClinic({
    required this.id,
    required this.name,
    required this.slug,
    required this.city,
    required this.address,
    this.latitude,
    this.longitude,
    required this.phone,
    required this.email,
    this.website,
    this.instagram,
    required this.specializations,
    this.logo,
    required this.isVerified,
    required this.emailConfirmed,
    required this.adminApproved,
    required this.isActiveClinic,
    this.referralCode,
  });

  factory AppointmentClinic.fromJson(Map<String, dynamic> json) {
    return AppointmentClinic(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      website: json['website'],
      instagram: json['instagram'],
      specializations: json['specializations'] ?? '',
      logo: json['logo'],
      isVerified: json['is_verified'] ?? false,
      emailConfirmed: json['email_confirmed'] ?? false,
      adminApproved: json['admin_approved'] ?? false,
      isActiveClinic: json['is_active_clinic'] ?? false,
      referralCode: json['referral_code'],
    );
  }
}

/// Detailed appointment information
class AppointmentDetail {
  final int id;
  final String referenceCode;
  final AppointmentPet pet;
  final AppointmentUser user;
  final AppointmentClinic clinic;
  final String appointmentDate;
  final String appointmentTime;
  final int durationMinutes;
  final AppointmentReason? reason;
  final String? reasonText;
  final String? notes;
  final String status;
  final String statusDisplay;
  final bool isUpcoming;
  final bool canCancel;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppointmentDetail({
    required this.id,
    required this.referenceCode,
    required this.pet,
    required this.user,
    required this.clinic,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.durationMinutes,
    this.reason,
    this.reasonText,
    this.notes,
    required this.status,
    required this.statusDisplay,
    required this.isUpcoming,
    required this.canCancel,
    this.confirmedAt,
    this.cancelledAt,
    required this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppointmentDetail.fromJson(Map<String, dynamic> json) {
    return AppointmentDetail(
      id: json['id'] ?? 0,
      referenceCode: json['reference_code'] ?? '',
      pet: AppointmentPet.fromJson(json['pet']),
      user: AppointmentUser.fromJson(json['user']),
      clinic: AppointmentClinic.fromJson(json['clinic']),
      appointmentDate: json['appointment_date'] ?? '',
      appointmentTime: json['appointment_time'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 30,
      reason: json['reason'] != null
          ? AppointmentReason.fromJson(json['reason'])
          : null,
      reasonText: json['reason_text'],
      notes: json['notes'],
      status: json['status'] ?? 'PENDING',
      statusDisplay: json['status_display'] ?? 'Pending',
      isUpcoming: json['is_upcoming'] ?? false,
      canCancel: json['can_cancel'] ?? false,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      cancellationReason: json['cancellation_reason'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  AppointmentStatus get statusEnum => AppointmentStatus.fromString(status);
}

/// Clinic appointment item (for clinic owners)
class ClinicAppointmentItem {
  final int id;
  final String referenceCode;
  final AppointmentPet pet;
  final AppointmentUser user;
  final String appointmentDate;
  final String appointmentTime;
  final int durationMinutes;
  final AppointmentReason? reason;
  final String? reasonText;
  final String? notes;
  final String status;
  final String statusDisplay;
  final DateTime? confirmedAt;
  final DateTime createdAt;

  ClinicAppointmentItem({
    required this.id,
    required this.referenceCode,
    required this.pet,
    required this.user,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.durationMinutes,
    this.reason,
    this.reasonText,
    this.notes,
    required this.status,
    required this.statusDisplay,
    this.confirmedAt,
    required this.createdAt,
  });

  factory ClinicAppointmentItem.fromJson(Map<String, dynamic> json) {
    return ClinicAppointmentItem(
      id: json['id'] ?? 0,
      referenceCode: json['reference_code'] ?? '',
      pet: AppointmentPet.fromJson(json['pet']),
      user: AppointmentUser.fromJson(json['user']),
      appointmentDate: json['appointment_date'] ?? '',
      appointmentTime: json['appointment_time'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 30,
      reason: json['reason'] != null
          ? AppointmentReason.fromJson(json['reason'])
          : null,
      reasonText: json['reason_text'],
      notes: json['notes'],
      status: json['status'] ?? 'PENDING',
      statusDisplay: json['status_display'] ?? 'Pending',
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  AppointmentStatus get statusEnum => AppointmentStatus.fromString(status);
}

/// Request body for creating an appointment
class CreateAppointmentRequest {
  final int clinic;
  final int pet;
  final String appointmentDate;
  final String appointmentTime;
  final int? reason;
  final String? reasonText;
  final String? notes;

  CreateAppointmentRequest({
    required this.clinic,
    required this.pet,
    required this.appointmentDate,
    required this.appointmentTime,
    this.reason,
    this.reasonText,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'clinic': clinic,
      'pet': pet,
      'appointment_date': appointmentDate,
      'appointment_time': appointmentTime,
      if (reason != null) 'reason': reason,
      if (reasonText != null && reasonText!.isNotEmpty)
        'reason_text': reasonText,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

/// Response after creating an appointment
class CreateAppointmentResponse {
  final int id;
  final String referenceCode;
  final int clinic;
  final int pet;
  final String appointmentDate;
  final String appointmentTime;
  final int durationMinutes;
  final int? reason;
  final String? reasonText;
  final String? notes;
  final String status;
  final DateTime createdAt;

  CreateAppointmentResponse({
    required this.id,
    required this.referenceCode,
    required this.clinic,
    required this.pet,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.durationMinutes,
    this.reason,
    this.reasonText,
    this.notes,
    required this.status,
    required this.createdAt,
  });

  factory CreateAppointmentResponse.fromJson(Map<String, dynamic> json) {
    return CreateAppointmentResponse(
      id: json['id'] ?? 0,
      referenceCode: json['reference_code'] ?? '',
      clinic: json['clinic'] ?? 0,
      pet: json['pet'] ?? 0,
      appointmentDate: json['appointment_date'] ?? '',
      appointmentTime: json['appointment_time'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 30,
      reason: json['reason'],
      reasonText: json['reason_text'],
      notes: json['notes'],
      status: json['status'] ?? 'PENDING',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
