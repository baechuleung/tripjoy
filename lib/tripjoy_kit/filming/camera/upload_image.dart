import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tripjoy/loading_widgets/menu_loading_spinner.dart';
import '../translated_content/translated_content_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UploadImagePage extends StatefulWidget {
  final String imagePath;
  UploadImagePage({required this.imagePath});

  @override
  _UploadImagePageState createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  bool _isUploading = false;
  // API 키를 환경 변수에서 가져오기
  String get apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  String _extractedText = "";
  String _translatedText = "";

  @override
  void initState() {
    super.initState();
    _extractTextThenTranslate();
  }

  // 이미지에서 텍스트 추출 후 번역 시작
  void _extractTextThenTranslate() async {
    setState(() => _isUploading = true);

    try {
      // 1단계: gpt-4.1-mini로 이미지에서 텍스트 추출
      _extractedText = await _extractTextFromImage(widget.imagePath);

      if (_extractedText.isNotEmpty) {
        print("✅ 텍스트 추출 완료: $_extractedText");

        // 2단계: gpt-4.1-mini로 번역 시작
        _translatedText = await _translateText(_extractedText);

        if (_translatedText.isNotEmpty) {
          // UTF-8 인코딩 확인
          print("✅ 번역 완료: $_translatedText");

          // 번역이 완료되면 결과 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TranslatedContentPage(
                imagePath: widget.imagePath,
                translatedContent: _translatedText,
              ),
            ),
          );
        } else {
          setState(() => _isUploading = false);
          _showErrorMessage("텍스트를 번역할 수 없습니다.");
        }
      } else {
        setState(() => _isUploading = false);
        _showErrorMessage("이미지에서 텍스트를 추출할 수 없습니다.");
      }
    } catch (e) {
      print("❌ 처리 오류: $e");
      _showErrorMessage("처리 중 오류가 발생했습니다: $e");
      setState(() => _isUploading = false);
    }
  }

  // gpt-4.1-mini로 이미지에서 텍스트 추출
  Future<String> _extractTextFromImage(String imagePath) async {
    try {
      File imageFile = File(imagePath);
      List<int> imageBytes = imageFile.readAsBytesSync();
      String base64Image = base64Encode(imageBytes);

      final response = await http.post(
          Uri.parse("https://api.openai.com/v1/chat/completions"),
          headers: {
            "Authorization": "Bearer $apiKey",
            "Content-Type": "application/json; charset=utf-8"
          },
          body: jsonEncode({
            "model": "gpt-4.1-mini",
            "messages": [
              {"role": "system", "content": "이미지에서 텍스트만 추출해주세요. 원본 형식을 유지하고 추가적인 설명 없이 텍스트만 출력해주세요."},
              {"role": "user", "content": [
                {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image"}}
              ]}
            ]
          })
      );

      if (response.statusCode == 200) {
        // UTF-8 디코딩 명시
        final responseBody = utf8.decode(response.bodyBytes);
        final decodedResponse = jsonDecode(responseBody);
        final extractedText = decodedResponse["choices"][0]["message"]["content"];
        print("📄 OCR 추출된 텍스트: $extractedText");
        return extractedText;
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        print("❌ OCR 실패: $responseBody");
        _showErrorMessage("OCR 처리 중 오류 발생: ${response.statusCode}");
        return "";
      }
    } catch (e) {
      print("❌ OCR 요청 중 오류 발생: $e");
      _showErrorMessage("OCR 요청 중 오류 발생: $e");
      return "";
    }
  }

  // gpt-4.1-mini로 텍스트 번역 - UTF-8 인코딩 적용
  Future<String> _translateText(String text) async {
    try {
      final response = await http.post(
          Uri.parse("https://api.openai.com/v1/chat/completions"),
          headers: {
            "Authorization": "Bearer $apiKey",
            "Content-Type": "application/json; charset=utf-8"
          },
          body: jsonEncode({
            "model": "gpt-4.1-mini",
            "messages": [
              {"role": "system", "content": "한국어 번역가입니다. 입력된 텍스트를 한국어로 정확하게 번역해주세요. 설명이나 주석 없이 번역만 제공해주세요."},
              {"role": "user", "content": text}
            ]
          })
      );

      if (response.statusCode == 200) {
        // UTF-8 디코딩 명시
        final responseBody = utf8.decode(response.bodyBytes);
        final decodedResponse = jsonDecode(responseBody);
        final translatedText = decodedResponse["choices"][0]["message"]["content"];

        // UTF-8 인코딩 상태 디버깅
        Uint8List bytes = utf8.encode(translatedText);
        print("📄 번역된 텍스트 바이트: $bytes");
        print("📄 번역된 텍스트: $translatedText");

        return translatedText;
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        print("❌ 번역 실패: $responseBody");
        _showErrorMessage("번역 처리 중 오류 발생: ${response.statusCode}");
        return "";
      }
    } catch (e) {
      print("❌ 번역 요청 중 오류 발생: $e");
      _showErrorMessage("번역 요청 중 오류 발생: $e");
      return "";
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isUploading
            ? MenuLoadingSpinner()
            : Image.file(File(widget.imagePath), fit: BoxFit.cover),
      ),
    );
  }
}