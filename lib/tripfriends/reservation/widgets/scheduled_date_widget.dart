import 'package:flutter/material.dart';
import '../services/reservation_service.dart';
import '../services/reservation_info_service.dart';
import '../models/custom_calendar.dart';
import 'package:intl/intl.dart';

class ScheduledDateWidget extends StatelessWidget {
  final Map<String, dynamic> reservationData;
  final ReservationService reservationService;
  final VoidCallback? onUpdateUI;
  final bool isEditable;
  final VoidCallback? onDateSelected;

  const ScheduledDateWidget({
    Key? key,
    required this.reservationData,
    required this.reservationService,
    this.onUpdateUI,
    this.isEditable = true,
    this.onDateSelected,
  }) : super(key: key);

  Future<void> showDatePicker(BuildContext context) async {
    String currentDate = '';
    if (reservationData.containsKey('useDate')) {
      currentDate = reservationData['useDate'] as String? ?? '';
    }

    DateTime selectedDate = DateTime.now();
    if (currentDate.isNotEmpty) {
      try {
        final parts = currentDate.split(' ');
        if (parts.length >= 3) {
          final year = int.parse(parts[0].replaceAll('년', ''));
          final month = int.parse(parts[1].replaceAll('월', ''));
          final day = int.parse(parts[2].replaceAll('일', ''));
          selectedDate = DateTime(year, month, day);
        }
      } catch (e) {
        print('날짜 변환 오류: $e');
      }
    }

    String friendUserId = '';
    if (reservationData.containsKey('friendUserId')) {
      friendUserId = reservationData['friendUserId'] as String? ?? '';
    }
    if (friendUserId.isEmpty && reservationData.containsKey('friends_uid')) {
      friendUserId = reservationData['friends_uid'] as String? ?? '';
    }
    if (friendUserId.isEmpty && reservationData.containsKey('friendsId')) {
      friendUserId = reservationData['friendsId'] as String? ?? '';
    }

    if (friendUserId.isEmpty) {
      print('❌ 오류: friendUserId를 찾을 수 없습니다.');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('오류'),
              content: const Text('친구 ID를 찾을 수 없어 달력을 표시할 수 없습니다.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return CustomCalendar(
          selectedDate: selectedDate,
          onDateSelected: (date) {
            final formattedDate = '${date.year}년 ${date.month}월 ${date.day}일';
            _updateScheduledDate(formattedDate);
            Navigator.pop(context, true);
          },
          friendUserId: friendUserId,
        );
      },
    );

    if (result == true && onDateSelected != null) {
      onDateSelected!();
    }
  }

  Future<void> _updateScheduledDate(String useDate) async {
    if (!reservationData.containsKey('userId') || !reservationData.containsKey('requestId')) {
      print("userId 또는 requestId가 없어 예약 일시 업데이트 실패");
      return;
    }

    reservationData['useDate'] = useDate;

    final service = ReservationInfoService();
    final String userId = reservationData['userId'];
    final String requestId = reservationData['requestId'];

    final success = await service.updateScheduledDate(
      userId: userId,
      requestId: requestId,
      useDate: useDate,
    );

    if (success && onUpdateUI != null) {
      onUpdateUI!();
    }
  }

  @override
  Widget build(BuildContext context) {
    String? scheduledDate;
    if (reservationData.containsKey('useDate') &&
        reservationData['useDate'] != null &&
        reservationData['useDate'].toString().isNotEmpty) {
      final useDate = reservationData['useDate'] as String? ?? '';
      scheduledDate = useDate.isNotEmpty ? useDate : null;
    } else if (reservationData.containsKey('scheduledDate') &&
        reservationData['scheduledDate'] != null) {
      scheduledDate = reservationService.formatDateTime(reservationData['scheduledDate']);
      scheduledDate = scheduledDate != '-' ? scheduledDate : null;
    }

    if (scheduledDate == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '예약일시',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => showDatePicker(context),
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
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFF666666),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '날짜를 선택해주세요.',
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
    else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Text(
              '예약일시',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isEditable)
              InkWell(
                onTap: () => showDatePicker(context),
                child: Row(
                  children: [
                    Text(
                      scheduledDate,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF237AFF),
                    ),
                  ],
                ),
              )
            else
              Text(
                scheduledDate,
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
}