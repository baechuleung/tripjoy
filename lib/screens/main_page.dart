import 'package:flutter/material.dart';
import 'package:tripjoy/components/side_drawer/drawer/user_drawer.dart';
import 'footer_dec.dart';
import '../tripfriends/plan/plan_request_view.dart';
import '../components/tripfriends_bottom_navigator.dart';
import 'banner/banner_widget.dart';
import 'main_tab_bar.dart';
import '../workmate_main/workmate_main_screen.dart';
import '../live_board/live_board.dart';
import '../triprace/triprace_main_screen.dart';
import '../popup/popup_manager.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  int _selectedTab = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // 화면 빌드 후 팝업 체크
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PopupManager.checkAndShowPopups(context);
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  Widget _getSelectedContent() {
    switch (_selectedTab) {
      case 0:
        return PlanRequestView();
      case 1:
        return TripraceMainScreen();
      case 2:
        return WorkmateMainScreen();
      case 3:
        return LiveBoard();
      default:
        return PlanRequestView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF5F5F5),
      endDrawer: UserDrawer(),
      body: Stack(
        children: [
          // 고정된 배경 Container
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: ShapeDecoration(
              color: const Color(0xFF5963D0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                  bottomRight: Radius.circular(80),
                ),
              ),
            ),
          ),

          // 원래 컨텐츠
          Container(
            color: Colors.transparent,
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더 콘텐츠
                  Container(
                    width: double.infinity,
                    alignment: Alignment.topLeft,
                    padding: EdgeInsets.only(
                      left: 24.0,
                      top: MediaQuery.of(context).padding.top + 24.0,
                      right: 24.0,
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
                            // 햄버거 메뉴 아이콘
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
                      ],
                    ),
                  ),

                  // 탭바 추가
                  MainTabBar(
                    selectedIndex: _selectedTab,
                    onTabSelected: _onTabSelected,
                  ),

                  // 선택된 콘텐츠 표시
                  _getSelectedContent(),

                  // 배너 위젯
                  BannerWidget(),

                  // 푸터
                  FooterWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: TripfriendsBottomNavigator(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        scaffoldKey: _scaffoldKey,
      ),
    );
  }
}