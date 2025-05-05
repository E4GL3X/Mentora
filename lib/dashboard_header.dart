import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mentora/login_page.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  void _logout(BuildContext context) {
    print('Logout pressed');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF2E5077))),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              });
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: AppBar(
            leading: null,
            title: const Text(
              'Mentora',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424874),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFF424874), size: 30),
                  onPressed: () => _logout(context),
                ),
              ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
        ),
        const SizedBox(height: 40),
        Center(
          child: SvgPicture.asset(
            'assets/images/instructor.svg',
            width: 150,
            height: 150,
            placeholderBuilder: (context) => const CircularProgressIndicator(),
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}