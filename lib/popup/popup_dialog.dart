import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'popup_model.dart';

class PopupDialog extends StatelessWidget {
  final PopupModel popup;

  const PopupDialog({Key? key, required this.popup}) : super(key: key);

  Future<void> _setDoNotShowAgain() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'popup_do_not_show_${popup.id}';
    await prefs.setBool(key, true);
  }

  @override
  Widget build(BuildContext context) {
    print('🖼️ [PopupDialog] build 호출됨');
    print('🖼️ [PopupDialog] 이미지 URL: ${popup.imageUrl}');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 이미지 컨테이너
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: popup.imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  constraints: BoxConstraints(
                    minHeight: 100,
                    maxWidth: MediaQuery.of(context).size.width - 40,
                  ),
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  constraints: BoxConstraints(
                    minHeight: 100,
                    maxWidth: MediaQuery.of(context).size.width - 40,
                  ),
                  color: Colors.grey[200],
                  child: Icon(Icons.error),
                ),
              ),
            ),
          ),
          // 버튼 영역
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // 다시 보지 않기 버튼
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      await _setDoNotShowAgain();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '다시 보지 않기',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          height: 1.50,
                        ),
                      ),
                    ),
                  ),
                ),
                // 구분선
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withOpacity(0.3),
                ),
                // 확인 버튼
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '네, 확인했어요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          height: 1.50,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}