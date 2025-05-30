import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 폰트 색상을 아주 연한 회색으로 변경
    const TextStyle footerTextStyle = TextStyle(
      color: Color(0xFFD0D0D0), // 기존 Color(0xFFFFFFFF)에서 아주 연한 회색으로 변경
      fontSize: 8,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      // color: Colors.white 제거됨
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '(주)리프컴퍼니',
            style: footerTextStyle,
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: footerTextStyle,
              children: [
                TextSpan(text: 'CEO 박상호, '),
                TextSpan(text: 'CTO 배철응, '),
                TextSpan(text: 'CDO 정윤우'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '사업자 등록번호 413-87-02826',
            style: footerTextStyle,
          ),
          const Text(
            '통신판매업 신고번호 제 2024-서울광진-1870 호',
            style: footerTextStyle,
          ),
          const Text(
            '관광사업자 등록번호 제2024-000022호(종합여행업)',
            style: footerTextStyle,
          ),
          const Text(
            '서울특별시 광진구 아차산로62길 14-12 202호(구의동, 대영트윈,투)',
            style: footerTextStyle,
          ),
          const SizedBox(height: 12),
          const Text(
            '(주)리프컴퍼니는 통신판매중개자로서 통신판매의 당사자가 아니며\n상품 거래정보 및 거래 등에 대해 책임을 지지 않습니다.',
            style: footerTextStyle,
          ),
        ],
      ),
    );
  }
}