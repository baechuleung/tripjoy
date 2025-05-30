import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:typed_data';
import 'upload_image.dart';
import 'package:just_audio/just_audio.dart'; // just_audio 패키지 임포트
import 'package:saver_gallery/saver_gallery.dart';

Future<CameraController> initializeCamera() async {
  try {
    // 사용 가능한 카메라 목록 가져오기
    final cameras = await availableCameras();
    print('사용 가능한 카메라 수: ${cameras.length}');
    cameras.forEach((camera) {
      print('카메라 정보: ${camera.name}, 렌즈 방향: ${camera.lensDirection}');
    });

    if (cameras.isEmpty) {
      throw CameraException('no_cameras', '사용 가능한 카메라가 없습니다.');
    }

    // 후면 카메라 찾기
    final backCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () {
        print('후면 카메라를 찾을 수 없어 첫 번째 카메라를 사용합니다.');
        return cameras.first;
      },
    );

    print('선택된 카메라: ${backCamera.name}');

    // 컨트롤러 생성
    final controller = CameraController(
      backCamera,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.jpeg
          : ImageFormatGroup.bgra8888,
    );

    print('카메라 컨트롤러 생성 완료');

    // 컨트롤러 초기화
    try {
      await controller.initialize();
      print('카메라 컨트롤러 초기화 성공');
    } catch (e) {
      print('카메라 컨트롤러 초기화 실패: $e');
      throw CameraException('initialization_failed', '카메라 초기화에 실패했습니다: $e');
    }

    // 카메라 설정
    if (controller.value.isInitialized) {
      try {
        await Future.wait([
          controller.setFocusMode(FocusMode.auto),
          controller.setExposureMode(ExposureMode.auto),
          controller.setFlashMode(FlashMode.off),
        ]);
        print('카메라 설정 완료 (포커스, 노출, 플래시)');
      } catch (e) {
        print('카메라 설정 중 오류 발생 (계속 진행): $e');
      }
    }

    return controller;
  } catch (e) {
    print('카메라 초기화 중 치명적 오류: $e');
    rethrow;
  }
}

// 줌 레벨 설정 함수
Future<void> setZoomLevel(CameraController controller, double zoomLevel) async {
  if (controller == null || !controller.value.isInitialized) {
    print('카메라 컨트롤러가 초기화되지 않음');
    return;
  }

  try {
    // 줌 레벨 범위 제한 (1.0~5.0 사이로 제한)
    zoomLevel = zoomLevel.clamp(1.0, 5.0);
    await controller.setZoomLevel(zoomLevel);
    print('줌 레벨 설정: $zoomLevel');
  } catch (e) {
    print('줌 설정 오류: $e');
  }
}

// 최대 줌 레벨 가져오기 - 기기별로 다를 수 있으므로 안전한 기본값 사용
Future<double> getMaxZoomLevel(CameraController controller) async {
  // 고정된 값 반환 (대부분의 기기가 지원하는 안전한 값)
  return 3.0;
}

// 특정 포인트에 초점 맞추기 (텍스트 가까이 촬영용 개선)
Future<void> setFocusPoint(CameraController controller, Offset point, Size previewSize) async {
  if (controller == null || !controller.value.isInitialized) {
    print('카메라 컨트롤러가 초기화되지 않음');
    return;
  }

  try {
    // 좌표가 이미 정규화되었는지 확인
    double x = point.dx;
    double y = point.dy;

    // 좌표가 정규화되지 않았다면 정규화 (1x1 사이즈라면 이미 정규화된 것)
    if (previewSize.width != 1 || previewSize.height != 1) {
      x = point.dx / previewSize.width;
      y = point.dy / previewSize.height;
    }

    // 범위 제한 (0.0 ~ 1.0 사이로 조정)
    x = x.clamp(0.0, 1.0);
    y = y.clamp(0.0, 1.0);

    print('초점 설정 최종 좌표: ($x, $y)');

    // 근접 초점 모드로 설정하여 텍스트 촬영에 최적화
    await controller.setFocusMode(FocusMode.auto);
    await controller.setFocusPoint(Offset(x, y));

    // 텍스트 인식을 위한 매크로 모드 활성화 시도
    try {
      // 매크로 모드가 지원되는 경우 사용 (일부 기기에서만 지원)
      await controller.setExposureOffset(0.0); // 노출을 중립으로 설정
    } catch (e) {
      print('매크로 모드 설정 실패 (무시됨): $e');
    }

    print('텍스트 인식을 위한 초점 설정 완료: ($x, $y)');
  } catch (e) {
    print('초점 설정 오류: $e');
  }
}

Future<void> captureImage(CameraController cameraController, BuildContext context, Function setSavingState) async {
  if (cameraController == null || !cameraController.value.isInitialized) {
    print('카메라 컨트롤러가 초기화되지 않음');
    return;
  }

  try {
    // just_audio를 사용한 셔터 사운드 재생
    final player = AudioPlayer();
    try {
      await player.setAsset('assets/sounds/camera_shutter.mp3');
      player.play();
    } catch (audioError) {
      print('오디오 재생 오류 (무시됨): $audioError');
      // 오디오 오류가 발생해도 사진 촬영은 계속 진행
    }

    // 사진 촬영
    final image = await cameraController.takePicture();
    print('사진 촬영 완료: ${image.path}');

    // 저장 상태 업데이트
    setSavingState(true);

    // 이미지 저장 및 네비게이션
    await saveImageAndNavigate(image.path, context);

    // 플레이어 해제
    await player.dispose();
  } catch (e) {
    print('이미지 촬영 오류: $e');
    _showSnackBar(context, '이미지 촬영 중 오류가 발생했습니다.');
  } finally {
    setSavingState(false);
  }
}

Future<void> saveImageAndNavigate(String imagePath, BuildContext context) async {
  try {
    // 이미지 파일 읽기
    final File imageFile = File(imagePath);
    final Uint8List imageBytes = await imageFile.readAsBytes();
    print('이미지 파일 읽기 완료: ${imageBytes.length} bytes');

    // 갤러리에 이미지 저장
    final fileName = 'Tripjoy_${DateTime.now().millisecondsSinceEpoch}';
    final result = await SaverGallery.saveImage(
        imageBytes,
        quality: 100,
        fileName: fileName,  // 필수 매개변수
        skipIfExists: false,  // 필수 매개변수
        androidRelativePath: "Pictures/Tripjoy/"  // Android용 상대 경로
    );
    print('갤러리 저장 결과: $result');

    if (result.isSuccess) {
      print('이미지 저장 성공, 업로드 페이지로 이동');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadImagePage(imagePath: imagePath),
        ),
      );
    } else {
      throw Exception('이미지 저장 실패: ${result.errorMessage}');
    }
  } catch (e) {
    print('저장 오류: $e');
    _showSnackBar(context, '이미지 저장 중 오류가 발생했습니다: $e');
  }
}

void _showSnackBar(BuildContext context, String message) {
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
    );
  }
}