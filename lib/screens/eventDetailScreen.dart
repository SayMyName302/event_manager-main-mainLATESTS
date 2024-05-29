import 'package:event_manager/screens/historyscreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;
  final String adminId;

  EventDetailsPage({required this.eventId, required this.adminId});

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late String userdocid;
  String? _selectedTimeSlot;
  String? _selectedPaymentMetod;
  String? _selectedAdanvcedPay;
  List<String> _selectedFacilities = [];
  List<String> _selectedFoodItems = [];
  Future<void> _showBookingNotification(String eventName) async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'default_notification_channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Event Booked',
      '$eventName was successfully Booked!',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userdocid = prefs.getString('userdocid') ?? "";
    });
  }

  bool _isBooking = false;
  Future<void> _bookEvent() async {
    if (_selectedTimeSlot != null && !_isBooking) {
      setState(() {
        _isBooking = true;
      });

      // Check if user has already booked this event
      var bookingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userdocid)
          .collection('bookings')
          .where('eventId', isEqualTo: widget.eventId)
          .get();

      if (bookingSnapshot.docs.isNotEmpty) {
        setState(() {
          _isBooking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already booked this event.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.adminId)
          .get();
      if (!adminSnapshot.exists) {
        setState(() {
          _isBooking = false;
        });
        return;
      }

      var adminData = adminSnapshot.data() as Map<String, dynamic>;
      String accountNumber = adminData['accountnumber'] ?? '';
      String bankDetails = adminData['bankdetails'] ?? '';
      String contactnumber = adminData['contact'];

      DocumentSnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.adminId)
          .collection('events')
          .doc(widget.eventId)
          .get();

      if (!eventSnapshot.exists) {
        setState(() {
          _isBooking = false;
        });
        return;
      }

      var eventData = eventSnapshot.data() as Map<String, dynamic>;
      String eventName = eventData['eventName'] ?? '';
      String eventAddress = eventData['eventAddress'] ?? '';
      String eventCapacity = eventData['eventCapacity'] ?? '';
      String eventDate = eventData['eventDate'] ?? '';
      String eventDetails = eventData['eventDetails'] ?? '';
      String eventPrice = eventData['eventPrice'] ?? '';
      List<String> imageUrls = List<String>.from(eventData['imageUrls'] ?? []);
      List<String> availableTimeSlots =
          List<String>.from(eventData['selectedTimeSlots'] ?? []);
      availableTimeSlots.remove(_selectedTimeSlot);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.adminId)
          .collection('events')
          .doc(widget.eventId)
          .update({
        'selectedTimeSlots': availableTimeSlots,
      });

      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userdocid)
          .get();
      if (!userSnapshot.exists) {
        setState(() {
          _isBooking = false;
        });
        return;
      }

      var userData = userSnapshot.data() as Map<String, dynamic>;
      String userName = userData['username'] ?? '';
      String userEmail = userData['email'] ?? '';
      String userContact = userData['contact'] ?? '';

      setState(() {
        _isBooking = false;
      });

      // Calculate advance payment based on selected percentage
      double advancePaymentPercentage = 0.3; // Default to 30%
      if (_selectedAdanvcedPay == '20%') {
        advancePaymentPercentage = 0.2;
      } else if (_selectedAdanvcedPay == '50%') {
        advancePaymentPercentage = 0.5;
      }
      double advancePayment =
          double.parse(eventPrice) * advancePaymentPercentage;

      // Show confirmation dialog
      bool confirmBooking = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Booking?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Event: $eventName'),
                Text('Total Price: $eventPrice'),
                Text(
                    'Advance Payment (${_selectedAdanvcedPay}): $advancePayment'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // No, cancel booking
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Yes, confirm booking
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );

      if (confirmBooking != null && confirmBooking) {
        // Proceed with booking
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userdocid)
            .collection('bookings')
            .add({
          'eventId': widget.eventId,
          'eventName': eventName,
          'eventAddress': eventAddress,
          'eventCapacity': eventCapacity,
          'eventDate': eventDate,
          'eventDetails': eventDetails,
          'eventPrice': eventPrice,
          'imageUrls': imageUrls,
          'selectedTimeSlot': _selectedTimeSlot,
          'selectedFacilities': _selectedFacilities,
          'selectedFoodItems': _selectedFoodItems,
          'bookingDate': Timestamp.now(),
          'accountNumber': accountNumber,
          'bankDetails': bankDetails,
          'contactnumber': contactnumber,
          'paymentmethod': _selectedPaymentMetod,
          'advancepaymeny': _selectedAdanvcedPay,
          'adminId': widget.adminId
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.adminId)
            .collection('bookedEvents')
            .add({
          'eventId': widget.eventId,
          'userId': userdocid,
          'userName': userName,
          'userEmail': userEmail,
          'userContact': userContact,
          'eventName': eventName,
          'eventAddress': eventAddress,
          'eventDate': eventDate,
          'selectedTimeSlot': _selectedTimeSlot,
          'bookingDate': Timestamp.now(),
        });

        // Add booking details to admin's bookedEventsByUsers collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.adminId)
            .collection('bookedEventsByUsers')
            .add({
          'eventId': widget.eventId,
          'userId': userdocid,
          'userName': userName,
          'userEmail': userEmail,
          'userContact': userContact,
          'eventName': eventName,
          'eventAddress': eventAddress,
          'eventDate': eventDate,
          'selectedTimeSlot': _selectedTimeSlot,
          'bookingDate': Timestamp.now(),
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Thank You!'),
              content: Text('Thank you for choosing $eventName.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        await _showBookingNotification(eventName);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event booked successfully.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: Stack(children: [
        FutureBuilder(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.adminId)
              .get(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> adminSnapshot) {
            if (adminSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (adminSnapshot.hasError) {
              return Center(child: Text('Error: ${adminSnapshot.error}'));
            }
            if (!adminSnapshot.hasData || !adminSnapshot.data!.exists) {
              return const Center(child: Text('Admin user not found.'));
            }

            var adminData = adminSnapshot.data!;
            String accountNumber = adminData['accountnumber'] ?? '';
            String bankDetails = adminData['bankdetails'] ?? '';
            String contactnumbeer = adminData['contact'] ?? '';
            return StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.adminId)
                  .collection('events')
                  .doc(widget.eventId)
                  .snapshots(),
              builder:
                  (context, AsyncSnapshot<DocumentSnapshot> eventSnapshot) {
                if (eventSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (eventSnapshot.hasError) {
                  return Center(child: Text('Error: ${eventSnapshot.error}'));
                }
                if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
                  return const Center(child: Text('Event not found.'));
                }

                var eventData = eventSnapshot.data!;
                String eventName = eventData['eventName'] ?? '';
                String eventAddress = eventData['eventAddress'] ?? '';
                String eventCapacity = eventData['eventCapacity'] ?? '';
                String eventDate = eventData['eventDate'] ?? '';
                String eventDetails = eventData['eventDetails'] ?? '';

                double? rating;
                var data = eventData.data() as Map<String, dynamic>;
                if (data.containsKey('averageRating')) {
                  if (data['averageRating'] is double) {
                    rating = data['averageRating'] ?? 0;
                  } else if (data['averageRating'] is String) {
                    rating = double.tryParse(data['averageRating']) ?? 0;
                  }
                }

                String eventPrice = eventData['eventPrice'] ?? '';
                List<String> imageUrls =
                    List<String>.from(eventData['imageUrls'] ?? []);
                List<String> availableFacilities =
                    List<String>.from(eventData['selectedFacilities'] ?? []);
                List<String> availableFoodItems =
                    List<String>.from(eventData['selectedFoodItems'] ?? []);
                List<String> availableTimeSlots =
                    List<String>.from(eventData['selectedTimeSlots'] ?? []);
                List<String> paymentmethod =
                    List<String>.from(eventData['selectedpaymentmethod'] ?? []);
                List<String> advancepayment =
                    List<String>.from(eventData['advancepayment'] ?? []);
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 200,
                            width: double.infinity,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        imageUrls.isNotEmpty
                                            ? imageUrls[0]
                                            : '',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                  ),
                                  child: Text(
                                    eventName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          _buildSectionTitle('Date'),
                          _buildSectionContent(eventDate),
                          const SizedBox(height: 12.0),
                          _buildSectionTitle('Address'),
                          _buildSectionContent(eventAddress),
                          const SizedBox(height: 12.0),
                          _buildSectionTitle('Capacity'),
                          _buildSectionContent(eventCapacity),
                          const SizedBox(height: 12.0),
                          _buildSectionTitle('Price'),
                          _buildSectionContent(eventPrice),
                          const SizedBox(height: 12.0),
                          _buildSectionTitle('Details'),
                          _buildSectionContent(eventDetails),
                          if (rating != null) _buildSectionTitle('Rating'),
                          _buildSectionContent(rating.toString()),
                          const SizedBox(height: 12.0),
                          _buildSectionTitle('Contact no.'),
                          _buildSectionContent(contactnumbeer),
                          GestureDetector(
                            onTap: () {
                              _launchDialer(contactnumbeer);
                            },
                            child: const SizedBox(
                              height: 20,
                              child: Text(
                                'Contact Organizer',
                                style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.blue),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          _buildSectionTitle('Facilities'),
                          Wrap(
                            spacing: 8.0,
                            children: availableFacilities
                                .map((facility) => CheckboxListTile(
                                      title: Text(facility),
                                      value: _selectedFacilities
                                          .contains(facility),
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value != null && value) {
                                            _selectedFacilities.add(facility);
                                          } else {
                                            _selectedFacilities
                                                .remove(facility);
                                          }
                                        });
                                      },
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 12.0),
                          _buildSectionTitle('Food Menu'),
                          Wrap(
                            spacing: 8.0,
                            children: availableFoodItems
                                .map((foodItem) => CheckboxListTile(
                                      title: Text(foodItem),
                                      value:
                                          _selectedFoodItems.contains(foodItem),
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value != null && value) {
                                            _selectedFoodItems.add(foodItem);
                                          } else {
                                            _selectedFoodItems.remove(foodItem);
                                          }
                                        });
                                      },
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 12.0),
                          _buildSectionTitle('Available Time Slots'),
                          Column(
                            children: availableTimeSlots.isEmpty
                                ? [
                                    const Text(
                                        'No time slots available to book.'),
                                  ]
                                : availableTimeSlots
                                    .map(
                                      (timeSlot) => RadioListTile<String>(
                                        title: Text(timeSlot),
                                        value: timeSlot,
                                        groupValue: _selectedTimeSlot,
                                        onChanged: (String? value) {
                                          setState(() {
                                            _selectedTimeSlot = value;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                          ),
                          const SizedBox(height: 12.0),
                          _buildSectionTitle('Payment Method'),
                          Column(
                            children: paymentmethod.isEmpty
                                ? [
                                    const Text(
                                        'No time slots available to book.'),
                                  ]
                                : paymentmethod
                                    .map(
                                      (timeSlot) => RadioListTile<String>(
                                        title: Text(timeSlot),
                                        value: timeSlot,
                                        groupValue: _selectedPaymentMetod,
                                        onChanged: (String? value) {
                                          setState(() {
                                            _selectedPaymentMetod = value;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                          ),
                          const SizedBox(height: 12.0),
                          _buildSectionTitle('Advance Payment'),
                          Column(
                            children: advancepayment.isEmpty
                                ? [
                                    const Text(
                                        'No time slots available to book.'),
                                  ]
                                : advancepayment
                                    .map(
                                      (timeSlot) => RadioListTile<String>(
                                        title: Text(timeSlot),
                                        value: timeSlot,
                                        groupValue: _selectedAdanvcedPay,
                                        onChanged: (String? value) {
                                          setState(() {
                                            _selectedAdanvcedPay = value;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                          ),
                          const SizedBox(height: 12.0),
                          _buildSectionTitle('Account Number'),
                          _buildSectionContent(accountNumber),
                          const SizedBox(height: 12.0),
                          availableTimeSlots.isEmpty
                              ? const Center(child: Text('No Slots Available'))
                              : Center(
                                  child: ElevatedButton(
                                    onPressed: _bookEvent,
                                    child: const Text('Book Event'),
                                  ),
                                ),
                        ],
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
        if (_isBooking) const Center(child: CircularProgressIndicator())
      ]),
    );
  }

  void _launchDialer(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: const TextStyle(fontSize: 18),
    );
  }
}
