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

  // 다양한 기본 아이콘 리스트 추가 (3D 느낌을 줄 수 있는 아이콘 선택)
  final List<IconData> icons = [
    Icons.flight_takeoff,
    Icons.directions_boat_filled,
    Icons.directions_car_filled,
    Icons.directions_bike,
    Icons.train,
  ];

  @override
  void initState() {
    super.initState();
    currentIndex = 0;

    // 매 300 밀리초마다 아이콘을 변경하는 타이머 설정
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        currentIndex = (currentIndex + 1) % icons.length;
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
      color: Colors.black.withOpacity(widget.opacity), // 반투명한 배경
      child: Center(
        child: Container(
          width: 50, // 원 크기
          height: 50, // 원 크기
          decoration: BoxDecoration(
            color: Colors.white, // 흰색 배경의 동그라미
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200), // 빠른 전환 효과
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Icon(
                icons[currentIndex],
                key: ValueKey<int>(currentIndex),
                color: Colors.blue, // 아이콘 색상
                size: 30, // 아이콘 크기
              ),
            ),
          ),
        ),
      ),
    );
  }
}
