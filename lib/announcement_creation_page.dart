import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementCreationPage extends StatefulWidget {
  const AnnouncementCreationPage({super.key});

  @override
  _AnnouncementCreationPageState createState() =>
      _AnnouncementCreationPageState();
}

class _AnnouncementCreationPageState extends State<AnnouncementCreationPage> {
  final _announcementController = TextEditingController();

  void _createAnnouncement() {
    if (_announcementController.text.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('announcements')
          .add({
            'announcement': _announcementController.text,
            'timestamp': FieldValue.serverTimestamp(),
          })
          .then((value) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Announcement Created!')));
            _announcementController.clear();
          })
          .catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to create announcement: $error')),
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Announcement")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _announcementController,
              decoration: InputDecoration(labelText: "Enter your announcement"),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createAnnouncement,
              child: Text("Create Announcement"),
            ),
          ],
        ),
      ),
    );
  }
}
