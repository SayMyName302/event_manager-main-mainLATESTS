import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_manager/screens/lcoationservice.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:location/location.dart';

import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

class AdminPage extends StatefulWidget {
  final String? email;
  final String? username;

  const AdminPage({Key? key, this.email, this.username}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  TextEditingController eventNameController = TextEditingController();
  TextEditingController eventPriceController = TextEditingController();
  TextEditingController eventDateController = TextEditingController();
  TextEditingController eventAddressController = TextEditingController();
  TextEditingController eventDetailsController = TextEditingController();
  TextEditingController capacityDetailsController = TextEditingController();
  String? eventNameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Event name is required';
    }
    if (value.split(' ').length > 50) {
      return 'Event name should not exceed 50 words';
    }
    return null;
  }

  String? eventPriceValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Event price is required';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Event price should be in digits';
    }
    return null;
  }

  String? eventCapacity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Event price is required';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Event price should be in digits';
    }
    return null;
  }

  String? eventDetailsValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Event details are required';
    }
    if (value.split(' ').length > 500) {
      return 'Event details should not exceed 500 words';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != DateTime.now()) {
      eventDateController.text = pickedDate.toString().split(' ')[0];
    }
  }

  final GlobalKey<FormState> _formKey2 = GlobalKey<FormState>();
  ProgressDialog? progressDialog;
  void _addEvent() async {
    // Validate input
    if (_formKey2.currentState!.validate()) {
      progressDialog = ProgressDialog(context); // Initialize the ProgressDialog

      progressDialog!.show();
      // Fetch values from text controllers
      String eventName = eventNameController.text;
      String eventPrice = eventPriceController.text;
      String eventAddress = eventAddressController.text;
      String eventDetails = eventDetailsController.text;
      String capacity = capacityDetailsController.text;
      String eventDate = DateFormat('dd/MM/yyyy')
          .format(DateTime.parse(eventDateController.text));

      try {
        // Query Firestore to find the user with the matching email
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: widget.email)
            .limit(1)
            .get();

        // Check if the query returned any documents
        if (querySnapshot.docs.isNotEmpty) {
          // Get the user's document ID
          String userId = querySnapshot.docs.first.id;

          // Prepare a list to store image URLs
          List<String> imageUrls = [];

          // Upload images to Firebase Storage and get the download URLs
          for (int i = 0; i < selectedImages.length; i++) {
            if (selectedImages[i] != null) {
              String imagePath = 'events/$userId/$eventName/$i.jpg';
              Reference ref = FirebaseStorage.instance.ref().child(imagePath);
              UploadTask uploadTask = ref.putFile(selectedImages[i]!);
              TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
              String imageUrl = await taskSnapshot.ref.getDownloadURL();
              imageUrls.add(imageUrl);
            }
          }

          // Add event details and image URLs to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('events')
              .add({
            'eventName': eventName,
            'eventPrice': eventPrice,
            'eventAddress': eventAddress,
            'eventDetails': eventDetails,
            'eventDate': eventDate,
            'imageUrls': imageUrls,
            'selectedFacilities': selectedFacilities,
            'selectedTimeSlots': selectedTimeSlots,
            'selectedFoodItems': selectedFoodItems,
            'eventCapacity': capacity,
            'advancepayment': selectedAdvance,
            'selectedpaymentmethod': selectedPaymentMethod
            // Store image URLs in Firestore
          });

          // Perform any additional actions (e.g., show a confirmation message)
          print('Event added successfully');
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content:
                  Text('Event "$eventName" has been added to the database'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          // Clear text fields after adding event
          eventNameController.clear();
          eventPriceController.clear();
          eventDateController.clear();
          eventAddressController.clear();
          eventDetailsController.clear();
          progressDialog!.hide();
        } else {
          progressDialog!.hide();
          // Handle case where no user with the matching email is found
          print('No user found with the email: $widget.email');
        }
      } catch (e) {
        progressDialog!.hide();
        // Handle any errors that occur during Firestore operation
        print('Error adding event: $e');
      }
    }
  }

  List<String> facilities = ['Catering', 'DJ', 'Music', 'Others'];
  List<String> advancepayment = ['10%', '20%', '30%', '50%', '70%', '100%'];
  List<String> selectedAdvance = [];

  List<String> paymentMethod = ['Eayspaisa', 'JazzCash', 'Bank'];
  List<String> selectedPaymentMethod = [];
  // Initialize a list to store selected facilities
  List<String> selectedFacilities = [];
  void toggleSelection(String facility) {
    setState(() {
      if (selectedFacilities.contains(facility)) {
        selectedFacilities.remove(facility);
      } else {
        selectedFacilities.add(facility);
      }
    });
  }

  void toggleSelection2(String facility) {
    setState(() {
      if (selectedAdvance.contains(facility)) {
        selectedAdvance.remove(facility);
      } else {
        selectedAdvance.add(facility);
      }
    });
  }

  void toggleSelection3(String facility) {
    setState(() {
      if (selectedPaymentMethod.contains(facility)) {
        selectedPaymentMethod.remove(facility);
      } else {
        selectedPaymentMethod.add(facility);
      }
    });
  }

  String? _selectedLocation;
  List<File?> selectedImages = [null, null, null];

  Future<void> _addImage(int index) async {
// Image selection logic
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File? compressedImage = await compressImage(File(image.path));
      setState(() {
        selectedImages[index] = compressedImage;
      });
    }
  }

  Future<File?> compressImage(File file) async {
    final String outputPath =
        '${file.path}_compressed.jpg'; // Define the output path
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outputPath,
      quality: 50, // Adjust the quality as needed
    );
    return File(outputPath); // Convert the compressed image path to File
  }

  List<String> timeSlots = [
    '09:00 AM - 11:00 AM',
    '12:00 PM - 02:00 PM',
    '03:00 PM - 06:00 PM',
    '07:00 PM - 10:00 PM'
  ];

  List<String> selectedTimeSlots = [];
  List<String> foodItems = [
    'Chicken Karahi / Pulao / Desserts',
    'Mutton Karahi / Pulao / Desserts',
    'Chicken Karahi / Chicken Karahi /Chicken tikka /Desserts',
    'Beef kabab / Broast / Chicken tikka /Desserts',
    'Any Fast Food itme / Refreshments',
    'Vegetatian Menu',
    'Others'
  ];

  List<String> selectedFoodItems = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Events'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(shrinkWrap: true, children: [
          Form(
            key: _formKey2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Text(
                //   'Add Event',
                //   style: TextStyle(
                //     fontSize: 24,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // const SizedBox(height: 20),
                TextFormField(
                  controller: eventNameController,
                  decoration: InputDecoration(
                    labelText: 'Event Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  validator: eventNameValidator,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  keyboardType: TextInputType.number,
                  controller: eventPriceController,
                  decoration: InputDecoration(
                    labelText: 'Event Price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  validator: eventPriceValidator,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: eventDateController,
                      decoration: InputDecoration(
                        labelText: 'Event Date Available',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Time Slots'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  children: timeSlots
                      .map((timeSlot) => FilterChip(
                            label: Text(timeSlot),
                            selected: selectedTimeSlots.contains(timeSlot),
                            onSelected: (isSelected) {
                              setState(() {
                                if (isSelected) {
                                  selectedTimeSlots.add(timeSlot);
                                } else {
                                  selectedTimeSlots.remove(timeSlot);
                                }
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),

                // Food Menu
                const Text('Food Menu'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  children: foodItems
                      .map((foodItem) => FilterChip(
                            label: Text(foodItem),
                            selected: selectedFoodItems.contains(foodItem),
                            onSelected: (isSelected) {
                              setState(() {
                                if (isSelected) {
                                  selectedFoodItems.add(foodItem);
                                } else {
                                  selectedFoodItems.remove(foodItem);
                                }
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),

                // Event Capacity
                TextFormField(
                  controller: capacityDetailsController,
                  decoration: InputDecoration(
                    labelText: 'Capacity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  validator: eventCapacity,
                ),

                const SizedBox(height: 20),
                TextFormField(
                  readOnly: true,
                  controller: eventAddressController,
                  onTap: () async {
                    _selectedLocation = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectLocationScreen(),
                      ),
                    );

                    if (_selectedLocation != null) {
                      eventAddressController.text = _selectedLocation!;
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Event Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: eventDetailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Event Details',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  validator: eventDetailsValidator,
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text('Add Images'),
                const SizedBox(
                  height: 10,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < 3; i++)
                        GestureDetector(
                          onTap: () => _addImage(i),
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20)),
                            child: selectedImages[i] == null
                                ? const Icon(Icons.add)
                                : Image.file(
                                    selectedImages[i]!,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text('Facilities'),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: 200,
                  width: 250,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: facilities.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        width: MediaQuery.of(context)
                            .size
                            .width, // Set width according to your requirements
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(facilities[index]),
                            ),
                            Checkbox(
                              value: selectedFacilities
                                  .contains(facilities[index]),
                              onChanged: (bool? value) {
                                toggleSelection(facilities[index]);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Text('Advance Payment'),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: 200,
                  width: 250,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: advancepayment.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        width: MediaQuery.of(context)
                            .size
                            .width, // Set width according to your requirements
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(advancepayment[index]),
                            ),
                            Checkbox(
                              value: selectedAdvance
                                  .contains(advancepayment[index]),
                              onChanged: (bool? value) {
                                toggleSelection2(advancepayment[index]);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Text('Payment Method'),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: 200,
                  width: 250,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: paymentMethod.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        width: MediaQuery.of(context)
                            .size
                            .width, // Set width according to your requirements
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(paymentMethod[index]),
                            ),
                            Checkbox(
                              value: selectedPaymentMethod
                                  .contains(paymentMethod[index]),
                              onChanged: (bool? value) {
                                toggleSelection3(paymentMethod[index]);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addEvent,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: const Text('Add Event'),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class SelectLocationScreen extends StatefulWidget {
  @override
  _SelectLocationScreenState createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  LatLng? _currentLocation;
  void _determineCurrentLocation() async {
    // Replace with your actual location fetching code, considering platform differences
    // (e.g., using geolocation plugin for mobile or browser-based APIs for web)
    // Ensure you have the necessary permissions to access location data
    try {
      final Position position = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {});
      }
// Trigger rebuild to update the map
    } catch (e) {
      // Handle location errors gracefully
      print(e);
    }
  }

  late GoogleMapController _controller;
  LocationData? _locationData;
  Marker? _marker;
  LatLng _lastMapPosition = const LatLng(33.5651, 73.0169);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: GoogleMap(
        zoomControlsEnabled: false,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
        onTap: (LatLng latLng) {
          setState(() {
            _lastMapPosition = latLng;
            _marker = Marker(
              // This marker id can be anything that uniquely identifies each marker
              markerId: MarkerId(_lastMapPosition.toString()),
              position: _lastMapPosition,
            );
          });
        },
        markers: _marker == null ? {} : {_marker!},
        initialCameraPosition: _currentLocation != null
            ? CameraPosition(target: _currentLocation!, zoom: 14.0)
            : CameraPosition(
                target: _lastMapPosition,
                zoom: 14.4746,
              ),
      ),
      floatingActionButton:
          Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
          heroTag: '2',
          onPressed: () async {
            LocationService.askLocationPermission(context);
            if (await LocationService.checkLocationPermission()) {
              _animateToUserLocation();
            }
          },
          backgroundColor: Colors.white,
          child: Icon(
            Icons.my_location,
            color: Colors.black,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        FloatingActionButton(
          heroTag: '1',
          onPressed: () async {
            // Check if a marker is present before popping the context
            if (_marker != null) {
              String? address = await _getAddressFromLatLng(_lastMapPosition);
              if (address != null) {
                Navigator.pop(context, address);
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a location on the map.'),
                ),
              );
              // Handle the case where no marker is present
              // You might want to show a message or prevent popping the context
            }
          },
          child: const Icon(Icons.check),
        ),
      ]),
    );
  }

  Future<void> _animateToUserLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    _controller!.animateCamera(CameraUpdate.newLatLngZoom(
      LatLng(position.latitude, position.longitude),
      14, // Zoom level
    ));
  }

  Future<String?> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List;
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks != null && placemarks.isNotEmpty) {
        final Placemark? placemark = placemarks.first;
        return '${placemark!.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}';
      }
    } catch (e) {
      print("Error: $e");
    }
    return null;
  }
}
