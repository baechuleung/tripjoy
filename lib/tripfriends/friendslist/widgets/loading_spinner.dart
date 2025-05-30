// lib/tripfriends/friendslist/widgets/loading_spinner.dart
import 'package:flutter/material.dart';
import 'dart:async';

class FriendsLoadingSpinner extends StatefulWidget {
  const FriendsLoadingSpinner({
    Key? key,
  }) : super(key: key);

  @override
  State<FriendsLoadingSpinner> createState() => _FriendsLoadingSpinnerState();
}

class _FriendsLoadingSpinnerState extends State<FriendsLoadingSpinner> with SingleTickerProviderStateMixin {
  bool _showTimeoutMessage = false;
  Timer? _timeoutTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 60; // 60초부터 카운트다운 (30초에서 증가)
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // 색상 애니메이션 설정
    _colorAnimation = ColorTween(
      begin: const Color(0xFF3182F6),
      end: const Color(0xFF6B9DFF),
    ).animate(_animationController);

    // 1초마다 카운트다운 업데이트
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _showTimeoutMessage = true;
            timer.cancel();
          }
        });
      }
    });

    // 60초 후에 타임아웃 메시지 표시 (백업용)
    _timeoutTimer = Timer(const Duration(seconds: 60), () {
      if (mounted) {
        setState(() {
          _showTimeoutMessage = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_showTimeoutMessage) ...[
            // 개선된 로딩 스피너
            AnimatedBuilder(
              animation: _colorAnimation,
              builder: (context, child) {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3182F6).withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_colorAnimation.value!),
                    strokeWidth: 4.0,
                  ),
                );
              },
            ),
            const SizedBox(height: 24.0),
            // 로딩 메시지
            const Text(
              '추천 받을 회원 정보 가져오는중...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8.0),
            // 카운트다운 타이머
            Text(
              '${_secondsRemaining}초 후 시간 초과',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _secondsRemaining <= 10 ? Colors.red : const Color(0xFF666666),
                fontWeight: FontWeight.w400,
              ),
            ),
          ] else ...[
            // 타임아웃 메시지
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2E2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE0B2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF9800),
                    size: 50,
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    '회원 정보를 불러오지 못했습니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    '여행할 나라를 다시 선택해주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}