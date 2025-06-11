// lib/auth/user_info_input_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/main_page.dart';
import '../utils/shared_preferences_util.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _homeLocationController.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '회원정보 입력',
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                '생년월일',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF424242),
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
                          hint: const Text('YYYY', style: TextStyle(color: Color(0xFFBDBDBD))),
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
                          hint: const Text('MM', style: TextStyle(color: Color(0xFFBDBDBD))),
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
                          hint: const Text('DD', style: TextStyle(color: Color(0xFFBDBDBD))),
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
              const SizedBox(height: 16),
              const Text(
                '휴대폰번호',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: '- 없이 입력',
                  hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              const Text(
                '성별',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF424242),
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
              const Spacer(),
              Container(
                width: double.infinity,
                height: 55,
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveUserInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7269F7),
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
            ],
          ),
        ),
      ),
    );
  }
}