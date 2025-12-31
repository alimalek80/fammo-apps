import 'package:flutter/material.dart';
import '../services/legal_documents_service.dart';
import '../services/language_service.dart';
import '../utils/app_localizations.dart';
import 'paw_loading_indicator.dart';
import 'legal_document_viewer.dart';

class LegalAgreements extends StatefulWidget {
  final bool isClinicRegistration;
  final Function(Map<String, bool>) onAgreementChanged;
  final Map<String, bool> initialAgreements;

  const LegalAgreements({
    super.key,
    required this.isClinicRegistration,
    required this.onAgreementChanged,
    this.initialAgreements = const {},
  });

  @override
  State<LegalAgreements> createState() => _LegalAgreementsState();
}

class _LegalAgreementsState extends State<LegalAgreements> {
  final LegalDocumentsService _legalService = LegalDocumentsService();
  
  Map<String, LegalDocument?> _documents = {};
  Map<String, bool> _agreements = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _agreements = Map.from(widget.initialAgreements);
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    try {
      Map<String, LegalDocument?> docs;
      if (widget.isClinicRegistration) {
        docs = await _legalService.getClinicRegistrationDocuments();
      } else {
        docs = await _legalService.getUserRegistrationDocuments();
      }

      setState(() {
        _documents = docs;
        _isLoading = false;
        
        // Initialize agreements if not already set
        if (widget.isClinicRegistration) {
          _agreements['clinicTerms'] ??= false;
          _agreements['partnership'] ??= false;
          _agreements['privacy'] ??= false;
          _agreements['eoi'] ??= false;
        } else {
          _agreements['terms'] ??= false;
          _agreements['privacy'] ??= false;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading legal documents: $e');
    }
  }

  void _onAgreementChanged(String key, bool value) {
    setState(() {
      _agreements[key] = value;
    });
    widget.onAgreementChanged(_agreements);
  }

  void _openDocument(String docType, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LegalDocumentViewer(
          docType: docType,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: LanguageService().getLocalLanguage(),
      builder: (context, snapshot) {
        String languageCode = snapshot.data ?? 'en';
        AppLocalizations loc = AppLocalizations(languageCode);

        if (_isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: PawLoadingIndicator(),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.isClinicRegistration
                ? _buildClinicAgreements(loc)
                : _buildUserAgreements(loc),
          ),
        );
      },
    );
  }

  List<Widget> _buildUserAgreements(AppLocalizations loc) {
    return [
      // Terms and Conditions + Privacy Policy combined checkbox
      CheckboxListTile(
        value: _agreements['terms'] == true && _agreements['privacy'] == true,
        onChanged: (value) {
          _onAgreementChanged('terms', value ?? false);
          _onAgreementChanged('privacy', value ?? false);
        },
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C3E50),
            ),
            children: [
              TextSpan(text: '${loc.iAgreeToThe} '),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => _openDocument('user_terms', loc.termsAndConditions),
                  child: Text(
                    loc.termsAndConditions,
                    style: const TextStyle(
                      color: Color(0xFF26B5A4),
                      decoration: TextDecoration.underline,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              TextSpan(text: ' ${loc.and} '),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => _openDocument('user_privacy', loc.privacyPolicy),
                  child: Text(
                    loc.privacyPolicy,
                    style: const TextStyle(
                      color: Color(0xFF26B5A4),
                      decoration: TextDecoration.underline,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildClinicAgreements(AppLocalizations loc) {
    return [
      // 1. Clinic Terms and Conditions
      CheckboxListTile(
        value: _agreements['clinicTerms'] ?? false,
        onChanged: (value) => _onAgreementChanged('clinicTerms', value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C3E50),
            ),
            children: [
              TextSpan(text: '${loc.iAgreeToThe} '),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => _openDocument('clinic_terms', loc.clinicTermsAndConditions),
                  child: Text(
                    loc.clinicTermsAndConditions,
                    style: const TextStyle(
                      color: Color(0xFF26B5A4),
                      decoration: TextDecoration.underline,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // 2. Clinic Partnership Agreement
      CheckboxListTile(
        value: _agreements['partnership'] ?? false,
        onChanged: (value) => _onAgreementChanged('partnership', value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C3E50),
            ),
            children: [
              TextSpan(text: '${loc.iAgreeToThe} '),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => _openDocument('clinic_partnership', loc.clinicPartnershipAgreement),
                  child: Text(
                    loc.clinicPartnershipAgreement,
                    style: const TextStyle(
                      color: Color(0xFF26B5A4),
                      decoration: TextDecoration.underline,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // 3. Privacy Policy
      CheckboxListTile(
        value: _agreements['privacy'] ?? false,
        onChanged: (value) => _onAgreementChanged('privacy', value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C3E50),
            ),
            children: [
              TextSpan(text: '${loc.iAgreeToThe} '),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => _openDocument('user_privacy', loc.privacyPolicy),
                  child: Text(
                    loc.privacyPolicy,
                    style: const TextStyle(
                      color: Color(0xFF26B5A4),
                      decoration: TextDecoration.underline,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // 4. EOI Terms (Optional)
      if (_documents['eoi'] != null)
        CheckboxListTile(
          value: _agreements['eoi'] ?? false,
          onChanged: (value) => _onAgreementChanged('eoi', value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2C3E50),
              ),
              children: [
                TextSpan(text: '${loc.iAgreeToThe} '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => _openDocument('clinic_eoi', loc.eoiTerms),
                    child: Text(
                      loc.eoiTerms,
                      style: const TextStyle(
                        color: Color(0xFF26B5A4),
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                TextSpan(
                  text: ' ${loc.optionalForPilotProgram}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  bool get hasRequiredAgreements {
    if (widget.isClinicRegistration) {
      return (_agreements['clinicTerms'] ?? false) &&
             (_agreements['partnership'] ?? false) &&
             (_agreements['privacy'] ?? false);
    } else {
      return (_agreements['terms'] ?? false) &&
             (_agreements['privacy'] ?? false);
    }
  }

  Map<String, int?> get documentIds {
    return _documents.map((key, doc) => MapEntry(key, doc?.id));
  }
}