import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'popup_model.dart';

class PopupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> _isPopupDismissed(String popupId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'popup_do_not_show_$popupId';
    return prefs.getBool(key) ?? false;
  }

  static Future<List<PopupModel>> getActivePopups() async {
    try {
      print('📱 [PopupService] 팝업 조회 시작...');

      final querySnapshot = await _firestore
          .collection('popups')
          .where('isActive', isEqualTo: true)
          .get();

      print('📱 [PopupService] Firestore에서 활성 팝업 ${querySnapshot.docs.length}개 조회됨');

      // 각 팝업의 상세 정보 출력
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('📱 [PopupService] 팝업 ID: ${doc.id}');
        print('   - 제목: ${data['title']}');
        print('   - 활성화: ${data['isActive']}');
        print('   - 우선순위: ${data['priority']}');
      }

      final List<PopupModel> validPopups = [];

      for (var doc in querySnapshot.docs) {
        final popup = PopupModel.fromFirestore(doc);

        // 유효기간 체크
        final isValid = popup.isValidPeriod();
        print('📱 [PopupService] 팝업 "${popup.title}" 유효기간 체크:');
        print('   - 시작일: ${popup.startDate}');
        print('   - 종료일: ${popup.endDate}');
        print('   - 현재시간: ${DateTime.now()}');
        print('   - 유효여부: $isValid');

        if (isValid) {
          // 다시 보지 않기 체크
          final isDismissed = await _isPopupDismissed(popup.id);
          print('📱 [PopupService] 팝업 "${popup.title}" 다시 보지 않기 여부: $isDismissed');

          if (!isDismissed) {
            validPopups.add(popup);
          }
        }
      }

      // 우선순위로 정렬
      validPopups.sort((a, b) => b.priority.compareTo(a.priority));

      print('📱 [PopupService] 최종 유효한 팝업 ${validPopups.length}개');

      return validPopups;
    } catch (e) {
      print('❌ [PopupService] 팝업 조회 오류: $e');
      print('❌ [PopupService] 스택 트레이스: ${StackTrace.current}');
      return [];
    }
  }
}