import 'package:flutter/material.dart';

class ComplaintCaution extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 0.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                '불편사항 신고시 주의사항',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildCautionItem(
                '1. 정확한 내용 입력',
                '• 신고 내용은 가능한 명확하고 구체적으로 작성해주세요.\n  정확한 정보를 입력해야 신속한 처리가 가능합니다.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildCautionItem(
                '2. 허위 신고 금지',
                '• 허위 또는 악의적인 신고는 처리되지 않을 수 있습니다.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildCautionItem(
                '3. 내용 수정 불가',
                '• 신고 접수 후에는 입력한 내용을 수정하거나 삭제할 수 없습니다.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildCautionItem(
                '4. 개인정보 보호',
                '• 신고 내용에 개인 연락처 등 개인정보를 입력하지 않도록 주의해주세요.',
              ),
            ),
            Divider(color: Color(0xFFD9D9D9), thickness: 1),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  '네, 확인했습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF007CFF),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCautionItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
