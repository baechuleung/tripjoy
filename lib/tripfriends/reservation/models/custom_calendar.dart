import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String friendUserId; // 선택한 프렌즈의 사용자 ID

  const CustomCalendar({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    required this.friendUserId,
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late PageController _pageController;
  DateTime? _selectedDate;
  late DateTime _focusedDate;
  Set<String> _reservedDates = {}; // 예약된 날짜를 저장할 Set
  Map<String, List<String>> _reservationsByDate = {}; // 날짜별 예약 문서 ID 맵
  bool _isLoading = true; // 데이터 로딩 상태

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _focusedDate = widget.selectedDate ?? DateTime.now();
    _pageController = PageController(
      initialPage: _focusedDate.year * 12 + _focusedDate.month - 1,
    );
    _loadReservedDates(); // 예약된 날짜 로드
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Firebase에서 예약된 날짜 불러오기
  Future<void> _loadReservedDates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // friendUserId가 비어있는지 확인
      if (widget.friendUserId.isEmpty) {
        print('❌ 오류: friendUserId가 비어 있어 예약 정보를 가져올 수 없습니다.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final friendId = widget.friendUserId;
      print('📅 프렌즈($friendId)의 예약된 날짜 로딩 시작...');
      print('🔍 쿼리 경로: tripfriends_users/$friendId/reservations');

      // 선택한 프렌즈의 예약 정보 중 status가 'pending' 또는 'in_progress'인 것만 가져오기
      final pendingSnapshot = await FirebaseFirestore.instance
          .collection('tripfriends_users')
          .doc(friendId)
          .collection('reservations')
          .where('status', whereIn: ['pending', 'in_progress'])
          .get();

      print('📊 검색된 reservation 문서 수: ${pendingSnapshot.docs.length}');

      Set<String> reservedDates = {};
      Map<String, List<String>> reservationsByDate = {};

      for (var doc in pendingSnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        String docId = doc.id;
        String? path = doc.reference.path;
        String status = data['status'] as String? ?? '';

        print('🔍 문서 데이터 [ID: $docId, 경로: $path, 상태: $status]: $data');

        String? useDate = data['useDate'] as String?;
        if (useDate != null) {
          reservedDates.add(useDate);

          // 날짜별 예약 문서 ID 목록 저장
          if (!reservationsByDate.containsKey(useDate)) {
            reservationsByDate[useDate] = [];
          }
          reservationsByDate[useDate]!.add(docId);

          print('📌 예약된 날짜 로드: $useDate, 문서 ID: $docId, 상태: $status, 경로: $path');
        }
      }

      setState(() {
        _reservedDates = reservedDates;
        _reservationsByDate = reservationsByDate;
        _isLoading = false;
      });

      // 디버깅을 위해 모든 예약된 날짜와 문서 ID 출력
      print('🗓️ 로드된 모든 예약 날짜: $_reservedDates');

      _reservationsByDate.forEach((date, docIds) {
        print('📝 날짜 $date에 예약된 문서 ID 목록: $docIds');
      });

    } catch (e) {
      print('❌ 예약 날짜 로드 오류: $e');
      print('❌ 오류 스택 트레이스: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 날짜가 선택 가능한지 확인
  bool _isAvailableDay(DateTime date) {
    // 이미 지난 날짜는 선택 불가능
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false;
    }

    // 날짜를 한국어 형식으로 변환
    String koreanDate = _formatDateToKorean(date);

    // 디버깅: 날짜 확인 출력
    bool isReserved = _reservedDates.contains(koreanDate);
    print('🔎 확인 중인 날짜: $koreanDate, 예약됨: $isReserved');

    if (isReserved) {
      List<String>? docIds = _reservationsByDate[koreanDate];
      print('🚫 예약된 날짜: $koreanDate, 문서 ID: $docIds');
    }

    // 예약된 날짜인지 확인
    return !isReserved;
  }

  // 날짜가 예약된 날짜인지 확인
  bool _isReservedDay(DateTime date) {
    String koreanDate = _formatDateToKorean(date);
    bool isReserved = _reservedDates.contains(koreanDate);

    if (isReserved) {
      List<String>? docIds = _reservationsByDate[koreanDate];
      print('📅 예약된 날짜 확인: $koreanDate, 문서 ID: $docIds');
    }

    return isReserved;
  }

  // DateTime을 한국어 날짜 형식으로 변환 (예: "2025년 5월 16일")
  String _formatDateToKorean(DateTime date) {
    // 월과 일이 한 자릿수인 경우에도 그대로 유지 (예: 5월, 9일)
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  void _onDateTap(DateTime date) {
    // 선택 가능한 날짜인 경우에만 선택 처리
    bool isAvailable = _isAvailableDay(date);
    String formattedDate = _formatDateToKorean(date);
    print('👆 날짜 탭됨: $formattedDate, 선택 가능: $isAvailable');

    if (isAvailable) {
      setState(() {
        _selectedDate = date;
      });
      // 날짜 선택 시 콜백만 호출하고 화면은 닫지 않음
      widget.onDateSelected(date);
    } else {
      // 스낵바 대신 디버그 프린트 사용
      List<String>? docIds = _reservationsByDate[formattedDate];
      print('❌ 선택 불가: $formattedDate는 이미 예약이 완료된 날짜입니다. 문서 ID: $docIds');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      padding: EdgeInsets.only(top: 12,),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들 추가
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E4E4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            _buildHeader(),
            _isLoading
                ? const Center()
                : _buildCalendarGrid(),
            const SizedBox(height: 24), // 하단 여백도 늘림
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 상단에 "이용 날짜 선택" 헤더 추가
        const Padding(
          padding: EdgeInsets.only(bottom: 16), // 여백 추가
          child: Text(
            '예약 일시 선택',
            style: TextStyle(
              fontSize: 18, // 글자 크기 키움
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        // 기존 년월 표시 및 화살표 버튼
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 여백 조정
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${_focusedDate.year}년 ${_focusedDate.month}월',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    return SizedBox(
      height: 350, // 높이를 증가시켜 달력이 모두 표시되도록 함
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _focusedDate = DateTime(index ~/ 12, index % 12 + 1);
          });
        },
        itemBuilder: (context, index) {
          final year = index ~/ 12;
          final month = index % 12 + 1;
          return _buildMonthCalendar(year, month);
        },
      ),
    );
  }

  Widget _buildMonthCalendar(int year, int month) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    // 첫 번째 날의 요일을 구함 (월=1, 화=2, ..., 일=7)
    final firstWeekday = firstDayOfMonth.weekday;

    // 달력에서의 시작 위치를 계산 (0=일, 1=월, ..., 6=토)
    // 월요일(1)이면 1, 화요일(2)이면 2, ..., 일요일(7)이면 0이 되어야 함
    final startOffset = (firstWeekday == 7) ? 0 : firstWeekday;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
        mainAxisSpacing: 5, // 세로 간격 추가
        crossAxisSpacing: 5, // 가로 간격 추가
      ),
      itemCount: 7 + (6 * 7), // 요일 헤더 + 최대 6주(42일)를 표시 (모든 달력이 표시되도록)
      itemBuilder: (context, index) {
        if (index < 7) {
          // 요일 헤더 출력 (첫 번째 줄)
          const koreanWeekdays = ['일', '월', '화', '수', '목', '금', '토'];

          // 일요일(0)과 토요일(6)은 빨간색으로 표시
          final Color weekdayColor = (index == 0 || index == 6)
              ? const Color(0xFFFF3B30) // 일요일과 토요일은 빨간색
              : const Color(0xFF1A1A1A); // 다른 요일은 검정색

          return Center(
            child: Text(
              koreanWeekdays[index],
              style: TextStyle(
                fontSize: 13, // 글자 크기 약간 키움
                fontWeight: FontWeight.w500,
                color: weekdayColor,
              ),
            ),
          );
        } else {
          // 날짜 출력 (요일 아래 바로 붙음)
          final adjustedIndex = index - 7; // 헤더 행 제외
          final col = adjustedIndex % 7; // 요일 (0=일, 1=월, ..., 6=토)

          // 날짜 계산
          final day = adjustedIndex - startOffset + 1;

          if (day < 1 || day > lastDayOfMonth.day) {
            return const SizedBox(); // 빈 칸 채우기
          }

          final date = DateTime(year, month, day);
          final isSelected = _selectedDate?.year == date.year &&
              _selectedDate?.month == date.month &&
              _selectedDate?.day == date.day;

          // 일요일과 토요일 확인
          final isSunday = date.weekday == DateTime.sunday;
          final isSaturday = date.weekday == DateTime.saturday;

          final isAvailable = _isAvailableDay(date);
          final isReserved = _isReservedDay(date);

          // 색상 결정 로직
          Color textColor;
          if (isReserved) {
            textColor = const Color(0xFFFF3B30); // 예약된 날짜는 빨간색
          } else if (!isAvailable) {
            textColor = const Color(0xFFD9D9D9); // 선택 불가능한 날짜는 회색
          } else if (isSelected) {
            textColor = Colors.white; // 선택된 날짜는 흰색
          } else if (isSunday || isSaturday) {
            textColor = const Color(0xFFFF3B30); // 주말은 빨간색
          } else {
            textColor = const Color(0xFF1A1A1A); // 평일은 검정색
          }

          // 오버플로우 오류 수정을 위한 SizedBox로 감싸기
          return GestureDetector(
            onTap: () => _onDateTap(date),
            child: SizedBox(
              height: 44, // 높이 제한
              child: Column(
                mainAxisSize: MainAxisSize.min, // 필요한 최소 크기만 사용
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 1), // 하단 마진 감소
                    height: 28, // 원의 높이 약간 줄임
                    width: 28, // 원의 너비 약간 줄임
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF237AFF) : Colors.transparent,
                      shape: BoxShape.circle, // 원형 유지
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  // 예약완료 텍스트 추가 (isReserved가 true일 때만 표시)
                  if (isReserved)
                    const Text(
                      '예약완료',
                      style: TextStyle(
                        fontSize: 8, // 글자 크기 줄임
                        color: Color(0xFFFF3B30),
                        height: 1.0, // 줄 간격 줄임
                      ),
                    ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}