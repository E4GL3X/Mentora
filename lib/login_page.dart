import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentora/signup_page.dart';
import 'package:mentora/instructor_home.dart';
import 'package:mentora/forgot_password_page.dart';
import 'package:mentora/student_home_page.dart';
import 'package:flutter/services.dart'; // For SystemChrome
import 'package:flutter_spinkit/flutter_spinkit.dart'; // For custom loading

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set the status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Transparent status bar
        statusBarIconBrightness: Brightness.light, // Light icons for visibility
      ),
    );
  }

  Future<void> login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in with email and password
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user;

      // Check if user exists and email is verified
      if (user != null && user.emailVerified) {
        // Fetch role from Firestore with explicit type
        final DocumentSnapshot<Map<String, dynamic>> userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        // Explicitly check if document exists
        final bool docExists = userDoc.exists;

        // Safely fetch role with type casting and debug
        final String role =
            docExists
                ? (userDoc.data()?['role'] as String? ?? 'Student')
                : 'Student';
        print('Retrieved role: $role'); // Debug print

        // Navigate based on role, clearing the navigation stack
        if (role.toLowerCase() == 'instructor') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const InstructorHome()),
            (route) => false, // Removes all previous routes
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const StudentHomePage()),
            (route) => false, // Removes all previous routes
          );
        }
      } else {
        // Show email verification error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please verify your email.')),
        );
      }
    } catch (e) {
      // Show login error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check credentials or sign up first.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen height
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PNG Image at the top, taking 1/3 of the screen height
            SizedBox(
              width: double.infinity,
              height: screenHeight / 3, // 1/3 of the screen height
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover, // Fills the space, may crop if needed
              ),
            ),
            // Padding for the remaining content
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 80,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email TextField
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      filled: true,
                      fillColor: const Color(0xFFDCD6F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password TextField
                  TextField(
                    controller: passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      filled: true,
                      fillColor: const Color(0xFFDCD6F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFF2E5077),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 70),

                  // Login Button with custom loading
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 50,
                      child:
                          _isLoading
                              ? SpinKitFadingCircle(
                                color: const Color(0xFF424874),
                                size: 30.0,
                              )
                              : ElevatedButton(
                                onPressed: login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF424874),
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sign Up and Forgot Password Links
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Join with Mentora',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E5077),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E5077),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}