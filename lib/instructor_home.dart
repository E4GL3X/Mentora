// instructor_home.dart
import 'package:flutter/material.dart';

class InstructorHome extends StatelessWidget {
  const InstructorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instructor Home')),
      body: Center(
        child: const Text('Welcome to the Instructor Dashboard'),
      ),
    );
  }
}
