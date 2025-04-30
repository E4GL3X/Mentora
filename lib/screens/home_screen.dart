import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentora Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${user?.email ?? "User"}!'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to attendance screen
              },
              child: const Text('Attendance'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to homework screen
              },
              child: const Text('Homework'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to payment screen
              },
              child: const Text('Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
