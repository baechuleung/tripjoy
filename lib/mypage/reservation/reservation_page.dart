import 'package:flutter/material.dart';
import 'current/screens/current_reservation_tab.dart';
import 'past/screens/past_reservation_tab.dart';
import '../../components/tripfriends_bottom_navigator.dart';
import 'package:tripjoy/components/side_drawer/drawer/user_drawer.dart';

// 전역 TabController 인스턴스 - 어디서든 접근 가능
TabController? globalTabController;

class ReservationPage extends StatefulWidget {
  const ReservationPage({Key? key}) : super(key: key);

  @override
  _ReservationPageState createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 1; // 예약확인 탭이 선택된 상태로 시작
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // GlobalKey 추가

  // 정적 메서드로 탭 전환 기능 제공
  static void switchToPastTab(BuildContext context) {
    if (globalTabController != null) {
      globalTabController!.animateTo(1); // 지난예약 탭으로 전환 (인덱스 1)
      print("전역 컨트롤러를 통해 지난예약 탭으로 전환됨!");
    }
  }

// reservation_page.dart에서 initState 부분만 수정

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 네비게이션으로 전달된 인자 확인 - 지연시켜서 빌드 완료 후 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 인자 확인
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is Map<String, dynamic>) {
        // tabIndex 값이 있으면 해당 탭으로 이동
        if (arguments.containsKey('tabIndex')) {
          final tabIndex = arguments['tabIndex'] as int;
          _tabController.animateTo(tabIndex);
          print('인자를 통해 탭 $tabIndex으로 이동했습니다!');
        }
      }
    });
  }

  @override
  void dispose() {
    // 전역 변수 정리
    if (globalTabController == _tabController) {
      globalTabController = null;
    }
    _tabController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // GlobalKey 추가
      appBar: AppBar(
        title: Text(
          '내 예약',
          style: TextStyle(
            color: Color(0xFF353535),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true, // 제목 가운데 정렬
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: '진행중인 예약'),
            Tab(text: '지난예약'),
          ],
        ),
      ),
      endDrawer: UserDrawer(), // MainPage와 동일한 UserDrawer 사용
      body: TabBarView(
        controller: _tabController,
        children: [
          CurrentReservationTab(),
          PastReservationTab(),
        ],
      ),
      bottomNavigationBar: TripfriendsBottomNavigator(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        scaffoldKey: _scaffoldKey, // 수정된 BottomNavigator에 전달
      ),
    );
  }
}