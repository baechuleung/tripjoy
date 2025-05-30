import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PremiumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final PremiumService _instance = PremiumService._internal();

  factory PremiumService() {
    return _instance;
  }

  PremiumService._internal();

  // 강제로 프리미엄 상태를 설정 (디버그용)
  bool _forcePremium = false;

  // 프리미엄 상태 강제 설정 (디버그 목적)
  void setForcePremium(bool value) {
    _forcePremium = value;
    debugPrint('💰 프리미엄 상태 강제 설정: $_forcePremium');
  }

  // Cache the premium status to avoid frequent Firestore reads
  bool? _isPremium;
  DateTime? _premiumExpiration;
  DateTime? _lastCheckTime;

  // Check if current user is premium - 불리언 타입 처리 추가
  Future<bool> isPremium() async {
    // 강제 설정이 있으면 그대로 반환
    if (_forcePremium) {
      debugPrint('💰 강제 설정된 프리미엄 상태 반환: $_forcePremium');
      return true;
    }

    // 캐시 무효화 - 항상 최신 상태 확인
    _lastCheckTime = null;
    _isPremium = null;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('👤 No logged in user');
        _isPremium = false;
        _lastCheckTime = DateTime.now();
        return false;
      }

      // 디버깅을 위한 로그 추가
      debugPrint('🔍 Checking premium status for user: ${currentUser.uid}');

      // 1. 먼저 'users' 컬렉션 확인
      var userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      // 2. 'users'에 없으면 'tripfriends_users' 컬렉션 확인
      if (!userDoc.exists) {
        debugPrint('👤 Document not found in "users" collection, checking "tripfriends_users"');
        userDoc = await _firestore
            .collection('tripfriends_users')
            .doc(currentUser.uid)
            .get();
      }

      if (!userDoc.exists || userDoc.data() == null) {
        debugPrint('👤 User document does not exist in any collection');
        _isPremium = false;
        _lastCheckTime = DateTime.now();
        return false;
      }

      final userData = userDoc.data()!;

      // 모든 필드 로깅 (디버깅 목적)
      debugPrint('📄 User document data: ${userData.toString()}');

      // 3. 다양한 가능한 프리미엄 필드 이름 확인 및 불리언 타입 처리 개선
      _isPremium = false; // 기본값

      // is_premium 필드 처리 (불리언 타입 변환 처리)
      if (userData.containsKey('is_premium')) {
        var value = userData['is_premium'];
        debugPrint('💰 Found is_premium field with value: $value (${value.runtimeType})');

        // 다양한 타입 처리
        if (value is bool) {
          _isPremium = value;
        } else if (value is String) {
          _isPremium = value.toLowerCase() == 'true';
        } else if (value is int) {
          _isPremium = value == 1;
        } else if (value is num) {
          _isPremium = value > 0;
        }

        debugPrint('💰 is_premium converted to: $_isPremium');
      }
      // isPremium 필드 처리
      else if (userData.containsKey('isPremium')) {
        var value = userData['isPremium'];
        debugPrint('💰 Found isPremium field with value: $value (${value.runtimeType})');

        if (value is bool) {
          _isPremium = value;
        } else if (value is String) {
          _isPremium = value.toLowerCase() == 'true';
        } else if (value is int) {
          _isPremium = value == 1;
        } else if (value is num) {
          _isPremium = value > 0;
        }

        debugPrint('💰 isPremium converted to: $_isPremium');
      }
      // premium 필드 처리
      else if (userData.containsKey('premium')) {
        var value = userData['premium'];
        debugPrint('💰 Found premium field with value: $value (${value.runtimeType})');

        if (value is bool) {
          _isPremium = value;
        } else if (value is String) {
          _isPremium = value.toLowerCase() == 'true';
        } else if (value is int) {
          _isPremium = value == 1;
        } else if (value is num) {
          _isPremium = value > 0;
        }

        debugPrint('💰 premium converted to: $_isPremium');
      }
      else {
        debugPrint('💰 No premium field found, using default: false');
      }

      // 4. 프리미엄 만료일 필드 확인 (여러 가능한 이름 확인)
      var expirationField = userData['premium_expiration'] ??
          userData['premiumExpiration'] ??
          userData['premium_expires'] ??
          userData['premiumExpires'];

      // 만료일 처리
      if (_isPremium == true && expirationField != null) {
        debugPrint('💰 Found expiration field: $expirationField (${expirationField.runtimeType})');

        // 다양한 형식 처리
        if (expirationField is Timestamp) {
          _premiumExpiration = expirationField.toDate();
        } else if (expirationField is String) {
          try {
            _premiumExpiration = DateTime.parse(expirationField);
          } catch (e) {
            debugPrint('❌ Failed to parse expiration date: $e');
          }
        } else {
          debugPrint('❌ Unknown expiration date format: ${expirationField.runtimeType}');
        }

        // 만료일 확인
        if (_premiumExpiration != null) {
          final now = DateTime.now();
          if (_premiumExpiration!.isBefore(now)) {
            debugPrint('💰 Premium expired on ${_premiumExpiration!.toIso8601String()}');
            _isPremium = false;
          } else {
            debugPrint('💰 Premium active until ${_premiumExpiration!.toIso8601String()}');
          }
        }
      }

      // 현재 상태 디버그 출력
      final bool finalStatus = _isPremium ?? false;
      debugPrint('👑 Final premium status: $finalStatus');

      _lastCheckTime = DateTime.now();
      return finalStatus;

    } catch (e) {
      debugPrint('❌ Error checking premium status: $e');
      _isPremium = false;
      _lastCheckTime = DateTime.now();
      return false;
    }
  }

  // Get premium expiration date (returns null if not premium)
  Future<DateTime?> getPremiumExpiration() async {
    await isPremium(); // Make sure we have up-to-date data
    return _premiumExpiration;
  }
}