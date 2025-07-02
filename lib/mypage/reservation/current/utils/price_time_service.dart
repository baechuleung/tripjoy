// lib/components/side_drawer/mypage/reservation/current/utils/price_time_service.dart

class PriceTimeService {
  // 도시 코드에 따른 시간대 오프셋 가져오기 (UTC 기준)
  static int getTimezoneOffset(String cityCode) {
    // 베트남 도시들 (UTC+7)
    if ([
      'DNN', // 다낭
      'NPT', // 나트랑
      'DAD', // 달랏
      'PQC', // 푸꾸옥
      'HAN', // 하노이
      'HLB', // 하룽베이
      'HCM', // 호치민
      'MNE', // 무이네
      'SPA', // 사파
      'HPH', // 하이퐁
    ].contains(cityCode)) {
      return 7; // UTC+7
    }

    // 홍콩, 타이완, 마카오, 중국 (UTC+8)
    else if ([
      'HKG', // 홍콩
      'TPE', // 타이페이
    ].contains(cityCode)) {
      return 8; // UTC+8
    }

    // 한국, 일본 (UTC+9)
    else if ([
      'SEL', // 서울
      'TYO', // 도쿄
    ].contains(cityCode)) {
      return 9; // UTC+9
    }

    // 태국, 캄보디아 (UTC+7)
    else if ([
      'BKK', // 방콕
      'REP', // 시엠립
    ].contains(cityCode)) {
      return 7; // UTC+7
    }

    // 알 수 없는 도시 코드는 오류가 생길 수 있음을 알려주는 로그 출력
    print('알 수 없는 도시 코드: $cityCode - 시간대 계산에 오류가 있을 수 있습니다');
    throw Exception('알 수 없는 도시 코드: $cityCode');
  }

  // 도시 코드 가져오기 - reservation data에서 location 맵의 city 정보 사용
  static String getCityCodeFromReservation(Map<String, dynamic> reservationData) {
    try {
      // location 맵에서 city 필드 값 가져오기
      if (reservationData.containsKey('location') &&
          reservationData['location'] is Map &&
          (reservationData['location'] as Map).containsKey('city')) {

        String city = reservationData['location']['city'];
        print('가져온 도시 정보: $city');
        return city; // 있는 그대로 반환
      }

      throw Exception('location 맵에서 city 필드를 찾을 수 없음');
    } catch (e) {
      print('도시 코드 추출 오류: $e');
      throw Exception('도시 코드 추출 오류: $e');
    }
  }

  // 실시간 요금 및 이용 시간을 계산하는 메서드
  static Map<String, dynamic> calculateRealTimePrice({
    required String status,
    required int pricePerHour,
    required String useDate,
    required String startTime,
    required Map<String, dynamic> reservationData,  // 전체 reservation 데이터 전달
  }) {
    // 결과를 저장할 맵
    Map<String, dynamic> result = {
      'totalPrice': 0,
      'usedTime': '0분', // 기본값
    };

    try {
      // 예약 데이터에서 도시 코드 가져오기 - 없으면 예외 발생
      String cityCode = getCityCodeFromReservation(reservationData);
      print('실시간 요금 계산에 사용되는 도시 코드: $cityCode');

      // pending 상태인 경우: 기본 요금과 0분 이용 시간
      if (status == 'pending') {
        result['totalPrice'] = pricePerHour;
        result['usedTime'] = '0분';
        return result;
      }

      // in_progress 상태인 경우: 시간 계산 필요
      if (status == 'in_progress') {
        try {
          // 날짜 형식 변환 (한국어 형식인 경우)
          String convertedUseDate = useDate;
          if (useDate.contains('년')) {
            convertedUseDate = _convertKoreanDateFormat(useDate);
            print('변환된 날짜: $convertedUseDate');
          }

          // 시간 형식 변환 (AM/PM 또는 오전/오후 형식인 경우)
          String convertedStartTime = startTime;
          if (startTime.contains('PM') || startTime.contains('AM') ||
              startTime.contains('오전') || startTime.contains('오후')) {
            convertedStartTime = _convertTimeFormat(startTime);
            print('변환된 시간: $convertedStartTime');
          }

          DateTime startDateTime = _parseDateTime(convertedUseDate, convertedStartTime);
          print('파싱된 예약 시작 시간: $startDateTime');

          // 현재 시간을 도시 시간으로 변환
          final DateTime cityNow = _getCityCurrentTime(cityCode);
          print('도시 현재 시간: $cityNow');

          // 사용 시간 계산 (분 단위)
          final usedMinutes = cityNow.difference(startDateTime).inMinutes;
          print('사용 시간(분): $usedMinutes');

          // 음수 시간 처리 (아직 예약 시간이 되지 않은 경우)
          if (usedMinutes <= 0) {
            result['totalPrice'] = pricePerHour;
            result['usedTime'] = '0분';
            return result;
          }

          // 사용 시간 및 요금 계산
          final hours = usedMinutes ~/ 60; // 온전한 시간
          final remainingMinutes = usedMinutes % 60; // 남은 분

          // 요금 계산
          int totalPrice = 0;

          if (hours < 1) {
            // 1시간 미만: 기본 시간당 요금 적용
            totalPrice = pricePerHour;
          } else {
            // 1시간 이상: 기본 시간당 요금 + 추가 시간 요금
            totalPrice = pricePerHour; // 첫 1시간

            // 1시간 이후 추가 분에 대한 요금 (10분 단위로 계산)
            int additionalMinutes = (hours - 1) * 60 + remainingMinutes;
            int tenMinuteBlocks = (additionalMinutes / 10).ceil(); // 10분 블록 수 (올림)
            totalPrice += (pricePerHour ~/ 6) * tenMinuteBlocks;
          }

          // 사용 시간 문자열 형식으로 변환
          String usedTimeStr = '';
          if (hours > 0) {
            usedTimeStr = '${hours}시간 ';
          }
          usedTimeStr += '${remainingMinutes}분';

          result['totalPrice'] = totalPrice;
          result['usedTime'] = usedTimeStr;
          return result;
        } catch (e) {
          print('실시간 요금 계산 중 오류: $e');
          throw Exception('실시간 요금 계산 중 오류: $e');
        }
      }

      return result;
    } catch (e) {
      print('실시간 요금 계산 오류: $e');
      // 오류 발생 시 기본 요금 설정하고 오류 메시지 추가
      result['totalPrice'] = pricePerHour;
      result['usedTime'] = '오류: $e';
      return result;
    }
  }

  // 한국어 날짜 문자열 변환 (예: "2025년 5월 17일" -> "2025-05-17")
  static String _convertKoreanDateFormat(String koreanDate) {
    try {
      print('한국어 날짜 변환 시도: "$koreanDate"');

      // 숫자만 추출
      final RegExp numRegex = RegExp(r'\d+');
      final matches = numRegex.allMatches(koreanDate).toList();

      if (matches.length >= 3) {
        final year = matches[0].group(0)!;
        final month = matches[1].group(0)!.padLeft(2, '0');
        final day = matches[2].group(0)!.padLeft(2, '0');

        final result = '$year-$month-$day';
        print('한국어 날짜 변환 결과: $result');
        return result;
      }

      print('한국어 날짜 변환 실패: $koreanDate');
      return koreanDate; // 변환 실패 시 원본 반환
    } catch (e) {
      print('한국어 날짜 변환 오류: $e');
      return koreanDate; // 오류 시 원본 반환
    }
  }

  // 시간 형식 변환 (예: "오후 9:30" -> "21:30")
  static String _convertTimeFormat(String timeStr) {
    try {
      print('시간 형식 변환 시도: "$timeStr"');

      // 오전/오후 확인
      bool isPM = timeStr.contains('오후') || timeStr.contains('PM');

      // 숫자와 콜론만 남기기 위한 정제
      String cleanTime = timeStr
          .replaceAll('오전', '')
          .replaceAll('오후', '')
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim();

      print('정제된 시간 문자열: "$cleanTime"');

      // 시간:분 구분
      if (cleanTime.contains(':')) {
        List<String> parts = cleanTime.split(':');
        if (parts.length >= 2) {
          // 불필요한 문자 제거
          String hourStr = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
          String minuteStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');

          print('추출된 시: "$hourStr", 분: "$minuteStr"');

          int hour = int.parse(hourStr);
          int minute = int.parse(minuteStr);

          // 오후인 경우 12시간 더하기 (12시는 제외)
          if (isPM && hour < 12) {
            hour += 12;
          }
          // 오전 12시는 0시로 변환
          else if (!isPM && hour == 12) {
            hour = 0;
          }

          final result = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          print('시간 변환 결과: $result');
          return result;
        }
      }

      print('시간 변환 실패: $timeStr');
      return timeStr; // 변환 실패 시 원본 반환
    } catch (e) {
      print('시간 변환 오류: $e');
      return timeStr; // 오류 시 원본 반환
    }
  }

  // 날짜와 시간 문자열을 파싱하여 DateTime 객체로 변환하는 메서드
  static DateTime _parseDateTime(String dateStr, String timeStr) {
    try {
      print('DateTime 파싱 시도: 날짜="$dateStr", 시간="$timeStr"');

      // 날짜 파싱 (YYYY-MM-DD 형식 가정)
      List<String> dateParts = dateStr.split('-');
      if (dateParts.length != 3) {
        throw FormatException('날짜 형식이 YYYY-MM-DD 형식이 아닙니다: $dateStr');
      }

      int year = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int day = int.parse(dateParts[2]);

      // 시간 파싱 (HH:MM 형식 가정)
      List<String> timeParts = timeStr.split(':');
      if (timeParts.length < 2) {
        throw FormatException('시간 형식이 HH:MM 형식이 아닙니다: $timeStr');
      }

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      // DateTime 객체 생성
      DateTime result = DateTime(year, month, day, hour, minute);
      print('파싱된 DateTime: $result');
      return result;
    } catch (e) {
      print('DateTime 파싱 오류: $e');
      return DateTime.now(); // 오류 시 현재 시간 반환
    }
  }

  // 현재 로컬 시간을 해당 도시 시간으로 변환
  static DateTime _getCityCurrentTime(String cityCode) {
    try {
      // 1. 기기의 로컬 시간대 오프셋 구하기
      final localNow = DateTime.now();
      final localOffset = localNow.timeZoneOffset.inHours;
      print('로컬 시간대 오프셋: $localOffset 시간');

      // 2. 도시의 시간대 오프셋 구하기
      final cityOffset = getTimezoneOffset(cityCode);
      print('도시($cityCode) 시간대 오프셋: $cityOffset 시간');

      // 3. 로컬 시간을 UTC로 변환 후 도시 시간으로 변환
      final utcTime = localNow.subtract(Duration(hours: localOffset));
      print('UTC 시간: $utcTime');

      final cityNow = utcTime.add(Duration(hours: cityOffset));
      print('도시 현재 시간: $cityNow');

      return cityNow;
    } catch (e) {
      print('도시 시간 변환 오류: $e');
      // 오류 시 현재 시간 반환
      return DateTime.now();
    }
  }

  // 예약 시간과 해당 도시 현지 시간 사이의 차이 계산 - 도시 시간 기준
  static String calculateTimeRemaining(String useDate, String startTime, Map<String, dynamic> reservationData) {
    try {
      print('calculateTimeRemaining 호출: 날짜="$useDate", 시간="$startTime"');

      // 날짜 형식 변환 (한국어 형식인 경우)
      String convertedUseDate = useDate;
      if (useDate.contains('년')) {
        convertedUseDate = _convertKoreanDateFormat(useDate);
        print('변환된 날짜: $convertedUseDate');
      }

      // 시간 형식 변환 (AM/PM 또는 오전/오후 형식인 경우)
      String convertedStartTime = startTime;
      if (startTime.contains('PM') || startTime.contains('AM') ||
          startTime.contains('오전') || startTime.contains('오후')) {
        convertedStartTime = _convertTimeFormat(startTime);
        print('변환된 시간: $convertedStartTime');
      }

      // 예약 데이터에서 도시 코드 가져오기
      String cityCode = getCityCodeFromReservation(reservationData);
      print('시간 차이 계산에 사용되는 도시 코드: $cityCode');

      // 날짜와 시간 문자열을 파싱하여 DateTime 객체로 변환
      DateTime reservationDateTime = _parseDateTime(convertedUseDate, convertedStartTime);
      print('예약 시간: $reservationDateTime');

      // 현재 도시 시간 가져오기
      DateTime cityNow = _getCityCurrentTime(cityCode);
      print('도시 현재 시간: $cityNow');

      // 시간 차이 계산 (분 단위)
      final differenceMinutes = reservationDateTime.difference(cityNow).inMinutes;
      print('시간 차이(분): $differenceMinutes');

      // 결과 생성
      if (differenceMinutes < 0) {
        // 음수는 이미 시간이 지난 경우 (경과)
        final Duration elapsed = Duration(minutes: -differenceMinutes);
        print('경과 시간으로 변환된 차이: ${_formatDuration(elapsed)} 경과');
        return '${_formatDuration(elapsed)} 경과';
      } else {
        // 양수는 아직 시간이 남은 경우 (남음)
        final Duration remaining = Duration(minutes: differenceMinutes);
        print('잔여 시간으로 변환된 차이: ${_formatDuration(remaining)} 남음');
        return '${_formatDuration(remaining)} 남음';
      }
    } catch (e) {
      print('시간 차이 계산 오류: $e');
      print('오류 발생 경로 추적: ${e.toString() + StackTrace.current.toString()}');
      // 오류 발생 시 기본값 반환
      return '시간 계산 오류';
    }
  }

  // 시간 간격 포맷팅 - 항상 분까지 표시
  static String _formatDuration(Duration duration) {
    final int days = duration.inDays;
    final int hours = duration.inHours % 24;
    final int minutes = duration.inMinutes % 60;

    print('포맷팅할 시간: $days일 $hours시간 $minutes분');

    if (days > 0) {
      return '$days일 $hours시간 $minutes분';
    } else if (hours > 0) {
      return '$hours시간 $minutes분';
    } else {
      return '$minutes분';
    }
  }
}