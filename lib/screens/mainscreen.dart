import 'package:carousel_slider/carousel_slider.dart';
import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:event_manager/screens/adminPanel.dart';
import 'package:event_manager/screens/eventDetailScreen.dart';
import 'package:event_manager/screens/historyscreen.dart';
import 'package:event_manager/screens/models/modle.dart';
import 'package:event_manager/screens/models/popularmodel.dart';
import 'package:event_manager/screens/userprofilescreen.dart';
import 'package:event_manager/screens/viewEvents.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  // final String email;

  const HomeScreen({
    super.key,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserData();

    _fetchCarouselData();
    _fetchUsername();
  }

  Future<List<CarouselItem>> _fetchCarouselData() async {
    List<CarouselItem> carouselItems = [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('carousel')
          .orderBy('order')
          .get();

      snapshot.docs.forEach((doc) {
        carouselItems.add(CarouselItem.fromJson(doc.data()));
      });
    } catch (e) {
      print('Error fetching carousel data: $e');
    }

    return carouselItems;
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

  Future<void> _fetchUsername() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data();
        setState(() {
          username = userData['username'];
        });
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
  }

  final List<PopularItems> _popularItems = [
    PopularItems(
      imageUrl: 'https://picsum.photos/id/1/200/300',
      title: 'Popular Event 1',
    ),
    PopularItems(
      imageUrl: 'https://picsum.photos/id/2/200/300',
      title: 'Popular Event 2',
    ),
    // Add more items as needed
  ];

  final List<PopularItems> _trendingItems = [
    PopularItems(
      imageUrl: 'https://picsum.photos/id/1/200/300',
      title: 'Trending Event 1',
    ),
    PopularItems(
      imageUrl: 'https://picsum.photos/id/2/200/300',
      title: 'Trending Event 2',
    ),
    // Add more items as needed
  ];

  Future<void> _handleLogout() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      await _auth.signOut();
      await googleSignIn.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isUserLoggedIn', false);
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  Future<String> getAdminId(String eventId) async {
    String adminId = '';

    // Query Firestore to find the admin ID whose event you tapped
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('isAdmin', isEqualTo: true)
        .get();

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.id)
          .collection('events')
          .where(FieldPath.documentId, isEqualTo: eventId)
          .get();

      if (eventSnapshot.docs.isNotEmpty) {
        adminId = doc.id; // This is the admin's user ID
        break;
      }
    }

    print('Admin ID: $adminId');
    return adminId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mr Event'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 250,
              child: DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      // You can add user profile image here
                    ),
                    Text(
                      username ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person), // Icon for Profile
              title: const Text('Profile'),
              onTap: () {
                // Handle profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback), // Icon for Feedback
              title: const Text('Feedback'),
              onTap: () {
                // Handle feedback
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_phone), // Icon for Contact Us
              title: const Text('Contact Us'),
              onTap: () {
                // Handle contact us
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout), // Icon for Logout
              title: const Text('Logout'),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Carousel slider
            FutureBuilder<List<CarouselItem>>(
              future: _fetchCarouselData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CarouselSlider(
                        items: snapshot.data!.map((item) {
                          return Builder(
                            builder: (BuildContext context) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15.0),
                                  image: DecorationImage(
                                    image: NetworkImage(item.imageUrl),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 5.0),
                              );
                            },
                          );
                        }).toList(),
                        options: CarouselOptions(
                          aspectRatio: 16 / 9,
                          autoPlay: true,
                          enlargeCenterPage: true,
                        ),
                      ),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          AdminPanelCard(
                            title: 'Book Complex',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewEvents(),
                                ),
                              );

                              // Handle Add Events tap
                            },
                            imageUrl: 'assets/images/bookevent.png',
                          ),
                          AdminPanelCard(
                            title: 'Manage Profile',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfileScreen(
                                    userEmail: email,
                                  ),
                                ),
                              );

                              // Handle Add Events tap
                            },
                            imageUrl: 'assets/images/profile.png',
                          ),
                          AdminPanelCard(
                            title: 'History',
                            imageUrl: 'assets/images/history.png',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      HistoryScreen(userDocId: userdocid),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      // Horizontal scrollable cards for different sections
                      const Padding(
                        padding: EdgeInsets.all(15.0),
                        child: Text(
                          'Popular',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('isAdmin', isEqualTo: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            var users = snapshot.data!.docs;
                            return SizedBox(
                              width: 300,
                              height: 300,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  var user = users[index];
                                  return StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.id)
                                        .collection('events')
                                        .orderBy('averageRating',
                                            descending: true)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const CircularProgressIndicator();
                                      }
                                      var events = snapshot.data!.docs;
                                      events.retainWhere((event) =>
                                          (event.data() as Map<String, dynamic>)
                                              .containsKey('averageRating'));
                                      return SizedBox(
                                        height: 600,
                                        width: 600,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          scrollDirection: Axis.horizontal,
                                          itemCount: events.length,
                                          itemBuilder: (context, index) {
                                            var event = events[index];
                                            var eventData = event.data()
                                                as Map<String, dynamic>;
                                            if (!eventData
                                                    .containsKey('imageUrls') ||
                                                !eventData
                                                    .containsKey('eventName') ||
                                                eventData['averageRating'] ==
                                                    null) {
                                              return Container();
                                            }
                                            double rating = 0.0;
                                            if (eventData['averageRating']
                                                is double) {
                                              rating =
                                                  eventData['averageRating'];
                                            } else if (eventData[
                                                'averageRating'] is String) {
                                              rating = double.tryParse(
                                                      eventData[
                                                          'averageRating']) ??
                                                  0.0;
                                            }
                                            return GestureDetector(
                                              onTap: () async {
                                                String adminId =
                                                    await getAdminId(
                                                        event.id.toString());
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        EventDetailsPage(
                                                      eventId: event.id,
                                                      adminId: adminId,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 18.0),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      height: 170,
                                                      width: 250,
                                                      child: Card(
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(15),
                                                        ),
                                                        elevation: 5,
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(15),
                                                          child: Column(
                                                            children: [
                                                              Image.network(
                                                                eventData[
                                                                    'imageUrls'][0],
                                                                fit: BoxFit
                                                                    .cover,
                                                                height: 100,
                                                                width: 250,
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                  vertical: 8.0,
                                                                  horizontal:
                                                                      8.0,
                                                                ),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      eventData[
                                                                          'eventName'],
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    Row(
                                                                      children: [
                                                                        RatingBar
                                                                            .readOnly(
                                                                          isHalfAllowed:
                                                                              true,
                                                                          size:
                                                                              20,
                                                                          filledIcon:
                                                                              Icons.star,
                                                                          emptyIcon:
                                                                              Icons.star_border,
                                                                          halfFilledIcon:
                                                                              Icons.star_half,
                                                                          initialRating:
                                                                              rating,
                                                                          maxRating:
                                                                              5,
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                4),
                                                                        Text(
                                                                          '${eventData['averageRating']} Rating',
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                12,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHorizontalScrollableCards(List<PopularItems> items) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 150,
            margin: const EdgeInsets.symmetric(
                horizontal: 8.0), // Add some margin between cards
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(item.imageUrl),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  item.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class EventDetailsScreen extends StatelessWidget {
  final String eventId;

  EventDetailsScreen({required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: FutureBuilder<DocumentSnapshot?>(
        future: _findEvent(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var event = snapshot.data;
          if (event == null) {
            return const Center(child: Text('Event not found'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(event['imgUrl'], fit: BoxFit.cover),
                const SizedBox(height: 16),
                Text(event['eventName'],
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Rating: ${event['rating']}'),
                const SizedBox(height: 16),
                Text('Comments: ${event['comment']}'),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<DocumentSnapshot?> _findEvent() async {
    var adminsQuerySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('isAdmin', isEqualTo: true)
        .get();

    for (var adminDoc in adminsQuerySnapshot.docs) {
      var eventDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminDoc.id)
          .collection('events')
          .doc(eventId)
          .get();
      if (eventDoc.exists) {
        return eventDoc;
      }
    }
    return null;
  }
}
