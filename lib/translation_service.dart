import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  // 모든 데이터를 저장할 통합 맵
  final Map<String, dynamic> _data = {};

  // 로딩 완료 여부
  bool _isLoaded = false;

  // 지원하는 JSON 파일 목록
  final List<String> _jsonFiles = [
    'translations.json',
    'auth_translations.json',
    'bottom_translations.json',
    'mypage_translations.json',
    'city.json',
    'country.json',
    'currency.json',
    'db.json',
    'exchange.json'
  ];

  Future<void> loadTranslations() async {
    if (_isLoaded) return;

    // 모든 JSON 파일을 병렬로 로드
    await Future.wait(_jsonFiles.map((file) async {
      try {
        final String path = 'assets/data/$file';
        final String jsonString = await rootBundle.loadString(path);
        final dynamic jsonData = json.decode(jsonString);

        // 파일명에서 확장자 제거하여 키로 사용
        final String key = file.split('.').first;
        _data[key] = jsonData;
      } catch (e) {
        print('Failed to load $file: $e');
      }
    }));

    _isLoaded = true;
  }

  // 번역 텍스트 가져오기 (모든 번역 파일 통합 검색)
  String getTranslatedText(String key, {String lang = 'KR'}) {
    // 번역 데이터가 포함된 파일들 목록
    final translationFiles = [
      'translations',
      'auth_translations',
      'bottom_translations',
      'mypage_translations'
    ];

    // 모든 번역 파일에서 검색
    for (final file in translationFiles) {
      final translations = _data[file]?['translations'];
      if (translations != null && translations[key] != null) {
        return translations[key][lang] ?? key;
      }
    }

    return key;
  }

  // 특정 데이터 가져오기
  dynamic getData(String category, {String? id}) {
    if (id == null) {
      return _data[category];
    }
    return _data[category]?[id];
  }

  // 도시 정보 가져오기
  Map<String, dynamic>? getCityData(String cityId) {
    return _data['city']?[cityId];
  }

  // 국가 정보 가져오기
  Map<String, dynamic>? getCountryData(String countryCode) {
    return _data['country']?[countryCode];
  }

  // 환율 정보 가져오기
  double getExchangeRate(String fromCurrency, String toCurrency) {
    return _data['exchange']?[fromCurrency]?[toCurrency] ?? 1.0;
  }
}