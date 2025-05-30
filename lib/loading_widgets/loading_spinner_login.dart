// loading_spinner_login.dart

import 'dart:async';
import 'package:flutter/material.dart';

class LoadingSpinnerLogin extends StatefulWidget {
  final double opacity;

  const LoadingSpinnerLogin({
    Key? key,
    this.opacity = 1.0,
  }) : super(key: key);

  @override
  _LoadingSpinnerLoginState createState() => _LoadingSpinnerLoginState();
}

class _LoadingSpinnerLoginState extends State<LoadingSpinnerLogin>
    with TickerProviderStateMixin {
  double leftOpacity = 0;
  double centerOpacity = 0;
  double rightOpacity = 0;

  late AnimationController _leftController;
  late AnimationController _rightController;
  late AnimationController _centerController;
  late Animation<Offset> _leftSlideAnimation;
  late Animation<Offset> _rightSlideAnimation;
  late Animation<Offset> _centerSlideAnimation;

  @override
  void initState() {
    super.initState();

    // 왼쪽 이미지 컨트롤러
    _leftController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // 오른쪽 이미지 컨트롤러
    _rightController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // 중앙 비행기 컨트롤러
    _centerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 왼쪽에서 오는 애니메이션
    _leftSlideAnimation = Tween<Offset>(
      begin: const Offset(-2.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _leftController,
      curve: Curves.easeOutCubic,
    ));

    // 오른쪽에서 오는 애니메이션
    _rightSlideAnimation = Tween<Offset>(
      begin: const Offset(2.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _rightController,
      curve: Curves.easeOutCubic,
    ));

    // 비행기 날아오는 애니메이션 (위에서 아래로, 곡선)
    _centerSlideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.0, -2.0),
          end: const Offset(-0.5, -1.0),
        ),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-0.5, -1.0),
          end: const Offset(0.0, 0.0),
        ),
        weight: 70.0,
      ),
    ]).animate(CurvedAnimation(
      parent: _centerController,
      curve: Curves.easeInOutQuad,
    ));

    startAnimation();
  }

  void startAnimation() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          leftOpacity = 1;
        });
        _leftController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          centerOpacity = 1;
        });
        _centerController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          rightOpacity = 1;
        });
        _rightController.forward();
      }
    });
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    _centerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 왼쪽 이미지
            SlideTransition(
              position: _leftSlideAnimation,
              child: AnimatedOpacity(
                opacity: leftOpacity,
                duration: const Duration(milliseconds: 500),
                child: Image.asset(
                  'assets/login/left_title.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // 중앙 비행기
            SlideTransition(
              position: _centerSlideAnimation,
              child: AnimatedOpacity(
                opacity: centerOpacity,
                duration: const Duration(milliseconds: 500),
                child: Image.asset(
                  'assets/login/center_flight.png',
                  width: 42,
                  height: 39,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // 오른쪽 이미지
            SlideTransition(
              position: _rightSlideAnimation,
              child: AnimatedOpacity(
                opacity: rightOpacity,
                duration: const Duration(milliseconds: 500),
                child: Image.asset(
                  'assets/login/right_title.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}