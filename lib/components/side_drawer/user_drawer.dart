import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:async';
import 'user_notice_list.dart';
import 'invite_service.dart';
import 'logout_handler.dart';
import 'complaint/complaint.dart';
import 'profile_update.dart';
import 'user_faq_list.dart';
import 'setting/setting.dart';
import 'mypage/review/review_page.dart';
import 'mypage/reservation/reservation_page.dart';
import 'customer/customer_service_page.dart';

class UserDrawer extends StatefulWidget {
  @override
  _UserDrawerState createState() => _UserDrawerState();
}

class _UserDrawerState extends State<UserDrawer> {
  String? _photoUrl;
  String? _nickname;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  bool _isImageLoading = true;
  ImageProvider? _avatarImage;

  final List<String> defaultAvatars = [
    'https://robohash.org/trip1.png?size=150x150&set=set4',
    'https://robohash.org/trip2.png?size=150x150&set=set4',
    'https://robohash.org/trip3.png?size=150x150&set=set4',
    'https://robohash.org/trip4.png?size=150x150&set=set4',
    'https://robohash.org/trip5.png?size=150x150&set=set4'
  ];

  String getRandomDefaultAvatar() {
    final random = Random();
    return defaultAvatars[random.nextInt(defaultAvatars.length)];
  }

  @override
  void initState() {
    super.initState();
    _initializeUserDataStream();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _initializeUserDataStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((docSnapshot) {
        if (docSnapshot.exists) {
          setState(() {
            _nickname = docSnapshot.data()?['name'] ?? '여행하는길동이 님';
            _photoUrl = docSnapshot.data()?['photoUrl'];
            if (_photoUrl == null || _photoUrl!.isEmpty) {
              _photoUrl = getRandomDefaultAvatar();
            }
            _loadImage();
          });
        }
      });
    }
  }

// 이미지를 미리 로드하는 함수
  void _loadImage() {
    if (!mounted) return;

    setState(() {
      _isImageLoading = true;
    });

    final image = NetworkImage(_photoUrl ?? getRandomDefaultAvatar());

    // 이미지 프리캐싱 처리
    precacheImage(image, context).then((_) {
      if (mounted) {
        setState(() {
          _avatarImage = image;
          _isImageLoading = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          // 오류가 발생하면 기본 이미지 표시 상태로 전환
          _avatarImage = null;
          _isImageLoading = false;
        });
      }
    });
  }

  Future<void> _refreshUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _nickname = doc.data()?['name'] ?? '여행하는길동이 님';
          _photoUrl = doc.data()?['photoUrl'];
          if (_photoUrl == null || _photoUrl!.isEmpty) {
            _photoUrl = getRandomDefaultAvatar();
          }
          _loadImage();
        });
      }
    }
  }

  Future<void> _showProfileUpdateDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ProfileUpdateDialog(
        onProfileUpdated: () async {
          await _refreshUserData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.80,
      height: MediaQuery.of(context).size.height,
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 8.0, left: 10.0, right: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close, size: 23, color: Colors.black),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        IconButton(
                          icon: Image.asset(
                            'assets/side/setting.png',
                            width: 20,
                            height: 20,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => SettingPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              image: _isImageLoading || _avatarImage == null
                                  ? null
                                  : DecorationImage(
                                image: _avatarImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: _isImageLoading
                                ? Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                ),
                              ),
                            )
                                : _avatarImage == null
                                ? Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey[400],
                            )
                                : null,
                          ),
                        ),
                        SizedBox(height: 15),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _showProfileUpdateDialog,
                                child: Text(
                                  _nickname ?? '여행하는길동이 님',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ),
                              SizedBox(width: 5),
                              GestureDetector(
                                onTap: _showProfileUpdateDialog,
                                child: Image.asset(
                                  'assets/side/name_change.png',
                                  width: 18,
                                  height: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  // 수정된 메뉴 항목
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMenuButton(
                          imagePath: 'assets/side/review.png',
                          label: '내 리뷰',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => ReviewPage()),
                          ),
                        ),
                        Text(
                          '|',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        _buildMenuButton(
                          imagePath: 'assets/side/reservation.png',
                          label: '내 예약',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => ReservationPage()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  SizedBox(height: 5, child: Container(color: Color(0xFFF9F9F9))),
                  SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 친구초대 - 전체 컨테이너를 터치 가능하게 수정
                        InkWell(
                          onTap: () {
                            InviteService.inviteFriends();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '친구초대',
                                style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Color(0xFF999999), size: 14),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        Divider(color: Color(0xFFF1F1F1)),
                        SizedBox(height: 15),
                        // 공지사항 - 전체 컨테이너를 터치 가능하게 수정
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => UserNoticeList()));
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '공지사항',
                                style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Color(0xFF999999), size: 14),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        Divider(color: Color(0xFFF1F1F1)),
                        SizedBox(height: 15),
                        // FAQ - 전체 컨테이너를 터치 가능하게 수정
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => UserFaqList()));
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'FAQ',
                                style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Color(0xFF999999), size: 14),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        Divider(color: Color(0xFFF1F1F1)),
                        SizedBox(height: 15),
                        // 이용불편사항신고 - 전체 컨테이너를 터치 가능하게 수정
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => ComplaintPage()));
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '이용불편사항신고',
                                style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Color(0xFF999999), size: 16),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        Divider(color: Color(0xFFF1F1F1)),
                        SizedBox(height: 15),
                        // 고객센터 - 새로 추가
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => CustomerServicePage()));
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '고객센터',
                                style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Color(0xFF999999), size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  SizedBox(height: 5, child: Container(color: Color(0xFFF9F9F9))),
                  Expanded(child: Container()),
                  LogoutHandler(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    String? imagePath,
    IconData? icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(  // 세로 배치를 가로 배치로 변경
        mainAxisSize: MainAxisSize.min,
        children: [
          imagePath != null
              ? Image.asset(imagePath, width: 24, height: 24)
              : Icon(icon, size: 25, color: Colors.black87),
          SizedBox(width: 6),  // 간격 추가
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}