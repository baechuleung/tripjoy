import 'dart:async';
import 'package:flutter/material.dart';

class LoadingSpinner extends StatefulWidget {
  final double opacity;

  const LoadingSpinner({
    Key? key,
    this.opacity = 0.5,
  }) : super(key: key);

  @override
  _LoadingSpinnerState createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<LoadingSpinner> {
  late Timer _timer;
  late int currentIndex;

  final List<String> imagePaths = [
    'assets/spiner/1.png',
    'assets/spiner/2.png',
    'assets/spiner/3.png',
  ];

  @override
  void initState() {
    super.initState();
    currentIndex = 0;

    // 300ms마다 이미지 변경
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        currentIndex = (currentIndex + 1) % imagePaths.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Image.asset(
            imagePaths[currentIndex],
            key: ValueKey<int>(currentIndex),
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
