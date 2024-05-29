import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatefulWidget {
  final String userEmail;

  const UserProfileScreen({Key? key, required this.userEmail})
      : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _contactController;
  late TextEditingController _accountNumberController;
  late TextEditingController _bankdetailsController;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _contactController = TextEditingController();
    _accountNumberController = TextEditingController();
    _bankdetailsController = TextEditingController();
    fetchUserDetails();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _contactController.dispose();
    _accountNumberController.dispose();
    _bankdetailsController.dispose();
    super.dispose();
  }

  void fetchUserDetails() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .where('email', isEqualTo: widget.userEmail)
          .get();

      if (snapshot.docs.isNotEmpty) {
        Map<String, dynamic> data = snapshot.docs.first.data();
        setState(() {
          _usernameController.text = data['username'] ?? '';
          _contactController.text = data['contact'] ?? '';
          _accountNumberController.text = data['accountnumber'] ?? '';
          _bankdetailsController.text = data['bankdetails'] ?? '';
          isAdmin = data['isAdmin'] ?? false;
        });
      } else {
        print('No user found with email: ${widget.userEmail}');
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  void updateUserDetails() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .where('email', isEqualTo: widget.userEmail)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'username': _usernameController.text,
          'contact': _contactController.text,
          'accountnumber': isAdmin ? null : _accountNumberController.text,
          'bankdetails': isAdmin ? null : _bankdetailsController.text
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Details updated successfully')));
      } else {
        print('No user found with email: ${widget.userEmail}');
      }
    } catch (e) {
      print('Error updating user details: $e');
    }
  }

  void deleteUserAccount() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .where('email', isEqualTo: widget.userEmail)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .delete();
        Future.delayed(const Duration(seconds: 2));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')));
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        print('No user found with email: ${widget.userEmail}');
      }
    } catch (e) {
      print('Error deleting user account: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: 'Contact'),
            ),
            if (!isAdmin)
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(labelText: 'Account Number'),
              ),
            if (!isAdmin)
              TextFormField(
                controller: _bankdetailsController,
                decoration: const InputDecoration(labelText: 'Payment method'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateUserDetails,
              child: const Text('Update Details'),
            ),
            ElevatedButton(
              onPressed: deleteUserAccount,
              child: const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }
}
