import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'updatescreen.dart';

class EditDeleteScreen extends StatefulWidget {
  final String userEmail;

  EditDeleteScreen({required this.userEmail});

  @override
  State<EditDeleteScreen> createState() => _EditDeleteScreenState();
}

class _EditDeleteScreenState extends State<EditDeleteScreen> {
  Future<void> editEvent(
      BuildContext context, String userId, String eventId, String eventName) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateScreen(
          userId: userId,
          eventId: eventId,
          eventName: eventName,
        ),
      ),
    );
  }

  Future<void> deleteEvent(BuildContext context, String userId, String eventId,
      String eventName, List<String> imageUrls) async {
    try {
      ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('events')
          .doc(eventId)
          .delete();

      for (int i = 0; i < imageUrls.length; i++) {
        // Construct the reference to the image in Firebase Storage
        String imagePath = 'events/$userId/$eventName/$i.jpg';
        Reference imageRef = FirebaseStorage.instance.ref().child(imagePath);

        // Delete the image
        await imageRef.delete();
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Event deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit or Delete Events'),
        ),
        body: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: widget.userEmail)
              .where('isAdmin', isEqualTo: true)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            if (snapshot.data!.docs.isEmpty) {
              return const Center(
                child:
                    Text('Access denied. User is not an admin or not found.'),
              );
            }

            // User is an admin, get their events
            String userId = snapshot.data!.docs.first.id;
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('events')
                  .snapshots(),
              builder: (context, eventsSnapshot) {
                if (eventsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (eventsSnapshot.hasError) {
                  return Center(
                    child: Text('Error: ${eventsSnapshot.error}'),
                  );
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                        'Access denied. User is not an admin or not found.'),
                  );
                }
                if (eventsSnapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No events found.'),
                  );
                }

                // Display events in cards
                return ListView.builder(
                  itemCount: eventsSnapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var eventDoc = eventsSnapshot.data!.docs[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  editEvent(context, userId, eventDoc.id,
                                      eventDoc['eventName']);
                                  // Handle edit event
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  // Ensure eventDoc['imageUrls'] is parsed into a list of strings
                                  List<String> imageUrls =
                                      (eventDoc['imageUrls'] as List<dynamic>)
                                          .cast<String>();
                                  deleteEvent(
                                    context,
                                    userId,
                                    eventDoc
                                        .id, // Pass eventId as the third parameter
                                    eventDoc['eventName'],
                                    imageUrls,
                                  );
                                },
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                eventDoc['eventName'],
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Date',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${eventDoc['eventDate']}',
                              ),
                              const Text(
                                'Details',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),

                              Text('${eventDoc['eventDetails']}'),
                              const Text(
                                'Complex Capacity',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),

                              Text('${eventDoc['eventCapacity']}'),
                              const SizedBox(height: 8),
                              const Text(
                                'Address',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text('${eventDoc['eventAddress']}'),
                              const SizedBox(height: 8),
                              const Text(
                                'Price',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text('${eventDoc['eventPrice']} -/Rs only'),
                              const SizedBox(height: 8),
                              // Display images
                              if (eventDoc['imageUrls'] != null &&
                                  eventDoc['imageUrls'].length > 0)
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: eventDoc['imageUrls'].length,
                                    itemBuilder: (context, imgIndex) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Image.network(
                                          eventDoc['imageUrls'][imgIndex],
                                          height: 100,
                                          width: 100,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 8),
                              const Text(
                                'Facilities',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              // Display selected facilities
                              if (eventDoc['selectedFacilities'] != null &&
                                  eventDoc['selectedFacilities'].length > 0)
                                Wrap(
                                  spacing: 10,
                                  children: eventDoc['selectedFacilities']
                                      .map<Widget>((facility) {
                                    return Chip(label: Text(facility));
                                  }).toList(),
                                ),

                              const SizedBox(height: 8),
                              const Text(
                                'Time Slots:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              // Display selected facilities
                              if (eventDoc['selectedTimeSlots'] != null &&
                                  eventDoc['selectedTimeSlots'].length > 0)
                                Wrap(
                                  spacing: 10,
                                  children: eventDoc['selectedTimeSlots']
                                      .map<Widget>((facility) {
                                    return Chip(label: Text(facility));
                                  }).toList(),
                                ),
                              const SizedBox(height: 8),
                              const Text(
                                'Menu:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              // Display selected facilities
                              if (eventDoc['selectedFoodItems'] != null &&
                                  eventDoc['selectedFoodItems'].length > 0)
                                Wrap(
                                  spacing: 10,
                                  children: eventDoc['selectedFoodItems']
                                      .map<Widget>((facility) {
                                    return Chip(label: Text(facility));
                                  }).toList(),
                                ),
                            ],
                          ),
                        ]),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
