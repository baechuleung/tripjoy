import 'dart:async';
import 'package:flutter/material.dart';
import '../controller/current_reservation_controller.dart';
import '../models/current_reservation_model.dart';
import '../widgets/list/current_reservation_info.dart';  // 변경된 파일 import
import '../widgets/list/current_reservation_empty_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 현재 예약 정보를 표시하는 탭 위젯
class CurrentReservationTab extends StatefulWidget {
  const CurrentReservationTab({Key? key}) : super(key: key);

  @override
  _CurrentReservationTabState createState() => _CurrentReservationTabState();
}

class _CurrentReservationTabState extends State<CurrentReservationTab> with AutomaticKeepAliveClientMixin {
  // 컨트롤러 인스턴스
  final CurrentReservationController _controller = CurrentReservationController();

  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  bool get wantKeepAlive => true; // 탭 변경 시에도 상태 유지

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 예약 삭제 이벤트 처리
  void _onReservationDeleted() {
    // StreamBuilder를 사용하므로 별도의 새로고침 로직이 필요 없음
    // 자동으로 스트림이 새로운 데이터를 감지하고 UI를 업데이트함
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 사용 시 필수

    // 현재 로그인한 사용자 확인
    final user = _controller.getCurrentUser();
    if (user == null) {
      return _buildLoginRequiredView();
    }

    // 현재 로그인한 사용자의 예약 데이터 스트림 사용
    return StreamBuilder<List<Reservation>>(
      // collectionGroup을 사용한 개선된 실시간 스트림 사용
      stream: _controller.getReservationsRealTimeStream(),
      builder: (context, snapshot) {
        // 로딩 중 표시
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView();
        }

        // 오류 처리
        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error);
        }

        // 예약 목록 가져오기
        final reservations = snapshot.data ?? [];

        // 예약 없음 처리
        if (reservations.isEmpty) {
          return const ReservationEmptyState();
        }

        // 예약 목록 표시
        return _buildReservationListView(reservations, user.uid);
      },
    );
  }

  /// 로그인 필요 화면
  Widget _buildLoginRequiredView() {
    return const Center(child: Text('로그인이 필요합니다.'));
  }

  /// 로딩 화면
  Widget _buildLoadingView() {
    return const Center(child: CircularProgressIndicator());
  }

  /// 오류 화면
  Widget _buildErrorView(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('오류가 발생했습니다: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // setState를 호출하여 StreamBuilder 재구축
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF237AFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  /// 예약 목록 화면
  Widget _buildReservationListView(List<Reservation> reservations, String currentUserId) {
    return RefreshIndicator(
      onRefresh: () async {
        // 새로고침 시 StreamBuilder 재구축
        setState(() {});
      },
      child: ListView.builder(
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          return CurrentReservationInfo(  // 클래스명 변경
            reservation: reservations[index],
            currentUserId: currentUserId,
            onViewDetail: (_) {
              // 상세 페이지 이동 제거 - 상세 페이지 없이 그냥 카드 내에서 모든 정보 표시
              // 아무 작업도 수행하지 않음
            },
            onTimerExpired: _onReservationDeleted,
          );
        },
      ),
    );
  }
}
