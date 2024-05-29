import 'package:event_manager/components/provider.dart';
import 'package:event_manager/screens/adminPanel.dart';

import 'package:event_manager/screens/login_screen.dart';
import 'package:event_manager/screens/mainscreen.dart';
import 'package:event_manager/screens/viewEvents.dart';
import 'package:event_manager/shared/notificationservice.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared/routes.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  _firebaseMessaging.requestPermission(
    alert: true,
    badge: true,
    provisional: false,
    sound: true,
  );
  _firebaseMessaging.getToken().then((token) {
    print("FCM Token: $token");
  });
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Message received: ${message.notification?.title}");
  });
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserData(),
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      child: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // or a loading indicator
          } else {
            final isLoggedIn = snapshot.data ?? false;
            return MaterialApp(
              home: isLoggedIn ? AdminPanelScreen() : HomeScreen(),
              theme: ThemeData(
                textTheme: const TextTheme(
                  bodyMedium: TextStyle(
                    fontFamily: 'Ubuntu',
                  ),
                ),
              ),
              debugShowCheckedModeBanner: false,
              // routes: RouteHelper.routes(context),
            );
          }
        },
      ),
    );
  }

  Future<bool> _isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}
