import 'package:flutter/material.dart';
import '../service/customer_service_controller.dart';

class InquiryDetailAnswer extends StatelessWidget {
  final Map<String, dynamic> data;

  const InquiryDetailAnswer({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Color(0xFFF9F9F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.support_agent,
                color: Color(0xFF3182F6),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '고객센터 답변',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3182F6),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            data['answer'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              height: 1.5,
            ),
          ),
          if (data['answeredAt'] != null) ...[
            SizedBox(height: 16),
            Text(
              '답변일시: ${CustomerServiceController.formatDate(data['answeredAt'])}',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ],
      ),
    );
  }
}