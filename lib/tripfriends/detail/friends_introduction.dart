import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FriendsIntroduction extends StatefulWidget {
  final Map<String, dynamic> friends;

  const FriendsIntroduction({
    Key? key,
    required this.friends,
  }) : super(key: key);

  @override
  State<FriendsIntroduction> createState() => _FriendsIntroductionState();
}

class _FriendsIntroductionState extends State<FriendsIntroduction> {
  String _introduction = '';
  String _translatedIntroduction = '';
  bool _isLoading = true;
  bool _isTranslating = false;
  bool _isTranslated = false;

  @override
  void initState() {
    super.initState();
    _loadIntroduction();
  }

  Future<void> _loadIntroduction() async {
    try {
      // 안전하게 introduction 가져오기
      final introduction = widget.friends['introduction'];
      if (introduction != null && introduction.toString().trim().isNotEmpty) {
        setState(() {
          _introduction = introduction;
          _isLoading = false;
        });
      } else {
        final userDoc = await FirebaseFirestore.instance
            .collection('tripfriends_users')
            .doc(widget.friends['uid'])
            .get();

        final docIntroduction = userDoc.data()?['introduction'];
        if (userDoc.exists &&
            docIntroduction != null &&
            docIntroduction.toString().trim().isNotEmpty) {
          setState(() {
            _introduction = docIntroduction;
            _isLoading = false;
          });
        } else {
          setState(() {
            _introduction = '자기소개가 없습니다.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _introduction = '자기소개가 없습니다.';
        _isLoading = false;
      });
      print('소개글 로딩 오류: $e');
    }
  }

  Future<void> _translateText() async {
    if (_isTranslated) {
      setState(() {
        _isTranslated = false;
      });
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      print('번역 시작...');

      final apiKey = dotenv.env['GOOGLE_CLOUD_API_KEY'];
      if (apiKey == null) {
        throw Exception('Google Cloud API Key not found in .env file');
      }

      final url = 'https://translation.googleapis.com/language/translate/v2?key=$apiKey';

      print('번역할 텍스트: $_introduction');
      print('API URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'q': _introduction,
          'target': 'ko',
          'format': 'text',
        }),
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('디코딩된 응답 데이터: $data');

        if (data.containsKey('data') &&
            data['data'].containsKey('translations') &&
            data['data']['translations'].isNotEmpty) {

          final translations = data['data']['translations'];
          print('번역 결과: $translations');

          setState(() {
            _translatedIntroduction = translations[0]['translatedText'];
            _isTranslated = true;
            _isTranslating = false;
          });
          print('번역 성공: $_translatedIntroduction');
        } else {
          print('번역 응답 형식 오류: 예상된 필드가 없음 - $data');
          setState(() {
            _isTranslating = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('번역 응답 형식 오류')),
          );
        }
      } else {
        print('번역 API 오류 - 상태 코드: ${response.statusCode}');
        print('오류 세부 정보: ${response.body}');
        setState(() {
          _isTranslating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('번역 API 오류: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('번역 중 예외 발생: $e');
      print('스택 트레이스: ${StackTrace.current}');
      setState(() {
        _isTranslating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('번역 중 오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '프렌즈 소개말',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF353535),
                ),
              ),
              if (!_isLoading)
                GestureDetector(
                  onTap: _isTranslating ? null : _translateText,
                  child: Text(
                    _isTranslated ? '원문 보기' : '번역하기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _isTranslating
                          ? Color(0xFFBBBBBB)
                          : Color(0xFF237AFF),
                      decoration: TextDecoration.underline,
                      decorationColor: _isTranslating
                          ? Color(0xFFBBBBBB)
                          : Color(0xFF237AFF),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_isTranslating)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text(
                    '번역 중...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Text(
                _isTranslated ? _translatedIntroduction : _introduction,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF666666),
                ),
              ),
            ),
        ],
      ),
    );
  }
}