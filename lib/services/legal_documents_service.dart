import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import 'auth_service.dart';
import 'language_service.dart';

class LegalDocument {
  final int id;
  final String docType;
  final String title;
  final String content;
  final String? version;
  final String? summary;
  final DateTime effectiveDate;
  final DateTime createdAt;

  LegalDocument({
    required this.id,
    required this.docType,
    required this.title,
    required this.content,
    this.version,
    this.summary,
    required this.effectiveDate,
    required this.createdAt,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      id: json['id'],
      docType: json['doc_type'],
      title: json['title'],
      content: json['content'],
      version: json['version'],
      summary: json['summary'],
      effectiveDate: DateTime.parse(json['effective_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class LegalDocumentsService {
  final AuthService _authService = AuthService();
  final LanguageService _languageService = LanguageService();
  
  // Cache for storing documents for 24 hours
  static final Map<String, Map<String, dynamic>> _documentCache = {};
  
  Future<LegalDocument?> getLegalDocument(String docType) async {
    // Check cache first
    final cacheKey = docType;
    final cachedData = _documentCache[cacheKey];
    if (cachedData != null) {
      final cacheTime = cachedData['timestamp'] as DateTime;
      final isValid = DateTime.now().difference(cacheTime).inHours < 24;
      if (isValid) {
        return cachedData['document'] as LegalDocument;
      }
    }

    final baseUrl = await ConfigService.getBaseUrl();
    final languageCode = await _languageService.getLocalLanguage() ?? 'en';
    
    final url = Uri.parse('$baseUrl/api/v1/legal/documents/by_type/?doc_type=$docType');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept-Language': languageCode,
          'Content-Type': 'application/json',
        },
      );

      print('Legal document request: $url');
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final document = LegalDocument.fromJson(data);
        
        // Cache the document
        _documentCache[cacheKey] = {
          'document': document,
          'timestamp': DateTime.now(),
        };
        
        return document;
      }

      return null;
    } catch (e) {
      print('Error fetching legal document: $e');
      return null;
    }
  }

  Future<Map<String, LegalDocument?>> getUserRegistrationDocuments() async {
    final futures = await Future.wait([
      getLegalDocument('user_terms'),
      getLegalDocument('user_privacy'),
    ]);

    return {
      'terms': futures[0],
      'privacy': futures[1],
    };
  }

  Future<Map<String, LegalDocument?>> getClinicRegistrationDocuments() async {
    final futures = await Future.wait([
      getLegalDocument('clinic_terms'),
      getLegalDocument('clinic_partnership'),
      getLegalDocument('user_privacy'),
      getLegalDocument('clinic_eoi'),
    ]);

    return {
      'clinicTerms': futures[0],
      'partnership': futures[1],
      'privacy': futures[2],
      'eoi': futures[3],
    };
  }

  Future<bool> recordUserConsent({
    required int termsDocId,
    required int privacyDocId,
  }) async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) return false;

    final url = Uri.parse('$baseUrl/api/v1/user-consent/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'terms_document_id': termsDocId,
          'privacy_document_id': privacyDocId,
          'consent_given': true,
        }),
      );

      print('Record user consent status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error recording user consent: $e');
      return false;
    }
  }

  Future<bool> recordClinicConsent({
    required int clinicTermsDocId,
    required int partnershipDocId,
    required int privacyDocId,
    int? eoiDocId,
  }) async {
    final baseUrl = await ConfigService.getBaseUrl();
    final accessToken = await _authService.getAccessToken();

    if (accessToken == null) return false;

    final url = Uri.parse('$baseUrl/api/v1/clinic-consent/');

    try {
      final Map<String, dynamic> body = {
        'clinic_terms_document_id': clinicTermsDocId,
        'partnership_document_id': partnershipDocId,
        'privacy_document_id': privacyDocId,
        'consent_given': true,
      };

      if (eoiDocId != null) {
        body['eoi_document_id'] = eoiDocId;
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('Record clinic consent status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error recording clinic consent: $e');
      return false;
    }
  }

  void clearCache() {
    _documentCache.clear();
  }
}