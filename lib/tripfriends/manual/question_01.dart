// tripfriends/manual/question_01.dart

import 'package:flutter/material.dart';
import 'question_item.dart';

class Question01 extends StatelessWidget {
  const Question01({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const QuestionItem(
      number: '01',
      question: ' 어떻게 사용하는 건가요?',
      answerWidget: _AnswerContent(),
    );
  }
}

class _AnswerContent extends StatelessWidget {
  const _AnswerContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // 가운데 정렬
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: ShapeDecoration(
            color: const Color(0xFFF3F3F3),
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
                'STEP 1',
                style: TextStyle(
                  color: Color(0xFF4E5968),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(
          child: Text(
            '여행국가, 여행도시를 선택하고 \n저장하기를 눌러주세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4E5968),
              fontSize: 14,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              height: 1.50,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 이미지 추가
        Image.asset(
          'assets/manual/question_01_step_01.png',
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 24),

        // Step 2
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: ShapeDecoration(
            color: const Color(0xFFF3F3F3),
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
                'STEP 2',
                style: TextStyle(
                  color: Color(0xFF4E5968),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          child: Text(
            '내 일정에 맞춰 각 나라에 맞는 추천 프렌즈 목록이 업데이트 되면 원하는 프렌즈를 선택 합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF4E5968),
              fontSize: 14,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              height: 1.50,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Image.asset(
          'assets/manual/question_01_step_02.png',
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 24),

        // Step 3
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: ShapeDecoration(
            color: const Color(0xFFF3F3F3),
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
                'STEP 3',
                style: TextStyle(
                  color: Color(0xFF4E5968),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(
          child: Text(
            '프렌즈 상세 소개를 확인하고 원하는 프렌즈와 채팅으로 상세 세부적인 스케줄을 정할수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4E5968),
              fontSize: 14,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              height: 1.50,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Image.asset(
          'assets/manual/question_01_step_03.png',
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 24),

        // Step 4
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: ShapeDecoration(
            color: const Color(0xFFF3F3F3),
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
                'STEP 4',
                style: TextStyle(
                  color: Color(0xFF4E5968),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(
          child: Text(
            '프렌즈와의 예약 전, 채팅을 통해 프렌즈와 일정에 대한 조율 또는 궁금한점에 대해 이야기를 나눈 후 예약을 진핼할수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4E5968),
              fontSize: 14,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              height: 1.50,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Image.asset(
          'assets/manual/question_01_step_04.png',
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 24),

        // Step 5
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: ShapeDecoration(
            color: const Color(0xFFF3F3F3),
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
                'STEP 5',
                style: TextStyle(
                  color: Color(0xFF4E5968),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(
          child: Text(
            '프렌즈 현장결제 이용요금과 필수동의 항목을 동의한 후, 예약하기를 누르면 프렌즈와의 예약이 확정됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4E5968),
              fontSize: 14,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              height: 1.50,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Image.asset(
          'assets/manual/question_01_step_05.png',
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 24),

        // Step 6
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: ShapeDecoration(
            color: const Color(0xFFF3F3F3),
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
                'STEP 6',
                style: TextStyle(
                  color: Color(0xFF4E5968),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(
          child: Text(
            '프렌즈 예약확정 후, 프렌즈 이용시 1시간 기준 프렌즈 기본요금과 10분당 추가요금을 실시간으로 확인할수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4E5968),
              fontSize: 14,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              height: 1.50,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Image.asset(
          'assets/manual/question_01_step_06.png',
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}