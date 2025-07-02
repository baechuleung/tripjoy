import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../logout_handler.dart';
import 'widgets/user_profile_section.dart';
import 'widgets/drawer_menu_section.dart';
import 'widgets/drawer_header_section.dart';
import 'widgets/point_charge_section.dart';

class UserDrawer extends StatefulWidget {
  @override
  _UserDrawerState createState() => _UserDrawerState();
}

class _UserDrawerState extends State<UserDrawer> {
  String? _photoUrl;
  String? _nickname;
  int? _points;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _initializeUserDataStream();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('🔥 [UserDrawer] 현재 유저 UID: ${user.uid}');
      print('🔥 [UserDrawer] Firebase Auth photoURL: ${user.photoURL}');

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          print('🔥 [UserDrawer] Firestore 데이터: $data');

          setState(() {
            _nickname = data['name'] ?? '여행하는길동이 님';
            // Firestore에 photoUrl이 없으면 Firebase Auth의 photoURL 사용
            _photoUrl = data['photoUrl'] ?? user.photoURL;
            _points = data['points'] ?? 0;
            _isLoading = false;
          });

          print('🔥 [UserDrawer] 초기 로드 완료 - photoUrl: $_photoUrl');
        }
      } catch (e) {
        print('❌ [UserDrawer] 초기 데이터 로드 오류: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          final data = docSnapshot.data()!;
          print('🔥 [UserDrawer] 스트림 업데이트 - photoUrl: ${data['photoUrl']}');

          setState(() {
            _nickname = data['name'] ?? '여행하는길동이 님';
            // Firestore에 photoUrl이 없으면 Firebase Auth의 photoURL 사용
            _photoUrl = data['photoUrl'] ?? user.photoURL;
            _points = data['points'] ?? 0;
          });
        }
      });
    }
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
        final data = doc.data()!;
        print('🔥 [UserDrawer] 리프레시 - photoUrl: ${data['photoUrl']}');

        setState(() {
          _nickname = data['name'] ?? '여행하는길동이 님';
          // Firestore에 photoUrl이 없으면 Firebase Auth의 photoURL 사용
          _photoUrl = data['photoUrl'] ?? user.photoURL;
          _points = data['points'] ?? 0;
        });
      }
    }
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
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DrawerHeaderSection(),
                  if (_isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    UserProfileSection(
                      photoUrl: _photoUrl,
                      nickname: _nickname,
                      points: _points,
                      onProfileUpdated: _refreshUserData,
                    ),
                  PointChargeSection(
                    points: _points ?? 0,
                  ),
                  SizedBox(height: 5),
                  SizedBox(height: 5, child: Container(color: Color(0xFFF9F9F9))),
                  SizedBox(height: 15),
                  DrawerMenuSection(),
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
}