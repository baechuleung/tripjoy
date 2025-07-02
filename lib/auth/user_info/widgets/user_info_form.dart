// lib/auth/widgets/user_info_form.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../screens/main_page.dart';
import '../../../utils/shared_preferences_util.dart';
import '../validators/referrer_code_validator.dart';
import '../handlers/referrer_bonus_handler.dart';
import 'birth_date_selector.dart';
import 'gender_selector.dart';
import 'referrer_code_input.dart';
import 'phone_number_input.dart';
import 'dart:ui' as ui;

class UserInfoForm extends StatefulWidget {
  final bool personalInfoConsent;
  final bool locationInfoConsent;
  final bool termsOfServiceConsent;
  final bool thirdPartyConsent;
  final bool marketingConsent;
  final UserCredential userCredential;
  final String displayName;
  final String email;
  final String photoUrl;
  final String loginType;
  final String fcmToken;

  const UserInfoForm({
    Key? key,
    required this.personalInfoConsent,
    required this.locationInfoConsent,
    required this.termsOfServiceConsent,
    required this.thirdPartyConsent,
    required this.marketingConsent,
    required this.userCredential,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.loginType,
    required this.fcmToken,
  }) : super(key: key);

  @override
  _UserInfoFormState createState() => _UserInfoFormState();
}

class _UserInfoFormState extends State<UserInfoForm> {
  DateTime? _selectedDate;
  String? _selectedGender;
  final TextEditingController _homeLocationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referrerCodeController = TextEditingController();
  bool _isLoading = false;

  bool _showDateError = false;
  bool _showPhoneError = false;
  bool _showGenderError = false;
  bool _showReferrerCodeError = false;

  @override
  void dispose() {
    _homeLocationController.dispose();
    _phoneController.dispose();
    _referrerCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveUserInfo() async {
    setState(() {
      _showDateError = false;
      _showPhoneError = false;
      _showGenderError = false;
      _showReferrerCodeError = false;
    });

    bool hasError = false;

    if (_selectedDate == null) {
      setState(() => _showDateError = true);
      hasError = true;
    }

    if (_phoneController.text.trim().isEmpty) {
      setState(() => _showPhoneError = true);
      hasError = true;
    }

    if (_selectedGender == null) {
      setState(() => _showGenderError = true);
      hasError = true;
    }

    bool hasValidReferrerCode = false;
    if (_referrerCodeController.text.trim().isNotEmpty) {
      final isValidCode = await ReferrerCodeValidator.validateReferrerCode(
          _referrerCodeController.text.trim()
      );

      if (!isValidCode) {
        setState(() => _showReferrerCodeError = true);
        hasError = true;
      } else {
        hasValidReferrerCode = true;
      }
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = widget.userCredential.user;
      if (currentUser != null) {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
        String currentLocale = ui.window.locale.languageCode;
        int initialPoints = 3000; // 기본 포인트만 설정

        Map<String, dynamic> firestoreData = {
          'personalInfoConsent': widget.personalInfoConsent,
          'locationInfoConsent': widget.locationInfoConsent,
          'termsOfServiceConsent': widget.termsOfServiceConsent,
          'thirdPartyConsent': widget.thirdPartyConsent,
          'marketingConsent': widget.marketingConsent,
          'name': widget.displayName,
          'email': widget.email,
          'photoUrl': widget.photoUrl,
          'loginType': widget.loginType,
          'fcmToken': widget.fcmToken,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'birthDate': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
          'gender': _selectedGender,
          'homeLocation': _homeLocationController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'referredBy': _referrerCodeController.text.trim().isNotEmpty
              ? _referrerCodeController.text.trim()
              : null,
          'language': currentLocale,
          'points': initialPoints,
          'usage_count': 0,
          'is_premium': true,
        };

        await userDocRef.set(firestoreData, SetOptions(merge: true));

        if (hasValidReferrerCode) {
          await ReferrerBonusHandler.handleReferrerBonus(
            userId: currentUser.uid,
            referrerCode: _referrerCodeController.text.trim(),
            currentPoints: 0,
          );
        }

        Map<String, dynamic> prefsData = {
          'personalInfoConsent': widget.personalInfoConsent,
          'locationInfoConsent': widget.locationInfoConsent,
          'termsOfServiceConsent': widget.termsOfServiceConsent,
          'thirdPartyConsent': widget.thirdPartyConsent,
          'marketingConsent': widget.marketingConsent,
          'name': widget.displayName,
          'email': widget.email,
          'photoUrl': widget.photoUrl,
          'loginType': widget.loginType,
          'fcmToken': widget.fcmToken,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'lastLoginAt': DateTime.now().millisecondsSinceEpoch,
          'birthDate': _selectedDate?.millisecondsSinceEpoch,
          'gender': _selectedGender,
          'homeLocation': _homeLocationController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'referredBy': _referrerCodeController.text.trim().isNotEmpty
              ? _referrerCodeController.text.trim()
              : null,
          'language': currentLocale,
          'points': initialPoints,
          'usage_count': 0,
          'is_premium': true,
        };

        await SharedPreferencesUtil.saveUserDocument(prefsData);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원정보 저장 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    '회원정보 입력',
                    style: TextStyle(
                      color: const Color(0xFF353535),
                      fontSize: 24,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 40),
                  BirthDateSelector(
                    selectedDate: _selectedDate,
                    onDateChanged: (date) => setState(() => _selectedDate = date),
                    showError: _showDateError,
                  ),
                  const SizedBox(height: 32),
                  PhoneNumberInput(
                    controller: _phoneController,
                    showError: _showPhoneError,
                  ),
                  const SizedBox(height: 32),
                  GenderSelector(
                    selectedGender: _selectedGender,
                    onGenderChanged: (gender) => setState(() => _selectedGender = gender),
                    showError: _showGenderError,
                  ),
                  const SizedBox(height: 32),
                  ReferrerCodeInput(
                    controller: _referrerCodeController,
                    showError: _showReferrerCodeError,
                    onErrorChanged: (error) => setState(() => _showReferrerCodeError = error),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '휴대폰번호',
          style: TextStyle(
            color: Color(0xFF4E5968),
            fontSize: 14,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _phoneController,
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 12,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '- 없이 입력',
              hintStyle: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 12,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            keyboardType: TextInputType.phone,
          ),
        ),
        if (_showPhoneError) ...[
          const SizedBox(height: 8),
          const Text(
            '휴대폰 번호를 입력해주세요',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.infinity,
        height: 55,
        margin: const EdgeInsets.only(bottom: 20),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveUserInfo,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4050FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
            '회원가입하기',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}