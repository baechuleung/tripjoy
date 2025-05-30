import 'package:flutter/material.dart';

class OneLineReview extends StatefulWidget {
  final TextEditingController controller;

  const OneLineReview({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  _OneLineReviewState createState() => _OneLineReviewState();
}

class _OneLineReviewState extends State<OneLineReview> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF5F5F5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프렌즈에 대한 한줄평을 남겨주세요!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: widget.controller,
            maxLength: 100,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: '짧게 나마 프렌즈 이용 후 후기를 공유해주세요!',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              filled: true,
              fillColor: Color(0xFFF9F9F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Color(0xFF3182F6),
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}