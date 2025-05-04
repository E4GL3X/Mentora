import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mentora/login_page.dart';
import 'package:mentora/profile_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _selectedIndex = 0; // Bottom navigation bar index
  DateTime? nextClassDate;
  String? latestAssignment;
  String? latestAnnouncement;
  List<Map<String, dynamic>> attendance = [];
  int unreadAssignments = 0;
  int unreadAnnouncements = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final instructorDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(user.uid)
        .get();
    if (instructorDoc.exists) {
      final instructorId = instructorDoc.data()?['instructorId'];
      if (instructorId != null) {
        // Load next class date
        final nextClassDoc = await FirebaseFirestore.instance
            .collection('instructors')
            .doc(instructorId)
            .get();
        if (nextClassDoc.exists) {
          setState(() {
            nextClassDate = (nextClassDoc.data()!['nextClassDate'] as Timestamp?)?.toDate();
          });
        }

        // Load latest assignment and count unread
        final assignmentSnapshot = await FirebaseFirestore.instance
            .collection('instructors')
            .doc(instructorId)
            .collection('assignments')
            .orderBy('timestamp', descending: true)
            .limit(5) // Fetch last 5 to check unread
            .get();
        if (assignmentSnapshot.docs.isNotEmpty) {
          setState(() {
            latestAssignment = assignmentSnapshot.docs.first.data()['text'];
            unreadAssignments = assignmentSnapshot.docs.length; // Simple count; refine later
          });
        }

        // Load latest announcement and count unread
        final announcementSnapshot = await FirebaseFirestore.instance
            .collection('instructors')
            .doc(instructorId)
            .collection('announcements')
            .orderBy('timestamp', descending: true)
            .limit(5) // Fetch last 5 to check unread
            .get();
        if (announcementSnapshot.docs.isNotEmpty) {
          setState(() {
            latestAnnouncement = announcementSnapshot.docs.first.data()['text'];
            unreadAnnouncements = announcementSnapshot.docs.length; // Simple count; refine later
          });
        }

        // Load attendance
        final cycleDoc = await FirebaseFirestore.instance
            .collection('instructors')
            .doc(instructorId)
            .collection('cycles')
            .doc('current')
            .get();
        if (cycleDoc.exists) {
          final data = cycleDoc.data()!;
          setState(() {
            attendance = (data['attendance'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          });
        }
      }
    }
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F0), // Off-White background
      body: SafeArea(
        child: _selectedIndex == 0
            ? _buildDashboard()
            : _selectedIndex == 1
                ? _buildAttendance()
                : _selectedIndex == 2
                    ? _buildProfile()
                    : Container(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFECE2E1), // Dark Blue
        unselectedItemColor: const Color(0xFFA6B1E1), // Teal
        backgroundColor: const Color(0xFF424874), // Off-White background
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mentora',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E5077), // Dark Blue
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFF2E5077)),
                  onPressed: () => _logout(context),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Center(
              child: SvgPicture.asset(
                'assets/images/student.svg',
                width: 150,
                height: 150,
                placeholderBuilder: (context) => const Placeholder(
                  fallbackWidth: 150,
                  fallbackHeight: 150,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Student Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E5077), // Dark Blue
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Next Class on ${nextClassDate != null ? '${nextClassDate!.day}${['th', 'st', 'nd', 'rd', 'th'][nextClassDate!.day % 10 > 3 ? 4 : nextClassDate!.day % 10]} ${nextClassDate!.toString().substring(0, 10)} at 6:00 PM' : 'Not set'}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF2E5077)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Card(
                    color: const Color(0xFFDCD6F7), // Light Green
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                     //side: const BorderSide(color: Color(0xFF4DA1A9)), // Teal
                    ),
                    child: InkWell(
                      onTap: () {
                        // Navigate to assignment details (to be implemented)
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Stack(
                          children: [
                            const Align(
                              alignment: Alignment.center,
                              child: Text(
                                'View Assignment',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (unreadAssignments > 0)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadAssignments.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    color: const Color(0xFFDCD6F7), // Light Green
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      //side: const BorderSide(color: Color(0xFF4DA1A9)), // Teal
                    ),
                    child: InkWell(
                      onTap: () {
                        // Navigate to announcement details (to be implemented)
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Stack(
                          children: [
                            const Align(
                              alignment: Alignment.center,
                              child: Text(
                                'View Announcement',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (unreadAnnouncements > 0)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadAnnouncements.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendance() {
    // Group attendance by month
    Map<int, List<Map<String, dynamic>>> groupedAttendance = {};
    for (var entry in attendance) {
      final date = (entry['date'] as Timestamp).toDate();
      final month = date.month;
      if (!groupedAttendance.containsKey(month)) {
        groupedAttendance[month] = [];
      }
      groupedAttendance[month]!.add(entry);
    }

    // Sort months
    var sortedMonths = groupedAttendance.keys.toList()..sort();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E5077), // Dark Blue
              ),
            ),
            const SizedBox(height: 20),
            if (sortedMonths.isEmpty)
              const Text('No attendance data available'),
            ...sortedMonths.map((month) {
              final monthData = groupedAttendance[month]!;
              final totalClasses = monthData.length;
              final presentCount = monthData.where((entry) => entry['status'] == 'Present').length;
              final absentCount = monthData.where((entry) => entry['status'] == 'Absent').length;
              final rescheduledCount = monthData.where((entry) => entry['status'] == 'Rescheduled').length;
              final extraClassCount = monthData.where((entry) => entry['status'] == 'Extra Class').length;
              final cancelledCount = monthData.where((entry) => entry['status'] == 'Cancelled by Student').length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Month $month',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E5077)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Classes:', style: TextStyle(fontSize: 16)),
                      Text('$totalClasses', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Present:', style: TextStyle(fontSize: 16)),
                      Text('$presentCount', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Absent:', style: TextStyle(fontSize: 16)),
                      Text('$absentCount', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Rescheduled:', style: TextStyle(fontSize: 16)),
                      Text('$rescheduledCount', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Extra Classes:', style: TextStyle(fontSize: 16)),
                      Text('$extraClassCount', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cancelled by Student:', style: TextStyle(fontSize: 16)),
                      Text('$cancelledCount', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Color(0xFF4DA1A9), thickness: 1), // Teal divider
                  const SizedBox(height: 10),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return const ProfilePage(role: 'Student');
  }
}