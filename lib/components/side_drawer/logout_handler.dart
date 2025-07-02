import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tripjoy/auth/login_selection/login_selection_screen.dart';
import 'package:tripjoy/screens/main_page.dart';

class LogoutHandler extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _handleLogoutAction(BuildContext context) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      // 로그인된 상태인 경우 로그아웃 다이얼로그 표시
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  SizedBox(height: 10),
                  Text(
                    '정말 로그아웃 하시겠습니까?',
                    style: TextStyle(
                      color: const Color(0xFF353535),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      height: 1.50,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: const Color(0xFFE4E4E4),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // 다이얼로그 닫기
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              '취소',
                              style: TextStyle(
                                color: const Color(0x7F14181F),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _auth.signOut();
                            Navigator.of(context).pop(); // 다이얼로그 닫기

                            // 모든 스택을 지우고 로그인 선택 화면으로 이동
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => MainPage(),  // LoginSelectionScreen에서 MainPage로 변경
                              ),
                                  (Route<dynamic> route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFE8E8),
                            foregroundColor: const Color(0xFFFF3E6C),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            '확인',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF3E6C),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // 로그인되지 않은 상태인 경우 바로 로그인 화면으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => LoginSelectionScreen(),
        ),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = _auth.currentUser != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => _handleLogoutAction(context),
            child: Text(
              isLoggedIn ? '로그아웃' : '로그인',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            isLoggedIn ? Icons.logout : Icons.login,
            color: Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }
}