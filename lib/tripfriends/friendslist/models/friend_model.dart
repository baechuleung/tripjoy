// lib/tripfriends/friendslist/models/friend_model.dart
import 'package:flutter/foundation.dart';

class FriendModel {
  final String id;
  final String uid;
  final String name;
  final String? profileImageUrl;
  final Map<String, dynamic> birthDate;
  final String gender;
  final List<String> languages;
  final Map<String, dynamic> location;
  final double averageRating;
  final int matchCount;
  final bool isActive;
  final bool isApproved;
  final String? currencySymbol;

  FriendModel({
    required this.id,
    required this.uid,
    required this.name,
    this.profileImageUrl,
    required this.birthDate,
    required this.gender,
    required this.languages,
    required this.location,
    required this.averageRating,
    required this.matchCount,
    required this.isActive,
    required this.isApproved,
    this.currencySymbol,
  });

  factory FriendModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return FriendModel(
      id: docId ?? map['id'] ?? map['uid'] ?? '',
      uid: map['uid'] ?? '',
      name: map['name'] ?? '이름 없음',
      profileImageUrl: map['profileImageUrl'],
      birthDate: map['birthDate'] ?? {'year': 0, 'month': 0, 'day': 0},
      gender: map['gender'] ?? '',
      languages: List<String>.from(map['languages'] ?? []),
      location: Map<String, dynamic>.from(map['location'] ?? {}),
      averageRating: _parseDouble(map['average_rating']),
      matchCount: map['match_count'] ?? 0,
      isActive: map['isActive'] ?? false,
      isApproved: map['isApproved'] ?? false,
      currencySymbol: map['currencySymbol'] ?? '\$',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'birthDate': birthDate,
      'gender': gender,
      'languages': languages,
      'location': location,
      'average_rating': averageRating,
      'match_count': matchCount,
      'isActive': isActive,
      'isApproved': isApproved,
      'currencySymbol': currencySymbol,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}