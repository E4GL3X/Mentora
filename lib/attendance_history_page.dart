import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

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

    final cycles = await Future.wait(historySnapshot.docs.map((doc) async {
      final cycleData = doc.data();
      final attendanceList = (cycleData['attendance'] as List<dynamic>?) ?? [];

      final Map<String, Map<String, List<Map<String, dynamic>>>> groupedByStudentAndMonth = {};
      for (var entry in attendanceList) {
        final studentId = entry['studentId'] as String?;
        final date = (entry['date'] as Timestamp?)?.toDate();
        if (studentId == null || date == null) continue;

        final studentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get();
        final studentName = studentDoc.data()?['name'] ?? 'Unknown';

        final monthName = DateFormat('MMMM').format(date);

        if (!groupedByStudentAndMonth.containsKey(studentId)) {
          groupedByStudentAndMonth[studentId] = {};
        }
        if (!groupedByStudentAndMonth[studentId]!.containsKey(monthName)) {
          groupedByStudentAndMonth[studentId]![monthName] = [];
        }
        groupedByStudentAndMonth[studentId]![monthName]!.add({
          'name': studentName,
          'status': entry['status'] ?? 'Unknown',
        });
      }

      final List<Map<String, dynamic>> cycleEntries = [];
      groupedByStudentAndMonth.forEach((studentId, months) {
        months.forEach((month, entries) {
          cycleEntries.add({
            'studentId': studentId,
            'month': month,
            'attendance': entries,
          });
        });
      });

      return cycleEntries;
    }).toList());

    setState(() {
      cycleHistory = cycles.expand((entry) => entry).toList();
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
                        final month = cycle['month'] as String;
                        final attendanceEntries = cycle['attendance'] as List<Map<String, dynamic>>;
                        final studentName = attendanceEntries.isNotEmpty
                            ? attendanceEntries.first['name']
                            : 'Unknown';

                        final presentCount = attendanceEntries
                            .where((entry) => entry['status'] == 'Present')
                            .length;
                        final absentCount = attendanceEntries
                            .where((entry) => entry['status'] == 'Absent')
                            .length;
                        final rescheduledCount = attendanceEntries
                            .where((entry) => entry['status'] == 'Rescheduled')
                            .length;
                        final extraClassCount = attendanceEntries
                            .where((entry) => entry['status'] == 'Extra Class')
                            .length;
                        final cancelledCount = attendanceEntries
                            .where((entry) => entry['status'] == 'Cancelled by Student')
                            .length;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF424874),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                month,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF424874),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Present $presentCount'),
                                  Text('Absent $absentCount'),
                                  Text('Rescheduled $rescheduledCount'),
                                  Text('Extra Class $extraClassCount'),
                                  Text('Cancelled by Student $cancelledCount'),
                                ],
                              ),
                            ],
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