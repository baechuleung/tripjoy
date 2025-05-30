import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocationInfoWidget extends StatefulWidget {
  final Map<String, dynamic> locationData;

  const LocationInfoWidget({
    Key? key,
    required this.locationData,
  }) : super(key: key);

  @override
  State<LocationInfoWidget> createState() => _LocationInfoWidgetState();
}

class _LocationInfoWidgetState extends State<LocationInfoWidget> {
  bool _isLoading = true;
  String _countryName = '';
  String _cityName = '';

  @override
  void initState() {
    super.initState();
    _loadLocationNames();
  }

  Future<void> _loadLocationNames() async {
    try {
      // 국가 코드와 도시 코드 가져오기
      String? countryCode = widget.locationData['nationality'];
      String? cityCode = widget.locationData['city'];

      if (countryCode == null || cityCode == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 국가 정보 로드
      final String countryJsonString = await rootBundle.loadString('assets/data/country.json');
      final Map<String, dynamic> countryData = json.decode(countryJsonString);

      // 국가 이름 찾기
      List<dynamic> countries = countryData['countries'];
      Map<String, dynamic>? country;

      for (var c in countries) {
        if (c['code'] == countryCode) {
          country = c;
          break;
        }
      }

      if (country != null && country['names'] != null) {
        _countryName = country['names']['KR'] ?? countryCode;
      } else {
        _countryName = countryCode;
      }

      // 도시 정보 로드
      try {
        final String cityJsonString = await rootBundle.loadString('assets/data/city/${countryCode}.json');
        final List<dynamic> cityData = json.decode(cityJsonString);

        // 도시 이름 찾기
        Map<String, dynamic>? city;

        for (var c in cityData) {
          if (c['code'] == cityCode) {
            city = c;
            break;
          }
        }

        if (city != null && city['name'] != null) {
          _cityName = city['name'];
        } else {
          _cityName = cityCode;
        }
      } catch (e) {
        // 도시 파일을 찾지 못하거나 파싱 오류 발생 시
        print('도시 정보 로드 중 오류: $e');
        _cityName = cityCode;
      }

      // 상태 업데이트
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('위치 정보 로드 중 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중이면 로딩 UI 표시
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.place,
              size: 18,
              color: const Color(0xFF237AFF),
            ),
            const SizedBox(width: 8),
            Text(
              '여행국가,도시',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF237AFF),
              ),
            ),
          ],
        ),
      );
    }

    // 표시할 텍스트 생성
    String displayText = '';
    if (_countryName.isNotEmpty && _cityName.isNotEmpty) {
      displayText = '$_countryName,$_cityName';
    } else if (_countryName.isNotEmpty) {
      displayText = _countryName;
    } else if (_cityName.isNotEmpty) {
      displayText = _cityName;
    }

    // 표시할 내용이 없으면 빈 컨테이너 반환
    if (displayText.isEmpty) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Text(
            '국가,도시',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            displayText,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}