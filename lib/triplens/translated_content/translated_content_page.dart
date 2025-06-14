import 'dart:io';
import 'package:flutter/material.dart';
import '../camera/camera_page.dart'; // CameraPage import

class TranslatedContentPage extends StatefulWidget {
  final String imagePath; // 저장된 이미지 경로
  final String translatedContent; // 서버로부터 가져온 번역된 텍스트

  TranslatedContentPage({required this.imagePath, required this.translatedContent});

  @override
  _TranslatedContentPageState createState() => _TranslatedContentPageState();
}

class _TranslatedContentPageState extends State<TranslatedContentPage> {
  double _containerHeight = 0.5; // 텍스트 박스의 초기 높이 (화면의 50%)

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CameraPage()),
        );
        return false; // 현재 화면을 닫지 않도록 false 반환
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,  // 흰색 배경 추가
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => CameraPage()),
              );
            },
          ),
          title: Text(
            '문서번역',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,  // 타이틀 중앙 정렬
          elevation: 0,  // 그림자 제거
        ),
        body: Stack(
          children: [
            // 이미지가 화면의 상단에 위치하도록 배치
            Positioned.fill(
              child: Column(
                children: [
                  // 원본 크기로 이미지를 보여줌
                  Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.contain, // 원본 비율 유지
                    width: double.infinity,
                  ),
                ],
              ),
            ),
            // 텍스트를 포함한 박스가 이미지와 정확히 겹치도록 배치
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _containerHeight -= details.primaryDelta! / MediaQuery.of(context).size.height;
                    if (_containerHeight < 0.2) _containerHeight = 0.2; // 최소 높이
                    if (_containerHeight > 0.8) _containerHeight = 0.8; // 최대 높이
                  });
                },
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * _containerHeight, // 조정 가능한 높이
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        spreadRadius: 1,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 사용자가 박스를 드래그할 수 있다는 것을 인식시키기 위한 상단 바
                      Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 40.0, // 텍스트와 북마크 사이 간격
                            left: 16.0,
                            right: 16.0,
                            bottom: 16.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start, // 텍스트 왼쪽 정렬
                            children: [
                              // 번역된 언어 타이틀
                              Stack(
                                clipBehavior: Clip.none, // 위젯이 부모의 영역을 넘어설 수 있도록 함
                                children: [
                                  Positioned(
                                    left: 16.0, // 왼쪽 여백 조정
                                    top: -40.0, // 북마크가 텍스트 박스의 상단 끝에 맞도록 조정
                                    child: Image.asset(
                                      'assets/tripjoy_kit/bookmark.png',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  // 번역된 언어 텍스트와 닫기 버튼을 같은 라인에 배치
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10.0, top: 10.0), // 북마크와 텍스트의 간격 추가 및 텍스트 위치 조정
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '번역된 언어',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.close),
                                          onPressed: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(builder: (context) => CameraPage()),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20), // '번역된 언어'와 번역된 내용 사이의 간격 추가
                              // 번역된 내용
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    widget.translatedContent.isNotEmpty ? widget.translatedContent : "번역된 내용이 없습니다.",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.start, // 왼쪽 정렬
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
