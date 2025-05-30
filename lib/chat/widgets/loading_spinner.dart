// lib/chat/widgets/loading_spinner.dart - 트립프렌즈 앱(고객용)
import 'package:flutter/material.dart';
import 'dart:math' as math;

class LoadingSpinner extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final double strokeWidth;
  final String? message;
  final bool showShadow;

  const LoadingSpinner({
    Key? key,
    this.size = 50.0,
    this.primaryColor = const Color(0xFF237AFF),
    this.secondaryColor = const Color(0xFFAED6FF),
    this.strokeWidth = 4.0,
    this.message,
    this.showShadow = true,
  }) : super(key: key);

  @override
  State<LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<LoadingSpinner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 로딩 스피너 컨테이너
          Container(
            width: widget.size,
            height: widget.size,
            decoration: widget.showShadow ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ) : null,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SpinnerPainter(
                    value: _controller.value,
                    primaryColor: widget.primaryColor,
                    secondaryColor: widget.secondaryColor,
                    strokeWidth: widget.strokeWidth,
                  ),
                );
              },
            ),
          ),

          // 메시지 텍스트
          if (widget.message != null)
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: widget.showShadow ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ] : null,
                ),
                child: Text(
                  widget.message!,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// 커스텀 로딩 스피너 페인터
class _SpinnerPainter extends CustomPainter {
  final double value;
  final Color primaryColor;
  final Color secondaryColor;
  final double strokeWidth;

  _SpinnerPainter({
    required this.value,
    required this.primaryColor,
    required this.secondaryColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 배경 원
    final backgroundPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 회전하는 호
    final foregroundPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 첫 번째 호
    final startAngle = -math.pi / 2 + (2 * math.pi * value);
    final sweepAngle = math.pi / 1.5;  // 호의 길이

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      foregroundPaint,
    );

    // 두 번째 작은 호
    final secondaryStartAngle = startAngle + math.pi;
    final secondarySweepAngle = math.pi / 3;  // 더 작은 호

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      secondaryStartAngle,
      secondarySweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) {
    return value != oldDelegate.value;
  }
}