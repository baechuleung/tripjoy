import 'package:flutter/material.dart';
import 'screens/main_page.dart';
import 'auth/login_selection/login_selection_screen.dart';

Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => MainPage(),
  '/auth/login': (context) => LoginSelectionScreen(),
};