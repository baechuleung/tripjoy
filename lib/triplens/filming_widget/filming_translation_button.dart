import 'package:flutter/material.dart';
import '../camera/camera_page.dart'; // CameraPage 파일 임포트

class FilmingTranslationButton extends StatelessWidget { // 클래스 이름 변경
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // CameraPage로 이동
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CameraPage()),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15), // 양쪽 10씩 여백 추가
        decoration: ShapeDecoration(
          color: Colors.white, // 배경을 흰색으로 설정
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: Color(0xFFD9D9D9)), // 테두리 설정
            borderRadius: BorderRadius.circular(5), // 둥근 모서리 설정
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 왼쪽과 오른쪽 정렬
          children: [
            Row(
              children: [
                // 왼쪽에 아이콘 추가
                Image.asset(
                  'assets/tripjoy_kit/filming_appbar.png', // 아이콘 경로
                  width: 24, // 아이콘 크기 설정
                  height: 24,
                ),
                SizedBox(width: 10), // 아이콘과 텍스트 사이 간격
                Text(
                  '촬영 번역', // 텍스트 수정
                  style: TextStyle(
                    color: Colors.black, // 텍스트 색상을 검정색으로 변경
                    fontSize: 18, // 글자 크기를 18로 설정
                    fontWeight: FontWeight.w600, // 글자 굵기를 medium으로 설정
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '번역하기', // 오른쪽에 추가할 텍스트
                  style: TextStyle(
                    color: Color(0xFF999999), // 회색 텍스트
                    fontSize: 16, // 글자 크기를 16으로 설정
                    fontWeight: FontWeight.w500, // 글자 굵기를 medium으로 설정
                  ),
                ),
                SizedBox(width: 10), // 텍스트와 햄버거 아이콘 사이의 간격
                IconButton(
                  icon: Icon(Icons.swap_vert),
                  color: Color(0xFFD9D9D9), // 아이콘 색상을 헥사코드 #D9D9D9로 설정
                  onPressed: () {
                    // 여기에 위젯 이동 기능을 넣을 예정
                    // 기능이 추가될 때 여기에 코드 작성
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
