import 'package:cloud_firestore/cloud_firestore.dart';

class PopupModel {
  final String id;
  final String title;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int priority;
  final DateTime createdAt;

  PopupModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.priority,
    required this.createdAt,
  });

  factory PopupModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PopupModel(
      id: doc.id,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? false,
      priority: data['priority'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  bool isValidPeriod() {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate) && isActive;
  }
}