import 'package:cloud_firestore/cloud_firestore.dart';

/// 지난 예약 정보를 나타내는 모델 클래스
class PastReservationModel {
  final String id;
  final String parentId;
  final DateTime scheduledDateTime;
  final String reservationNumber;
  final int personCount;
  final String startTime;
  final String endTime;
  final int useDuration;
  final String detailRequest;
  final String status;
  final DateTime? completedAt;
  final Map<String, dynamic> originalData;

  PastReservationModel({
    required this.id,
    required this.parentId,
    required this.scheduledDateTime,
    required this.reservationNumber,
    required this.personCount,
    required this.startTime,
    required this.endTime,
    required this.useDuration,
    required this.detailRequest,
    required this.status,
    this.completedAt,
    required this.originalData,
  });

  /// Firestore 문서에서 모델 객체 생성
  factory PastReservationModel.fromDocument(DocumentSnapshot doc) {
    final reservation = doc.data() as Map<String, dynamic>;
    final parentId = extractParentIdFromPath(doc.reference.path);

    // 날짜 추출
    final scheduledDateTime = getDateFromReservation(reservation);

    // 완료 시간 추출
    final completedAt = reservation['completedAt'] as Timestamp?;
    final completedDateTime = completedAt?.toDate();

    // 기본 정보 추출
    final useTime = reservation['useTime'] as String? ?? '';
    final personCount = reservation['personCount'] ?? 0;
    final reservationNumber = reservation['reservationNumber'] ?? '';
    final detailRequest = reservation['detailRequest'] as String? ?? '';

    // 상태 정보
    final status = reservation['status'] as String? ?? 'pending';

    // 이용 시간 계산
    final useDuration = reservation['useDuration'] as int? ?? 1;
    final timeRange = calculateTimeRange(useTime, useDuration, scheduledDateTime);

    return PastReservationModel(
      id: doc.id,
      parentId: parentId,
      scheduledDateTime: scheduledDateTime,
      reservationNumber: reservationNumber,
      personCount: personCount,
      startTime: timeRange['startTime'] ?? '',
      endTime: timeRange['endTime'] ?? '',
      useDuration: useDuration,
      detailRequest: detailRequest,
      status: status,
      completedAt: completedDateTime,
      originalData: reservation,
    );
  }

  /// 날짜 필드 추출 헬퍼 메서드
  static DateTime getDateFromReservation(Map<String, dynamic> data) {
    // 여러 가능한 날짜 필드 시도
    if (data['scheduledDate'] is Timestamp) {
      return (data['scheduledDate'] as Timestamp).toDate();
    }
    else if (data['scheduledAt'] is Timestamp) {
      return (data['scheduledAt'] as Timestamp).toDate();
    }
    else if (data['useDate'] is String) {
      try {
        return DateTime.parse(data['useDate'] as String);
      } catch (e) {
        return DateTime.now();
      }
    }
    // 기본값
    return DateTime.now();
  }

  /// 시간 정보 계산
  static Map<String, String> calculateTimeRange(String useTime, int useDuration, DateTime scheduledDateTime) {
    String startTime = useTime;
    String endTime = '';

    if (useTime.isNotEmpty) {
      try {
        final timeParts = useTime.split(':');
        if (timeParts.length == 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);

          final startDateTime = DateTime(
            scheduledDateTime.year,
            scheduledDateTime.month,
            scheduledDateTime.day,
            hour,
            minute,
          );

          final endDateTime = startDateTime.add(Duration(hours: useDuration));
          endTime = '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
        }
      } catch (e) {
        print('시간 변환 오류: $e');
      }
    }

    return {
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  /// 문서 경로에서 사용자 ID 추출
  static String extractParentIdFromPath(String path) {
    final pathParts = path.split('/');
    return pathParts.length >= 3 ? pathParts[1] : 'unknown';
  }
}