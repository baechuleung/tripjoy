// tripfriends/manual/question_04.dart

import 'package:flutter/material.dart';
import 'question_item.dart';

class Question04 extends StatelessWidget {
  const Question04({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const QuestionItem(
      number: '04',
      question: ' 프렌즈와 가이드의 차이점이 뭔가요?',
      answerWidget: _AnswerContent(),
    );
  }
}

class _AnswerContent extends StatelessWidget {
  const _AnswerContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 세로 Divider
        Container(
          height: 40,
          width: 2,
          color: const Color(0xFF353535),
          margin: const EdgeInsets.symmetric(vertical: 16),
        ),

        // 제목 텍스트
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '진짜 여행자가 원하는건,\n',
                style: TextStyle(
                  color: const Color(0xFF353535),
                  fontSize: 18,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  height: 1.60,
                ),
              ),
              TextSpan(
                text: '"자유롭고 유연한 현지 경험"',
                style: TextStyle(
                  color: const Color(0xFF353535),
                  fontSize: 18,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  height: 1.60,
                ),
              ),
              TextSpan(
                text: '입니다. ',
                style: TextStyle(
                  color: const Color(0xFF353535),
                  fontSize: 18,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  height: 1.60,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // 첫 번째 이미지
        Image.asset(
          'assets/manual/step4_01.png',
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 24),

        // 첫 번째 행 태그들
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: ShapeDecoration(
                color: const Color(0xFFF6F6F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    '#맛집/카페 탐방',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Color(0xFF4E5968),
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      height: 1.60,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: ShapeDecoration(
                color: const Color(0xFFF6F6F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    '#문화/관광지 체험',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Color(0xFF4E5968),
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      height: 1.60,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 두 번째 행 태그들
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: ShapeDecoration(
                color: const Color(0xFFF6F6F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    '#자유일정/동행',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Color(0xFF4E5968),
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      height: 1.60,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: ShapeDecoration(
                color: const Color(0xFFF6F6F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    '#긴급 상황지원',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Color(0xFF4E5968),
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      height: 1.60,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 세 번째 행 태그
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: ShapeDecoration(
            color: const Color(0xFFF6F6F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                '#전통시장/쇼핑탐방',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Color(0xFF4E5968),
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  height: 1.60,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 두 번째 이미지
        SizedBox(
          width: 200, // 이미지 너비 제한
          child: Image.asset(
            'assets/manual/step4_02.png',
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 24),

        // 마지막 설명 텍스트
        Text(
          "트립프렌즈는 정해진 코스를 안내하는\n'일반가이드'가 아닌 여행자의 일정에 맞춰 현지 감성과 경험을 더해주는 친구 같은 동행입니다.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF353535),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.60,
          ),
        ),
      ],
    );
  }
}