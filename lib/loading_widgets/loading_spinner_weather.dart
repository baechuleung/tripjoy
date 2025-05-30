// loading_spinner_wether.dart
import 'dart:async';
import 'package:flutter/material.dart';

class LoadingSpinnerWeather extends StatefulWidget {
  final double progress;

  const LoadingSpinnerWeather({
    Key? key,
    required this.progress,
  }) : super(key: key);

  @override
  _LoadingSpinnerWeatherState createState() => _LoadingSpinnerWeatherState();
}

class _LoadingSpinnerWeatherState extends State<LoadingSpinnerWeather> {
  late Timer _timer;
  late ScrollController _scrollController;
  final double _itemWidth = 60.0;
  final double _spacing = 20.0;
  double _animatedProgress = 0.0;

  final List<String> imagePaths = [
    'assets/tripjoy_kit/spinner/w_01.png',
    'assets/tripjoy_kit/spinner/w_02.png',
    'assets/tripjoy_kit/spinner/w_03.png',
    'assets/tripjoy_kit/spinner/w_04.png',
    'assets/tripjoy_kit/spinner/w_05.png',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startScrolling();

    // 프로그레스 바 자동 증가 애니메이션
    _startProgressAnimation();
  }

  void _startProgressAnimation() {
    const interval = Duration(milliseconds: 10); // 50ms에서 30ms로 감소
    _timer = Timer.periodic(interval, (timer) {
      if (mounted) {
        setState(() {
          if (_animatedProgress < widget.progress) {
            _animatedProgress = _animatedProgress + 0.02; // 0.01에서 0.02로 증가
            if (_animatedProgress > widget.progress) {
              _animatedProgress = widget.progress;
            }
          }
        });
      }
    });
  }

  void _startScrolling() {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final nextScroll = currentScroll + 0.5;

      if (currentScroll >= maxScroll) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(nextScroll);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 날씨 아이콘 스크롤
            SizedBox(
              height: 60,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    ...List.generate(3, (listIndex) {
                      return Row(
                        children: imagePaths.map((imagePath) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: _spacing / 2),
                            child: Image.asset(
                              imagePath,
                              width: _itemWidth,
                              height: _itemWidth,
                              fit: BoxFit.contain,
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 부드러운 프로그레스 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 100), // 500ms에서 300ms로 감소
                    curve: Curves.easeInOut,
                    tween: Tween<double>(
                      begin: 0,
                      end: _animatedProgress,
                    ),
                    builder: (context, double value, child) {
                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: value,
                              backgroundColor: const Color(0xFFE0E0E0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF3C84F5)),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(value * 100).toInt()}%',
                            style: const TextStyle(
                              color: Color(0xFF353535),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              '날씨데이터를 불러오고있어요!\n잠시만 기다려주세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF353535),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}