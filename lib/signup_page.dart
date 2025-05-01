import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mentora/login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = 'Student';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signUpUser() async {
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      print('Attempting sign-up with email: $email');

      if (email.isEmpty || password.isEmpty) {
        showErrorDialog('Please enter both email and password.');
        return;
      }

      print('Creating user...');
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      print('User created: ${user?.email}');

      if (user != null) {
        print('Storing user data in Firestore...');
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'role': selectedRole,
        });

        print('Sending verification email...');
        await user.sendEmailVerification();
        print('Verification email sent.');

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verification Email Sent'),
            content: const Text(
              'A verification email has been sent to your inbox. Please verify your email to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      String errorMessage;
      if (e is FirebaseAuthException) {
        print('FirebaseAuthException: ${e.code} - ${e.message}');
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already registered.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is invalid.';
            break;
          case 'weak-password':
            errorMessage = 'The password is too weak.';
            break;
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your connection.';
            break;
          default:
            errorMessage = 'An error occurred: ${e.message}';
        }
      } else {
        print('Unexpected error: $e');
        errorMessage = 'An unexpected error occurred: $e';
      }
      showErrorDialog(errorMessage);
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 80),
                Center(
                  child: SvgPicture.asset(
                    'assets/images/signup.svg',
                    width: 150,
                    height: 150,
                    placeholderBuilder: (context) => const Placeholder(
                      fallbackWidth: 150,
                      fallbackHeight: 150,
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // Email
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: const Color.fromARGB(255, 246, 252, 223),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(height: 20),

                // Password
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: const Color.fromARGB(255, 246, 252, 223),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(height: 20),

                // Role buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Student'),
                      selected: selectedRole == 'Student',
                      selectedColor: const Color.fromARGB(0, 187, 255, 0),
                      backgroundColor: const Color.fromARGB(255, 14, 57, 8),
                      labelStyle: TextStyle(
                        color: selectedRole == 'Student'
                            ? const Color.fromARGB(255, 0, 0, 0)
                            : const Color.fromARGB(255, 255, 255, 255),
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedRole = 'Student';
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    ChoiceChip(
                      label: const Text('Instructor'),
                      selected: selectedRole == 'Instructor',
                      selectedColor: const Color.fromARGB(0, 187, 255, 0),
                      backgroundColor: const Color.fromARGB(255, 14, 57, 8),
                      labelStyle: TextStyle(
                        color: selectedRole == 'Instructor'
                            ? const Color.fromARGB(255, 0, 0, 0)
                            : const Color.fromARGB(255, 255, 255, 255),
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedRole = 'Instructor';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 50),

                // Sign Up Button
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: signUpUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 49, 81, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      'Already have an account? Log In',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 49, 81, 30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}