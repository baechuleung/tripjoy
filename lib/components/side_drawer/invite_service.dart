import 'package:share_plus/share_plus.dart';
import 'dart:io';

class InviteService {
  static void inviteFriends() {
    const String androidStoreLink = 'https://play.google.com/store/apps/details?id=com.leadproject.tripjoy';
    const String iosStoreLink = 'https://apps.apple.com/app/6740760245';

    final String inviteText = '''
🌍 여행 필수 도구, TripJoy!
계획부터 번역서비스까지! 한번에!.

👉 지금 다운로드하기:
📱 iOS: $iosStoreLink
🤖 Android: $androidStoreLink
''';

    Share.share(inviteText, subject: 'TripJoy로 여행을 함께해요!');
  }
}