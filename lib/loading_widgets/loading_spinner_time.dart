// loading_spinner_time.dart
import 'dart:async';
import 'package:flutter/material.dart';

class LoadingSpinnerTime extends StatefulWidget {
  final double progress;

  const LoadingSpinnerTime({
    Key? key,
    required this.progress,
  }) : super(key: key);

  @override
  _LoadingSpinnerTimeState createState() => _LoadingSpinnerTimeState();
}

class _LoadingSpinnerTimeState extends State<LoadingSpinnerTime> {
  late Timer _timer;
  late ScrollController _scrollController;
  final double _itemWidth = 30.0;
  final double _spacing = 20.0;
  double _animatedProgress = 0.0;

  final List<String> imagePaths = [
    'assets/tripjoy_kit/spinner/t_01.png',
    'assets/tripjoy_kit/spinner/t_02.png',
    'assets/tripjoy_kit/spinner/t_03.png',
    'assets/tripjoy_kit/spinner/t_04.png',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startScrolling();
    _startProgressAnimation();
  }

  void _startProgressAnimation() {
    const interval = Duration(milliseconds: 10);
    _timer = Timer.periodic(interval, (timer) {
      if (mounted) {
        setState(() {
          if (_animatedProgress < widget.progress) {
            _animatedProgress = _animatedProgress + 0.02;
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
            // 시계 아이콘 애니메이션
            Stack(
              alignment: Alignment.center,
              children: [
                // 슬라이딩되는 이미지들
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
                // 중앙 고정 이미지
                Image.asset(
                  'assets/tripjoy_kit/spinner/t_center.png',
                  width: _itemWidth * 2.0,  // 50% 더 크게 설정
                  height: _itemWidth * 2.0, // 50% 더 크게 설정
                  fit: BoxFit.contain,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 프로그레스 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 100),
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

            // 변경된 안내 텍스트
            const Text(
              '시차정보를 불러오고 있어요!\n잠시만 기다려주세요!',
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