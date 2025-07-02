// lib/point_module/widgets/point_usage_guide_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';

class PointUsageGuideWidget extends StatelessWidget {
  const PointUsageGuideWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: const Color(0xFFF9F9F9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '포인트 정책 안내',
            style: TextStyle(
              color: Color(0xFF4E5968),
              fontSize: 13,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildBulletPoint(
            '충전된 포인트는 모든 서비스에서 사용 가능합니다.',
          ),
          const SizedBox(height: 4),
          _buildBulletPointWithHighlight(
            '프렌즈 채팅 1회당 ',
            '1,300',
            '포인트 차감됩니다.',
          ),
          const SizedBox(height: 4),
          _buildBulletPointWithHighlight(
            '워크메이트 채용공고 15일 등록 시 ',
            '5,000',
            '포인트 차감됩니다.',
          ),
          const SizedBox(height: 4),
          _buildBulletPointWithHighlight(
            '현지톡톡에서 톡 메이트와 채팅 시 ',
            '1,300',
            '포인트 차감됩니다.',
          ),
          const SizedBox(height: 4),
          _buildBulletPointWithBracket(
            '서비스 이용에 따라 포인트가 자동 차감되며, 포인트 차감 내역은 ',
            '[내 포인트]',
            '에서 확인하실 수 있습니다.',
          ),
          const SizedBox(height: 20),
          const Text(
            '환불정책 안내',
            style: TextStyle(
              color: Color(0xFF4E5968),
              fontSize: 13,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildBulletPoint(
            '포인트 충전 후 앱 내에서 단 1회라도 사용 이력이 있을 경우, 부분 환불은 불가능합니다.',
          ),
          const SizedBox(height: 4),
          _buildBulletPoint(
            Platform.isIOS
                ? '환불을 원하실 경우, 애플 앱스토어를 통해 환불이 가능합니다.'
                : '환불을 원하실 경우, 구글 플레이스토어를 통해 환불이 가능합니다.',
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 12,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPointWithHighlight(String prefix, String highlight, String suffix) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: prefix,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: highlight,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: suffix,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPointWithBracket(String prefix, String bracket, String suffix) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: prefix,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: bracket,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: suffix,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}