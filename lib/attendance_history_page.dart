import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentora/login_page.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  List<Map<String, dynamic>> cycleHistory = [];

  @override
  void initState() {
    super.initState();
    _loadCycleHistory();
  }

  Future<void> _loadCycleHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final historySnapshot = await FirebaseFirestore.instance
        .collection('instructors')
        .doc(user.uid)
        .collection('cycles')
        .get();
    setState(() {
      cycleHistory = historySnapshot.docs
          .where((doc) => !doc.id.startsWith('current'))
          .map((doc) => doc.data())
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance Tracker',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424874),
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
                          color: const Color(0xFFDCD6F7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: const BorderSide(color: Color(0xFFA6B1E1)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Month ${index + 1} (${cycle['startDate']?.toDate().toString().substring(0, 10)} - ${cycle['endDate']?.toDate().toString().substring(0, 10)})',
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
      ),
    );
  }
}