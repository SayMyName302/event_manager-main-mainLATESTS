import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignIn {
  Future<dynamic> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // User cancelled login
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        // Missing access token or ID token
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on Exception catch (e) {
      print('exception->$e');
      return null;
    }
  }

  Future<bool> signOutFromGoogle() async {
    try {
      await FirebaseAuth.instance.signOut();
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  static Future<void> saveUserData(String username, String email,
      String contact, String accountnumber, String bankdetails) async {
    final CollectionReference users =
        FirebaseFirestore.instance.collection('users');
    FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
    String? deviceId = await _firebaseMessaging.getToken();
    // Check if username already exists
    final duplicateUsername =
        await users.where('username', isEqualTo: username).get();
    if (duplicateUsername.docs.isEmpty) {
      // Username doesn't exist, save user data
      await users.add({
        'username': username,
        'email': email,
        'contact': contact,
        'accountnumber': accountnumber,
        'deviceId': deviceId,
        'bankdetails': bankdetails,
        // Add other fields as needed
      });
      sendNotification(deviceId, "Bhenchod", "deya");
    } else {
      // Username already exists
      throw Exception('Username or email already exists');
    }
  }

  static Future<void> sendNotification(
      String? deviceId, String title, String body) async {
    try {
      if (deviceId != null) {
        var message = {
          'notification': {'title': title, 'body': body},
          'to': deviceId,
        };

        // Print the message being sent
        print('Sending message: ${jsonEncode(message)}');

        var response = await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization':
                'key=AAAA-UXIxow:APA91bHESfrLElnP7fG5ehh-I3EskGELjGrvkcMPSdCch4kxa0iApvqMGN8eB0AmdexhYuJTavCWtxY4H76o8MbL53TEvLGkLNHaU3E6wlYtfSHX2ldiX9NRfkUFL4Lyh7DoO3mCAvcC',
          },
          body: jsonEncode(message),
        );

        // Print the response from FCM server
        print('FCM response: ${response.body}');
      } else {
        throw Exception('Device ID is null');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}
