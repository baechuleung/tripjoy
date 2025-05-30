

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddressInputPage extends StatelessWidget {
  final String initialAddress;
  final TextEditingController _controller;

  AddressInputPage({required this.initialAddress})
      : _controller = TextEditingController(text: initialAddress);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Scaffold 배경을 흰색으로 설정
      appBar: AppBar(
        title: Text('주소 입력'),
        backgroundColor: Colors.white, // AppBar 배경을 흰색으로 설정
        elevation: 0, // AppBar 그림자를 제거해 깔끔한 디자인
        systemOverlayStyle: SystemUiOverlayStyle.dark, // 상태 표시줄 아이콘을 검은색으로 설정
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "주소를 입력하세요",
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _controller.text),
              child: Text("저장"),
            ),
          ],
        ),
      ),
    );
  }
}
