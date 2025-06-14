import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/reservation_info_service.dart';
import '../models/custom_purpose.dart';

class PurposeWidget extends StatelessWidget {
  final Map<String, dynamic> reservationData;
  final VoidCallback? onUpdateUI;
  final bool isEditable;
  final VoidCallback? onPurposeSelected;

  const PurposeWidget({
    Key? key,
    required this.reservationData,
    this.onUpdateUI,
    this.isEditable = true,
    this.onPurposeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> purposes = [];

    if (reservationData.containsKey('purpose')) {
      if (reservationData['purpose'] is String && reservationData['purpose'].toString().isNotEmpty) {
        purposes = [reservationData['purpose']];
      } else if (reservationData['purpose'] is List) {
        purposes = List<String>.from(reservationData['purpose']);
      }
    }

    if (purposes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이용목적',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: isEditable ? () => showPurposeSelector(context) : null,
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
                      Icons.assignment_outlined,
                      size: 16,
                      color: Color(0xFF666666),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '이용목적을 선택해주세요.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isEditable)
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: isEditable ? () => showPurposeSelector(context) : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이용목적',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              purposes.first,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF333333),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            if (isEditable)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Color(0xFF237AFF),
                                ),
                              ),
                          ],
                        ),
                        ...purposes.skip(1).map((purpose) => Padding(
                          padding: EdgeInsets.only(top: 4, right: isEditable ? 28.0 : 0),
                          child: Text(
                            purpose,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> showPurposeSelector(BuildContext context) async {
    List<String> currentPurposes = [];

    if (reservationData.containsKey('purpose')) {
      if (reservationData['purpose'] is String && reservationData['purpose'].toString().isNotEmpty) {
        currentPurposes = [reservationData['purpose']];
      } else if (reservationData['purpose'] is List) {
        currentPurposes = List<String>.from(reservationData['purpose']);
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return CustomPurposeSelector(
          selectedPurposes: currentPurposes,
          onPurposeSelected: (purposes) {
            _updatePurposes(purposes);
            Navigator.pop(context);
            if (onPurposeSelected != null) {
              onPurposeSelected!();
            }
          },
        );
      },
    );
  }

  Future<void> _updatePurposes(List<String> purposes) async {
    if (!reservationData.containsKey('userId') || !reservationData.containsKey('requestId')) {
      print("userId 또는 requestId가 없어 이용목적 업데이트 실패");
      return;
    }

    reservationData['purpose'] = purposes;

    final service = ReservationInfoService();
    final String userId = reservationData['userId'];
    final String requestId = reservationData['requestId'];

    bool success = false;
    if (purposes.length == 1) {
      success = await service.updatePurpose(
        userId: userId,
        requestId: requestId,
        purpose: purposes.first,
      );
    } else {
      try {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('plan_requests')
            .doc(requestId);

        await docRef.update({
          'purpose': purposes,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        success = true;
      } catch (e) {
        print("이용목적 목록 업데이트 오류: $e");
        success = false;
      }
    }

    if (success && onUpdateUI != null) {
      onUpdateUI!();
    }
  }
}