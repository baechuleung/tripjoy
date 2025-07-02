import 'package:flutter/material.dart';
import 'popup_service.dart';
import 'popup_dialog.dart';

class PopupManager {
  static Future<void> checkAndShowPopups(BuildContext context) async {
    try {
      final popups = await PopupService.getActivePopups();

      if (popups.isEmpty) return;

      // 우선순위가 가장 높은 팝업 하나만 표시
      final topPriorityPopup = popups.first;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return PopupDialog(popup: topPriorityPopup);
          },
        );
      }
    } catch (e) {
      print('팝업 표시 오류: $e');
    }
  }
}