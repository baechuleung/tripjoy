import 'package:flutter/material.dart';
import '../../services/translation_service.dart';
import 'services/reservation_service.dart';
import 'reservation_info_section.dart';
import 'payment_amount_section.dart';
import 'widgets/agreement_checkbox_widget.dart';
import 'dart:async';
import 'package:tripjoy/components/side_drawer/mypage/reservation/reservation_page.dart';

class ReservationPage extends StatefulWidget {
  final String reservationId;
  final String friendsId;
  final Map<String, dynamic> reservationData;
  final String userId;
  final String requestId;

  const ReservationPage({
    super.key,
    required this.reservationId,
    required this.friendsId,
    required this.reservationData,
    required this.userId,
    required this.requestId,
  });

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final TranslationService _translationService = TranslationService();
  final ReservationService _reservationService = ReservationService();

  bool _isLoading = true;
  bool _isAllChecked = false;
  Map<String, dynamic>? _reservationData;

  // 필수 입력 및 동의 상태 관리
  bool _needLocationInput = false;
  bool _needDateInput = false;
  bool _needPersonInput = false;
  bool _needPurposeInput = false;
  bool _isPaymentAgreed = false;
  bool _isProhibitionAgreed = false;
  bool _isReviewAgreed = false;

  // 체크박스 위젯 참조
  final GlobalKey<AgreementCheckboxWidgetState> _checkboxKey = GlobalKey<AgreementCheckboxWidgetState>();

  @override
  void initState() {
    super.initState();
    // 초기값 설정 - widget의 데이터로 초기화
    _reservationData = Map<String, dynamic>.from(widget.reservationData);
    _loadData();
    _loadTranslations();
  }

  // 데이터 로드 및 초기화
  Future<void> _loadData() async {
    try {
      // plan_requests에서 데이터 로드
      final requestData = await _reservationService.loadRequestData(
          widget.userId,
          widget.requestId
      );

      // 예약 데이터 준비
      final preparedData = _reservationService.prepareReservationData(
        reservationData: widget.reservationData,
        requestData: requestData,
        userId: widget.userId,
        requestId: widget.requestId,
      );

      if (mounted) {
        setState(() {
          _reservationData = preparedData;
          // 필수 입력 필드 확인
          _updateRequiredInputFlags();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('데이터 로드 중 오류: $e');
      if (mounted) {
        setState(() {
          _needLocationInput = true;
          _needDateInput = true;
          _needPersonInput = true;
          _needPurposeInput = true;
          _isLoading = false;
        });
      }
    }
  }

  // 필수 입력 필드 상태 업데이트
  void _updateRequiredInputFlags() {
    if (_reservationData == null) return;

    final bool locationEmpty = _reservationService.isMeetingPlaceEmpty(_reservationData!);

    // 예약일시 확인
    final bool dateEmpty = !_reservationData!.containsKey('useDate') ||
        _reservationData!['useDate'] == null ||
        _reservationData!['useDate'].toString().isEmpty;

    // 예약인원 확인
    final bool personEmpty = !_reservationData!.containsKey('personCount') ||
        _reservationData!['personCount'] == null ||
        _reservationData!['personCount'] <= 0;

    // 이용목적 확인
    final bool purposeEmpty = _reservationService.isPurposeEmpty(_reservationData!);

    print("필드 상태 체크: meetingPlace=$locationEmpty, useDate=$dateEmpty, personCount=$personEmpty, purpose=$purposeEmpty");

    setState(() {
      _needLocationInput = locationEmpty;
      _needDateInput = dateEmpty;
      _needPersonInput = personEmpty;
      _needPurposeInput = purposeEmpty;
    });
  }

  // UI 상태 업데이트 콜백 (ReservationInfoSection에서 호출)
  void _updateUIState() {
    if (_reservationData == null) return;

    setState(() {
      _needLocationInput = _reservationService.isMeetingPlaceEmpty(_reservationData!);

      // 예약일시 확인
      _needDateInput = !_reservationData!.containsKey('useDate') ||
          _reservationData!['useDate'] == null ||
          _reservationData!['useDate'].toString().isEmpty;

      // 예약인원 확인
      _needPersonInput = !_reservationData!.containsKey('personCount') ||
          _reservationData!['personCount'] == null ||
          _reservationData!['personCount'] <= 0;

      // 이용목적 확인
      _needPurposeInput = _reservationService.isPurposeEmpty(_reservationData!);
    });

    print("UI 상태 업데이트: meetingPlace=${_needLocationInput}, useDate=${_needDateInput}, personCount=${_needPersonInput}, purpose=${_needPurposeInput}");
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadTranslations() async {
    await _translationService.loadTranslations();
    if (mounted && _isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 동의 상태 확인
  void _updateAgreementStatus() {
    final checkboxState = _checkboxKey.currentState;
    if (checkboxState != null) {
      setState(() {
        _isPaymentAgreed = checkboxState.isPaymentAgreed;
        _isProhibitionAgreed = checkboxState.isProhibitionAgreed;
        _isReviewAgreed = checkboxState.isReviewAgreed;
      });
    }
  }

  // 전체 동의 상태 변경 핸들러
  void _onAllAgreementChanged(bool value) {
    setState(() {
      _isAllChecked = value;
      // 상태 업데이트
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateAgreementStatus();
      });
    });
  }

  // 예약 처리 함수
  Future<void> _processReservation() async {
    // 데이터가 없으면 처리하지 않음
    if (_reservationData == null) {
      print("예약 데이터가 없어 처리할 수 없습니다.");
      if (context.mounted) {
        _reservationService.showErrorDialog(context);
      }
      return;
    }

    // 동의 상태 업데이트
    _updateAgreementStatus();

    // 현재 데이터 상태 로그
    print("예약 처리 시작");
    print("저장될 예약 데이터: $_reservationData");
    print("약속장소: ${_reservationData!['meetingPlace']}");
    print("예약일시: ${_reservationData!['useDate']}");
    print("예약인원: ${_reservationData!['personCount']}");
    print("동의 상태 - 현장결제: $_isPaymentAgreed, 금지행위: $_isProhibitionAgreed, 리뷰약속: $_isReviewAgreed");

    // 필수 정보 확인
    if (_needLocationInput || _needDateInput || _needPersonInput || _needPurposeInput) {
      String missingInfo = "";
      if (_needLocationInput) missingInfo += "약속장소, ";
      if (_needDateInput) missingInfo += "예약일시, ";
      if (_needPersonInput) missingInfo += "예약인원, ";
      if (_needPurposeInput) missingInfo += "이용목적, ";

      if (missingInfo.isNotEmpty) {
        missingInfo = missingInfo.substring(0, missingInfo.length - 2); // 마지막 쉼표와 공백 제거
      }

      print("필수 정보 누락됨: $missingInfo");

      // 누락된 정보 안내 팝업
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('필수 정보 누락'),
            content: Text('예약을 신청하기 전에 $missingInfo을(를) 입력해주세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text('확인'),
              ),
            ],
          );
        },
      );
      return;
    }

    // 확인 팝업창 표시
    // 확인 팝업창 표시
    _reservationService.showConfirmationDialog(context, () async {
      try {
        // 필수 동의 항목 검증
        bool agreementsValid = _reservationService.validateAgreements(
            _isPaymentAgreed,
            _isProhibitionAgreed
        );

        if (!agreementsValid) {
          if (context.mounted) {
            _reservationService.showErrorDialog(context);
          }
          return;
        }

        // 예약 생성 요청
        final result = await _reservationService.createReservation(
          friendsId: widget.friendsId,
          reservationData: _reservationData!,
          isPaymentAgreed: _isPaymentAgreed,
          isProhibitionAgreed: _isProhibitionAgreed,
          isReviewPromised: _isReviewAgreed,
        );

        bool isSuccess = result.reservationId.isNotEmpty;

        print("예약 처리 결과: $isSuccess");

        // 컨텍스트가 유효한지 확인
        if (context.mounted) {
          if (isSuccess) {
            // 예약 완료 후 예약 페이지로 이동 (CurrentReservationDetail 대신)
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/', // 홈 화면으로 이동
                  (route) => false,
            );

            // 예약 목록 페이지로 이동하고 진행 중인 예약 탭 선택
            Navigator.pushNamed(
              context,
              '/reservation',
              arguments: {'tabIndex': 0}, // 진행 중인 예약 탭 선택
            );
          } else {
            // 오류 다이얼로그 표시
            _reservationService.showErrorDialog(context);
          }
        }
      } catch (e) {
        print('예약 처리 중 오류: $e');
        if (context.mounted) {
          _reservationService.showErrorDialog(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _reservationData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('예약 신청'),
          backgroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          '예약 신청',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 예약 정보 섹션
              ReservationInfoSection(
                reservationData: _reservationData!,
                reservationService: _reservationService,
                onUpdateUI: _updateUIState,
                needLocationInput: _needLocationInput,
                userId: widget.userId,
                requestId: widget.requestId,
              ),
              const SizedBox(height: 16),

              // 결제 금액 섹션
              PaymentAmountSection(
                onSiteAmount: 0, // 서버측에서 계산하므로 수정 안함
                reservationService: _reservationService,
                reservationData: _reservationData!,
              ),
              const SizedBox(height: 16),
              // 동의 체크박스 섹션 추가
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: AgreementCheckboxWidget(
                  key: _checkboxKey,
                  isChecked: _isAllChecked,
                  onChanged: _onAllAgreementChanged,
                ),
              ),
            ],
          ),
        ),
      ),
      // 예약하기 버튼 섹션
      bottomNavigationBar: _buildReservationButton(),
    );
  }

  // 예약하기 버튼
  Widget _buildReservationButton() {
    // 버튼 활성화 전에 상태 업데이트
    _updateAgreementStatus();

    // 버튼 활성화 조건: 위치, 날짜, 인원, 이용목적 입력 완료와 필수 동의 항목 체크
    bool isButtonEnabled = !_needLocationInput && !_needDateInput && !_needPersonInput &&
        !_needPurposeInput && _isPaymentAgreed && _isProhibitionAgreed;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      child: ElevatedButton(
        onPressed: isButtonEnabled ? _processReservation : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isButtonEnabled
              ? const Color(0xFF237AFF)
              : const Color(0xFFCCCCCC),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: const Text(
          '예약 신청하기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}