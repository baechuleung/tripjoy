import 'package:flutter/material.dart';
import '../service/customer_service_controller.dart';

class InquiryDetailContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const InquiryDetailContent({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusInfo = CustomerServiceController.getStatusInfo(data['status']);

    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 상태 배지
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusInfo['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusInfo['text'],
                  style: TextStyle(
                    color: statusInfo['color'],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8),
              // 카테고리
              Text(
                data['category'] ?? '일반문의',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // 제목
          Text(
            data['title'] ?? '',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          // 내용
          Text(
            data['content'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          // 작성일
          Text(
            CustomerServiceController.formatDate(data['createdAt']),
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}