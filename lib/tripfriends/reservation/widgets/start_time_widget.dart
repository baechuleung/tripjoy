import 'package:flutter/material.dart';
import '../services/reservation_info_service.dart';
import '../models/custom_time_selector.dart';

class StartTimeWidget extends StatelessWidget {
  final Map<String, dynamic> reservationData;
  final bool needTimeInput;
  final Function(String)? onTimeSelected;
  final VoidCallback? onUpdateUI;
  final bool isEditable;
  final VoidCallback? onTimeCompleted;

  const StartTimeWidget({
    Key? key,
    required this.reservationData,
    this.needTimeInput = true,
    this.onTimeSelected,
    this.onUpdateUI,
    this.isEditable = true,
    this.onTimeCompleted,
  }) : super(key: key);

  Future<void> showTimeSelector(BuildContext context) async {
    TimeOfDay initialTime = TimeOfDay.now();

    if (reservationData.containsKey('startTime') &&
        reservationData['startTime'] != null &&
        reservationData['startTime'].toString().isNotEmpty) {
      try {
        final timeStr = reservationData['startTime'].toString();
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          final minuteParts = parts[1].split(' ');
          int minute = int.parse(minuteParts[0]);

          if (minuteParts.length > 1) {
            if (minuteParts[1].toUpperCase() == 'PM' && hour < 12) {
              hour += 12;
            } else if (minuteParts[1].toUpperCase() == 'AM' && hour == 12) {
              hour = 0;
            }
          }

          initialTime = TimeOfDay(hour: hour, minute: minute);
        }
      } catch (e) {
        print('시간 변환 오류: $e');
      }
    }

    DateTime selectedDate = DateTime.now();
    if (reservationData.containsKey('useDate') &&
        reservationData['useDate'] != null &&
        reservationData['useDate'].toString().isNotEmpty) {
      try {
        final dateStr = reservationData['useDate'].toString();
        if (dateStr.contains('-')) {
          final parts = dateStr.split('-');
          if (parts.length == 3) {
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);
            selectedDate = DateTime(year, month, day);
          }
        }
        else if (dateStr.contains('년')) {
          final parts = dateStr.split(' ');
          if (parts.length >= 3) {
            final year = int.parse(parts[0].replaceAll('년', ''));
            final month = int.parse(parts[1].replaceAll('월', ''));
            final day = int.parse(parts[2].replaceAll('일', ''));
            selectedDate = DateTime(year, month, day);
          }
        }
      } catch (e) {
        print('날짜 변환 오류: $e');
      }
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CustomTimeSelector(
          selectedTimes: initialTime != TimeOfDay.now() ? [initialTime] : null,
          onTimesSelected: (times) {
            if (times.isNotEmpty) {
              final selectedTime = times.first;
              final formattedTime =
                  '${selectedTime.hourOfPeriod == 0 ? 12 : selectedTime.hourOfPeriod}:${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.period == DayPeriod.am ? 'AM' : 'PM'}';

              if (onTimeSelected != null) {
                onTimeSelected?.call(formattedTime);
              } else {
                _updateStartTime(formattedTime);
              }
              Navigator.pop(context, true);
            }
          },
          startTime: '00:00',
          endTime: '23:55',
          bookedTimes: [],
          selectedDate: selectedDate,
        );
      },
    );

    if (result == true && onTimeCompleted != null) {
      onTimeCompleted!();
    }
  }

  Future<void> _updateStartTime(String startTime) async {
    if (!reservationData.containsKey('userId') || !reservationData.containsKey('requestId')) {
      print("userId 또는 requestId가 없어 시작 시간 업데이트 실패");
      return;
    }

    reservationData['startTime'] = startTime;

    final service = ReservationInfoService();
    final String userId = reservationData['userId'];
    final String requestId = reservationData['requestId'];

    final success = await service.updateStartTime(
      userId: userId,
      requestId: requestId,
      startTime: startTime,
    );

    if (success && onUpdateUI != null) {
      onUpdateUI!();
    }
  }

  @override
  Widget build(BuildContext context) {
    String startTime = '';
    if (reservationData.containsKey('startTime') &&
        reservationData['startTime'] != null &&
        reservationData['startTime'].toString().isNotEmpty) {
      startTime = reservationData['startTime'].toString();
    }

    final bool showInputField = needTimeInput && startTime.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical:6),
      child: startTime.isNotEmpty
          ? Row(
        children: [
          Text(
            '시작시간',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (isEditable)
            InkWell(
              onTap: () => showTimeSelector(context),
              child: Row(
                children: [
                  Text(
                    startTime,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: Color(0xFF237AFF),
                  ),
                ],
              ),
            )
          else
            Text(
              startTime,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '시작시간',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => showTimeSelector(context),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: const Color(0xFFE4E4E4),
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '시작시간을 선택해주세요.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}