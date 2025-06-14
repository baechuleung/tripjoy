import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'camera_function.dart';
import 'camera_permission.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cam_dec.dart';
import 'package:tripjoy/screens/main_page.dart';
import 'dart:async';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isSaving = false;
  bool _permissionDenied = false;
  bool _isInitialized = false;
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 3.0;
  double _baseZoomLevel = 1.0; // 핀치 줌 시작시 기준 줌 레벨
  Offset? _focusPoint;
  bool _showFocusCircle = false;
  Timer? _focusTimer;
  bool _isDisposed = false; // 컴포넌트 dispose 상태 추적

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      bool permissionGranted = await checkCameraPermission();
      if (permissionGranted) {
        await _initializeCameraController();
      } else {
        // 권한이 영구적으로 거부된 경우에만 설정으로 이동
        bool isPermanentlyDenied = [
          await Permission.camera.isPermanentlyDenied,
          await Permission.microphone.isPermanentlyDenied,
          await Permission.photos.isPermanentlyDenied
        ].any((isDenied) => isDenied);

        if (isPermanentlyDenied) {
          _handlePermissionDenied();
        }
      }
    } catch (e) {
      print('카메라 초기화 오류: $e');
      _showSnackBar('카메라 초기화에 실패했습니다.');
      if (!_isDisposed && mounted) {
        setState(() {
          _permissionDenied = true;
        });
      }
    }
  }

  Future<void> _initializeCameraController() async {
    try {
      if (_cameraController != null) {
        await _cameraController!.dispose();
      }

      // 카메라 컨트롤러 초기화 시 해상도 설정 추가
      _cameraController = await initializeCamera();

      // 컴포넌트가 dispose 되었는지 확인
      if (_isDisposed) {
        // 이미 dispose 된 경우 카메라 컨트롤러도 정리
        await _cameraController?.dispose();
        return;
      }

      // 카메라 초기화
      await _cameraController!.initialize();

      // 줌 레벨 범위 가져오기
      _minZoomLevel = 1.0;
      _maxZoomLevel = await getMaxZoomLevel(_cameraController!);
      _currentZoomLevel = 1.0;

      if (!_isDisposed && mounted) {
        setState(() {
          _isInitialized = true;
          _permissionDenied = false;
        });
      }

      await _checkAndShowPopup();
    } catch (e) {
      print('카메라 컨트롤러 초기화 오류: $e');
      _showSnackBar('카메라 초기화에 실패했습니다.');
      if (!_isDisposed && mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  void _handlePermissionDenied() {
    if (!_isDisposed && mounted) {
      setState(() {
        _permissionDenied = true;
        _isInitialized = false;
      });
      _showSnackBar('카메라와 마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.');
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainPage())
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true; // 먼저 상태 업데이트
    WidgetsBinding.instance.removeObserver(this);
    _focusTimer?.cancel();

    // 카메라 컨트롤러 정리
    if (_cameraController != null) {
      _cameraController!.dispose();
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // 앱이 백그라운드로 가거나 다른 화면으로 전환될 때
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      // 앱이 다시 포그라운드로 돌아올 때
      _initializeCameraController();
    }
  }

  // 카메라 리소스 정리를 위한 별도 메소드
  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null; // 명시적으로 null 할당
    }
  }

  Future<void> _checkAndShowPopup() async {
    if (_isDisposed || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    final lastShown = prefs.getString('popup_last_shown') ?? '';

    if (lastShown != today) {
      showCameraPopup(context);
      await prefs.setString('popup_last_shown', today);
    }
  }

  Future<void> _captureImage() async {
    if (!_isInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      _showSnackBar('카메라가 준비되지 않았습니다.');
      return;
    }

    try {
      await captureImage(_cameraController!, context, (saving) {
        if (!_isDisposed && mounted) {
          setState(() {
            _isSaving = saving;
          });
        }
      });
    } catch (e) {
      print('이미지 촬영 오류: $e');
      _showSnackBar('이미지 촬영 중 오류가 발생했습니다.');
    }
  }

  void _showSnackBar(String message) {
    if (_isDisposed || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
    );
  }

  Future<void> _handleBackPress() async {
    await _disposeCamera();
    if (_isDisposed || !mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => MainPage()),
          (route) => false,
    );
  }

  // 줌 슬라이더 값 변경 처리
  void _handleZoomChanged(double value) {
    if (_isDisposed || !mounted) return;

    setState(() {
      _currentZoomLevel = value;
    });
    setZoomLevel(_cameraController!, value);
  }

  // 화면 탭 처리 - 초점 맞추기 (완전히 수정된 버전)
  void _handleTapToFocus(TapDownDetails details) {
    if (!_isInitialized || _cameraController == null || !_cameraController!.value.isInitialized || _isDisposed) {
      return;
    }

    // 현재 탭의 실제 위치 (화면 좌표)
    final Offset tapPosition = details.globalPosition;

    print('실제 탭 위치: ${tapPosition.dx}, ${tapPosition.dy}');

    // 앱바 높이 등 가져오기
    final Size screenSize = MediaQuery.of(context).size;
    final double appBarHeight = AppBar().preferredSize.height;

    // 터치 위치를 보정
    double viewHeight = screenSize.height - appBarHeight;
    // 카메라 뷰는 4:3 비율이고 화면 가운데 맞춰져 있음
    double originalY = tapPosition.dy;

    // UI에 표시할 초점 포인트 위치를 설정
    if (!_isDisposed && mounted) {
      setState(() {
        _focusPoint = tapPosition;
        _showFocusCircle = true;
      });
    }

    // 카메라 API에 전달할 정규화된 좌표 계산
    // 화면 좌표를 0.0~1.0 사이의 값으로 변환
    double normX = (tapPosition.dx / screenSize.width).clamp(0.0, 1.0);
    double normY = (tapPosition.dy / screenSize.height).clamp(0.0, 1.0);

    print('카메라에 전달할 정규화된 좌표: $normX, $normY');

    // 카메라 초점 설정
    setFocusPoint(
        _cameraController!,
        Offset(normX, normY),
        Size(1, 1) // 이미 정규화된 좌표
    );

    // 기존 타이머 취소
    _focusTimer?.cancel();

    // 2초 후 초점 원 숨기기
    _focusTimer = Timer(Duration(seconds: 2), () {
      if (!_isDisposed && mounted) {
        setState(() {
          _showFocusCircle = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return MainPage();
    }

    final mediaSize = MediaQuery.of(context).size;
    final screenHeight = mediaSize.height;
    final screenWidth = mediaSize.width;

    // AppBar와 하단 컨트롤 영역 고려
    final appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
    final bottomControlHeight = MediaQuery.of(context).size.height * 0.20;
    final availableHeight = screenHeight - appBarHeight - bottomControlHeight;

    // 16:9 비율 계산
    final aspectRatio = 16 / 9;
    final containerWidth = screenWidth;
    final containerHeight = containerWidth / aspectRatio;

    return WillPopScope(
      onWillPop: () async {
        await _handleBackPress();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => _handleBackPress(),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 카메라 프리뷰 - 16:9 비율로 화면 전체를 채우도록 설정
            if (_isInitialized && _cameraController != null && _cameraController!.value.isInitialized)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: screenHeight - bottomControlHeight,
                child: Container(
                  color: Colors.black,
                  child: Transform.scale(
                    scale: 1.0, // 추가 확대가 필요하면 값을 증가
                    alignment: Alignment.topCenter,
                    child: AspectRatio(
                      aspectRatio: 9 / 16, // 세로 모드에서 16:9 비율은 9/16
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                ),
              ),

            // 제스처 감지 영역 - 초점 맞추기, 줌 등
            if (_isInitialized && _cameraController != null && _cameraController!.value.isInitialized)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: screenHeight - bottomControlHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: _handleTapToFocus,
                  onScaleStart: (details) {
                    _baseZoomLevel = _currentZoomLevel;
                  },
                  onScaleUpdate: (details) {
                    if (details.scale != 1.0 && _isInitialized && _cameraController != null) {
                      final double newZoomLevel = (_baseZoomLevel * details.scale).clamp(_minZoomLevel, _maxZoomLevel);
                      if ((_currentZoomLevel - newZoomLevel).abs() > 0.05) {
                        if (!_isDisposed && mounted) {
                          setState(() {
                            _currentZoomLevel = newZoomLevel;
                          });
                        }
                        setZoomLevel(_cameraController!, newZoomLevel);
                      }
                    }
                  },
                ),
              ),

            // 초점 원 표시 - 정확한 위치에 표시하도록 수정 (Container로 변경)
            if (_showFocusCircle && _focusPoint != null)
              Positioned(
                left: _focusPoint!.dx - 25,
                top: _focusPoint!.dy - 100,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

            // 줌 컨트롤
            Positioned(
              right: 20,
              top: screenHeight * 0.3,
              child: Container(
                height: 200,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Slider(
                    value: _currentZoomLevel,
                    min: _minZoomLevel,
                    max: _maxZoomLevel,
                    onChanged: _handleZoomChanged,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),

            // 줌 레벨 표시
            Positioned(
              right: 20,
              top: screenHeight * 0.25,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_currentZoomLevel.toStringAsFixed(1)}x',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),

            // 하단 컨트롤
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: bottomControlHeight,
              child: Container(
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIconButton(
                      context,
                      icon: Icons.home,
                      label: '홈',
                      onPressed: () => _navigateToMainPage(context),
                    ),
                    ShutterButton(onPressed: _captureImage),
                    _buildIconButton(
                      context,
                      icon: Icons.help_outline,
                      label: '도움말',
                      onPressed: () => showCameraPopup(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onPressed,
      }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 4),
          Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: 14)
          ),
        ],
      ),
    );
  }

  void _navigateToMainPage(BuildContext context) {
    _disposeCamera(); // 네비게이션하기 전에 카메라 컨트롤러 정리
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainPage()),
    );
  }
}

class ShutterButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ShutterButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: CustomPaint(
        size: Size(60, 60),
        painter: ShutterButtonPainter(),
      ),
    );
  }
}

class ShutterButtonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2, outerCirclePaint);
    canvas.drawCircle(size.center(Offset.zero), size.width / 2.5, innerCirclePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// FocusCirclePainter 클래스 추가
class FocusCirclePainter extends CustomPainter {
  final Offset position;
  final double size = 50.0;

  FocusCirclePainter(this.position);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 정확히 터치 위치에 원 그리기
    canvas.drawCircle(
      position, // 정확한 터치 위치
      this.size / 2, // 반지름
      paint,
    );
  }

  @override
  bool shouldRepaint(FocusCirclePainter oldDelegate) {
    return oldDelegate.position != position;
  }
}