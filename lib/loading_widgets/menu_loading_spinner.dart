import 'package:flutter/material.dart';
import 'dart:math' as math;

class MenuLoadingSpinner extends StatefulWidget {
  const MenuLoadingSpinner({Key? key}) : super(key: key);

  @override
  State<MenuLoadingSpinner> createState() => _MenuLoadingSpinnerState();
}

class _MenuLoadingSpinnerState extends State<MenuLoadingSpinner>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;
  late AnimationController _slideController;
  late List<Animation<Color?>> _dotAnimations;

  final double boxHeight = 55.0;
  final double boxSpacing = 5.0;

  @override
  void initState() {
    super.initState();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _dotAnimations = List.generate(3, (index) {
      Color getBeginColor() {
        switch(index) {
          case 0: return const Color(0xFFFFEA9C);
          case 1: return const Color(0xFFF8D965);
          case 2: return const Color(0xFFFFCB0B);
          default: return const Color(0xFFFFEA9C);
        }
      }

      Color getEndColor() {
        switch(index) {
          case 0: return const Color(0xFFF8D965);
          case 1: return const Color(0xFFFFCB0B);
          case 2: return const Color(0xFFFFEA9C);
          default: return const Color(0xFFF8D965);
        }
      }

      return ColorTween(
        begin: getBeginColor(),
        end: getEndColor(),
      ).animate(
        CurvedAnimation(
          parent: _dotsController,
          curve: Interval(
            index * 0.333,
            (index + 1) * 0.333,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  double getOpacity(double position) {
    if (position < 0 || position > 381) return 0.0;
    if (position < 30) return position / 30;
    if (position > 351) return (381 - position) / 30;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 212,
            height: 381,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/tripjoy_kit/loadingspinnerbg.png',
                  fit: BoxFit.contain,
                ),
                ClipRect(
                  child: SizedBox(
                    height: 320,
                    child: AnimatedBuilder(
                      animation: _slideController,
                      builder: (context, child) {
                        return Stack(
                          children: List.generate(6, (index) {
                            double itemHeight = boxHeight + boxSpacing;
                            double totalHeight = itemHeight * 6;
                            double initialPosition = index * itemHeight;
                            double offset = _slideController.value * totalHeight;
                            double currentPosition = (initialPosition + offset) % totalHeight;

                            double opacity = getOpacity(currentPosition);
                            opacity = math.max(0.0, math.min(1.0, opacity));

                            return Positioned(
                              bottom: currentPosition,
                              left: (212 - 200) / 2,
                              child: Opacity(
                                opacity: opacity,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Image.asset(
                                    'assets/tripjoy_kit/loadingspinnerbox1.png',
                                    width: 200,
                                    height: boxHeight,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _dotAnimations[index],
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _dotAnimations[index].value,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          const Text(
            '촬영문서를 변역하고 있어요!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Text(
            '잠시만 기다려주세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}