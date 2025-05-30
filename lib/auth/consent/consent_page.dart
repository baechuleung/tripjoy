import 'package:flutter/material.dart';
import '../../term/term_service.dart';
import '../../term/term_privacy.dart';
import '../../term/term_third_party.dart';
import '../../term/term_location.dart';
import '../../term/term_marketing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../sign_up_complete_screen.dart';

class ConsentPage extends StatefulWidget {
  final UserCredential userCredential;
  final String displayName;
  final String email;
  final String photoUrl;
  final String loginType;
  final String fcmToken;  // FCM 토큰 추가

  const ConsentPage({
    Key? key,
    required this.userCredential,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.loginType,
    required this.fcmToken,  // FCM 토큰 추가
  }) : super(key: key);

  _ConsentPageState createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool termsOfServiceConsent = false;
  bool personalInfoConsent = false;
  bool thirdPartyConsent = false;
  bool locationInfoConsent = false;
  bool marketingConsent = false;
  bool allConsents = false;

  bool get allRequiredConsentsAccepted =>
      termsOfServiceConsent && personalInfoConsent && thirdPartyConsent &&
          locationInfoConsent;

  void updateAllConsents(bool value) {
    setState(() {
      allConsents = value;
      termsOfServiceConsent = personalInfoConsent = thirdPartyConsent =
          locationInfoConsent = marketingConsent = value;
    });
  }

  void updateConsent(bool value, String type) {
    setState(() {
      switch (type) {
        case 'terms':
          termsOfServiceConsent = value;
          break;
        case 'personal':
          personalInfoConsent = value;
          break;
        case 'thirdParty':
          thirdPartyConsent = value;
          break;
        case 'location':
          locationInfoConsent = value;
          break;
        case 'marketing':
          marketingConsent = value;
          break;
      }
      if (!value) allConsents = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '이용약관',
          style: TextStyle(color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: '반갑습니다!\n',
                                style: TextStyle(color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500),
                              ),
                              TextSpan(
                                text: widget.displayName,
                                style: const TextStyle(color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700),
                              ),
                              const TextSpan(
                                text: ' 사용을 위한\n동의가 필요합니다.',
                                style: TextStyle(color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        buildAllConsentsBox('모든 약관에 동의합니다', allConsents, (
                            value) => updateAllConsents(value!)),
                        const SizedBox(height: 20),
                        Expanded(
                          child: buildConsentList(),
                        ),
                        const SizedBox(height: 20),
                        // Container 부분만 수정
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          height: 55,
                          decoration: ShapeDecoration(
                            color: const Color(0xFF7269F7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: TextButton(
                            onPressed: allRequiredConsentsAccepted
                                ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignUpCompleteScreen(
                                    personalInfoConsent: personalInfoConsent,
                                    locationInfoConsent: locationInfoConsent,
                                    termsOfServiceConsent: termsOfServiceConsent,
                                    thirdPartyConsent: thirdPartyConsent,
                                    marketingConsent: marketingConsent,
                                    userCredential: widget.userCredential,
                                    displayName: widget.displayName,
                                    email: widget.email,
                                    photoUrl: widget.photoUrl,
                                    loginType: widget.loginType,
                                    fcmToken: widget.fcmToken,  // FCM 토큰 전달
                                  ),
                                ),
                              );
                            }
                                : null,
                            child: const Text(
                              '동의합니다',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ... rest of the widget building methods remain the same ...
  Widget buildAllConsentsBox(String title, bool value,
      Function(bool?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          width: 1,
          color: const Color(0xFFD0D0D0),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: value ? const Color(0xFF7269F7) : Colors.grey
                    .withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.check,
              size: 20,
              color: value ? const Color(0xFF7269F7) : Colors.grey.withOpacity(
                  0.3),
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget buildConsentList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () =>
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TermServicePage(),
                ),
              ),
          child: buildCustomCheckbox(
              '[필수]서비스 이용약관',
              termsOfServiceConsent,
                  (value) => updateConsent(value!, 'terms')
          ),
        ),
        GestureDetector(
          onTap: () =>
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TermPrivacyPage(),
                ),
              ),
          child: buildCustomCheckbox(
              '[필수]개인정보수집/이용동의',
              personalInfoConsent,
                  (value) => updateConsent(value!, 'personal')
          ),
        ),
        GestureDetector(
          onTap: () =>
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TermThirdPartyPage(),
                ),
              ),
          child: buildCustomCheckbox(
              '[필수]개인정보 제3자 정보제공 동의',
              thirdPartyConsent,
                  (value) => updateConsent(value!, 'thirdParty')
          ),
        ),
        GestureDetector(
          onTap: () =>
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TermLocationPage(),
                ),
              ),
          child: buildCustomCheckbox(
              '[필수]위치기반 서비스 이용약관 동의',
              locationInfoConsent,
                  (value) => updateConsent(value!, 'location')
          ),
        ),
        GestureDetector(
          onTap: () =>
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TermMarketingPage(),
                ),
              ),
          child: buildCustomCheckbox(
              '[선택]마케팅 활용 동의',
              marketingConsent,
                  (value) => updateConsent(value!, 'marketing')
          ),
        ),
      ],
    );
  }

  Widget buildCustomCheckbox(String title, bool value,
      Function(bool?) onChanged) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -4),
        leading: GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: value ? const Color(0xFF7269F7) : Colors.grey
                    .withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.check,
              size: 16,
              color: value ? const Color(0xFF7269F7) : Colors.grey.withOpacity(
                  0.3),
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}