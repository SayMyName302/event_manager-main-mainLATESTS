import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:event_manager/screens/admin.dart';
import 'package:event_manager/screens/adminPanel.dart';
import 'package:event_manager/screens/login_screen.dart';
import 'package:event_manager/screens/mainscreen.dart';
import 'package:event_manager/screens/signup_screen.dart';

class RouteHelper {
  static const String initRoute = "/";
  static const String login = "/login";
  static const String signup = "/signup";
  static const String mainscreen = "/mainscreen";
  static const String admin = "/admin";
  static const String adminPanel = "/adminpanel";

  static Map<String, WidgetBuilder> routes(BuildContext context) {
    return {
      initRoute: (context) => const LoginScreen(),
      login: (context) => const LoginScreen(),
      signup: (context) => const SignUpScreen(),
      admin: (context) => AdminPage(),
      mainscreen: (context) => HomeScreen(),
      adminPanel: (context) => AdminPanelScreen(),
    };
  }
}
