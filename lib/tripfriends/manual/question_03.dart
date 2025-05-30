// tripfriends/manual/question_03.dart

import 'package:flutter/material.dart';
import 'question_item.dart';

class Question03 extends StatelessWidget {
  const Question03({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const QuestionItem(
      number: '03',
      question: ' 트립프렌즈는 안전한가요?',
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
        // 첫 번째 항목
        _buildSafetyItem(
          imagePath: 'assets/manual/panel_settings.png',
          title: '철저한 프렌즈 검증 시스템',
          description: '트립프렌즈에 등록되는 모든 프렌즈는 기본 프로필 인증 절차를 거칩니다. 신청된 프렌즈의 정보는 관리팀에서 검토 후 승인되며, 일정 기준을 충족해야만 활동이 가능합니다. 프렌즈는 사용자와의 매칭 전까지 프로필을 계속 업데이트 할수 있습니다.',
        ),

        const SizedBox(height: 32),

        // 두 번째 항목
        _buildSafetyItem(
          imagePath: 'assets/manual/star_shine.png',
          title: '후기 및 평점 시스템',
          description: '매칭 완료 후 사용자는 프렌즈에 대한 후기 및 평점을 남길 수 있으며 사용자들은 후기를 참고하여 신뢰할수 있는 프렌즈를 선택할 수 있습니다.',
        ),

        const SizedBox(height: 32),

        // 세 번째 항목
        _buildSafetyItem(
          imagePath: 'assets/manual/support_agent.png',
          title: '고객센터 및 1:1 문의 지원',
          description: '이용 중 문제가 발생하면, 1:1 문의 기능을 통해 빠르게 도움을 받을 수 있습니다. 서비스 이용 관련 문의 등 다양한 사항을 고객센터에서 지원 합니다. 매칭된 프렌즈와의 원활한 소통을 위해 채팅 기능을 제공하며, 예약일정 변경이 필요한 경우 프렌즈와 직접 조율 해야 합니다.',
        ),
      ],
    );
  }

  Widget _buildSafetyItem({
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
          width: 50,
          height: 50,
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 16),

        // 제목
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF4E5968),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        // 설명
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF353535),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}