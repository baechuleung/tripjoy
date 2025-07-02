import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../invite_service.dart';
import '../../user_notice_list.dart';
import '../../user_faq_list.dart';
import '../../complaint/complaint.dart';
import 'menu_item.dart';

class DrawerMenuSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 메뉴 리스트
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MenuItem(
                title: '친구초대',
                onTap: () => InviteService.inviteFriends(),
              ),
              _buildDivider(),
              MenuItem(
                title: '공지사항',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => UserNoticeList()),
                ),
              ),
              _buildDivider(),
              MenuItem(
                title: 'FAQ',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => UserFaqList()),
                ),
              ),
              _buildDivider(),
              MenuItem(
                title: '이용불편사항신고',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ComplaintPage()),
                ),
              ),
              _buildDivider(),
              MenuItem(
                title: '고객센터',
                onTap: () async {
                  final Uri url = Uri.parse('http://pf.kakao.com/_Klbrn');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 15),
        SizedBox(height: 5, child: Container(color: Color(0xFFF9F9F9))),
      ],
    );
  }

  Widget _buildDivider() {
    return Column(
      children: [
        SizedBox(height: 15),
        Divider(color: Color(0xFFF1F1F1)),
        SizedBox(height: 15),
      ],
    );
  }
}