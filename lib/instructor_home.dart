import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mentora/login_page.dart';
import 'package:mentora/profile_page.dart';
import 'package:mentora/students_page.dart';
import 'package:table_calendar/table_calendar.dart';

class InstructorHome extends StatefulWidget {
  const InstructorHome({super.key});

  @override
  State<InstructorHome> createState() => _InstructorHomeState();
}

class _InstructorHomeState extends State<InstructorHome> {
  int _selectedIndex = 0; // Bottom navigation bar index
  DateTime? cycleStartDate;
  DateTime? cycleEndDate;
  DateTime? nextClassDate;
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  String? selectedStatus;
  String? assignmentText;
  String? announcementText;
  final List<String> statusOptions = [
    'Present',
    'Absent',
    'Rescheduled',
    'Extra Class',
    'Cancelled by Student'
  ];
  List<Map<String, dynamic>> cycleHistory = []; // Store cycle summaries

  @override
  void initState() {
    super.initState();
    _loadCycleData();
  }

  Future<void> _loadCycleData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Load current cycle data
    final cycleDoc = await FirebaseFirestore.instance
        .collection('instructors')
        .doc(user.uid)
        .collection('cycles')
        .doc('current')
        .get();
    if (cycleDoc.exists) {
      final data = cycleDoc.data()!;
      setState(() {
        cycleStartDate = (data['startDate'] as Timestamp?)?.toDate();
        cycleEndDate = (data['endDate'] as Timestamp?)?.toDate();
        if (cycleEndDate != null && DateTime.now().isAfter(cycleEndDate!)) {
          _resetCycle();
        }
      });
    }

    // Load next class date
    final nextClassDoc = await FirebaseFirestore.instance
        .collection('instructors')
        .doc(user.uid)
        .get();
    if (nextClassDoc.exists) {
      setState(() {
        nextClassDate = (nextClassDoc.data()!['nextClassDate'] as Timestamp?)?.toDate();
      });
    }

    // Load cycle history
    final historySnapshot = await FirebaseFirestore.instance
        .collection('instructors')
        .doc(user.uid)
        .collection('cycles')
        .get();
    setState(() {
      cycleHistory = historySnapshot.docs
          .where((doc) => doc.id != 'current')
          .map((doc) => doc.data())
          .toList();
    });
  }

  Future<void> _resetCycle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Archive current cycle
    final currentCycle = await FirebaseFirestore.instance
        .collection('instructors')
        .doc(user.uid)
        .collection('cycles')
        .doc('current')
        .get();
    if (currentCycle.exists) {
      await FirebaseFirestore.instance
          .collection('instructors')
          .doc(user.uid)
          .collection('cycles')
          .doc('cycle_${DateTime.now().millisecondsSinceEpoch}')
          .set(currentCycle.data()!);
    }

    // Reset for new cycle
    await FirebaseFirestore.instance
        .collection('instructors')
        .doc(user.uid)
        .collection('cycles')
        .doc('current')
        .set({
      'startDate': null,
      'endDate': null,
      'attendance': [],
    });

    setState(() {
      cycleStartDate = null;
      cycleEndDate = null;
    });
  }

  Future<void> _setCycleDates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || cycleStartDate == null || cycleEndDate == null) return;

    await FirebaseFirestore.instance
        .collection('instructors')
        .doc(user.uid)
        .collection('cycles')
        .doc('current')
        .set({
      'startDate': Timestamp.fromDate(cycleStartDate!),
      'endDate': Timestamp.fromDate(cycleEndDate!),
      'attendance': [],
    }, SetOptions(merge: true));
  }

  Future<void> _submitAttendance() async {
    if (selectedDay == null || selectedStatus == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final attendanceEntry = {
      'date': Timestamp.fromDate(selectedDay!),
      'status': selectedStatus,
    };

    await FirebaseFirestore.instance
        .collection('instructors')
        .doc(user.uid)
        .collection('cycles')
        .doc('current')
        .update({
      'attendance': FieldValue.arrayUnion([attendanceEntry]),
    });

    setState(() {
      selectedStatus = null;
    });
  }

  Future<void> _setNextClassDate() async {
    if (nextClassDate == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('instructors')
        .doc(user.uid)
        .set({
      'nextClassDate': Timestamp.fromDate(nextClassDate!),
    }, SetOptions(merge: true));
  }

  Future<void> _submitAssignment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || assignmentText == null) return;

    await FirebaseFirestore.instance
        .collection('instructors')
        .doc(user.uid)
        .collection('assignments')
        .add({
      'text': assignmentText,
      'timestamp': Timestamp.now(),
    });

    setState(() {
      assignmentText = null;
    });
  }

  Future<void> _submitAnnouncement() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || announcementText == null) return;

    await FirebaseFirestore.instance
        .collection('instructors')
        .doc(user.uid)
        .collection('announcements')
        .add({
      'text': announcementText,
      'timestamp': Timestamp.now(),
    });

    setState(() {
      announcementText = null;
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
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
      backgroundColor: const Color(0xFFF6F4F0), // Light Purple background
      body: SafeArea(
        child: _selectedIndex == 0
            ? _buildDashboard()
            : _selectedIndex == 1
                ? _buildAttendanceHistory()
                : _selectedIndex == 2
                    ? _buildStudents()
                    : _buildProfile(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Attendance Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFECE2E1), // Dark Blue
        unselectedItemColor: const Color(0xFFA6B1E1), // Teal
        backgroundColor: const Color(0xFF424874), // Dark Blue
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
            // Title and Logout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mentora',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424874), // Dark Blue
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFF424874)),
                  onPressed: logout,
                ),
              ],
            ),
            const SizedBox(height: 50),

            // SVG Image
            Center(
              child: SvgPicture.asset(
                'assets/images/instructor.svg',
                width: 150,
                height: 150,
                placeholderBuilder: (context) => const Placeholder(
                  fallbackWidth: 150,
                  fallbackHeight: 150,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Dashboard Title
            const Text(
              'Instructor Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424874), // Dark Blue
              ),
            ),
            const SizedBox(height: 20),

            // Cycle Dates and Next Class Date (Side by Side)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cycle Dates
                Expanded(
                  child: Card(
                    color: const Color(0xFFA6B1E1), // Soft Purple
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SizedBox(
                      height: 120, // Adjusted height to fit content
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cycle Dates',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Start: ${cycleStartDate?.toString().substring(0, 10) ?? 'Not set'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'End: ${cycleEndDate?.toString().substring(0, 10) ?? 'Not set'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: cycleStartDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() {
                                    if (cycleStartDate == null) {
                                      cycleStartDate = picked;
                                    } else if (cycleEndDate == null && picked.isAfter(cycleStartDate!)) {
                                      cycleEndDate = picked;
                                      _setCycleDates();
                                    } else {
                                      cycleStartDate = picked;
                                      cycleEndDate = null;
                                    }
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF424874), // Custom color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(60, 30), // Small button
                              ),
                              child: const Text(
                                'Add',
                                style: TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Next Class Date
                Expanded(
                  child: Card(
                    color: const Color(0xFFA6B1E1), // Soft Purple
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SizedBox(
                      height: 120, // Adjusted height to fit content
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Next Class',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  nextClassDate?.toString().substring(0, 10) ?? 'Not set',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: nextClassDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() {
                                    nextClassDate = picked;
                                    _setNextClassDate();
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF424874), // Custom color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(60, 30), // Small button
                              ),
                              child: const Text(
                                'Add',
                                style: TextStyle(fontSize: 12, color: Colors.white),
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
            const SizedBox(height: 20),

            // Attendance
            Card(
              color: const Color(0xFFA6B1E1), // Soft Purple
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mark Attendance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      hint: const Text('Select Status'),
                      value: selectedStatus,
                      isExpanded: true,
                      items: statusOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: selectedDay != null && selectedStatus != null
                          ? _submitAttendance
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF424874), // Dark Blue
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Submit', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Assignment
            Card(
              color: const Color(0xFFA6B1E1), // Soft Purple
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Assignment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          assignmentText = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Enter Assignment',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: assignmentText != null && assignmentText!.isNotEmpty
                          ? _submitAssignment
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF424874), // Dark Blue
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Submit', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Announcement
            Card(
              color: const Color(0xFFA6B1E1), // Soft Purple
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Announcement',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          announcementText = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Enter announcement',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: announcementText != null && announcementText!.isNotEmpty
                          ? _submitAnnouncement
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF424874), // Dark Blue
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Submit', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceHistory() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Tracker',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424874), // Dark Blue
              ),
            ),
            const SizedBox(height: 20),
            cycleHistory.isEmpty
                ? const Center(child: Text('No history available'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cycleHistory.length,
                    itemBuilder: (context, index) {
                      final cycle = cycleHistory[index];
                      final attendance = (cycle['attendance'] as List<dynamic>?) ?? [];
                      final presentCount = attendance
                          .where((entry) => entry['status'] == 'Present')
                          .length;
                      final absentCount = attendance
                          .where((entry) => entry['status'] == 'Absent')
                          .length;
                      final rescheduledCount = attendance
                          .where((entry) => entry['status'] == 'Rescheduled')
                          .length;
                      final extraClassCount = attendance
                          .where((entry) => entry['status'] == 'Extra Class')
                          .length;
                      final cancelledCount = attendance
                          .where((entry) => entry['status'] == 'Cancelled by Student')
                          .length;

                      return Card(
                        color: const Color(0xFFDCD6F7), // Soft Purple
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(color: Color(0xFFA6B1E1)), // Muted Blue
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cycle ${index + 1} (${cycle['startDate']?.toDate().toString().substring(0, 10)} - ${cycle['endDate']?.toDate().toString().substring(0, 10)})',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Text('Present: $presentCount'),
                              Text('Absent: $absentCount'),
                              Text('Rescheduled: $rescheduledCount'),
                              Text('Extra Classes: $extraClassCount'),
                              Text('Cancelled by Student: $cancelledCount'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudents() {
    return const StudentsPage();
  }

  Widget _buildProfile() {
    return const ProfilePage(role: 'Instructor');
  }
}