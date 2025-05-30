import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart'; // 날짜 포맷을 위한 패키지

class UserNoticeRead extends StatelessWidget {
  final String noticeId;

  UserNoticeRead({required this.noticeId});

  Future<Map<String, dynamic>?> fetchNotice() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('board').doc(noticeId).get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;

        // Firestore에서 `created_at`이 Timestamp인지, String인지 확인 후 변환
        DateTime createdAt;
        if (data['created_at'] is Timestamp) {
          createdAt = (data['created_at'] as Timestamp).toDate();
        } else if (data['created_at'] is String) {
          createdAt = DateTime.tryParse(data['created_at']) ?? DateTime.now();
        } else {
          createdAt = DateTime.now(); // 필드가 없거나 null일 경우 기본값
        }

        return {
          'title': data['title'] ?? '제목 없음',
          'content': data['content'] ?? '내용 없음',
          'createdAt': createdAt,
        };
      }
      return null;
    } catch (e) {
      print("Firestore 오류: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '공지사항',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchNotice(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('공지사항을 불러오는 중 오류가 발생했습니다.'));
          }

          final notice = snapshot.data!;
          final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(notice['createdAt']);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice['title'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  '작성일: $formattedDate',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Divider(),
                SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Html(
                      data: notice['content'], // HTML 콘텐츠 렌더링
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
