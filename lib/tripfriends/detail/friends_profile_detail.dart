import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/translation_service.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'full_screen_image_viewer.dart';

class FriendsProfileDetail extends StatefulWidget {
  final Map<String, dynamic> friends;

  const FriendsProfileDetail({
    super.key,
    required this.friends,
  });

  @override
  State<FriendsProfileDetail> createState() => _FriendsProfileDetailState();
}

class _FriendsProfileDetailState extends State<FriendsProfileDetail> {
  final TranslationService _translationService = TranslationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NumberFormat _numberFormat = NumberFormat('#,###');
  bool _isTranslationsLoaded = false;
  bool _isDisposed = false;
  int _reviewCount = 0;
  int _friendsCount = 0;
  List<String> _translatedLanguages = [];

  // 미디어 관련 상태 변수
  List<Map<String, dynamic>> _mediaList = [];
  int _currentMediaIndex = 0;
  PageController _pageController = PageController();

  // 비디오 컨트롤러 관리
  Map<String, VideoPlayerController> _videoControllers = {};
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadTranslations();
    _loadCounts();
    _initializeMediaList();
  }

  void _initializeMediaList() {
    // profileMediaList만 사용
    if (widget.friends['profileMediaList'] != null &&
        widget.friends['profileMediaList'] is List) {

      final List<dynamic> mediaListData = widget.friends['profileMediaList'] as List;
      _mediaList = mediaListData.map((media) {
        return {
          'path': media['path'] ?? '',
          'type': media['type'] ?? 'image',
        };
      }).toList();

      // 비디오 컨트롤러 초기화
      _initializeVideoControllers();
    }

    // 디버깅용 로깅
    print('초기화된 미디어 목록: $_mediaList');
  }

  // 비디오 컨트롤러 초기화
  Future<void> _initializeVideoControllers() async {
    for (var media in _mediaList) {
      if (media['type'] == 'video') {
        final path = media['path'] as String;
        try {
          final controller = VideoPlayerController.network(path);
          await controller.initialize();
          controller.setLooping(true);
          // 자동 재생 없음 - 일시정지 상태로 유지
          controller.pause();
          _videoControllers[path] = controller;

          // 상태 업데이트를 위한 리스너 추가
          controller.addListener(() {
            if (mounted) {
              setState(() {
                // 비디오 상태가 변경되면 UI 업데이트
              });
            }
          });

          if (mounted) {
            setState(() {});  // UI 업데이트
          }
        } catch (e) {
          print('비디오 컨트롤러 초기화 오류: $e');
        }
      }
    }
  }

  // 비디오 재생/일시정지 토글
  void _toggleVideoPlayback(String path) {
    if (_videoControllers.containsKey(path)) {
      final controller = _videoControllers[path]!;
      setState(() {
        if (controller.value.isPlaying) {
          controller.pause();
          _isVideoPlaying = false;
        } else {
          controller.play();
          _isVideoPlaying = true;
        }
      });
    }
  }

  // 이미지를 전체 화면으로 보여주는 메서드
  void _showFullScreenImage(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imagePath: imagePath),
      ),
    );
  }

  // 현재 표시 중인 미디어가 비디오인지 확인
  bool _isCurrentMediaVideo() {
    if (_mediaList.isEmpty || _currentMediaIndex >= _mediaList.length) {
      return false;
    }
    return _mediaList[_currentMediaIndex]['type'] == 'video';
  }

  // 현재 표시 중인 비디오의 경로 가져오기
  String? _getCurrentVideoPath() {
    if (!_isCurrentMediaVideo()) {
      return null;
    }
    return _mediaList[_currentMediaIndex]['path'] as String;
  }

  Future<void> _loadTranslations() async {
    if (_isDisposed) return;
    await _translationService.loadTranslations();

    if (mounted && !_isDisposed) {
      // 언어 데이터 가져오기 및 번역
      List<String> languages = [];
      final List<dynamic> languagesList = widget.friends['languages'] ?? [];

      for (final language in languagesList) {
        String translatedLanguage = _translationService.getTranslatedText(language.toString());
        languages.add(translatedLanguage);
      }

      setState(() {
        _isTranslationsLoaded = true;
        _translatedLanguages = languages;
      });
    }
  }

  Future<void> _loadCounts() async {
    if (_isDisposed) return;

    try {
      final userRef = _firestore.collection('tripfriends_users').doc(widget.friends['uid']);

      // 리뷰 문서들 가져오기
      final reviewsSnapshot = await userRef.collection('reviews').get();

      if (reviewsSnapshot.docs.isNotEmpty) {
        // 리뷰 수 설정
        setState(() {
          _reviewCount = reviewsSnapshot.docs.length;
        });

        // 평균 평점 계산
        double totalRating = 0;
        for (var doc in reviewsSnapshot.docs) {
          totalRating += (doc.data()['rating'] as num).toDouble();
        }
        double averageRating = totalRating / reviewsSnapshot.docs.length;

        // 평균 평점 업데이트
        await userRef.update({
          'average_rating': double.parse(averageRating.toStringAsFixed(1))
        });
      }

      // 프렌즈 횟수 가져오기 (status가 completed인 예약만)
      final reservationsSnapshot = await userRef
          .collection('reservations')
          .where('status', isEqualTo: 'completed')
          .count()
          .get();

      if (!_isDisposed && mounted) {
        setState(() {
          _friendsCount = reservationsSnapshot.count ?? 0;
        });
      }
    } catch (e) {
      print('Error loading counts: $e');
    }
  }

  // 페이지 변경 시 비디오 일시 정지
  void _onPageChanged(int page) {
    // 이전 페이지가 비디오였다면 일시 정지
    if (_currentMediaIndex < _mediaList.length &&
        _mediaList[_currentMediaIndex]['type'] == 'video') {
      final String prevPath = _mediaList[_currentMediaIndex]['path'];
      if (_videoControllers.containsKey(prevPath)) {
        _videoControllers[prevPath]?.pause();
      }
    }

    setState(() {
      _currentMediaIndex = page;
      _isVideoPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return Container();

    final String name = widget.friends['name'] ?? '이름 없음';
    final int age = _calculateAge(widget.friends['birthDate'] ?? {'year': 0, 'month': 0, 'day': 0});
    final String genderEn = widget.friends['gender'] ?? '';
    final double averageRating = (widget.friends['average_rating'] ?? 0.0).toDouble();
    final screenWidth = MediaQuery.of(context).size.width;

    // 성별 한국어로 변환
    String gender = '성별 정보 없음';
    if (genderEn.toLowerCase() == 'male') {
      gender = '남성';
    } else if (genderEn.toLowerCase() == 'female') {
      gender = '여성';
    } else if (genderEn.isNotEmpty) {
      gender = genderEn;
    }

    return Container(
      width: screenWidth,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 스와이프를 위한 영역 - 오버레이 정보 없이 미디어만 표시
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _mediaList.isEmpty ? 1 : _mediaList.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                // 미디어 리스트가 비어있으면 빈 컨테이너 표시
                if (_mediaList.isEmpty) {
                  return Container(
                    color: Colors.grey[200],
                  );
                }

                final mediaItem = _mediaList[index];
                final mediaPath = mediaItem['path'] as String;
                final mediaType = mediaItem['type'] as String;

                // 미디어 타입에 따라 다른 위젯 반환
                if (mediaType == 'video') {
                  // 비디오 플레이어 반환
                  return _buildVideoPlayer(mediaPath, screenWidth);
                } else {
                  // 이미지 표시 - GestureDetector로 감싸서 탭 이벤트 처리
                  return GestureDetector(
                    onTap: () => _showFullScreenImage(mediaPath),
                    child: Image.network(
                      mediaPath,
                      fit: BoxFit.cover,
                      width: screenWidth,
                      height: 400,
                      cacheWidth: 1024,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.error, color: Colors.red),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),

          // 비디오 재생/일시정지 버튼 오버레이 (현재 미디어가 비디오일 때 항상 표시)
          if (_isCurrentMediaVideo())
            Center(
              child: GestureDetector(
                onTap: () {
                  final videoPath = _getCurrentVideoPath();
                  if (videoPath != null) {
                    _toggleVideoPlayback(videoPath);
                  }
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _videoControllers[_getCurrentVideoPath()]?.value.isPlaying ?? false
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),

          // 그라데이션 오버레이 - 터치 이벤트 무시 (IgnorePointer)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.3, 0.5, 0.7],
                  ),
                ),
              ),
            ),
          ),

          // 현재 페이지 번호 표시 (미디어가 2개 이상일 때만 표시) - 터치 이벤트 무시
          if (_mediaList.length > 1)
            Positioned(
              top: 10,
              right: 16,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${_currentMediaIndex + 1}/${_mediaList.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // 매칭 횟수 및 리뷰 - 터치 이벤트 무시
          Positioned(
            bottom: 84,
            left: 16,
            child: IgnorePointer(
              child: Row(
                children: [
                  // 매칭 횟수
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _numberFormat.format(_friendsCount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // 별점 및 리뷰 수
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.yellow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$averageRating/5',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        ' (${_numberFormat.format(_reviewCount)})',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 이름, 나이, 성별 정보 - 터치 이벤트 무시
          Positioned(
            bottom: 54,
            left: 16,
            child: IgnorePointer(
              child: Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$age세',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($gender)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 언어 컨테이너 - 터치 이벤트 무시
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: _translatedLanguages.isNotEmpty
                  ? Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _translatedLanguages.map((language) =>
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFFF3E6C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            language,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                ).toList(),
              )
                  : Container(
                padding: const EdgeInsets.all(5),
                decoration: ShapeDecoration(
                  color: const Color(0xFFFF3E6C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text(
                      '언어 정보 없음',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 비디오 플레이어 위젯 구성
  Widget _buildVideoPlayer(String path, double width) {
    // 컨트롤러 없거나 초기화 안된 경우
    if (!_videoControllers.containsKey(path) ||
        !_videoControllers[path]!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // 비디오 플레이어 반환
    return SizedBox(
      width: width,
      height: 400,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoControllers[path]!.value.size.width,
          height: _videoControllers[path]!.value.size.height,
          child: VideoPlayer(_videoControllers[path]!),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pageController.dispose();

    // 비디오 컨트롤러 정리
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();

    super.dispose();
  }

  int _calculateAge(Map<String, dynamic> birthDate) {
    final now = DateTime.now();
    final birth = DateTime(
      birthDate['year'] as int? ?? 0,
      birthDate['month'] as int? ?? 0,
      birthDate['day'] as int? ?? 0,
    );

    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }
}