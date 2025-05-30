import 'package:flutter/material.dart';
import 'package:tripjoy/term/term_service.dart';
import 'package:tripjoy/term/term_privacy.dart';
import 'package:tripjoy/term/term_third_party.dart';
import 'package:tripjoy/term/term_location.dart';
import 'package:tripjoy/term/term_marketing.dart';

class TermTotalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('약관 전체 보기'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: Text('서비스 약관'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TermServicePage()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text('개인정보 처리방침'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TermPrivacyPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text('제3자 제공 동의'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TermThirdPartyPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text('위치 정보 이용 약관'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TermLocationPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text('마케팅 정보 수신 동의'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TermMarketingPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}