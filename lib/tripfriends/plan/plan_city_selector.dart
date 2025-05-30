// plan_city_selector.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'modal/custom_city_selector.dart';

class PlanCitySelector extends StatefulWidget {
  final String? selectedCityId;
  final String selectedCountry;
  final String countryFlag;
  final Function(Map<String, dynamic>) onCitySelected;
  final Function(String?) validateCity;

  const PlanCitySelector({
    Key? key,
    this.selectedCityId,
    required this.selectedCountry,
    required this.countryFlag,
    required this.onCitySelected,
    required this.validateCity,
  }) : super(key: key);

  @override
  _PlanCitySelectorState createState() => _PlanCitySelectorState();
}

class _PlanCitySelectorState extends State<PlanCitySelector> {
  List<Map<String, dynamic>> _cities = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _selectedCity;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void didUpdateWidget(PlanCitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 국가가 변경되면 해당 국가의 도시 목록 다시 로드
    if (oldWidget.selectedCountry != widget.selectedCountry) {
      _loadCities();
      // 국가가 변경되면 선택된 도시 초기화
      setState(() {
        _selectedCity = null;
      });
    }
  }

  // 선택된 국가의 도시 목록 로드
  Future<void> _loadCities() async {
    // 국가가 선택되지 않았으면 무시
    if (widget.selectedCountry.isEmpty) {
      setState(() {
        _cities = [];
        _selectedCity = null;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 해당 국가의 JSON 파일 로드
      final String jsonString = await rootBundle.loadString(
          'assets/data/city/${widget.selectedCountry}.json'
      );

      // JSON 파싱
      final List<dynamic> citiesJson = json.decode(jsonString);

      // Map 리스트로 변환
      final List<Map<String, dynamic>> loadedCities = List<Map<String, dynamic>>.from(citiesJson);

      setState(() {
        _cities = loadedCities;
        _isLoading = false;

        // 이전에 선택된 도시가 있으면 해당 도시 찾기
        if (widget.selectedCityId != null) {
          try {
            _selectedCity = _cities.firstWhere(
                  (city) => city['code'] == widget.selectedCityId,
            );
          } catch (e) {
            // 해당 코드를 가진 도시가 없으면 null로 설정
            _selectedCity = null;
          }
        } else {
          _selectedCity = null;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '도시 목록을 불러올 수 없습니다.';
        _cities = [];

        // 오류 발생 시 더미 데이터 로드 (fallback)
        if (widget.selectedCountry == 'VN') {
          _loadDummyVietnamCities();
        }
      });

      print('도시 목록 로드 오류: $e');
      print('assets/data/city/${widget.selectedCountry}.json 파일이 없거나 잘못된 형식입니다.');
    }
  }

  // 더미 베트남 도시 데이터 로드 (JSON 파일이 없을 경우 대비)
  void _loadDummyVietnamCities() {
    _cities = [
      {"code": "HAN", "name": "하노이"},
      {"code": "HCM", "name": "호치민"},
      {"code": "DNN", "name": "다낭"},
      {"code": "NPT", "name": "나트랑"},
      {"code": "PQC", "name": "푸꾸옥"}
    ];
    _errorMessage = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 50,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: Color(0xFFE4E4E4)),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            children: [
              // 왼쪽에 아이콘 배치
              const Padding(
                padding: EdgeInsets.only(left: 16, right: 8),
                child: Icon(Icons.location_city, color: Color(0xFF4E5968), size: 22),
              ),
              // 오른쪽에 텍스트 필드 배치 (오른쪽 정렬)
              Expanded(
                child: Center(
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: widget.selectedCountry.isEmpty ? '국가를 먼저 선택하세요' : '방문할 도시 선택',
                      hintStyle: TextStyle(
                        color: Color(0xFF4E5968),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: EdgeInsets.only(right: 16),
                      isDense: true,
                    ),
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                    textAlignVertical: TextAlignVertical.center,
                    readOnly: true,
                    enabled: widget.selectedCountry.isNotEmpty && !_isLoading,
                    onTap: _isLoading || widget.selectedCountry.isEmpty
                        ? null
                        : () => _showCitySelector(context),
                    controller: TextEditingController(
                      text: _selectedCity != null ? _selectedCity!['name'] : '',
                    ),
                    validator: (value) => widget.validateCity(_selectedCity?['code']),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 에러 메시지 표시 (있는 경우)
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  // 도시 선택기 모달 표시
  void _showCitySelector(BuildContext context) {
    if (_cities.isEmpty) {
      // 도시 목록이 비어있으면 모달 표시하지 않음
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('선택한 국가의 도시 정보가 없습니다.'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CustomCitySelector(
        selectedCityId: _selectedCity?['code'],
        cities: _cities,
        countryFlag: widget.countryFlag,
        onCitySelected: (city) {
          setState(() {
            _selectedCity = city;
          });
          widget.onCitySelected(city);
          Navigator.pop(context);
        },
      ),
    );
  }
}