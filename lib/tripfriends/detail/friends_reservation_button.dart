import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../reservation/reservation_page.dart';
import '../../chat/screens/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../chat/widgets/plan_show_dialog.dart';

class FriendsReservationButton extends StatelessWidget {
  final String friends_uid;

  const FriendsReservationButton({
    super.key,
    required this.friends_uid,
  });

  // 예약 번호 생성 함수
  String _generateReservationNumber() {
    // 현재 시간을 가져옴
    final now = DateTime.now();

    // 날짜 부분 (YYYYMMDD 형식)
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // 영어 + 숫자 조합의 4자리 난수 생성
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String randomPart = '';

    // 4자리 영문+숫자 조합 생성
    for (int i = 0; i < 4; i++) {
      final randomIndex = now.millisecondsSinceEpoch % chars.length + i;
      randomPart += chars[randomIndex % chars.length];
    }

    // 최종 예약번호: 날짜 + 난수 (하이픈 없음)
    final reservationNumber = '$dateStr$randomPart';

    return reservationNumber;
  }

  // 예약 페이지로 이동
  Future<void> _navigateToReservationPage(BuildContext context) async {
    try {
      // 현재 로그인한 사용자 ID 가져오기
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("로그인이 필요합니다.");
      }

      // 프렌즈 정보 가져오기 (시간당 요금 정보 포함)
      print('조회할 프렌즈 ID: $friends_uid');
      final firestore = FirebaseFirestore.instance;
      final friendsDoc = await firestore
          .collection('tripfriends_users')
          .doc(friends_uid)
          .get();

      print('프렌즈 문서 조회 경로: tripfriends_users/$friends_uid');

      if (!friendsDoc.exists) {
        throw Exception("프렌즈 정보를 찾을 수 없습니다.");
      }

      // 프렌즈 데이터에서 시간당 요금 및 통화 정보 추출
      final friendsData = friendsDoc.data()!;

      // 정확히 문서에서 값을 가져오도록 확인
      print('프렌즈 데이터: $friendsData');

      // 필드 이름을 정확히 확인하고 값을 가져옴
      final int pricePerHour = friendsData['pricePerHour'] is int ? friendsData['pricePerHour'] : 0;
      final String currencyCode = friendsData['currencyCode'] is String ? friendsData['currencyCode'] : 'KRW';
      final String currencySymbol = friendsData['currencySymbol'] is String ? friendsData['currencySymbol'] : '₩';

      print('프렌즈의 시간당 요금: $pricePerHour');
      print('통화 코드: $currencyCode');
      print('통화 기호: $currencySymbol');

      // plan_requests 정보 조회 (가장 최근 문서)
      final querySnapshot = await firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('plan_requests')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // plan_requests가 없으면 프렌즈의 국가/도시 정보로 다이얼로그 표시
        final locationData = friendsData['location'] as Map<String, dynamic>?;
        final countryCode = locationData?['nationality'] ?? 'KR';
        final cityData = locationData?['city'] ?? '';

        if (context.mounted) {
          final confirmed = await showPlanConfirmDialog(
            context: context,
            countryCode: countryCode,
            cityData: cityData,
          );

          if (!confirmed) {
            return; // 사용자가 취소한 경우
          }

          // 확인한 경우 plan_requests 생성
          final now = DateTime.now();
          final newPlanRequest = {
            'location': {
              'city': cityData,
              'nationality': countryCode,
            },
            'createdAt': now,
            'updatedAt': now,
            'userEmail': currentUser.email ?? '',
            'userId': currentUser.uid,
            'userName': currentUser.displayName ?? '',
          };

          final docRef = await firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('plan_requests')
              .add(newPlanRequest);

          // 생성된 문서로 계속 진행
          final planRequestId = docRef.id;
          final planRequestData = newPlanRequest;

          // 예약 번호 생성
          final reservationNumber = _generateReservationNumber();

          // 새로운 데이터 맵 생성
          final Map<String, dynamic> updatedRequestData = Map<String, dynamic>.from(planRequestData);

          // 예약 번호와 시간당 요금 추가
          updatedRequestData['reservationNumber'] = reservationNumber;
          updatedRequestData['pricePerHour'] = pricePerHour;
          updatedRequestData['currencyCode'] = currencyCode;
          updatedRequestData['currencySymbol'] = currencySymbol;
          updatedRequestData['friends_uid'] = friends_uid;
          updatedRequestData['friendUserId'] = friends_uid;

          // plan_requests 문서 업데이트
          await firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('plan_requests')
              .doc(planRequestId)
              .update({
            'reservationNumber': reservationNumber,
            'friends_uid': friends_uid,
            'friendUserId': friends_uid,
          });

          print('예약 번호 생성 및 업데이트 완료: $reservationNumber');

          // 예약 페이지로 이동
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReservationPage(
                  reservationId: "",
                  friendsId: friends_uid,
                  reservationData: updatedRequestData,
                  userId: currentUser.uid,
                  requestId: planRequestId,
                ),
              ),
            );
          }
          return;
        }
      }

      // 찾은 문서의 ID와 데이터 가져오기
      final String planRequestId = querySnapshot.docs.first.id;
      final planRequestData = querySnapshot.docs.first.data();

      // 예약 번호 생성
      final reservationNumber = _generateReservationNumber();

      // 새로운 데이터 맵 생성 (원본 데이터를 변경하지 않기 위해)
      final Map<String, dynamic> updatedRequestData = Map<String, dynamic>.from(planRequestData);

      // 예약 번호와 시간당 요금 추가
      updatedRequestData['reservationNumber'] = reservationNumber;
      updatedRequestData['pricePerHour'] = pricePerHour;
      updatedRequestData['currencyCode'] = currencyCode;
      updatedRequestData['currencySymbol'] = currencySymbol;

      // 중요: friends_uid 필드 추가 (필수)
      updatedRequestData['friends_uid'] = friends_uid;

      // 중요: friendUserId 필드도 추가 (달력 컴포넌트에서 사용)
      updatedRequestData['friendUserId'] = friends_uid;

      // plan_requests 문서 업데이트 (예약 번호만 업데이트)
      await firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('plan_requests')
          .doc(planRequestId)
          .update({
        'reservationNumber': reservationNumber,
        'friends_uid': friends_uid,
        'friendUserId': friends_uid,
      });

      print('예약 번호 생성 및 업데이트 완료: $reservationNumber');
      print('시간당 요금 추가됨: $pricePerHour');
      print('통화 코드 추가됨: $currencyCode');
      print('통화 기호 추가됨: $currencySymbol');
      print('friends_uid 추가됨: $friends_uid');
      print('friendUserId 추가됨: $friends_uid');

      // 예약 페이지로 이동 - friends_uid와 업데이트된 데이터 전달
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReservationPage(
              reservationId: "", // 빈 문자열 (생성 전)
              friendsId: friends_uid,
              reservationData: updatedRequestData, // 예약 번호와 시간당 요금이 추가된 데이터 전달
              userId: currentUser.uid,
              requestId: planRequestId,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예약 페이지 이동 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 채팅 화면으로 이동
  Future<void> _navigateToChatScreen(BuildContext context) async {
    try {
      // 현재 로그인한 사용자 ID 가져오기
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("로그인이 필요합니다.");
      }
      final userId = currentUser.uid; // 변수명 userId로 유지

      // 프렌즈 정보 가져오기
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final friendsDoc = await firestore
          .collection('tripfriends_users')
          .doc(friends_uid)
          .get();

      if (!friendsDoc.exists) {
        throw Exception("프렌즈 정보를 찾을 수 없습니다.");
      }

      final friendsData = friendsDoc.data()!;
      final String friendsName = friendsData['name'] ?? "프렌즈";
      final String? friendsImage = friendsData['profileImageUrl'];

      if (context.mounted) {
        // 채팅 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userId: userId, // 원래 위젯 정의에 맞게 userId 유지
              friendsId: friends_uid,
              friendsName: friendsName,
              friendsImage: friendsImage,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('채팅 화면 이동 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      child: Row(
        children: [
          // 채팅하기 버튼
          Expanded(
            flex: 4,
            child: ElevatedButton(
              onPressed: () => _navigateToChatScreen(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF237AFF),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(
                  color: Color(0xFF237AFF),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: const Text(
                '채팅하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 예약하기 버튼
          Expanded(
            flex: 6,
            child: ElevatedButton(
              onPressed: () => _navigateToReservationPage(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF237AFF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: const Text(
                '예약하기',
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
}