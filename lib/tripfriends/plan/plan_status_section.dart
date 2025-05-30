// plan_status_section.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlanStatusSection extends StatefulWidget {
  final Map<String, dynamic>? planData;
  final VoidCallback onCancelPlan;

  const PlanStatusSection({
    Key? key,
    required this.planData,
    required this.onCancelPlan,
  }) : super(key: key);

  @override
  _PlanStatusSectionState createState() => _PlanStatusSectionState();
}

class _PlanStatusSectionState extends State<PlanStatusSection> {
  // 도시 정보 캐시
  Map<String, Map<String, String>> _citiesCache = {};

  @override
  void initState() {
    super.initState();
    // 도시 데이터 로드
    _loadCitiesData();
  }

  // 도시 데이터 로드
  Future<void> _loadCitiesData() async {
    if (widget.planData == null) return;

    try {
      // 플랜 데이터에서 국가 코드 추출
      String nationalityCode = '';
      if (widget.planData!.containsKey('location') && widget.planData!['location'] is Map) {
        final locationData = widget.planData!['location'] as Map<String, dynamic>;
        nationalityCode = locationData['nationality'] ?? '';
      }

      if (nationalityCode.isEmpty) {
        print('국가 코드가 없습니다.');
        return;
      }

      // 이미 캐시에 있는 경우 로드 스킵
      if (_citiesCache.containsKey(nationalityCode)) {
        return;
      }

      // 해당 국가의 JSON 파일 로드
      final jsonString = await rootBundle.loadString('assets/data/city/$nationalityCode.json');
      final List<dynamic> cities = json.decode(jsonString);

      Map<String, String> cityMap = {};
      for (var city in cities) {
        if (city is Map && city.containsKey('code') && city.containsKey('name')) {
          cityMap[city['code']] = city['name'];
        }
      }

      setState(() {
        _citiesCache[nationalityCode] = cityMap;
      });

      print('$nationalityCode 국가의 도시 데이터 로드 완료 (${cityMap.length}개 도시)');

    } catch (e) {
      print('도시 데이터 로드 오류: $e');
      print('해당 국가의 도시 데이터 파일이 없거나 형식이 잘못되었을 수 있습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFE4E4E4)),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Stack(
        children: [
          // 메인 컨텐츠
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: widget.planData != null
                ? _buildPlanInfoHeader()
                : const SizedBox(),
          ),

          // X 버튼 (오른쪽 상단)
          Positioned(
            top: 16.0,
            right: 16.0,
            child: GestureDetector(
              onTap: widget.onCancelPlan,
              child: Icon(
                Icons.close,
                size: 24,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanInfoHeader() {
    final Map<String, dynamic> planData = widget.planData!;

    // location 필드에서 정보 추출
    String nationalityCode = '';
    String cityCode = '';
    if (planData.containsKey('location') && planData['location'] is Map) {
      final locationData = planData['location'] as Map<String, dynamic>;
      nationalityCode = locationData['nationality'] ?? '';
      cityCode = locationData['city'] ?? '';
    }

    // 국가와 도시 이름 가져오기
    final String countryName = _getCountryName(nationalityCode);
    final String cityName = _getCityName(nationalityCode, cityCode);

    return Row(
      children: [
        Text(
          '내가 여행할 나라',
          style: TextStyle(
            color: const Color(0xFF4E5968),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 2.0),

        // 비행기 아이콘
        Transform.rotate(
          angle: 45 * 3.14159 / 180, // 45도 회전
          child: Icon(
            Icons.flight,
            size: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8.0),

        // 국가와 도시 정보 (사용 가능한 공간 모두 사용)
        Expanded(
          child: Row(
            children: [
              // 국가 이름
              Text(
                countryName,
                style: TextStyle(
                  color: const Color(0xFF5963D0),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),

              // 구분선
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '|',
                  style: TextStyle(
                    color: const Color(0xFF5963D0),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // 도시 이름 (남는 공간 모두 사용)
              Expanded(
                child: Text(
                  cityName,
                  style: TextStyle(
                    color: const Color(0xFF5963D0),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 도시 코드를 한글 이름으로 변환
  String _getCityName(String nationalityCode, String cityCode) {
    // 기본값 설정
    if (cityCode.isEmpty) {
      return '정보 없음';
    }

    // 캐시에서 해당 국가의 도시 정보 가져오기
    final citiesMap = _citiesCache[nationalityCode];
    if (citiesMap != null && citiesMap.containsKey(cityCode)) {
      return citiesMap[cityCode]!;
    }

    // 일치하는 도시를 찾지 못한 경우 코드 그대로 반환
    return cityCode;
  }

  String _getCountryName(String countryCode) {
    final Map<String, String> countryNames = {
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

    return countryNames[countryCode] ?? countryCode;
  }
}