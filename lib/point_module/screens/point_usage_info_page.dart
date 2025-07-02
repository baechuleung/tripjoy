// lib/point_module/screens/point_usage_info_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'point_page.dart';

class PointUsageInfoPage extends StatelessWidget {
  const PointUsageInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '포인트 이용안내',
          style: TextStyle(
            color: Color(0xFF353535),
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 상단 파란색 섹션
            Container(
              height: 136,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(color: Color(0xFF4977EE)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '트립조이 포인트 이용안내',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '트립조이에서 충전된 포인트는 앱 내 모든 서비스에서\n사용가능하며, 서비스 이용 시 포인트가 자동으로 차감됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // 신규 가입 혜택 섹션
            Container(
              height: 40,
              width: double.infinity,
              decoration: const BoxDecoration(color: Color(0xFF1A58F8)),
              child: const Center(
                child: Text(
                  '신규 가입시 3,000포인트 무료 적립!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // 하단 섹션
            Container(
              width: double.infinity,
              color: const Color(0xFF2D2D2D),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    '트립조이 포인트, 어디에 쓰이나요?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 서비스 카드
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/point/tripfriends.png',
                              width: 36,
                              height: 36,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '트립프렌즈',
                                    style: TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 13,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Text(
                                    '프렌즈 채팅 1회',
                                    style: TextStyle(
                                      color: Color(0xFF4E5968),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              '1,300 포인트',
                              style: TextStyle(
                                color: Color(0xFF353535),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Color(0xFFEEEEEE)),
                        ),
                        Row(
                          children: [
                            Image.asset(
                              'assets/point/workmate.png',
                              width: 36,
                              height: 36,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '워크메이트',
                                    style: TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 13,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '채용공고 등록 15일\n',
                                          style: TextStyle(
                                            color: Color(0xFF4E5968),
                                            fontSize: 14,
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '(인재 채팅 무료 3회)',
                                          style: TextStyle(
                                            color: Color(0xFF4E5968),
                                            fontSize: 12,
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              '5,000 포인트',
                              style: TextStyle(
                                color: Color(0xFF353535),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Color(0xFFEEEEEE)),
                        ),
                        Row(
                          children: [
                            Image.asset(
                              'assets/point/workmate_chat.png',
                              width: 36,
                              height: 36,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '워크메이트',
                                    style: TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 13,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Text(
                                    '인재 채팅 1회',
                                    style: TextStyle(
                                      color: Color(0xFF4E5968),
                                      fontSize: 14,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              '1,300 포인트',
                              style: TextStyle(
                                color: Color(0xFF353535),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 세로줄
                  Container(
                    height: 50,
                    width: 5,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    '포인트는 충전만 해야 하나요?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 좌우 2등분 박스
                  Row(
                    children: [
                      // 왼쪽 박스
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/point/point_write.png',
                                height: 60,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '실시간 톡톡',
                                style: TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 13,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '게시글 등록 시 100 P',
                                style: TextStyle(
                                  color: Color(0xFF353535),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '사건사고, 여행후기, 현지추천\n게시글 등록 시 포인트 적립!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF4E5968),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 오른쪽 박스
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/point/point_reply.png',
                                height: 60,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '실시간 톡톡',
                                style: TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 13,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '지식톡 채택 시 100 P',
                                style: TextStyle(
                                  color: Color(0xFF353535),
                                  fontSize: 14,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '지식톡 게시글에 댓글 작성 후\n작성자 채택 시 포인트 적립!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF4E5968),
                                  fontSize: 11,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '서비스 이용에 따라 포인트가 자동 차감되며, 포인트 차감 내역은 ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '메뉴>[보유 포인트]',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '에서 확인하실 수 있습니다.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // 충전하기 버튼
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF1A58F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Color(0x3F1A58F9),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PointPage(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: const Center(
                          child: Text(
                            '지금바로 포인트 충전하러가기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 안내사항
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBulletPoint(
                        '정책은 서비스 운영 상황에 따라 변경될 수 있으며, 변경 시 앱 내 공지 또는 푸시 알림을 통해 사전 안내해드립니다.',
                      ),
                      _buildBulletPoint(
                        '포인트 차감, 사용 범위, 유효 기간 등 은 트립조이 정책에 따라 수시로 조정될 수 있습니다.',
                      ),
                      _buildBulletPoint(
                        '포인트 부정 사용이 확인될 경우, 포인트 회수, 계정 이용 제한 또는 영구 정지 조치가 이루어질 수 있습니다',
                      ),
                      _buildBulletPoint(
                        Platform.isIOS
                            ? '환불은 애플 앱스토어를 통해 신청 가능하며, 트립조이 앱 내에서 포인트가 1회라도 사용된 경우, 전체 또는 부분 환불이 불가능합니다.'
                            : '환불은 구글 플레이스토어를 통해 신청 가능하며, 트립조이 앱 내에서 포인트가 1회라도 사용된 경우, 전체 또는 부분 환불이 불가능합니다.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem({
    required String icon,
    required String title,
    required String points,
  }) {
    return Row(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF353535),
              fontSize: 14,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
        Text(
          points,
          style: const TextStyle(
            color: Color(0xFF353535),
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w300,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w300,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}