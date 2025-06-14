import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CamDecPopup extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onDontShowToday;

  const CamDecPopup({
    required this.onClose,
    required this.onDontShowToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/tripjoy_kit/cam_popup.png',
            height: 400,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 20),
          Container(
            width: 400, // 이미지와 동일한 너비
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onDontShowToday,
                    child: Text(
                      '다시 보지 않기',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        height: 1.50,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 15,
                  color: Colors.white,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: onClose,
                    child: Text(
                      '네, 확인했어요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        height: 1.50,
                      ),
                    ),
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

// "오늘 하루 보지 않기" 설정
Future<void> dontShowToday() async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now().toString().substring(0, 10); // 오늘 날짜 저장
  await prefs.setString('popup_last_shown', today);
}

// 팝업 표시 함수
void showCameraPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: CamDecPopup(
          onClose: () => Navigator.of(context).pop(),
          onDontShowToday: () async {
            await dontShowToday();
            Navigator.of(context).pop();
          },
        ),
      );
    },
  );
}