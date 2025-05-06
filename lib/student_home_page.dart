import 'dart:async';
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
  List<Map<String, dynamic>> attendance = [];
  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> announcements = [];
  int unreadAssignments = 0;
  int unreadAnnouncements = 0;
  late StreamSubscription<QuerySnapshot> _attendanceSubscription;
  late StreamSubscription<QuerySnapshot> _assignmentsSubscription;
  late StreamSubscription<QuerySnapshot> _announcementsSubscription;
  late StreamSubscription<DocumentSnapshot> _nextClassSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupSubscriptions();
  }

  @override
  void dispose() {
    _attendanceSubscription.cancel();
    _assignmentsSubscription.cancel();
    _announcementsSubscription.cancel();
    _nextClassSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final studentDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (studentDoc.exists) {
      setState(() {
        nextClassDate = (studentDoc.data()?['nextClassDate'] as Timestamp?)?.toDate();
      });
    }
  }

  void _setupSubscriptions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Real-time updates for next class and payment reminder
    _nextClassSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          nextClassDate = (snapshot.data()?['nextClassDate'] as Timestamp?)?.toDate();
        });
      }
    });

    // Real-time attendance updates
    _attendanceSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          attendance = (data['attendance'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        });
      }
    });

    // Real-time assignments updates
    _assignmentsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('assignments')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        assignments = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'text': doc.data()['text'],
                  'timestamp': (doc.data()['timestamp'] as Timestamp).toDate(),
                  'completed': doc.data()['completed'] ?? false,
                })
            .toList();
        unreadAssignments = assignments.where((a) => !(a['completed'] ?? false)).length;
      });
    });

    // Real-time announcements updates
    _announcementsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        announcements = snapshot.docs
            .map((doc) => {
                  'text': doc.data()['text'],
                  'timestamp': (doc.data()['timestamp'] as Timestamp).toDate(),
                })
            .toList();
        unreadAnnouncements = announcements.length; // Refine this logic later if needed
      });
    });
  }

  void _logout(BuildContext context) {
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
            const SizedBox(height: 20),
            // Payment Reminder Message
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
            const SizedBox(height: 50),
            const Text(
              'Student Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E5077), // Dark Blue
              ),
            ),
            const SizedBox(height: 40),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text(
                    'Error loading payment status',
                    style: TextStyle(color: Colors.red),
                  );
                }
                final paymentReminder = (snapshot.data!.data() as Map<String, dynamic>)['paymentReminder'] ?? false;
                return Text(
                  paymentReminder
                      ? 'Tuition fee is due. Please ensure timely payment.'
                      : 'No due tuition fee',
                  style: TextStyle(
                    fontSize: 16,
                    color: paymentReminder ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Next Class ${nextClassDate != null ? '${nextClassDate!.day}${['th', 'st', 'nd', 'rd', 'th'][nextClassDate!.day % 10 > 3 ? 4 : nextClassDate!.day % 10]} ${nextClassDate!.toString().substring(0, 10)}' : 'not announced yet'}',
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
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AssignmentsPage(
                              assignments: assignments,
                              onAssignmentStatusChanged: (assignmentId, completed) {
                                setState(() {
                                  final index = assignments.indexWhere((a) => a['id'] == assignmentId);
                                  if (index != -1) {
                                    assignments[index]['completed'] = completed;
                                    unreadAssignments = assignments.where((a) => !(a['completed'] ?? false)).length;
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Stack(
                          children: [
                            const Align(
                              alignment: Alignment.center,
                              child: Text(
                                'Assignment',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (unreadAssignments > 0)
                              Positioned(
                                top: 1,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF424874),
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
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AnnouncementsPage(announcements: announcements),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Stack(
                          children: [
                            const Align(
                              alignment: Alignment.center,
                              child: Text(
                                'Announcement',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (unreadAnnouncements > 0)
                              Positioned(
                                top: 1,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF424874),
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
    Map<int, List<Map<String, dynamic>>> groupedAttendance = {};
    for (var entry in attendance) {
      final date = (entry['date'] as Timestamp).toDate();
      final month = date.month;
      if (!groupedAttendance.containsKey(month)) {
        groupedAttendance[month] = [];
      }
      groupedAttendance[month]!.add(entry);
    }

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
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E5077),
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
                  const Divider(color: Color(0xFF4DA1A9), thickness: 1),
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

class AssignmentsPage extends StatelessWidget {
  final List<Map<String, dynamic>> assignments;
  final Function(String, bool) onAssignmentStatusChanged;

  const AssignmentsPage({super.key, required this.assignments, required this.onAssignmentStatusChanged});

  Future<void> _updateAssignmentStatus(BuildContext context, String assignmentId, bool completed) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(completed ? 'Mark as Done' : 'Mark as Undone'),
        content: Text('Are you sure you want to mark this assignment as ${completed ? 'done' : 'undone'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF2E5077))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('assignments')
        .doc(assignmentId)
        .update({'completed': completed});

    final studentDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final instructorId = studentDoc.data()?['instructorId'];

    if (instructorId != null) {
      await FirebaseFirestore.instance
          .collection('instructors')
          .doc(instructorId)
          .collection('students')
          .doc(user.uid)
          .collection('assignments')
          .doc(assignmentId)
          .update({'completed': completed});
    }

    onAssignmentStatusChanged(assignmentId, completed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F0),
      appBar: AppBar(
        title: const Text(
          'Assignments',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E5077),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Assignments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5077),
                ),
              ),
              const SizedBox(height: 20),
              if (assignments.isEmpty)
                const Text('No assignments available'),
              ...assignments.map((assignment) {
                final bool completed = assignment['completed'] ?? false;
                return Card(
                  color: const Color(0xFFDCD6F7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignment['text'],
                                style: TextStyle(
                                  fontSize: 16,
                                  decoration: completed ? TextDecoration.lineThrough : TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Posted on: ${assignment['timestamp'].toString().substring(0, 10)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            completed ? Icons.check_circle : Icons.check_circle_outline,
                            color: completed ? Colors.green : Colors.grey,
                          ),
                          onPressed: () => _updateAssignmentStatus(context, assignment['id'], !completed),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class AnnouncementsPage extends StatelessWidget {
  final List<Map<String, dynamic>> announcements;

  const AnnouncementsPage({super.key, required this.announcements});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F0),
      appBar: AppBar(
        title: const Text(
          'Announcements',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E5077),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Announcements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5077),
                ),
              ),
              const SizedBox(height: 20),
              if (announcements.isEmpty)
                const Text('No announcements available'),
              ...announcements.map((announcement) {
                return Card(
                  color: const Color(0xFFDCD6F7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement['text'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Posted on: ${announcement['timestamp'].toString().substring(0, 10)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}