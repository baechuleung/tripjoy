// tripfriends/manual/manual_page.dart
// TripFriends 도움말 페이지

import 'package:flutter/material.dart';
// 각 질문 위젯 임포트
import 'question_01.dart';
import 'question_02.dart';
import 'question_03.dart';
import 'question_04.dart';

class ManualPage extends StatelessWidget {
  const ManualPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '도움말',
          style: TextStyle(
            color: const Color(0xFF353535),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤드라인 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 그라데이션 텍스트 적용
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: const [
                          Color(0xFF6F7BFF),  // 시작 색상 (#6F7BFF)
                          Color(0xFFFF7676),  // 끝 색상 (#FF7676)
                        ],
                      ).createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                      child: const Text(
                        '"낯선 여행지에서도 더 쉽게! 더 알차게!"',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white, // ShaderMask에서는 흰색으로 설정해야 그라데이션이 제대로 보임
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '트립프렌즈란?',
                      style: TextStyle(
                        color: Color(0xFF353535),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '프렌즈는 여행지에서 나에게 필요한 맞춤 동행을 찾을 수 있는 서비스입니다. 현지에서 맛집 탐방, 쇼핑 도우미, 단순 통역, 기타 서비스를 제공하는 프렌즈와 연결해 줍니다.',
                      style: TextStyle(
                        color: Color(0xFF4E5968),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 질문 01 - 별도 파일로 분리된 위젯 사용
              const Question01(),

              const SizedBox(height: 8),

              // 질문 02 - 별도 파일로 분리된 위젯 사용
              const Question02(),

              const SizedBox(height: 8),

              // 질문 03 - 별도 파일로 분리된 위젯 사용
              const Question03(),

              const SizedBox(height: 8),

              // 질문 04 - 새로 추가된 위젯
              const Question04(),
            ],
          ),
        ),
      ),
    );
  }
}