// lib/chat/widgets/plan_show_dialog.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class PlanShowDialog extends StatelessWidget {
  final String countryName;
  final String cityName;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const PlanShowDialog({
    Key? key,
    required this.countryName,
    required this.cityName,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      title: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            const Text(
              '여행 지역 확인',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.all(12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black),
                children: [
                  const TextSpan(
                    text: '현재 프렌즈는 ',
                  ),
                  TextSpan(
                    text: '[$countryName, $cityName] ',
                    style: const TextStyle(
                      color: Color(0xFF353535),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(
                    text: '에서 활동합니다.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black),
                children: [
                  TextSpan(
                    text: '[$countryName, $cityName] ',
                    style: const TextStyle(
                      color: Color(0xFF353535),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(
                    text: '여행이 맞습니까?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.all(12),
      actions: [
        Row(
          children: [
            // 취소 버튼
            Expanded(
              child: ElevatedButton(
                onPressed: onCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4F4F4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  '취소',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 확인 버튼
            Expanded(
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8F2FF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  '확인',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF3182F6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// 국가 코드를 국가 이름으로 변환하는 함수
String getCountryNameFromCode(String countryCode) {
  final Map<String, String> countryMap = {
    'KR': '대한민국',
    'JP': '일본',
    'VN': '베트남',
    'TH': '태국',
    'TW': '대만',
    'CN': '중국',
    'HK': '홍콩',
    'PH': '필리핀',
    'GU': '괌',
    'SG': '싱가포르',
  };

  return countryMap[countryCode] ?? countryCode;
}

// 도시 코드를 한국어 이름으로 변환하는 함수 (assets의 JSON 파일 사용)
Future<String> getCityNameFromCode(String countryCode, String cityCode) async {
  try {
    // JSON 파일 경로
    final String jsonPath = 'assets/data/city/$countryCode.json';

    // JSON 파일 로드
    final String jsonString = await rootBundle.loadString(jsonPath);
    final List<dynamic> cityList = json.decode(jsonString);

    // 도시 코드로 한국어 이름 찾기
    for (var city in cityList) {
      if (city['code'] == cityCode) {
        return city['name'];
      }
    }

    // 못 찾은 경우 원래 코드 반환
    return cityCode;
  } catch (e) {
    print('도시 정보 로드 오류: $e');
    return cityCode; // 오류 발생 시 원래 코드 반환
  }
}

// 다이얼로그 표시 함수 (비동기 처리로 변경)
Future<bool> showPlanConfirmDialog({
  required BuildContext context,
  required String countryCode,
  required dynamic cityData,
}) async {
  final String countryName = getCountryNameFromCode(countryCode);

  // 도시 코드 추출
  String cityCode = '';
  if (cityData is String) {
    cityCode = cityData;
  } else if (cityData is Map) {
    cityCode = cityData['code'] ?? '';
  }

  // 도시 한국어 이름 가져오기
  String cityName = '';
  try {
    cityName = await getCityNameFromCode(countryCode, cityCode);
  } catch (e) {
    print('도시 이름 변환 오류: $e');
    // 오류 발생 시 기본 처리
    if (cityData is String) {
      cityName = cityData;
    } else if (cityData is Map) {
      cityName = cityData['name'] ?? cityData['code'] ?? '알 수 없음';
    } else {
      cityName = '알 수 없음';
    }
  }

  // 결과 저장용 변수
  bool? result;

  await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return PlanShowDialog(
        countryName: countryName,
        cityName: cityName,
        onConfirm: () {
          result = true;
          Navigator.of(dialogContext).pop();
        },
        onCancel: () {
          result = false;
          Navigator.of(dialogContext).pop();
        },
      );
    },
  );

  return result ?? false;
}