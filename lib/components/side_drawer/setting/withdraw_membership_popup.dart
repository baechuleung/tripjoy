import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../utils/shared_preferences_util.dart';
import '../../../screens/main_page.dart';

class WithdrawMembershipPopup extends StatefulWidget {
  const WithdrawMembershipPopup({Key? key}) : super(key: key);

  @override
  State<WithdrawMembershipPopup> createState() => _WithdrawMembershipPopupState();
}

class _WithdrawMembershipPopupState extends State<WithdrawMembershipPopup> {
  bool _isLoading = false;

  Future<void> _deleteUserAccount(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final String uid = user.uid;

        // 백엔드 API 호출하여 계정 삭제 요청
        final success = await _requestUserDeletion(uid);

        if (success) {
          // 성공 메시지 디버그 프린트
          debugPrint('✅ 회원 탈퇴가 완료되었습니다.');

          // 로컬에서 로그아웃 처리
          await SharedPreferencesUtil.clearUserDocument();
          await FirebaseAuth.instance.signOut();

          setState(() {
            _isLoading = false;
          });

          if (!mounted) return;

          // 메인 화면으로 이동
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainPage(),
            ),
                (Route<dynamic> route) => false,
          );
        } else {
          setState(() {
            _isLoading = false;
          });

          if (!mounted) return;

          // 실패 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('회원 탈퇴 처리에 실패했습니다. 다시 시도해주세요.')),
          );

          Navigator.of(context).pop();
        }
      }
    } catch (error) {
      // 로딩 상태 해제
      setState(() {
        _isLoading = false;
      });

      // 에러 메시지 디버그 프린트
      debugPrint('🚫 회원 탈퇴 오류: ${error.toString()}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원 탈퇴 중 오류가 발생했습니다. 다시 시도해주세요.')),
      );

      Navigator.of(context).pop();
    }
  }

  // 백엔드에 사용자 계정 삭제 요청
  Future<bool> _requestUserDeletion(String uid) async {
    try {
      // 백엔드 API 엔드포인트
      const String apiUrl = 'https://us-central1-tripjoy-d309f.cloudfunctions.net/main/delete-users';

      debugPrint('🔄 계정 삭제 API 호출 시작: $uid');

      // HTTP 요청 전송
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': uid,
        }),
      );

      // 응답 확인
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ 계정 삭제 요청 성공: ${responseData['message']}');
          return true;
        } else {
          debugPrint('⚠️ 계정 삭제 요청 실패: ${responseData['message']}');
          return false;
        }
      } else {
        debugPrint('⚠️ 계정 삭제 API 응답 오류: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ 계정 삭제 API 호출 오류: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('정말 탈퇴하시겠어요?'),
      content: _isLoading
          ? Container(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      )
          : Text('탈퇴하시게 되면 작성하신 정보들이 모두 삭제됩니다.'),
      actions: _isLoading
          ? []
          : [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('취소', style: TextStyle(color: Colors.black)),
        ),
        TextButton(
          onPressed: () async {
            await _deleteUserAccount(context);
          },
          child: Text('탈퇴하기', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}