import 'package:flutter/material.dart';

class CustomTimeSelector extends StatefulWidget {
  final List<TimeOfDay>? selectedTimes;
  final ValueChanged<List<TimeOfDay>> onTimesSelected;
  final String startTime;
  final String endTime;
  final List<TimeOfDay> bookedTimes;
  final DateTime selectedDate;

  const CustomTimeSelector({
    super.key,
    this.selectedTimes,
    required this.onTimesSelected,
    required this.startTime,
    required this.endTime,
    this.bookedTimes = const [],
    required this.selectedDate,
  });

  @override
  State<CustomTimeSelector> createState() => _CustomTimeSelectorState();
}

class _CustomTimeSelectorState extends State<CustomTimeSelector> {
  int _selectedHour = 0;
  int _selectedMinute = 0;

  // 선택 가능한 시간과 분 목록
  late List<int> _hours;
  final List<int> _minutes = [00, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

  @override
  void initState() {
    super.initState();

    // 선택 가능한 시간 설정 - 모든 시간 선택 가능하도록 변경
    _hours = List.generate(24, (index) => index);

    // 초기 시간 설정
    if (widget.selectedTimes != null && widget.selectedTimes!.isNotEmpty) {
      _selectedHour = widget.selectedTimes!.first.hour;
      _selectedMinute = widget.selectedTimes!.first.minute;
    } else {
      final now = TimeOfDay.now();
      _selectedHour = now.hour;
      _selectedMinute = _getClosestAvailableMinute(now.minute);
    }
  }

  // 가장 가까운 사용 가능한 분 찾기
  int _getClosestAvailableMinute(int minute) {
    int closestMinute = _minutes.first;
    int minDiff = 60;

    for (final m in _minutes) {
      final diff = (m - minute).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestMinute = m;
      }
    }

    return closestMinute;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
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

          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '시작 시간 선택',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),

          // 시간 선택 위젯
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 시간 선택 (시)
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildHourSelector(),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '시',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4E5968),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),

                // 시간 선택 (분)
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildMinuteSelector(),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '분',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4E5968),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // 확인 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // 선택된 시간을 반환
                final selectedTime = TimeOfDay(hour: _selectedHour, minute: _selectedMinute);
                widget.onTimesSelected([selectedTime]);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF237AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 시간(시) 선택 위젯
  Widget _buildHourSelector() {
    // 가장 가까운 시간 찾기
    int initialHourIndex = 0;
    if (_hours.contains(_selectedHour)) {
      initialHourIndex = _hours.indexOf(_selectedHour);
    } else if (_selectedHour < _hours.first) {
      _selectedHour = _hours.first;
      initialHourIndex = 0;
    } else if (_selectedHour > _hours.last) {
      _selectedHour = _hours.last;
      initialHourIndex = _hours.length - 1;
    }

    return SizedBox(
      height: 150,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        controller: FixedExtentScrollController(
          initialItem: initialHourIndex,
        ),
        onSelectedItemChanged: (index) {
          setState(() {
            _selectedHour = _hours[index];
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: _hours.length,
          builder: (context, index) {
            final hour = _hours[index];
            final isSelected = hour == _selectedHour;

            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE6EFFF) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hour.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: isSelected ? 20 : 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF237AFF) : Colors.black54,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 시간(분) 선택 위젯
  Widget _buildMinuteSelector() {
    // 가장 가까운 분 찾기
    int closestMinuteIndex = 0;
    if (!_minutes.contains(_selectedMinute)) {
      int minDiff = 60;
      for (int i = 0; i < _minutes.length; i++) {
        int diff = (_minutes[i] - _selectedMinute).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestMinuteIndex = i;
        }
      }
      _selectedMinute = _minutes[closestMinuteIndex];
    } else {
      closestMinuteIndex = _minutes.indexOf(_selectedMinute);
    }

    return SizedBox(
      height: 150,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        controller: FixedExtentScrollController(
          initialItem: closestMinuteIndex,
        ),
        onSelectedItemChanged: (index) {
          setState(() {
            _selectedMinute = _minutes[index];
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: _minutes.length,
          builder: (context, index) {
            final minute = _minutes[index];
            final isSelected = minute == _selectedMinute;

            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE6EFFF) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                minute.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: isSelected ? 20 : 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF237AFF) : Colors.black54,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}