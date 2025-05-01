import 'package:flutter/material.dart';

class InstructorHomePage extends StatelessWidget {
  const InstructorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Welcome to the Instructor Dashboard!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add functionality for creating announcements
                showDialog(
                  context: context,
                  builder: (_) => const AnnouncementDialog(),
                );
              },
              child: const Text('Create Announcement'),
            ),
            // Add more instructor-specific features here
          ],
        ),
      ),
    );
  }
}

class AnnouncementDialog extends StatelessWidget {
  const AnnouncementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController announcementController = TextEditingController();

    return AlertDialog(
      title: const Text('Create an Announcement'),
      content: TextField(
        controller: announcementController,
        decoration: const InputDecoration(hintText: 'Enter announcement here'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Add code to save announcement (e.g., to Firebase)
            Navigator.pop(context); // Close the dialog
          },
          child: const Text('Save'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close the dialog without saving
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
