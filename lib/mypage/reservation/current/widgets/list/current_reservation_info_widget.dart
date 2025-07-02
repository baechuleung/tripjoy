import 'package:flutter/material.dart';
import '../../../../../../../mypage/reservation/current/models/current_reservation_model.dart';
import '../../../../../../../mypage/reservation/current/utils/current_reservation_formatter.dart';

/// 예약 정보를 표시하는 위젯
class CurrentReservationInfoWidget extends StatefulWidget {
  final Reservation reservation;

  const CurrentReservationInfoWidget({
    Key? key,
    required this.reservation,
  }) : super(key: key);

  @override
  State<CurrentReservationInfoWidget> createState() => _CurrentReservationInfoWidgetState();
}

class _CurrentReservationInfoWidgetState extends State<CurrentReservationInfoWidget> {
  bool _isExpanded = false; // 기본적으로 접힌 상태

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 기본값을 제공하여 null 체크 - personCount 사용
    final int memberCount = widget.reservation.originalData['personCount'] ?? 1;

    // 위치 정보 안전하게 가져오기 - meetingPlace에서 address 필드 사용
    String address = '주소 정보 없음';
    if (widget.reservation.originalData['meetingPlace'] is Map<String, dynamic>) {
      final meetingPlace = widget.reservation.originalData['meetingPlace'] as Map<String, dynamic>;
      if (meetingPlace.containsKey('address')) {
        address = meetingPlace['address'] as String? ?? '주소 정보 없음';
      }
    }

    // 날짜와 시간 정보 가져오기
    final String useDate = widget.reservation.originalData['useDate'] ?? '날짜 정보 없음';
    final String startTime = widget.reservation.originalData['startTime'] ?? '시간 정보 없음';

    // 감싸는 Container 없이 직접 Column 위젯 사용
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 예약 정보 타이틀과 화살표 버튼
        InkWell(
          onTap: _toggleExpand,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '예약 정보',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              // 접기/펼치기 아이콘
              Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Color(0xFF666666),
                size: 24,
              ),
            ],
          ),
        ),

        // 접힌 상태가 아닐 때만 내용 표시
        if (_isExpanded) ...[
          SizedBox(height: 20),

          // 한 줄로 표시되는 정보들
          _buildSingleLineInfoRow('여행 인원', '$memberCount명'),
          _buildSingleLineInfoRow('예약날짜', useDate),
          _buildSingleLineInfoRow('시작시간', startTime),

          // 약속 장소
          _buildInfoRow(
            '약속장소',
            address,
          ),

          // 요청사항 표시 (있는 경우에만)
          if (widget.reservation.originalData['detailRequest'] != null &&
              (widget.reservation.originalData['detailRequest'] as String).isNotEmpty)
            _buildInfoRow(
              '요청사항',
              widget.reservation.originalData['detailRequest'] as String,
            ),
        ],
      ],
    );
  }

  // 단일 라인 정보 행
  Widget _buildSingleLineInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
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

  // 여러 줄 정보 행 (약속장소 값을 오른쪽으로 정렬)
  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}