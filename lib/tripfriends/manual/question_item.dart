// tripfriends/manual/question_item.dart

import 'package:flutter/material.dart';

// 공통으로 사용될 질문 아이템 위젯의 기본 구조
class QuestionItem extends StatefulWidget {
  final String number;
  final String question;
  final Widget answerWidget; // 답변 위젯을 받도록 변경

  const QuestionItem({
    Key? key,
    required this.number,
    required this.question,
    required this.answerWidget,
  }) : super(key: key);

  @override
  State<QuestionItem> createState() => _QuestionItemState();
}

class _QuestionItemState extends State<QuestionItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,  // 수직 가운데 정렬 적용
                children: [
                  SizedBox(
                    width: 50,
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: const [
                          Color(0xFF3182F6),  // 시작 색상 (#3182F6)
                          Color(0xFFFA80A1),  // 끝 색상 (#FA80A1)
                        ],
                      ).createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                      child: Text(
                        widget.number,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white, // ShaderMask에서는 흰색으로 설정해야 그라데이션이 제대로 보임
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.question,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 펼쳐질 때 나타나는 답변 영역
          if (_isExpanded)
            Container(
              width: double.infinity,
              alignment: Alignment.center, // 내용 가운데 정렬
              padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
              child: widget.answerWidget, // 답변 위젯 표시
            ),
        ],
      ),
    );
  }
}