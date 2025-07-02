import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ProfileUpdateDialog extends StatefulWidget {
  final VoidCallback onProfileUpdated;

  ProfileUpdateDialog({required this.onProfileUpdated});

  @override
  _ProfileUpdateDialogState createState() => _ProfileUpdateDialogState();
}

class _ProfileUpdateDialogState extends State<ProfileUpdateDialog> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isLocalImageLoading = false;
  String? _photoUrl;
  File? _localImage;

  @override
  void initState() {
    super.initState();
    _nameController.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
    _photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
  }

  // 이미지 리사이징 함수
  Future<File> _resizeImage(File imageFile) async {
    // image 패키지를 사용하여 이미지 리사이징
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) return imageFile;

    // 가로 300px로 리사이징 (비율 유지)
    final targetWidth = 300;
    final targetHeight = (image.height * targetWidth) ~/ image.width;

    final resizedImage = img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );

    // 임시 파일로 저장
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final tempFile = File(tempPath);

    // JPEG 품질 90%로 저장 (추가 압축)
    await tempFile.writeAsBytes(img.encodeJpg(resizedImage, quality: 90));

    return tempFile;
  }

  Future<void> _pickImage() async {
    try {
      setState(() {
        _isLocalImageLoading = true;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        // 이미지 픽커에서 기본 퀄리티를 낮춤
        imageQuality: 80,
      );

      if (image == null) {
        setState(() {
          _isLocalImageLoading = false;
        });
        return;
      }

      final imageFile = File(image.path);

      // 이미지 리사이징
      final resizedImage = await _resizeImage(imageFile);

      setState(() {
        _localImage = resizedImage;
        _isLocalImageLoading = false;
      });
    } catch (e) {
      print('이미지 선택 및 처리 오류: $e');
      setState(() {
        _isLocalImageLoading = false;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_localImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 고정된 파일 이름 사용 (사용자당 하나의 프로필 이미지만 저장)
      String fileName = 'profile.jpg';
      Reference storageRef = FirebaseStorage.instanceFor(
          bucket: 'gs://tripjoy-d309f.firebasestorage.app'
      ).ref()
          .child('profile_images')
          .child(user.uid)
          .child(fileName);

      // 기존 이미지가 있다면 삭제
      try {
        await storageRef.delete();
        print('기존 프로필 이미지 삭제 완료');
      } catch (e) {
        print('기존 이미지가 없거나 삭제 중 오류: $e');
        // 처음 업로드하는 경우 이미지가 없으므로 오류는 무시
      }

      // Firebase Storage 업로드 설정 (추가 압축)
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'resized': 'true'},
      );

      // 새 이미지 업로드
      final uploadTask = storageRef.putFile(_localImage!, metadata);
      final downloadUrl = await (await uploadTask).ref.getDownloadURL();

      await Future.wait([
        user.updateProfile(photoURL: downloadUrl),
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'photoUrl': downloadUrl})
      ]);

      _photoUrl = downloadUrl;

    } catch (e) {
      print('이미지 업로드 오류: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    String newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 이름 업데이트
        await user.updateDisplayName(newName);

        // Firestore 업데이트 준비
        Map<String, dynamic> updateData = {
          'name': newName,
        };

        // 이미지 업로드가 필요한 경우
        if (_localImage != null) {
          await _uploadImage();
          if (_photoUrl != null) {
            updateData['photoUrl'] = _photoUrl;
          }
        }

        // Firestore 업데이트
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(updateData);

        widget.onProfileUpdated();
      }
    } catch (e) {
      print('프로필 업데이트 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      backgroundColor: Colors.white,
      child: SizedBox(
        height: 300,
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                      child: Text(
                        '프로필 수정',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Center(
                      child: GestureDetector(
                        onTap: _isLocalImageLoading ? null : _pickImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 이미지 표시
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _isLocalImageLoading ? null : _getProfileImage(),
                              child: _isLocalImageLoading
                                  ? null  // 로딩 중에는 child가 필요하지 않음
                                  : _getProfileImageChild(),
                            ),

                            // 로컬 이미지 로딩 중일 때 로딩 스피너 표시
                            if (_isLocalImageLoading)
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              )
                            // 로딩 중이 아닐 때 호버 효과용 반투명 오버레이와 카메라 아이콘
                            else
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                                child: _isLoading
                                    ? CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                )
                                    : Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    Center(
                      child: Container(
                        width: 300,
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            TextField(
                              controller: _nameController,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: '이름을 입력하세요',
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                                ),
                              ),
                            ),
                            if (_nameController.text.isNotEmpty)
                              Positioned(
                                right: 0,
                                child: IconButton(
                                  icon: Image.asset(
                                    'assets/side/cancel.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _nameController.clear();
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Center(
                      child: Text(
                        '특수문자/특수기호는 사용할 수 없습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                  ],
                ),
              ),
            ),
            Container(
              height: 1,
              color: Color(0xFFD9D9D9),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      '취소',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: Color(0xFFD9D9D9),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: (_isLoading || _isLocalImageLoading) ? null : _updateProfile,
                    child: _isLoading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007CFF)),
                      ),
                    )
                        : Text(
                      '수정완료',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF007CFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 이미지 소스를 결정하는 함수
  ImageProvider? _getProfileImage() {
    if (_localImage != null) {
      return FileImage(_localImage!);
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return NetworkImage(_photoUrl!);
    }
    return null;
  }

  // 이미지가 없을 때 표시할 위젯을 결정하는 함수
  Widget? _getProfileImageChild() {
    // 로컬 이미지나 네트워크 이미지가 있으면 null 반환 (CircleAvatar의 backgroundImage가 표시됨)
    if (_localImage != null || (_photoUrl != null && _photoUrl!.isNotEmpty)) {
      return null;
    }
    // 이미지가 없으면 기본 아이콘 표시
    return Icon(
      Icons.person,
      size: 40,
      color: Colors.grey[400],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}