class Clinic {
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
  final String? workingHours;
  final String bio;
  final String? logo;
  final bool isVerified;
  final bool emailConfirmed;
  final bool adminApproved;
  final bool isActiveClinic;
  final bool clinicEoi;
  final String? ownerEmail;
  final List<WorkingHoursSchedule>? workingHoursSchedule;
  final List<String>? formattedWorkingHours;
  final VetProfile? vetProfile;
  final List<ReferralCode>? referralCodes;
  final String? activeReferralCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Clinic({
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
    this.workingHours,
    required this.bio,
    this.logo,
    required this.isVerified,
    required this.emailConfirmed,
    required this.adminApproved,
    required this.isActiveClinic,
    required this.clinicEoi,
    this.ownerEmail,
    this.workingHoursSchedule,
    this.formattedWorkingHours,
    this.vetProfile,
    this.referralCodes,
    this.activeReferralCode,
    this.createdAt,
    this.updatedAt,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'],
      longitude: json['longitude'],
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      website: json['website'],
      instagram: json['instagram'],
      specializations: json['specializations'] ?? '',
      workingHours: json['working_hours'],
      bio: json['bio'] ?? '',
      logo: json['logo'],
      isVerified: json['is_verified'] ?? false,
      emailConfirmed: json['email_confirmed'] ?? false,
      adminApproved: json['admin_approved'] ?? false,
      isActiveClinic: json['is_active_clinic'] ?? false,
      clinicEoi: json['clinic_eoi'] ?? false,
      ownerEmail: json['owner_email'],
      workingHoursSchedule: json['working_hours_schedule'] != null
          ? (json['working_hours_schedule'] as List)
              .map((e) => WorkingHoursSchedule.fromJson(e))
              .toList()
          : null,
      formattedWorkingHours: json['formatted_working_hours'] != null
          ? List<String>.from(json['formatted_working_hours'])
          : null,
      vetProfile: json['vet_profile'] != null
          ? VetProfile.fromJson(json['vet_profile'])
          : null,
      referralCodes: json['referral_codes'] != null
          ? (json['referral_codes'] as List)
              .map((e) => ReferralCode.fromJson(e))
              .toList()
          : null,
      activeReferralCode: json['active_referral_code'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'website': website,
      'instagram': instagram,
      'specializations': specializations,
      'working_hours': workingHours,
      'bio': bio,
      'clinic_eoi': clinicEoi,
    };
  }

  Clinic copyWith({
    int? id,
    String? name,
    String? slug,
    String? city,
    String? address,
    String? latitude,
    String? longitude,
    String? phone,
    String? email,
    String? website,
    String? instagram,
    String? specializations,
    String? workingHours,
    String? bio,
    String? logo,
    bool? isVerified,
    bool? emailConfirmed,
    bool? adminApproved,
    bool? isActiveClinic,
    bool? clinicEoi,
    String? ownerEmail,
    List<WorkingHoursSchedule>? workingHoursSchedule,
    List<String>? formattedWorkingHours,
    VetProfile? vetProfile,
    List<ReferralCode>? referralCodes,
    String? activeReferralCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Clinic(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      city: city ?? this.city,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      instagram: instagram ?? this.instagram,
      specializations: specializations ?? this.specializations,
      workingHours: workingHours ?? this.workingHours,
      bio: bio ?? this.bio,
      logo: logo ?? this.logo,
      isVerified: isVerified ?? this.isVerified,
      emailConfirmed: emailConfirmed ?? this.emailConfirmed,
      adminApproved: adminApproved ?? this.adminApproved,
      isActiveClinic: isActiveClinic ?? this.isActiveClinic,
      clinicEoi: clinicEoi ?? this.clinicEoi,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      workingHoursSchedule: workingHoursSchedule ?? this.workingHoursSchedule,
      formattedWorkingHours: formattedWorkingHours ?? this.formattedWorkingHours,
      vetProfile: vetProfile ?? this.vetProfile,
      referralCodes: referralCodes ?? this.referralCodes,
      activeReferralCode: activeReferralCode ?? this.activeReferralCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class WorkingHoursSchedule {
  final int? id;
  final int dayOfWeek;
  final String dayName;
  final bool isClosed;
  final String? openTime;
  final String? closeTime;

  WorkingHoursSchedule({
    this.id,
    required this.dayOfWeek,
    required this.dayName,
    required this.isClosed,
    this.openTime,
    this.closeTime,
  });

  factory WorkingHoursSchedule.fromJson(Map<String, dynamic> json) {
    return WorkingHoursSchedule(
      id: json['id'],
      dayOfWeek: json['day_of_week'],
      dayName: json['day_name'],
      isClosed: json['is_closed'],
      openTime: json['open_time'],
      closeTime: json['close_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'is_closed': isClosed,
      'open_time': openTime,
      'close_time': closeTime,
    };
  }

  static String getDayName(int dayOfWeek) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[dayOfWeek];
  }
}

class VetProfile {
  final int? id;
  final String vetName;
  final String degrees;
  final String certifications;

  VetProfile({
    this.id,
    required this.vetName,
    required this.degrees,
    required this.certifications,
  });

  factory VetProfile.fromJson(Map<String, dynamic> json) {
    return VetProfile(
      id: json['id'],
      vetName: json['vet_name'] ?? '',
      degrees: json['degrees'] ?? '',
      certifications: json['certifications'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vet_name': vetName,
      'degrees': degrees,
      'certifications': certifications,
    };
  }
}

class ReferralCode {
  final int id;
  final String code;
  final bool isActive;
  final DateTime createdAt;

  ReferralCode({
    required this.id,
    required this.code,
    required this.isActive,
    required this.createdAt,
  });

  factory ReferralCode.fromJson(Map<String, dynamic> json) {
    return ReferralCode(
      id: json['id'],
      code: json['code'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
