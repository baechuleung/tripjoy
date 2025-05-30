import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPreferencesUtil {
  /// 🔑 **문자열 저장**
  static Future<void> setString(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// 🔑 **문자열 가져오기**
  static Future<String?> getString(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// 🔑 **특정 키 제거**
  static Future<void> remove(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    print('✅ SharedPreferences에서 $key 제거됨');
  }

  /// 🔑 **FCM 토큰 저장**
  static Future<void> setFCMToken(String token) async {
    await setString('fcm_token', token);
    print('✅ FCM 토큰 저장됨: $token');
  }

  /// 🔑 **FCM 토큰 가져오기**
  static Future<String?> getFCMToken() async {
    return await getString('fcm_token');
  }

  /// 🔑 **FCM 토큰 제거**
  static Future<void> removeFCMToken() async {
    await remove('fcm_token');
  }

  /// 🔑 **Firestore 사용자 문서 저장**
  static Future<void> saveUserDocument(Map<String, dynamic> userDoc) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(userDoc);
    await prefs.setString('userDocument', jsonString);
    await setLoggedIn(true);
    print('✅ 사용자 문서 저장됨: $jsonString');
  }

  /// 🔑 **저장된 사용자 문서 가져오기**
  static Future<Map<String, dynamic>?> getUserDocument() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('userDocument');
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        print('❌ 사용자 문서 디코딩 실패: $e');
        return null;
      }
    }
    return null;
  }

  /// 🔑 **특정 필드 동적으로 가져오기**
  static Future<dynamic> getField(String key) async {
    Map<String, dynamic>? userDoc = await getUserDocument();
    if (userDoc != null && userDoc.containsKey(key)) {
      return userDoc[key];
    }
    print('❌ 사용자 문서에 $key 필드가 없습니다.');
    return null;
  }

  /// 🔑 **사용자 문서 삭제**
  static Future<void> clearUserDocument() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userDocument');
    await prefs.setBool('isLoggedIn', false);
    await removeFCMToken(); // FCM 토큰도 함께 제거
    print('✅ 사용자 문서 및 로그인 상태 초기화됨');
  }

  /// 🔑 **로그인 상태 확인**
  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? loggedIn = prefs.getBool('isLoggedIn');
    print('🔍 SharedPreferences 로그인 상태 확인: $loggedIn');
    return loggedIn ?? false;
  }

  /// 🔑 **로그인 상태 설정**
  static Future<void> setLoggedIn(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', status);
    print('✅ SharedPreferences 로그인 상태 저장됨: $status');
  }

  /// 🔑 **모든 데이터 초기화**
  static Future<void> clearAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('✅ 모든 SharedPreferences 데이터 초기화됨');
  }

  /// 🔑 **모든 키 가져오기**
  static Future<Set<String>> getAllKeys() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getKeys();
  }

  /// 🔑 **모든 데이터 출력 (디버깅 용도)**
  static Future<void> printAllData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Set<String> keys = prefs.getKeys();
    print('🔍 **저장된 데이터 목록:**');
    for (String key in keys) {
      print('$key: ${prefs.get(key)}');
    }
  }
}