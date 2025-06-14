import 'package:flutter/material.dart';
import 'package:tripjoy/point_module/point_page.dart';

/// 채팅 포인트 관련 팝업 (포인트 부족, 차감 확인)
class ChatPointPopup extends StatelessWidget {
  final ChatPointPopupType type;
  final int requiredPoints;
  final int? currentPoints; // 포인트 부족 시에만 사용

  const ChatPointPopup({
    Key? key,
    required this.type,
    required this.requiredPoints,
    this.currentPoints,
  }) : super(key: key);

  // 숫자 포맷팅 (천 단위 콤마)
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isInsufficientPoints = type == ChatPointPopupType.insufficientPoints;
    final int shortagePoints = isInsufficientPoints && currentPoints != null
        ? requiredPoints - currentPoints!
        : 0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: const Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 아이콘
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isInsufficientPoints
                    ? Color(0xFFFFF5E5)
                    : Color(0xFFE8F2FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isInsufficientPoints
                    ? Icons.account_balance_wallet_outlined
                    : Icons.chat_bubble_outline,
                color: isInsufficientPoints
                    ? Color(0xFFFF9800)
                    : Color(0xFF237AFF),
                size: 32,
              ),
            ),
            SizedBox(height: 16),

            // 제목
            Text(
              isInsufficientPoints ? '포인트가 부족해요' : '채팅 시작하기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16),

            // 포인트 정보
            if (isInsufficientPoints) ...[
              // 포인트 부족 상황
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '필요 포인트',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                        Text(
                          '${_formatNumber(requiredPoints)}P',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '보유 포인트',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                        Text(
                          '${_formatNumber(currentPoints ?? 0)}P',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Color(0xFFE0E0E0)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '부족한 포인트',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_formatNumber(shortagePoints)}P',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF5252),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                '채팅을 시작하려면 포인트를 충전해주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
            ] else ...[
              // 포인트 차감 확인
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFFD6E9FF),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF237AFF),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${_formatNumber(requiredPoints)} 포인트가 차감됩니다',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF237AFF),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                '프렌즈와 채팅을 시작하시겠습니까?\n한 번 결제한 채팅방은 계속 사용할 수 있습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],

            SizedBox(height: 24),

            // 버튼 영역
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                // 왼쪽 버튼 (닫기/취소)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isInsufficientPoints ? '닫기' : '취소',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // 오른쪽 버튼 (충전하기/계속하기)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (isInsufficientPoints) {
                        Navigator.of(context).pop();
                        // 포인트 충전 페이지로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PointPage(),
                          ),
                        );
                      } else {
                        Navigator.of(context).pop(true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF237AFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isInsufficientPoints ? '포인트 충전' : '계속하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
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
}

// 팝업 타입 enum
enum ChatPointPopupType {
  insufficientPoints, // 포인트 부족
  pointDeduction,     // 포인트 차감 확인
}