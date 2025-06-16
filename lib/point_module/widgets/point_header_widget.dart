// lib/point_module/widgets/point_header_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
          const Text(
            '보유 포인트',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 6),
          if (isLoading)
            const SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  numberFormat.format(currentPoints),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF237AFF),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'P',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF237AFF),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}