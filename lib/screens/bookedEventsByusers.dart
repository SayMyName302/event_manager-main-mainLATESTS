import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class AdminBookedEventsScreen extends StatefulWidget {
  final String adminId;

  const AdminBookedEventsScreen({Key? key, required this.adminId})
      : super(key: key);

  @override
  _AdminBookedEventsScreenState createState() =>
      _AdminBookedEventsScreenState();
}

class _AdminBookedEventsScreenState extends State<AdminBookedEventsScreen> {
  @override
  void initState() {
    super.initState();
    listenForNewBookings(widget.adminId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booked Events'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.adminId)
            .collection('bookedEventsByUsers')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No booked events found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              return Card(
                elevation: 3.0,
                margin:
                    const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
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
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          const Icon(Icons.date_range, color: Colors.blue),
                          const SizedBox(width: 8.0),
                          Text('Event Date: ${data['eventDate']}'),
                        ],
                      ),
                      const SizedBox(height: 5.0),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.blue),
                          const SizedBox(width: 8.0),
                          Text('Time Slot: ${data['selectedTimeSlot']}'),
                        ],
                      ),
                      const SizedBox(height: 5.0),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 8.0),
                          Text(
                              'Booking Date: ${_formatTimestamp(data['bookingDate'])}'),
                        ],
                      ),
                      const SizedBox(height: 5.0),
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.blue),
                          const SizedBox(width: 8.0),
                          Text('Booked By: ${data['userName']}'),
                        ],
                      ),
                      const SizedBox(height: 5.0),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.blue),
                          const SizedBox(width: 8.0),
                          GestureDetector(
                            onTap: () {
                              _launchDialer(data['userContact']);
                            },
                            child: Text(
                              'Contact: ${data['userContact']}',
                              style: const TextStyle(
                                color: Colors.blue,
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
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _launchDialer(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
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
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK'
          },
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
          sendNotification(
              deviceToken, 'New Event Booked', 'Event: $eventName');
        }
      }
    });
  }
}
