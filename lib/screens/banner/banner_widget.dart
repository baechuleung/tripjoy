import 'package:flutter/material.dart';
import 'banner_webview.dart';

class BannerWidget extends StatelessWidget {
  const BannerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // 첫 번째 배너 (왼쪽)
          Expanded(
            child: GestureDetector(
              onTap: () {
                // 첫 번째 배너 탭 이벤트 처리
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BannerWebView(
                      url: 'https://www.trippartners.co.kr/?cafe=tripjoy',
                      title: '',
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/banners/banner_01.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 두 번째 배너 (오른쪽)
          Expanded(
            child: GestureDetector(
              onTap: () {
                // 두 번째 배너 탭 이벤트 처리
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BannerWebView(
                      url: 'https://smartstore.naver.com/tripsim',
                      title: '',
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Image.asset(
                      'assets/banners/banner_02.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}