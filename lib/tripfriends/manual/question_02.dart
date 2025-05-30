// tripfriends/manual/question_02.dart

import 'package:flutter/material.dart';
import 'question_item.dart';

class Question02 extends StatelessWidget {
  const Question02({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const QuestionItem(
      number: '02',
      question: ' 어떨때 사용하면 좋은가요?',
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
        // 첫 번째 항목 (대중교통)
        _buildUseCaseWithImage(
          imagePath: 'assets/manual/train.png',
          title: '처음 가보는 곳에 지하철, 버스 노선을 모른다면?',
          description: '현지 대중교통을 함께 이용하며 도와드릴수 있어요!',
        ),

        const SizedBox(height: 32),

        // 두 번째 항목 (도시 여행)
        _buildUseCaseWithImage(
          imagePath: 'assets/manual/cityscape.png',
          title: '계획은 세웠지만 혼자 다니기 막막하다면?',
          description: '가고싶은 곳 어디든 계획대로 함께 움직일수 있어요!',
        ),

        const SizedBox(height: 32),

        // 세 번째 항목 (음식)
        _buildUseCaseWithImage(
          imagePath: 'assets/manual/taste.png',
          title: '로컬 음식점을 가고 싶지만 주문이 망설여 진다면?',
          description: '언어 걱정 없이 현지 음식을 즐길 수 있도록 도와드릴수 있어요!',
        ),
      ],
    );
  }

  Widget _buildUseCaseWithImage({
    required String imagePath,
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 이미지
        Image.asset(
          imagePath,
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 16),

        // 제목
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF353535),
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            height: 1.60,
          ),
        ),

        const SizedBox(height: 8),

        // 설명
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF353535),
            fontSize: 14,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
            height: 1.60,
          ),
        ),
      ],
    );
  }
}