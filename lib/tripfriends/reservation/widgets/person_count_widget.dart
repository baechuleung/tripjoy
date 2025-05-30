import 'package:flutter/material.dart';
import '../services/reservation_info_service.dart';
import '../models/custom_person_selector.dart';

class PersonCountWidget extends StatelessWidget {
  final Map<String, dynamic> reservationData;
  final VoidCallback? onUpdateUI;
  final bool isEditable;
  final VoidCallback? onPersonSelected;

  const PersonCountWidget({
    Key? key,
    required this.reservationData,
    this.onUpdateUI,
    this.isEditable = true,
    this.onPersonSelected,
  }) : super(key: key);

  Future<void> showPersonSelector(BuildContext context) async {
    final int currentCount = reservationData['personCount'] ?? 0;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) {
        return CustomPersonSelector(
          selectedPerson: currentCount > 0 ? currentCount : null,
          onPersonSelected: (count) async {
            // 먼저 인원수 업데이트
            await _updatePersonCount(count);
            // 그 다음 모달 닫기 - modalContext 사용
            if (modalContext.mounted) {
              Navigator.pop(modalContext, true);
            }
          },
        );
      },
    );

    // 모달이 닫힌 후 다음 단계로 이동
    if (result == true && onPersonSelected != null) {
      onPersonSelected!();
    }
  }

  Future<void> _updatePersonCount(int count) async {
    if (!reservationData.containsKey('userId') || !reservationData.containsKey('requestId')) {
      print("userId 또는 requestId가 없어 인원 수 업데이트 실패");
      return;
    }

    reservationData['personCount'] = count;

    final service = ReservationInfoService();
    final String userId = reservationData['userId'];
    final String requestId = reservationData['requestId'];

    final success = await service.updatePersonCount(
      userId: userId,
      requestId: requestId,
      personCount: count,
    );

    if (success && onUpdateUI != null) {
      onUpdateUI!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int? personCount = reservationData['personCount'];

    if (personCount == null || personCount <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '예약인원',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => showPersonSelector(context),
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
                      Icons.people,
                      size: 16,
                      color: Color(0xFF666666),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '인원수를 선택해주세요.',
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
              '예약인원',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isEditable)
              InkWell(
                onTap: () => showPersonSelector(context),
                child: Row(
                  children: [
                    Text(
                      '$personCount명',
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
                '$personCount명',
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