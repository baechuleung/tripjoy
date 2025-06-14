import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

Future<bool> checkCameraPermission() async {
  if (Platform.isIOS) {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();
    final photosStatus = await Permission.photos.request();

    print('카메라 권한 상태: $cameraStatus');
    print('마이크 권한 상태: $microphoneStatus');
    print('사진 라이브러리 권한 상태: $photosStatus');

    return cameraStatus.isGranted && microphoneStatus.isGranted && photosStatus.isGranted;
  } else {
    // 안드로이드 권한 처리
    bool hasStoragePermission = false;

    if (await Permission.storage.status.isDenied) {
      // Android 10 이하의 저장소 권한
      final storageStatus = await [
        Permission.storage,
      ].request();

      print('저장소 권한 요청 결과: ${storageStatus[Permission.storage]}');
      hasStoragePermission = storageStatus[Permission.storage]?.isGranted ?? false;
    }

    if (!hasStoragePermission) {
      // Android 13 이상의 미디어 권한
      final mediaStatus = await [
        Permission.photos,
        Permission.videos,
      ].request();

      print('미디어 권한 요청 결과: ${mediaStatus[Permission.photos]}');
      hasStoragePermission = mediaStatus[Permission.photos]?.isGranted ?? false;
    }

    if (!hasStoragePermission) return false;

    // 카메라와 마이크 권한 요청
    final cameraStatus = await Permission.camera.request();
    print('카메라 권한 상태: $cameraStatus');
    if (!cameraStatus.isGranted) return false;

    final microphoneStatus = await Permission.microphone.request();
    print('마이크 권한 상태: $microphoneStatus');
    if (!microphoneStatus.isGranted) return false;

    return true;
  }
}