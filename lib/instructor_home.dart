import 'package:flutter/material.dart';
import 'package:mentora/students_page.dart';
import 'package:mentora/attendance_history_page.dart';
import 'package:mentora/dashboard_header.dart';
import 'package:mentora/dashboard_content.dart';
import 'package:mentora/profile_page.dart';
import 'package:mentora/assignment_report_page.dart';

class InstructorHome extends StatefulWidget {
  const InstructorHome({super.key});

  @override
  State<InstructorHome> createState() => _InstructorHomeState();
}

class _InstructorHomeState extends State<InstructorHome> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    print('Tapped index: $index');
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _getActivePage() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardContent();
      case 1:
        return const AttendanceHistoryPage();
      case 2:
        return const StudentsPage();
      case 3:
        return const AssignmentReportPage();
      case 4:
        return const ProfilePage(role: 'Instructor');
      default:
        return const DashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F0),
      body: Column(
        children: [
          if (_selectedIndex == 0) const DashboardHeader(),
          Expanded(
            child: _getActivePage(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFECE2E1),
        unselectedItemColor: const Color(0xFFA6B1E1),
        backgroundColor: const Color(0xFF424874),
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}