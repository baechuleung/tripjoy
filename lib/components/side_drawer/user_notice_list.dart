import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_notice_read.dart';
import 'package:intl/intl.dart';

class UserNoticeList extends StatelessWidget {
  Future<List<Map<String, dynamic>>> fetchNotices() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('board')
          .get();

      List<Map<String, dynamic>> notices = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;

        return {
          'id': doc.id,
          'title': data.containsKey('title') ? data['title'] ?? '제목 없음' : '제목 없음',
          'createdAt': data['created_at'] is Timestamp
              ? (data['created_at'] as Timestamp).toDate()
              : DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
        };
      }).toList();

      // 최신순 정렬
      notices.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

      return notices;
    } catch (e) {
      print("Firestore 오류: $e");
      return [];
    }
  }

  bool isNew(DateTime createdAt) {
    final now = DateTime.now();
    return now.difference(createdAt).inHours < 24;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '공지사항',
          style: TextStyle(
            color: const Color(0xFF353535),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        )
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchNotices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('공지사항을 불러오는 중 오류가 발생했습니다.\n${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('등록된 공지사항이 없습니다.'));
          }

          final notices = snapshot.data!;

          return ListView.separated(
            itemCount: notices.length,
            separatorBuilder: (context, index) => Divider(color: Color(0xFFD9D9D9)),
            itemBuilder: (context, index) {
              final notice = notices[index];
              final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(notice['createdAt']);

              return ListTile(
                title: Row(
                  children: [
                    if (isNew(notice['createdAt']))
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Image.asset(
                          'assets/side/new.png',
                          width: 15,
                          height: 15,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        notice['title'],
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 30.0),
                  child: Text(
                    formattedDate,
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF999999),
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserNoticeRead(noticeId: notice['id']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
