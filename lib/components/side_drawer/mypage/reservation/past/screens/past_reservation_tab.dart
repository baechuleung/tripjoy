import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controller/past_reservation_controller.dart';
import '../models/past_reservation_model.dart';
import '../widgets/list/past_reservation_info.dart'; // 파일명 수정
import '../widgets/list/past_reservation_empty_state.dart';

/// 지난 예약 정보를 표시하는 탭 위젯
class PastReservationTab extends StatefulWidget {
  const PastReservationTab({Key? key}) : super(key: key);

  @override
  _PastReservationTabState createState() => _PastReservationTabState();
}

class _PastReservationTabState extends State<PastReservationTab> {
  // 컨트롤러 인스턴스
  final PastReservationController controller = PastReservationController();

  // 데이터 갱신을 위한 Future 객체 - 타입 수정
  late Future<List<DocumentSnapshot>> _reservationsFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    // 별도의 async 함수로 실행
    _loadReservationsAsync();
  }

  // 비동기 로드 메서드 (initState에서 직접 await 사용 불가)
  Future<void> _loadReservationsAsync() async {
    try {
      // 자동 완료 상태 검사 수행 (오류가 발생해도 계속 진행)
      try {
        await controller.checkAndUpdateCompletionStatus();
      } catch (e) {
        print('자동 완료 상태 검사 중 오류 (무시됨): $e');
      }

      // 상태 업데이트
      if (mounted) {
        setState(() {
          _reservationsFuture = controller.getUserCompletedReservations();
        });
      }
    } catch (e) {
      print('예약 데이터 로드 중 오류: $e');
    }
  }

  // 예약 목록 다시 로드 메서드 (refresh 버튼 등에서 호출)
  void _loadReservations() {
    setState(() {
      _reservationsFuture = controller.getUserCompletedReservations();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 현재 로그인한 사용자 확인
    final user = controller.getCurrentUser();
    if (user == null) {
      return Center(child: Text('로그인이 필요합니다.', style: TextStyle(color: Colors.grey[400]))); // 연한 회색으로 변경
    }

    // 현재 로그인한 사용자의 완료된 예약 데이터 가져오기
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _reservationsFuture,
      builder: (context, snapshot) {
        // 로딩 중 표시 - 빈 화면으로 표시
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(); // 로딩중에는 아무것도 표시하지 않음
        }

        // 오류 처리
        if (snapshot.hasError) {
          print('Firestore Error Details: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '오류가 발생했습니다.',
                  style: TextStyle(color: Colors.grey[400]), // 연한 회색으로 변경
                ),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]), // 연한 회색으로 변경
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadReservations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF237AFF), // 원래 파란색으로 복원
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        // 예약 목록 가져오기
        final reservationDocs = snapshot.data ?? [];

        // 예약 없음 처리
        if (reservationDocs.isEmpty) {
          return PastReservationEmptyState(onRefresh: _loadReservations);
        }

        // 예약 목록 표시
        return RefreshIndicator(
          onRefresh: () async {
            _loadReservations();
          },
          child: ListView.builder(
            itemCount: reservationDocs.length,
            itemBuilder: (context, index) {
              // 문서를 모델로 변환
              final reservationModel = PastReservationModel.fromDocument(reservationDocs[index]);

              // 여기서 클래스명 수정 - PastReservationInfo 사용
              return PastReservationInfo(
                reservation: reservationModel,
                currentUserId: user.uid,
                docId: reservationDocs[index].id,
                onReload: _loadReservations,
              );
            },
          ),
        );
      },
    );
  }
}