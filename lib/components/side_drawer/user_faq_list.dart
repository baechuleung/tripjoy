import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_html/flutter_html.dart'; // flutter_html 패키지 임포트

class UserFaqList extends StatefulWidget {
  @override
  _UserFaqListState createState() => _UserFaqListState();
}

class _UserFaqListState extends State<UserFaqList> {
  Future<List<Map<String, dynamic>>> fetchFaqs() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('faq')
        .where('category', isEqualTo: 'user')
        .get();

    return querySnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'title': doc['title'],
        'content': doc['content'],
        'isExpanded': false, // 확장 상태를 추가
      };
    }).toList();
  }

  late Future<List<Map<String, dynamic>>> _faqsFuture;

  @override
  void initState() {
    super.initState();
    _faqsFuture = fetchFaqs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FAQ',
          style: TextStyle(
            color: const Color(0xFF353535),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        )
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _faqsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('FAQ을 불러오는 중 오류가 발생했습니다.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('FAQ이 없습니다.'));
          }

          final faqs = snapshot.data!;

          return ListView.separated(
            itemCount: faqs.length,
            separatorBuilder: (context, index) => Divider(color: Color(0xFFD9D9D9)), // 항목 사이 구분선 추가
            itemBuilder: (context, index) {
              final faq = faqs[index];

              return Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // ExpansionTile의 구분선 제거
                child: ExpansionTile(
                  tilePadding: EdgeInsets.symmetric(horizontal: 16.0), // 좌우 패딩 설정
                  title: Text(
                    'Q. ${faq['title']}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Html(
                        data: faq['content'], // HTML 콘텐츠 렌더링
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
