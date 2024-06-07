import 'dart:convert';

import 'package:event_manager/components/LoadingWidget.dart';
import 'package:event_manager/components/components.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class AdminBookedEventsScreen extends StatefulWidget {
  const AdminBookedEventsScreen({
    Key? key,
  }) : super(key: key);

  @override
  _AdminBookedEventsScreenState createState() =>
      _AdminBookedEventsScreenState();
}

class _AdminBookedEventsScreenState extends State<AdminBookedEventsScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  late String username = "";
  late String email = "";
  late String userid = "";
  late String userdocid = "";
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? "";
      username = prefs.getString('username') ?? "";
      userid = prefs.getString('userid') ?? "";
      userdocid = prefs.getString('userdocid') ?? "";
    });
  }

  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('Booked Events'),
        backgroundColor: Colors.grey[900],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomTextField2(
              controller: searchController,
              hinttext: 'Search event by name',
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userdocid)
                  .collection('bookedEventsByUsers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.white)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: loadingWidget2());
                }

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No booked events found.',
                          style: TextStyle(color: Colors.white)));
                }

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return data['eventName']
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase());
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: filteredDocs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data =
                        document.data() as Map<String, dynamic>;
                    return Card(
                      color: Colors.grey[850],
                      elevation: 3.0,
                      margin: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              data['eventName'],
                              style: const TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: [
                                const Icon(Icons.date_range,
                                    color: Colors.blueAccent),
                                const SizedBox(width: 8.0),
                                Text('Event Date: ${data['eventDate']}',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    color: Colors.blueAccent),
                                const SizedBox(width: 8.0),
                                Text('Time Slot: ${data['selectedTimeSlot']}',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: Colors.blueAccent),
                                const SizedBox(width: 8.0),
                                Text(
                                    'Booking Date: ${_formatTimestamp(data['bookingDate'])}',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                const Icon(Icons.person,
                                    color: Colors.blueAccent),
                                const SizedBox(width: 8.0),
                                Text('Booked By: ${data['userName']}',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 5.0),
                            Row(
                              children: [
                                const Icon(Icons.phone,
                                    color: Colors.blueAccent),
                                const SizedBox(width: 8.0),
                                GestureDetector(
                                  onTap: () {
                                    makePhoneCall(data['userContact']);
                                  },
                                  child: Text(
                                    'Contact: ${data['userContact']}',
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

Future<void> makePhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  await launchUrl(launchUri);
}

Future<void> sendNotification(String token, String title, String body) async {
  const String serverToken = 'YOUR_SERVER_KEY_HERE';
  final response = await http.post(
    Uri.parse('https://fcm.googleapis.com/fcm/send'),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization':
          'key=AAAA-UXIxow:APA91bHESfrLElnP7fG5ehh-I3EskGELjGrvkcMPSdCch4kxa0iApvqMGN8eB0AmdexhYuJTavCWtxY4H76o8MbL53TEvLGkLNHaU3E6wlYtfSHX2ldiX9NRfkUFL4Lyh7DoO3mCAvcC',
    },
    body: jsonEncode(
      <String, dynamic>{
        'notification': <String, dynamic>{'title': title, 'body': body},
        'priority': 'high',
        'data': <String, dynamic>{'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
        'to': token,
      },
    ),
  );

  if (response.statusCode == 200) {
    print('Notification sent successfully');
  } else {
    print('Failed to send notification');
  }
}

void listenForNewBookings(String adminId) {
  FirebaseFirestore.instance
      .collection('users')
      .doc(adminId)
      .collection('bookedEventsByUsers')
      .snapshots()
      .listen((snapshot) async {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        var data = change.doc.data() as Map<String, dynamic>;
        String eventName = data['eventName'];
        String userId = data['userId'];
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        String deviceToken = userSnapshot['deviceId'];
        sendNotification(deviceToken, 'New Event Booked', 'Event: $eventName');
      }
    }
  });
}
