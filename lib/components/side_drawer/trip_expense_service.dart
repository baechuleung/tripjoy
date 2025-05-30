import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  Future<int> calculateTotalExpense() async {
    if (userId == null) return 0;

    int totalExpense = 0;

    try {
      // trip_mate 배열에 현재 userId가 포함된 문서만 가져오도록 수정
      QuerySnapshot tripPlansSnapshot = await _firestore
          .collection('trip_plans')
          .where('trip_mate', arrayContains: userId)
          .get();

      print('Found ${tripPlansSnapshot.docs.length} trip plans for user $userId');

      for (var tripDoc in tripPlansSnapshot.docs) {
        print('Processing trip plan: ${tripDoc.id}');

        QuerySnapshot daysSnapshot = await tripDoc.reference
            .collection('days')
            .get();

        for (var dayDoc in daysSnapshot.docs) {
          List<dynamic> items = dayDoc.data().toString().contains('items')
              ? (dayDoc.data() as Map<String, dynamic>)['items'] ?? []
              : [];

          for (var item in items) {
            if (item is Map<String, dynamic> &&
                item.containsKey('price') &&
                item['price'] is Map<String, dynamic>) {

              var amount = item['price']['krwAmount'];
              if (amount != null) {
                if (amount is double) {
                  totalExpense += amount.toInt();
                  print('Added double amount: ${amount.toInt()}');
                } else if (amount is int) {
                  totalExpense += amount;
                  print('Added int amount: $amount');
                }
                print('Current total: $totalExpense');
              }
            }
          }
        }
      }

      print('Final total expense: $totalExpense');
      return totalExpense;
    } catch (e) {
      print('Error calculating total expense: $e');
      return 0;
    }
  }
}