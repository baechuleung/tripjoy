import 'package:flutter/material.dart';
import 'package:tripjoy/screens/main_page.dart';
import 'package:tripjoy/mypage/review/review_page.dart';
import 'package:tripjoy/mypage/reservation/reservation_page.dart';
import 'package:tripjoy/chat/screens/chat_list_screen.dart'; // 채팅 리스트 추가
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth 추가

class TripfriendsBottomNavigator extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const TripfriendsBottomNavigator({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.scaffoldKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // 상단 구분선 제거
      ),
      padding: EdgeInsets.only(top: 4),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          // 현재 선택된 인덱스와 동일한 경우 작업을 수행하지 않음
          if (index == currentIndex) {
            return; // 현재 페이지와 동일한 탭을 클릭한 경우 아무 작업도 수행하지 않음
          }

          onTap(index);

          // 각 탭에 따른 화면 이동 처리
          switch (index) {
            case 0: // 홈
            // 현재 화면이 홈이 아닐 경우에만 이동
              if (ModalRoute.of(context)?.settings.name != '/') {
                // 네비게이션 스택을 비우고 홈으로 이동
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => MainPage(),
                    transitionDuration: Duration.zero,
                  ),
                      (route) => false,
                );
              }
              break;
            case 1: // 내 예약
            // 이미 예약 화면에 있는지 확인
              if (!(ModalRoute.of(context)?.settings.name == '/reservation')) {
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => ReservationPage(),
                    transitionDuration: Duration.zero,
                    settings: RouteSettings(name: '/reservation'),
                  ),
                      (route) => route.isFirst, // 첫 번째 경로(홈)만 유지
                );
              }
              break;
            case 2: // 리뷰
            // 이미 리뷰 화면에 있는지 확인
              if (!(ModalRoute.of(context)?.settings.name == '/review')) {
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => ReviewPage(),
                    transitionDuration: Duration.zero,
                    settings: RouteSettings(name: '/review'),
                  ),
                      (route) => route.isFirst, // 첫 번째 경로(홈)만 유지
                );
              }
              break;
            case 3: // 채팅 리스트 (기존 MY 대신)
            // 이미 채팅 리스트 화면에 있는지 확인
              if (!(ModalRoute.of(context)?.settings.name == '/chat_list')) {
                // Firebase에서 현재 사용자 ID 가져오기
                final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                if (userId.isNotEmpty) {
                  Navigator.of(context).pushAndRemoveUntil(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => ChatListScreen(customerId: userId),
                      transitionDuration: Duration.zero,
                      settings: RouteSettings(name: '/chat_list'),
                    ),
                        (route) => route.isFirst, // 첫 번째 경로(홈)만 유지
                  );
                } else {
                  // 로그인되지 않은 경우 알림
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('채팅을 사용하려면 로그인이 필요합니다')),
                  );
                }
              }
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5963D0), // 활성화 글자색 변경
        unselectedItemColor: const Color(0xFFC2C2C2), // 비활성화 글자색 변경
        iconSize: 24,
        enableFeedback: false, // 피드백 효과 제거
        // 아이콘과 라벨 사이의 추가 공간 설정
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500, // 폰트 두께 변경
          height: 1.6, // 높이 조정하여 간격 늘림
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500, // 폰트 두께 변경
          height: 1.6, // 높이 조정하여 간격 늘림
        ),
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 8), // 아이콘과 텍스트 사이 간격 추가
              child: Image.asset(
                currentIndex == 0
                    ? 'assets/bottom_icons/home_on.png'
                    : 'assets/bottom_icons/home_off.png',
                width: 24,
                height: 24,
              ),
            ),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 8), // 아이콘과 텍스트 사이 간격 추가
              child: Image.asset(
                currentIndex == 1
                    ? 'assets/bottom_icons/reservation_on.png'
                    : 'assets/bottom_icons/reservation_off.png',
                width: 24,
                height: 24,
              ),
            ),
            label: '예약내역',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 8), // 아이콘과 텍스트 사이 간격 추가
              child: Image.asset(
                currentIndex == 2
                    ? 'assets/bottom_icons/review_on.png'
                    : 'assets/bottom_icons/review_off.png',
                width: 24,
                height: 24,
              ),
            ),
            label: '리뷰',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 8), // 아이콘과 텍스트 사이 간격 추가
              child: Image.asset(
                currentIndex == 3
                    ? 'assets/bottom_icons/chat_on.png'
                    : 'assets/bottom_icons/chat_off.png',
                width: 24,
                height: 24,
              ),
            ),
            label: '채팅',
          ),
        ],
      ),
    );
  }
}