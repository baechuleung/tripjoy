// loading_spinner_place.dart
import 'dart:async';
import 'package:flutter/material.dart';

class LoadingSpinnerPlace extends StatefulWidget {
  const LoadingSpinnerPlace({
    Key? key,
  }) : super(key: key);

  @override
  _LoadingSpinnerPlaceState createState() => _LoadingSpinnerPlaceState();
}

class _LoadingSpinnerPlaceState extends State<LoadingSpinnerPlace> {
  late ScrollController _scrollController;
  final double _itemWidth = 60.0;
  final double _spacing = 8.0;  // 간격을 20.0에서 8.0으로 줄임

  final List<String> imagePaths = [
    'assets/plan/spinner/01.png',
    'assets/plan/spinner/02.png',
    'assets/plan/spinner/03.png',
    'assets/plan/spinner/04.png',
    'assets/plan/spinner/05.png',
    'assets/plan/spinner/06.png',
    'assets/plan/spinner/07.png',
    'assets/plan/spinner/08.png',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startScrolling();
  }

  void _startScrolling() {
    Timer.periodic(const Duration(milliseconds: 10), (timer) {  // 50ms에서 30ms로 변경하여 속도 증가
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final nextScroll = currentScroll + 1.0;  // 0.5에서 1.0으로 변경하여 스크롤 속도 증가

      if (currentScroll >= maxScroll) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(nextScroll);
      }
    });
  }

  @override
  void dispose() {
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
            // 장소 아이콘 스크롤
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

            const Text(
              '검색결과를 찾고 있어요!\n잠시만 기다려 주세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}