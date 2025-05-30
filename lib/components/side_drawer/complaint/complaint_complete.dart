import 'package:flutter/material.dart';

class ComplaintComplete extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  ComplaintComplete({required this.onCancel, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20),
          Image.asset(
            'assets/side/warning.png',
            width: 30,
            height: 30,
          ),
          SizedBox(height: 5),
          Text(
            '신고접수를 완료하시겠습니까?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 30),
          Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onCancel,
                  child: Text(
                    '취소',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 55,
                color: Color(0xFFD9D9D9),
              ),
              Expanded(
                child: TextButton(
                  onPressed: onConfirm,
                  child: Text(
                    '완료',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF007CFF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
