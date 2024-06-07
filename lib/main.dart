import 'package:event_manager/components/LoadingWidget.dart';
import 'package:event_manager/components/bottomNavProvider.dart';
import 'package:event_manager/components/provider.dart';
import 'package:event_manager/screens/adminPanel.dart';
import 'package:event_manager/components/bottomNav.dart';

import 'package:event_manager/screens/login_screen.dart';
import 'package:event_manager/screens/mainscreen.dart';
import 'package:event_manager/screens/viewEvents.dart';
import 'package:event_manager/shared/notificationservice.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared/routes.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Stripe.publishableKey =
      "pk_test_51POkaFDfyCqLpIlIOVS0cMwxAi2GhJxn0rSxPtHCAq31JP8Xg02GI36JImxQuIkjCgwptXPlw6u3tdVQKH6x2Jfi00ksKUywza";
  await dotenv.load(fileName: "assets/.env");
  Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
  Stripe.urlScheme = 'flutterstripe';
  await Stripe.instance.applySettings();
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
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BottomTabsPageProvider()),
        Provider<FirebaseMessaging>.value(value: _firebaseMessaging),
      ],
      child: const MainApp(),
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
        child: MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(
              bodyMedium: TextStyle(
                fontFamily: 'Ubuntu',
              ),
            ),
          ),
          debugShowCheckedModeBanner: false,
          routes: RouteHelper.routes(context),
          initialRoute: RouteHelper.initRoute,
        ));
  }

  Future<bool> _isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}
