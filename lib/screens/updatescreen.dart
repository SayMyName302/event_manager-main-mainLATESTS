import 'package:event_manager/screens/admin.dart';
import 'package:event_manager/screens/editDeleteScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

class UpdateScreen extends StatefulWidget {
  final String userId;
  final String eventId;
  final String eventName;

  UpdateScreen(
      {required this.userId, required this.eventId, required this.eventName});

  @override
  _UpdateScreenState createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  late TextEditingController _eventNameController;
  late TextEditingController _eventDateController;
  late TextEditingController _eventDetailsController;
  late TextEditingController _eventAddressController;
  late TextEditingController _eventPriceController;
  late TextEditingController _selectedFacilitiesController;
  late TextEditingController _selectedFoodItems;
  late TextEditingController _selectedTimeSlots;
  late TextEditingController _eventCapacity;
  @override
  void initState() {
    super.initState();
    _eventNameController = TextEditingController();
    _eventDateController = TextEditingController();
    _eventDetailsController = TextEditingController();
    _eventAddressController = TextEditingController();
    _eventPriceController = TextEditingController();
    _selectedFacilitiesController = TextEditingController();
    _selectedFoodItems = TextEditingController();
    _selectedTimeSlots = TextEditingController();
    _eventCapacity = TextEditingController();

    // Load existing event data
    loadEventData();
    progressDialog = ProgressDialog(context);
  }

  ProgressDialog? progressDialog;
  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDateController.dispose();
    _eventDetailsController.dispose();
    _eventAddressController.dispose();
    _eventPriceController.dispose();
    _selectedFacilitiesController.dispose();
    _selectedFoodItems.dispose();
    _selectedTimeSlots.dispose();
    _eventCapacity.dispose();
    super.dispose();
  }

  Future<void> uploadImagesAndSaveData() async {
    // Initialize the ProgressDialog

    try {
      List<String> imageURLs = [];

      // Delete previous images from Firebase Storage
      String previousImagePath = 'events/${widget.userId}/${widget.eventName}/';
      for (int i = 0; i < selectedImages.length; i++) {
        Reference ref =
            FirebaseStorage.instance.ref().child(previousImagePath + '$i.jpg');
        await ref.delete().catchError((error) {
          print('Error deleting image $i: $error');
        });
      }

      // Upload new images to Firebase Storage and get their URLs
      for (int i = 0; i < selectedImages.length; i++) {
        if (selectedImages[i] != null) {
          String imagePath =
              'events/${widget.userId}/${widget.eventName}/$i.jpg';
          Reference ref = FirebaseStorage.instance.ref().child(imagePath);
          UploadTask uploadTask = ref.putFile(selectedImages[i]!);
          TaskSnapshot taskSnapshot = await uploadTask;
          String downloadURL = await taskSnapshot.ref.getDownloadURL();
          imageURLs.add(downloadURL);
        }
      }

      // Update the image URLs in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('events')
          .doc(widget.eventId)
          .update({'imageUrls': imageURLs});

      // Optionally, you can update the UI or perform any other tasks here.
    } catch (e) {
      print('Error uploading images and saving data: $e');
    }
  }

  Future<void> loadEventData() async {
    try {
      DocumentSnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('events')
          .doc(widget.eventId)
          .get();

      Map<String, dynamic> eventData =
          eventSnapshot.data() as Map<String, dynamic>;
      _eventNameController.text = eventData['eventName'];
      _eventDateController.text = eventData['eventDate'];
      _eventDetailsController.text = eventData['eventDetails'];
      _eventAddressController.text = eventData['eventAddress'];
      _eventPriceController.text = eventData['eventPrice'];
      _eventCapacity.text = eventData['eventCapacity'];
      _selectedFacilitiesController.text =
          eventData['selectedFacilities'] != null
              ? eventData['selectedFacilities'].join('\n')
              : '';
      _selectedTimeSlots.text = eventData['selectedTimeSlots'] != null
          ? eventData['selectedTimeSlots'].join('\n')
          : '';
      _selectedFoodItems.text = eventData['selectedFoodItems'] != null
          ? eventData['selectedFoodItems'].join('\n')
          : '';
    } catch (e) {
      print('Error loading event data: $e');
    }
  }

  Future<void> _pickDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        _eventDateController.text =
            "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";
      });
    }
  }

  List<File?> selectedImages = [null, null, null];
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

  Future<void> _addImage(int index) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File? compressedImage = await compressImage(File(image.path));
      setState(() {
        selectedImages[index] = compressedImage;
      });
    }
  }

  Future<void> updateEventData() async {
    progressDialog!.show();
    try {
      await uploadImagesAndSaveData();

      final eventRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('events')
          .doc(widget.eventId);

      // Upload new images to Firebase Storage

      // Update Firestore with new image paths
      await eventRef.update({
        'eventName': _eventNameController.text,
        'eventDate': _eventDateController.text,
        'eventDetails': _eventDetailsController.text,
        'eventAddress': _eventAddressController.text,
        'eventPrice': _eventPriceController.text,
        'eventCapacity': _eventPriceController.text,
        'selectedFacilities':
            _selectedFacilitiesController.text.split('\n').toList(),
        'selectedFoodItems': _selectedFoodItems.text.split('\n').toList(),
        'selectedTimeSlots': _selectedTimeSlots.text.split('\n').toList(),
      });
      progressDialog!.hide();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      progressDialog!.hide();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _selectedLocation;
  List<File> _selectedImages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              updateEventData();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _eventNameController,
              decoration: const InputDecoration(labelText: 'Event Name'),
            ),
            TextFormField(
              controller: _eventCapacity,
              decoration: const InputDecoration(labelText: 'Complex Capacity'),
            ),
            TextFormField(
              readOnly: true,
              controller: _eventDateController,
              decoration: const InputDecoration(labelText: 'Event Date'),
              onTap: _pickDate,
            ),
            TextFormField(
              readOnly: true,
              controller: _eventDetailsController,
              decoration: const InputDecoration(labelText: 'Event Details'),
            ),
            TextFormField(
              onTap: () async {
                _selectedLocation = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectLocationScreen(),
                  ),
                );

                if (_selectedLocation != null) {
                  _eventAddressController.text = _selectedLocation!;
                }
              },
              controller: _eventAddressController,
              decoration: const InputDecoration(labelText: 'Event Address'),
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              controller: _eventPriceController,
              decoration: const InputDecoration(labelText: 'Event Price'),
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
            TextFormField(
              controller: _selectedFacilitiesController,
              decoration: const InputDecoration(
                  labelText: ' Facilities (Separate with new line)'),
              maxLines: null,
            ),
            TextFormField(
              controller: _selectedFoodItems,
              decoration: const InputDecoration(
                  labelText: 'Food Menu (Separate with new line)'),
              maxLines: null,
            ),
            TextFormField(
              controller: _selectedTimeSlots,
              decoration: const InputDecoration(
                  labelText: 'Time slots (Separate with new line)'),
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }
}
