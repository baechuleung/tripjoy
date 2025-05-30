import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 추가된 부분
import '../auth/auth_service.dart';  // AuthService 임포트
import '../auth/login_selection/login_selection_screen.dart';  // 로그인 선택 화면 임포트
import '../term/term_service.dart';  // 서비스 약관 페이지 임포트
import '../term/term_privacy.dart';  // 개인정보 처리방침 페이지 임포트

class SideMenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          '카테고리',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSectionTitle('내주변'),
          _buildMenuItem('내 주변가게', Icons.store, context),
          _buildMenuItem('HOT플레이스', Icons.local_fire_department, context),
          _buildMenuItem('최근 본 가게', Icons.history, context),

          Divider(),

          _buildSectionTitle('찜'),
          _buildMenuItem('내가 찜한가게', Icons.favorite, context),

          Divider(),

          _buildSectionTitle('마이페이지'),
          _buildMenuItem('내가 작성한 리뷰', Icons.rate_review, context),
          _buildMenuItem('이용불편사항신고', Icons.report_problem, context),
          _buildMenuItem('이용약관 페이지', Icons.description, context, TermServicePage()),  // 서비스 약관으로 이동
          _buildMenuItem('개인정보 취급방침', Icons.privacy_tip, context, TermPrivacyPage()),  // 개인정보 처리방침으로 이동
          _buildMenuItem('회원탈퇴하기', Icons.exit_to_app, context),

          Divider(),

          ListTile(
            title: Text('로그아웃', style: TextStyle(color: Colors.black)),
            trailing: Icon(Icons.logout, color: Colors.black),
            onTap: () async {
              try {
                await AuthService.signOut();  // 로그아웃 서비스 호출 (인스턴스 대신 클래스 이름으로 호출)
                // 로그아웃 후 LoginSelectionScreen으로 이동
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginSelectionScreen()),  // LoginSelectionScreen으로 변경
                );
              } catch (e) {
                // 로그아웃 실패 시 처리
                print('로그아웃 실패: $e');  // 예외 로그 출력
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('로그아웃에 실패했습니다. 다시 시도해주세요.'),
                ));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, BuildContext context, [Widget? nextPage]) {
    return ListTile(
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 16.0),
      leading: Icon(icon, color: Colors.black),
      onTap: () {
        if (nextPage != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => nextPage),
          );
        } else {
          // 기본 동작, 다른 페이지로의 이동이 없는 항목들
          print('$title 클릭됨');
        }
      },
    );
  }
}
