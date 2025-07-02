import 'dart:math';

class AvatarUtils {
  static final List<String> defaultAvatars = [
    'https://robohash.org/trip1.png?size=150x150&set=set4',
    'https://robohash.org/trip2.png?size=150x150&set=set4',
    'https://robohash.org/trip3.png?size=150x150&set=set4',
    'https://robohash.org/trip4.png?size=150x150&set=set4',
    'https://robohash.org/trip5.png?size=150x150&set=set4'
  ];

  static String getRandomDefaultAvatar() {
    final random = Random();
    return defaultAvatars[random.nextInt(defaultAvatars.length)];
  }
}