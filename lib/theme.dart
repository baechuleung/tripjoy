import 'package:flutter/material.dart';
import 'package:tripjoy/loading_widgets/loading_spinner.dart';

final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: Colors.white,
  fontFamily: "Pretendard",
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    scrolledUnderElevation: 0,
    titleSpacing: 0,
  ),
  cardColor: Colors.white,
  dialogBackgroundColor: Colors.white,
  canvasColor: Colors.white,
  primaryColor: Colors.white,

  // 로딩 스피너 테마 추가
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Colors.blue,
    linearTrackColor: Colors.transparent,
  ),

  listTileTheme: const ListTileThemeData(
    selectedColor: Colors.black,
    selectedTileColor: Colors.transparent,
    tileColor: Colors.white,
    enableFeedback: false,
  ),
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
  splashColor: Colors.transparent,

  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      overlayColor: MaterialStateProperty.all(Colors.transparent),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      overlayColor: MaterialStateProperty.all(Colors.transparent),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      overlayColor: MaterialStateProperty.all(Colors.transparent),
    ),
  ),

  buttonTheme: const ButtonThemeData(
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  ),
);

// 로딩 스피너를 모든 ProgressIndicator로 대체하는 함수
Widget loadingSpinnerBuilder(BuildContext context, Widget? child) {
  return child is CircularProgressIndicator || child is LinearProgressIndicator
      ? const LoadingSpinner()
      : child ?? const SizedBox.shrink();
}
