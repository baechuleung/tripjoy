import 'package:flutter/material.dart';

// 베이스 다이얼로그 클래스 - 공통 UI 요소
class AgreementDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback onAgree;

  const AgreementDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onAgree,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // 내용
            Flexible(
              child: SingleChildScrollView(
                child: content,
              ),
            ),
            const SizedBox(height: 16),

            // 버튼 영역
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 취소 버튼
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFEEEEEE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 동의 버튼
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      onAgree();
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF4C6FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '동의',
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

// 1. 현장결제 안내 동의 다이얼로그
class PaymentAgreementDialog extends StatelessWidget {
  final VoidCallback onAgree;

  const PaymentAgreementDialog({
    super.key,
    required this.onAgree,
  });

  @override
  Widget build(BuildContext context) {
    return AgreementDialog(
      title: '현장 결제 안내 동의',
      content: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '어행자는 프렌즈(동행인)와 동행 종료 후, 현장에서 직접 현금으로 활동비를 정산합니다.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          SizedBox(height: 8),
          Text(
            '활동비는 프렌즈가 설정한 기본요금 및 이용 시간에 따라 추가 요금을 기준으로 계산됩니다.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          SizedBox(height: 8),
          Text(
            '트립조이는 결제 과정에 개입하지 않으며, 별도의 영수증 발급 의무가 없습니다.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          SizedBox(height: 8),
          Text(
            '※ 활동 시작 전, 예상 이용 시간과 금액을 꼭 확인해 주세요.',
            style: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      onAgree: onAgree,
    );
  }
}

// 2. 금지 행위 안내 동의 다이얼로그
class ProhibitionAgreementDialog extends StatelessWidget {
  final VoidCallback onAgree;

  const ProhibitionAgreementDialog({
    super.key,
    required this.onAgree,
  });

  @override
  Widget build(BuildContext context) {
    return AgreementDialog(
      title: '금지 행위 안내 동의',
      content: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '트립조이는 건전하고 안전한 동행 서비스를 지향합니다.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          SizedBox(height: 8),
          Text(
            '다음과 같은 행위는 엄격히 금지되며, 위반 시 별도 경고 없이 서비스 이용 제한 및 법적 조치가 이루어질 수 있습니다.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          SizedBox(height: 16),
          Text(
            '[성적 언어 행동 및 신체 접촉]',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            '성희롱, 성추행 등 성적 불쾌감을 유발하는 모든 발언 및 행동, 동의 없는 신체 접촉, 스킨십 요청',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          SizedBox(height: 8),
          Text(
            '[욕설 및 폭언]',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            '상대방에게 불쾌감을 주는 욕설, 비속어, 고압적 위협적 언행 사용',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          SizedBox(height: 8),
          Text(
            '[무리한 동행 연장 및 부당 요청]',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            '사전 약속 범위를 초과하는 강요, 금전, 선물 등을 통한 사적 거래 요청',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          SizedBox(height: 8),
          Text(
            '[개인정보 요구 및 사적 연락 시도]',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            '연락처, 소셜미디어 계정 등 개인정보 요구 또는 사적 만남 요청',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          SizedBox(height: 16),
          Text(
            '※ 위 금지 행위 위반 시, 트립조이는 사전 통보 없이 서비스 이용 제한 및 관련 법령에 따른 조치를 진행할 수 있습니다.',
            style: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      onAgree: onAgree,
    );
  }
}

// 3. 리뷰 약속 동의 다이얼로그
class ReviewAgreementDialog extends StatelessWidget {
  final VoidCallback onAgree;

  const ReviewAgreementDialog({
    super.key,
    required this.onAgree,
  });

  @override
  Widget build(BuildContext context) {
    return AgreementDialog(
      title: '프렌즈 이용 후 리뷰 작성 약속 동의',
      content: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '더 좋은 서비스를 만들기 위해, 이용 종료 후 간단한 리뷰 작성을 부탁드립니다.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          SizedBox(height: 8),
          Text(
            '리뷰는 서비스 품질 개선과 프렌즈 활동 데이터에 큰 도움이 됩니다.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          SizedBox(height: 8),
          Text(
            '*리뷰 작성은 자율이며, 미작성 시 별도의 불이익은 없습니다.',
            style: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      onAgree: onAgree,
    );
  }
}

// 다이얼로그 표시 함수들
void showPaymentAgreementDialog(BuildContext context, Function(bool) onChanged) {
  showDialog(
    context: context,
    builder: (context) => PaymentAgreementDialog(
      onAgree: () => onChanged(true),
    ),
  );
}

void showProhibitionAgreementDialog(BuildContext context, Function(bool) onChanged) {
  showDialog(
    context: context,
    builder: (context) => ProhibitionAgreementDialog(
      onAgree: () => onChanged(true),
    ),
  );
}

void showReviewAgreementDialog(BuildContext context, Function(bool) onChanged) {
  showDialog(
    context: context,
    builder: (context) => ReviewAgreementDialog(
      onAgree: () => onChanged(true),
    ),
  );
}