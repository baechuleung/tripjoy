import 'package:flutter/material.dart';

/// 지난 예약이 없을 때 표시되는 빈 상태 위젯
class PastReservationEmptyState extends StatelessWidget {
  final Function() onRefresh;

  const PastReservationEmptyState({
    Key? key,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]), // 연한 회색으로 변경
          const SizedBox(height: 16),
          Text(
            '이용완료된 예약이 없습니다.',
            style: TextStyle(fontSize: 16, color: Colors.grey[400]), // 연한 회색으로 변경
          ),
          const SizedBox(height: 8),
          Text(
            '프렌즈 이용 후 48시간이 지나면 자동으로 이용완료 처리됩니다.',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]), // 연한 회색으로 변경
            textAlign: TextAlign.center,
          ),
          // 새로고침 버튼 제거됨
        ],
      ),
    );
  }
}