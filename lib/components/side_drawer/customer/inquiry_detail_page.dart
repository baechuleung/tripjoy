import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/inquiry_detail_content.dart';
import 'widgets/inquiry_detail_answer.dart';

class InquiryDetailPage extends StatelessWidget {
  final String inquiryId;

  const InquiryDetailPage({
    Key? key,
    required this.inquiryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '문의 상세',
          style: TextStyle(
            color: const Color(0xFF353535),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('customer_service')
            .doc(inquiryId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 문의 내용
                InquiryDetailContent(data: data),

                // 답변이 있는 경우
                if (data['answer'] != null) ...[
                  SizedBox(height: 8),
                  InquiryDetailAnswer(data: data),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}