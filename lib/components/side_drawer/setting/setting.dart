import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tripjoy/term/term_service.dart';
import 'package:tripjoy/term/term_privacy.dart';
import 'package:tripjoy/term/term_location.dart';
import 'package:tripjoy/term/term_marketing.dart';
import 'package:tripjoy/term/term_third_party.dart';
import '../user_faq_list.dart';
import 'withdraw_membership.dart';
import 'dart:io' show Platform;

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> with WidgetsBindingObserver {
  String _locationPermissionStatus = '';
  String _cameraPermissionStatus = '';
  String _appVersion = '';
  String _notificationStatus = '허용됨';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePermissions();
    _getAppVersion();
  }

  Future<void> _initializePermissions() async {
    if (!mounted) return;
    await Future.wait([
      _checkLocationPermission(),
      _checkCameraPermission(),
      _checkNotificationPermission(),
    ]);
  }

  Future<void> _getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializePermissions();
    }
  }

  Future<void> _checkLocationPermission() async {
    if (Platform.isIOS) {
      // iOS에서는 항상 '설정에서 열기' 표시
      if (!mounted) return;
      setState(() {
        _locationPermissionStatus = '설정에서 열기';
      });
    } else {
      // Android 로직은 그대로 유지
      var status = await Permission.location.status;
      if (!mounted) return;
      setState(() {
        _locationPermissionStatus = _getPermissionText(status);
      });
    }
  }

  Future<void> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    setState(() {
      _cameraPermissionStatus = _getPermissionText(status);
    });
  }

  static const platform = MethodChannel('com.leapcompany.tripjoy/notification_permission');

  Future<void> _checkNotificationPermission() async {
    if (Platform.isAndroid) {
      // Android에서는 permission_handler를 사용
      var status = await Permission.notification.status;
      setState(() {
        _notificationStatus = _getPermissionText(status);
      });
    } else {
      // iOS에서는 기존 MethodChannel 사용
      try {
        final bool isNotificationEnabled = await platform.invokeMethod('checkNotificationPermission');
        if (!mounted) return;
        setState(() {
          _notificationStatus = isNotificationEnabled ? '허용됨' : '허용되지 않음';
        });
      } catch (e) {
        print('Failed to get notification permission: $e');
        if (!mounted) return;
        setState(() {
          _notificationStatus = '허용되지 않음';
        });
      }
    }
  }

  String _getPermissionText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '허용됨';
      case PermissionStatus.denied:
        return '허용되지 않음';
      case PermissionStatus.permanentlyDenied:
        return '설정에서 변경';
      case PermissionStatus.restricted:
        return '제한됨';
      case PermissionStatus.limited:
        return '제한적 허용';
      default:
        return '알 수 없음';
    }
  }

  Future<void> _requestLocationPermission() async {
    if (Platform.isIOS) {
      // iOS에서는 바로 설정으로 이동
      await openAppSettings();
    } else {
      // Android는 기존 로직 유지
      if (await Permission.location.request().isGranted) {
        await _checkLocationPermission();
      } else {
        await openAppSettings();
      }
    }
  }

  Future<void> _requestCameraPermission() async {
    if (await Permission.camera.request().isGranted) {
      _checkCameraPermission();
    } else {
      await openAppSettings();
    }
  }

  Future<void> _openNotificationSettings() async {
    if (Platform.isAndroid) {
      // Android에서는 먼저 권한 요청 시도
      final status = await Permission.notification.request();
      if (status.isDenied) {
        // 권한이 거부되면 설정으로 이동
        await openAppSettings();
      }
    } else {
      // iOS에서는 바로 설정으로 이동
      await openAppSettings();
    }
    _checkNotificationPermission(); // 권한 상태 재확인
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '설정',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        children: [
          // 서비스 설정
          _buildSectionTitle('서비스 설정'),
          _buildPermissionRow('위치서비스 허용', _locationPermissionStatus, _requestLocationPermission),
          _buildPermissionRow('카메라 접근 허용', _cameraPermissionStatus, _requestCameraPermission),

          SizedBox(height: 20),
          // 알림 설정
          _buildSectionTitle('알림 설정'),
          _buildPermissionRow('트립조이 알림', _notificationStatus, _openNotificationSettings),

          SizedBox(height: 20),
          // 서비스 약관
          _buildSectionTitle('서비스 약관'),
          _buildListTile('서비스 이용약관', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TermServicePage()))),
          _buildListTile('위치정보 이용약관', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TermLocationPage()))),
          _buildListTile('개인정보 처리방침', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TermPrivacyPage()))),
          _buildListTile('제3자 정보제공 약관', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TermThirdPartyPage()))),
          _buildListTile('마케팅 활용 약관', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TermMarketingPage()))),

          SizedBox(height: 20),
          // 고객 서비스
          _buildSectionTitle('고객서비스'),
          _buildListTile('현재버전', trailing: Text('v $_appVersion', style: TextStyle(fontSize: 14))),
          _buildListTile('FAQ', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserFaqList()))),
          _buildListTile('회원탈퇴', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => WithdrawMembershipPage()))),
        ],
      ),
    );
  }

  // Section Title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  // Permission Row
  Widget _buildPermissionRow(String title, String status, Function() onPressed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(
            status,
            style: TextStyle(color: Color(0xFF007CFF), fontSize: 14),
          ),
        ),
      ],
    );
  }

  // ListTile
  Widget _buildListTile(String title, {Widget? trailing, Function()? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}