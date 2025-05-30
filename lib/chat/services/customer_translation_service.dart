// lib/chat/services/customer_translation_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class CustomerTranslationService {
  // 싱글톤 패턴 구현
  static final CustomerTranslationService _instance = CustomerTranslationService._internal();
  factory CustomerTranslationService() => _instance;
  CustomerTranslationService._internal();

  // Google Translation API 사용
  static const String _baseUrl = 'https://translation.googleapis.com/language/translate/v2';

  // API 키 - 실제 키로 교체해야 함
  static const String _apiKey = 'AIzaSyAAfi5e2l_0DmWBiwIWqB7kKyzj9uiHlGk';

  // 번역 요청 함수 - 한국어로 고정
  Future<String> translateText(String text) async {
    try {
      // 번역할 텍스트가 없는 경우 그대로 반환
      if (text.isEmpty) {
        return text;
      }

      // HTTP 요청 보내기
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'q': text,
          'target': 'ko', // 항상 한국어로 고정
        }),
      );

      // 응답 확인
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final translations = data['data']['translations'] as List;

        if (translations.isNotEmpty) {
          return translations[0]['translatedText'];
        }
      }

      // 에러 로깅
      debugPrint('번역 API 오류: ${response.statusCode} - ${response.body}');
      return text; // 실패 시 원본 텍스트 반환
    } catch (e) {
      debugPrint('번역 오류: $e');
      return text; // 예외 발생 시 원본 텍스트 반환
    }
  }
}