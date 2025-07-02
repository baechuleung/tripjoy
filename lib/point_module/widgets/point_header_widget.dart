// lib/point_module/widgets/point_header_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/point_usage_info_page.dart';

class PointHeaderWidget extends StatelessWidget {
  final int currentPoints;
  final bool isLoading;

  const PointHeaderWidget({
    super.key,
    required this.currentPoints,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '보유 포인트',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PointUsageInfoPage(),
                    ),
                  );
                },
                child: const Icon(
                  Icons.help_outline,
                  size: 16,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (isLoading)
            const SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            Text(
              '${numberFormat.format(currentPoints)} P',
              style: const TextStyle(
                color: Color(0xFF4047ED),
                fontSize: 28,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                height: 1.20,
                letterSpacing: -0.56,
              ),
            ),
        ],
      ),
    );
  }
}