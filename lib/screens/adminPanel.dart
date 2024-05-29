import 'package:event_manager/components/provider.dart';
import 'package:event_manager/screens/admin.dart';
import 'package:event_manager/screens/bookedEventsByusers.dart';
import 'package:event_manager/screens/editDeleteScreen.dart';
import 'package:event_manager/screens/login_screen.dart';
import 'package:event_manager/shared/functions.dart';
import 'package:event_manager/shared/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'userprofilescreen.dart';

class AdminPanelScreen extends StatefulWidget {
  AdminPanelScreen({
    Key? key,
  }) : super(key: key);
  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.setBool('isAdminLoggedIn', false);
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  late String username = "";
  late String email = "";
  @override
  void initState() {
    super.initState();
    // Fetch email and username from provider
    SignIn.sendNotification(devicdeid, "dededBhenchod", "deya");
    _loadUserData();
  }

  late String userdocid = "";
  late String devicdeid = '';
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? "";
      username = prefs.getString('username') ?? "";
      userdocid = prefs.getString('userdocid') ?? "";
      devicdeid = prefs.getString('devicdeid') ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (email.isNotEmpty)
                    Text(
                      email!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  if (username.isNotEmpty)
                    Text(
                      username!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(
                      userEmail: email!,
                    ),
                  ),
                );

                // Navigate to profile page
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Feedback'),
              onTap: () {
                // Navigate to feedback page
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_mail),
              title: const Text('Contact Us'),
              onTap: () {
                // Navigate to contact us page
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminPanelCard(
              title: 'Add Events',
              imageUrl: 'assets/images/add.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AdminPage(email: email, username: username),
                  ),
                );
                // Handle Add Events tap
              },
            ),
            const SizedBox(height: 20),
            AdminPanelCard(
              title: 'View/Edit Events',
              imageUrl: 'assets/images/editdel.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditDeleteScreen(userEmail: email!),
                  ),
                );

                // Handle View/Edit Events tap
              },
            ),
            AdminPanelCard(
              title: 'Booked Events',
              imageUrl: 'assets/images/ticket.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AdminBookedEventsScreen(adminId: username),
                  ),
                );

                // Handle View/Edit Events tap
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AdminPanelCard extends StatelessWidget {
  final String title;

  final VoidCallback onTap;
  final String imageUrl;

  const AdminPanelCard({
    Key? key,
    required this.title,
    required this.onTap,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Image.asset(imageUrl, height: 40, width: 40),
          const SizedBox(height: 10),
          Center(
              child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Colors.black),
              children: title.split(' ').map((word) {
                return TextSpan(
                  text: word + '\n',
                );
              }).toList(),
            ),
          ))
        ],
      ),
    );
  }
}
