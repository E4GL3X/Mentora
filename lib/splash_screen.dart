import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentora/instructor_home.dart';
import 'package:mentora/login_page.dart';
import 'package:mentora/student_home_page.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Set the status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    Timer(const Duration(seconds: 3), () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseAuth.instance.currentUser?.getIdTokenResult();
        final role = userDoc?.claims?['role'];
        if (role == 'instructor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const InstructorHome()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentHomePage()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash.png',
              fit: BoxFit.cover, // Fills the entire screen
            ),
          ),
          // Center "Mentora" Text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Mentora',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDCD6F7),
                  ),
                ),
                const SizedBox(height: 400), // Space for loader at the bottom
                SpinKitFadingCircle(
                  color: const Color(0xFFDCD6F7),
                  size: 40.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}