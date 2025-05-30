import 'package:flutter/material.dart';
import 'dart:ui'; // ImageFilter를 사용하기 위해 추가
import 'dart:math'; // Random 클래스를 사용하기 위해 추가
import 'package:tripjoy/components/side_drawer/user_drawer.dart';
import 'footer_dec.dart';
import '../tripfriends/plan/plan_request_view.dart';
import '../components/bottom_navigator.dart';
import '../tripfriends/manual/manual_page.dart'; // ManualPage import 추가
import 'banner/banner_widget.dart'; // 배너 위젯 임포트 추가

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  // 추가: Scaffold 키 정의
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // 배경 이미지 랜덤 선택을 위한 변수
  late String _backgroundImage;

  @override
  void initState() {
    super.initState();
    // 랜덤으로 배경 이미지 선택
    _selectRandomBackground();
  }

  // 랜덤 배경 이미지 선택 메서드
  void _selectRandomBackground() {
    final random = Random();
    final imageNumber = random.nextInt(4) + 1; // 1부터 4까지 랜덤 숫자
    _backgroundImage = 'assets/main/main_0$imageNumber.png';
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // 추가: Scaffold에 키 설정
      backgroundColor: Colors.white,
      endDrawer: UserDrawer(),
      // 전체 화면을 스크롤 가능하게 만듦
      body: Stack(
        children: [
          // 배경 이미지 추가 (가우시안 블러 효과 적용)
          Positioned(
            top: -1, // 상단으로 아주 미세하게 확장
            left: -1, // 좌측으로 아주 미세하게 확장
            right: -1, // 우측으로 아주 미세하게 확장
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 1.5,  // 아주 연한 가로 블러
                sigmaY: 1.5,  // 아주 연한 세로 블러
              ),
              child: Image.asset(
                _backgroundImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.45, // 기존 이미지와 비슷한 크기로 유지
              ),
            ),
          ),

          // 원래 컨텐츠 - 위치 유지
          Container(
            color: Colors.transparent, // 배경색을 투명하게 변경
            child: SingleChildScrollView(
              padding: EdgeInsets.zero, // 스크롤뷰 패딩 제거
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬 설정
                children: [
                  // 헤더 콘텐츠 - SafeArea 대신 Container 사용
                  Container(
                    width: double.infinity,
                    alignment: Alignment.topLeft, // 수정: 올바른 정렬 속성
                    padding: EdgeInsets.only(
                      left: 24.0, // 왼쪽 패딩 감소
                      top: MediaQuery.of(context).padding.top + 24.0, // 상태바 높이만 고려
                      right: 24.0, // 오른쪽 패딩 감소
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 로고와 햄버거 메뉴를 가로로 배치
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 로고 이미지
                            Image.asset(
                              'assets/logo.png',
                              height: 16,
                            ),
                            // 햄버거 메뉴 아이콘 추가
                            GestureDetector(
                              onTap: () {
                                _scaffoldKey.currentState?.openEndDrawer();
                              },
                              child: Icon(
                                Icons.menu,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 도움말 링크 컨테이너 (기존 위치에서 이동)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ManualPage())
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      // 그라데이션이 적용된 아이콘
                                      ShaderMask(
                                        shaderCallback: (Rect bounds) {
                                          return LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [Color(0xFF8E87E9), Color(0xFFF680A4)],
                                          ).createShader(bounds);
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '트립프렌즈에 대해 더 자세히 알고싶다면?',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12), // 간격 추가

                        // 첫 번째 텍스트 - 가운데 정렬로 변경
                        Container(
                          width: double.infinity,
                          child: Text(
                            '현지를 가장 잘 아는 트립프렌즈와 함께',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // 두 번째 텍스트 - 가운데 정렬로 변경
                        Container(
                          width: double.infinity,
                          child: Text(
                            '더 깊이 있고 특별한 여행을 떠나보세요!',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12), // 간격 추가
                      ],
                    ),
                  ),

                  // 매치 요청 뷰 - 원래 위치 유지
                  PlanRequestView(),

                  // 배너 위젯 추가 - 원래 위치 유지
                  BannerWidget(),

                  // 푸터 - 원래 위치 유지
                  FooterWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigator(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        scaffoldKey: _scaffoldKey, // 수정된 BottomNavigator에 전달
      ),
    );
  }
}