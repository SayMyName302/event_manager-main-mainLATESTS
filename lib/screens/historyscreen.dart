import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryScreen extends StatefulWidget {
  final String userDocId;

  const HistoryScreen({Key? key, required this.userDocId}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  void _launchDialer(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
      ),
      body: widget.userDocId.isEmpty
          ? const Center(
              child: Text(
                'No user ID provided',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            )
          : FutureBuilder(
              future: _fetchBookings(widget.userDocId),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No bookings available',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  );
                }

                List<DocumentSnapshot> bookings = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot booking = bookings[index];
                    DateTime dateTime =
                        (booking['bookingDate'] as Timestamp).toDate();
                    String formattedDate =
                        '${dateTime.day}-${dateTime.month}-${dateTime.year}';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking['eventName'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Booked On:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                booking['eventDetails'],
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  _launchDialer(
                                    booking['contactnumber'],
                                  );
                                },
                                child: SizedBox(
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
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        _navigateToBookingDetails(booking);
                                      },
                                      child: const Text(
                                        'View Details',
                                        style: TextStyle(
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _showRatingDialog(booking);
                                      },
                                      child: const Text(
                                        'Rate This Event',
                                        style: TextStyle(
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchBookings(String userDocId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userDocId)
        .collection('bookings')
        .get();
  }

  void _navigateToBookingDetails(DocumentSnapshot booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(booking: booking),
      ),
    );
  }

  void _showRatingDialog(DocumentSnapshot booking) {
    showDialog(
      context: context,
      builder: (context) {
        double rating = 0;
        TextEditingController commentController = TextEditingController();
        return AlertDialog(
          title: const Text('Rate This Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Give a rating'),
              RatingBar(
                filledIcon: Icons.star,
                emptyIcon: Icons.star_border,
                initialRating: 3,
                maxRating: 5,
                onRatingChanged: (newRating) {
                  rating = newRating;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _submitRating(booking, rating, commentController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _submitRating(
      DocumentSnapshot booking, double rating, String comment) async {
    DocumentReference eventRef = FirebaseFirestore.instance
        .collection('users')
        .doc(booking['adminId'])
        .collection('events')
        .doc(booking['eventId']);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot eventSnapshot = await transaction.get(eventRef);

      if (!eventSnapshot.exists) {
        throw Exception("Event does not exist!");
      }

      Map<String, dynamic> eventData =
          eventSnapshot.data() as Map<String, dynamic>;

      int ratingCount = eventData['ratingCount'] ?? 0;
      double totalRating = (eventData['totalRating'] ?? 0.0) as double;

      ratingCount += 1;
      totalRating += rating;

      double averageRating = totalRating / ratingCount;

      transaction.update(eventRef, {
        'ratingCount': ratingCount,
        'totalRating': totalRating,
        'averageRating': averageRating.toStringAsFixed(1),
        'comment': comment,
      });
    });
  }
}

class BookingDetailsScreen extends StatelessWidget {
  final DocumentSnapshot booking;

  const BookingDetailsScreen({Key? key, required this.booking})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateTime dateTime = (booking['bookingDate'] as Timestamp).toDate();
    String formattedBookingDate =
        '${dateTime.day}-${dateTime.month}-${dateTime.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDetailRow('Event Name', booking['eventName']),
            _buildDetailRow('Event Price', booking['eventPrice'].toString()),
            _buildDetailRow(
                'Event Capacity', booking['eventCapacity'].toString()),
            _buildDetailRow('Event Address', booking['eventAddress']),
            _buildDetailRow(
                'Contact Number', booking['contactnumber'].toString()),
            _buildDetailRow('Booking Date', formattedBookingDate),
            _buildDetailRow('Payment Method', booking['paymentmethod']),
            _buildDetailRow('Bank Details', booking['bankDetails']),
            _buildDetailRow(
                'Advance Payment', booking['advancepaymeny'].toString()),
            const SizedBox(height: 12),
            _buildDetailRow('Selected Time Slots', booking['selectedTimeSlot']),
            _buildDetailRow(
                'Selected Food Items', booking['selectedFoodItems']),
            _buildDetailRow(
                'Selected Facilities', booking['selectedFacilities']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
