// lib/tripfriends/friendslist/services/friends_request_handler.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/friends_list_controller.dart';
import '../filter/friends_filter_service.dart';

/// 친구 요청 관련 처리를 담당하는 클래스
class FriendsRequestHandler {
  /// 빈 목록 메시지 표시
  static Widget buildEmptyListMessage(FriendsListController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Text(
          controller.isTranslationsLoaded
              ? controller.translationService.getTranslatedText('현재 추천할 프렌즈가 없습니다')
              : '현재 추천할 프렌즈가 없습니다',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  /// plan_request 정보 파싱
  static PlanRequestResult getPlanRequestInfo(
      AsyncSnapshot<QuerySnapshot> snapshot,
      FriendsFilterService filterService) {

    Map<String, dynamic>? requestLocation;
    String requestDocId = '';

    if (snapshot.hasData && snapshot.data != null &&
        snapshot.data!.docs.isNotEmpty) {
      final requestDoc = snapshot.data!.docs.first;

      // 문서 ID 추출
      requestDocId = requestDoc.id;

      final requestData = requestDoc.data() as Map<String, dynamic>;
      if (requestData['location'] is Map) {
        requestLocation = Map<String, dynamic>.from(requestData['location'] as Map);

        // 필터 서비스에 위치 정보 설정
        filterService.setLocationFilter(
            requestLocation["city"] as String?,
            requestLocation["nationality"] as String?
        );
      }
    } else {
      return PlanRequestResult(
        errorWidget: Center(child: Text('여행 요청 정보가 없습니다.')),
      );
    }

    // 위치 정보가 없는 경우
    if (requestLocation == null ||
        !requestLocation.containsKey('city') ||
        !requestLocation.containsKey('nationality')) {
      return PlanRequestResult(
        errorWidget: Center(child: Text('여행 요청의 위치 정보가 없습니다.')),
      );
    }

    // 도시와 국가 값 추출
    final String? requestCity = requestLocation['city'] as String?;
    final String? requestNationality = requestLocation['nationality'] as String?;

    if (requestCity == null || requestNationality == null) {
      return PlanRequestResult(
        errorWidget: Center(child: Text('여행 요청의 위치 정보가 불완전합니다.')),
      );
    }

    // 정상 정보 반환
    return PlanRequestResult(
        location: requestLocation,
        docId: requestDocId,
        city: requestCity,
        nationality: requestNationality
    );
  }
}

/// Plan Request 정보를 담는 결과 클래스
class PlanRequestResult {
  final Map<String, dynamic>? location;
  final String? docId;
  final String? city;
  final String? nationality;
  final Widget? errorWidget;

  PlanRequestResult({
    this.location,
    this.docId,
    this.city,
    this.nationality,
    this.errorWidget
  });
}