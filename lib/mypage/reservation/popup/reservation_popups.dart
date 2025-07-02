import 'package:flutter/material.dart';

/// 예약 취소 확인 팝업
class CancelPopup extends StatelessWidget {
  const CancelPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '예약을 취소하시겠습니까?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '예약을 취소하면 다시 복구할 수 없습니다.',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            '결제된 금액이 있다면 환불 규정에 따라 처리됩니다.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('예약 취소하기'),
        ),
      ],
    );
  }
}

/// 프렌즈 이용 완료 확인 팝업
class CompletedPopup extends StatelessWidget {
  const CompletedPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '프렌즈 이용을 완료하시겠습니까?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프렌즈 이용이 완료되면 리뷰를 작성하실 수 있습니다.',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            '완료 처리 후에는 다시 취소할 수 없습니다.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF237AFF),
            foregroundColor: Colors.white,
          ),
          child: const Text('이용 완료하기'),
        ),
      ],
    );
  }
}

/// 프렌즈 상태 확인 팝업 (이용 중이 아닐 때)
class GuideStatusCheckPopup extends StatelessWidget {
  const GuideStatusCheckPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '알림',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프렌즈 이용이 아직 시작되지 않았거나 이미 완료되었습니다.',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            '프렌즈 이용 중일 때만 완료 처리가 가능합니다.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF237AFF),
            foregroundColor: Colors.white,
          ),
          child: const Text('확인'),
        ),
      ],
    );
  }
}

/// 결제 페이지 (임시 구현, 실제로는 tripfriends/payments/reservation_page.dart 파일에서 구현)
class PaymentPage extends StatelessWidget {
  final String reservationId;
  final String friendsId;
  final int amount;
  final Map<String, dynamic> reservationData;

  const PaymentPage({
    Key? key,
    required this.reservationId,
    required this.friendsId,
    required this.amount,
    required this.reservationData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제 정보'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Text('결제 페이지 - 금액: $amount원'),
      ),
    );
  }
}