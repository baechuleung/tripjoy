// lib/auth/user_info_input_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/main_page.dart';
import '../utils/shared_preferences_util.dart';
import 'referrer_code_validator.dart';
import 'dart:ui' as ui;

class UserInfoInputScreen extends StatefulWidget {
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

  const UserInfoInputScreen({
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
  _UserInfoInputScreenState createState() => _UserInfoInputScreenState();
}

class _UserInfoInputScreenState extends State<UserInfoInputScreen> {
  DateTime? _selectedDate;
  String? _selectedGender;
  final TextEditingController _homeLocationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referrerCodeController = TextEditingController();
  bool _isLoading = false;

  // 에러 메시지 상태 변수들
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveUserInfo() async {
    // 에러 상태 초기화
    setState(() {
      _showDateError = false;
      _showPhoneError = false;
      _showGenderError = false;
      _showReferrerCodeError = false;
    });

    // 모든 필드가 입력되었는지 확인
    bool hasError = false;

    if (_selectedDate == null) {
      setState(() {
        _showDateError = true;
      });
      hasError = true;
    }

    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _showPhoneError = true;
      });
      hasError = true;
    }

    if (_selectedGender == null) {
      setState(() {
        _showGenderError = true;
      });
      hasError = true;
    }

    // 추천인 코드 유효성 검증 (선택사항)
    if (_referrerCodeController.text.trim().isNotEmpty) {
      final isValidCode = await ReferrerCodeValidator.validateReferrerCode(
          _referrerCodeController.text.trim()
      );

      if (!isValidCode) {
        setState(() {
          _showReferrerCodeError = true;
        });
        hasError = true;
      }
    }

    if (hasError) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = widget.userCredential.user;
      if (currentUser != null) {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

        String currentLocale = ui.window.locale.languageCode;

        // Firestore에 저장할 데이터
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
          'points': 0,
          'usage_count': 0,
          'is_premium': true,
        };

        // Firestore에 저장
        await userDocRef.set(firestoreData, SetOptions(merge: true));

        // SharedPreferences용 데이터 준비
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
          'points': 0,
          'usage_count': 0,
          'is_premium': true,
        };

        // SharedPreferences에 저장
        await SharedPreferencesUtil.saveUserDocument(prefsData);

        // 메인 페이지로 이동
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 빈 공간을 터치하면 키보드 숨기기
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: SafeArea(
          child: Column(
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
                        const Text(
                          '생년월일',
                          style: TextStyle(
                            color: Color(0xFF4E5968),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE0E0E0)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedDate?.year,
                                    hint: const Text('YYYY', style: TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
                                    )),
                                    style: const TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
                                    ),
                                    items: List.generate(100, (index) => DateTime.now().year - index)
                                        .map((year) => DropdownMenuItem(
                                      value: year,
                                      child: Text(year.toString()),
                                    ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedDate = DateTime(
                                            value,
                                            _selectedDate?.month ?? 1,
                                            _selectedDate?.day ?? 1,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE0E0E0)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedDate?.month,
                                    hint: const Text('MM', style: TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
                                    )),
                                    style: const TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
                                    ),
                                    items: List.generate(12, (index) => index + 1)
                                        .map((month) => DropdownMenuItem(
                                      value: month,
                                      child: Text(month.toString().padLeft(2, '0')),
                                    ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedDate = DateTime(
                                            _selectedDate?.year ?? DateTime.now().year,
                                            value,
                                            _selectedDate?.day ?? 1,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE0E0E0)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedDate?.day,
                                    hint: const Text('DD', style: TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
                                    )),
                                    style: const TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
                                    ),
                                    items: List.generate(31, (index) => index + 1)
                                        .map((day) => DropdownMenuItem(
                                      value: day,
                                      child: Text(day.toString().padLeft(2, '0')),
                                    ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedDate = DateTime(
                                            _selectedDate?.year ?? DateTime.now().year,
                                            _selectedDate?.month ?? 1,
                                            value,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_showDateError) ...[
                          const SizedBox(height: 8),
                          const Text(
                            '생년월일을 입력해주세요',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
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
                        const SizedBox(height: 32),
                        const Text(
                          '성별',
                          style: TextStyle(
                            color: Color(0xFF4E5968),
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedGender = '여성';
                                  });
                                },
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _selectedGender == '여성' ? const Color(0xFFE3F2FD) : Colors.white,
                                    border: Border.all(
                                      color: _selectedGender == '여성' ? const Color(0xFF2196F3) : const Color(0xFFE0E0E0),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '여성',
                                      style: TextStyle(
                                        color: _selectedGender == '여성' ? const Color(0xFF2196F3) : const Color(0xFF757575),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedGender = '남성';
                                  });
                                },
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _selectedGender == '남성' ? const Color(0xFFE3F2FD) : Colors.white,
                                    border: Border.all(
                                      color: _selectedGender == '남성' ? const Color(0xFF2196F3) : const Color(0xFFE0E0E0),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '남성',
                                      style: TextStyle(
                                        color: _selectedGender == '남성' ? const Color(0xFF2196F3) : const Color(0xFF757575),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_showGenderError) ...[
                          const SizedBox(height: 8),
                          const Text(
                            '성별을 선택해주세요',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            const Text(
                              '추천인 코드',
                              style: TextStyle(
                                color: Color(0xFF4E5968),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '선택사항',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE0E0E0)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: _referrerCodeController,
                                  style: const TextStyle(
                                    color: Color(0xFF999999),
                                    fontSize: 12,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '코드를 입력해주세요',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 12,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_referrerCodeController.text.trim().isEmpty) {
                                    setState(() {
                                      _showReferrerCodeError = true;
                                    });
                                    return;
                                  }

                                  setState(() {
                                    _showReferrerCodeError = false;
                                  });

                                  final isValid = await ReferrerCodeValidator.validateReferrerCode(
                                      _referrerCodeController.text.trim()
                                  );

                                  if (!isValid) {
                                    setState(() {
                                      _showReferrerCodeError = true;
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('유효한 추천인 코드입니다.')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF5F5F5),
                                  foregroundColor: const Color(0xFF757575),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '확인',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_showReferrerCodeError) ...[
                          const SizedBox(height: 8),
                          const Text(
                            '추천인 코드가 올바르지 않습니다. 다시 입력해주세요.',
                            style: TextStyle(
                              color: Color(0xFFFF5050),
                              fontSize: 10,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}