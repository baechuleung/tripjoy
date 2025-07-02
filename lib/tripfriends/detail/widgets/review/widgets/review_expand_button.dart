// lib/tripfriends/detail/widgets/review/widgets/review_expand_button.dart

import 'package:flutter/material.dart';

class ReviewExpandButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const ReviewExpandButton({
    super.key,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            shape: BoxShape.circle,
          ),
          child: Icon(
            expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: Colors.grey[700],
            size: 24,
          ),
        ),
      ),
    );
  }
}