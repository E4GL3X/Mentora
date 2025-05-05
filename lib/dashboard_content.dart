import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  DateTime? cycleStartDate;
  DateTime? cycleEndDate;
  DateTime? nextClassDate;
  DateTime? selectedDay;
  String? selectedStatus;
  String? assignmentText;
  String? announcementText;
  final List<String> statusOptions = ['Present', 'Absent', 'Rescheduled', 'Extra Class', 'Cancelled by Student'];
  List<Map<String, dynamic>> students = [];
  String? selectedStudentId;
  bool isLoading = true;
  String? error;
  bool paymentReminder = false; // Track payment reminder status for the selected student

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      await _loadStudents();
      if (selectedStudentId != null) {
        await _loadCycleData();
        await _loadPaymentReminder();
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load data: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStudents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('relationships')
          .where('instructorId', isEqualTo: user.uid)
          .get();

      final studentsList = await Future.wait(query.docs.map((doc) async {
        final studentId = doc.data()['studentId'];
        final studentDoc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();
        return {
          'id': studentId,
          'name': studentDoc.data()?['name'] ?? 'Unknown',
        };
      }).toList());

      if (mounted) {
        setState(() {
          students = studentsList;
          if (students.isNotEmpty && selectedStudentId == null) {
            selectedStudentId = students.first['id'];
          }
        });
      }
    } catch (e) {
      throw Exception('Error loading students: $e');
    }
  }

  Future<void> _loadCycleData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || selectedStudentId == null) return;

    try {
      final cycleDoc = await FirebaseFirestore.instance
          .collection('instructors')
          .doc(user.uid)
          .collection('cycles')
          .doc(selectedStudentId)
          .get();
      if (cycleDoc.exists) {
        final data = cycleDoc.data()!;
        if (mounted) {
          setState(() {
            cycleStartDate = (data['startDate'] as Timestamp?)?.toDate();
            cycleEndDate = (data['endDate'] as Timestamp?)?.toDate();
            if (cycleEndDate != null && DateTime.now().isAfter(cycleEndDate!)) {
              _resetCycle();
            }
          });
        }
      }

      final nextClassDoc = await FirebaseFirestore.instance
          .collection('instructors')
          .doc(user.uid)
          .collection('students')
          .doc(selectedStudentId)
          .get();
      if (nextClassDoc.exists && mounted) {
        setState(() {
          nextClassDate = (nextClassDoc.data()!['nextClassDate'] as Timestamp?)?.toDate();
        });
      }
    } catch (e) {
      throw Exception('Error loading cycle data: $e');
    }
  }

  Future<void> _loadPaymentReminder() async {
    if (selectedStudentId == null) return;

    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(selectedStudentId)
          .get();
      if (studentDoc.exists && mounted) {
        setState(() {
          paymentReminder = studentDoc.data()!['paymentReminder'] ?? false;
        });
      }
    } catch (e) {
      throw Exception('Error loading payment reminder: $e');
    }
  }

  Future<void> _togglePaymentReminder() async {
    if (selectedStudentId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(selectedStudentId)
          .update({'paymentReminder': !paymentReminder});
      setState(() {
        paymentReminder = !paymentReminder;
      });
    } catch (e) {
      throw Exception('Error toggling payment reminder: $e');
    }
  }

  Future<void> _resetCycle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || selectedStudentId == null) return;

    try {
      final currentCycle = await FirebaseFirestore.instance
          .collection('instructors')
          .doc(user.uid)
          .collection('cycles')
          .doc(selectedStudentId)
          .get();
      if (currentCycle.exists) {
        await FirebaseFirestore.instance
            .collection('instructors')
            .doc(user.uid)
            .collection('cycles')
            .doc('cycle_${DateTime.now().millisecondsSinceEpoch}_${selectedStudentId}')
            .set(currentCycle.data()!);
      }

      await FirebaseFirestore.instance
          .collection('instructors')
          .doc(user.uid)
          .collection('cycles')
          .doc(selectedStudentId)
          .set({
        'startDate': null,
        'endDate': null,
        'attendance': [],
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(selectedStudentId)
          .collection('cycles')
          .doc(user.uid)
          .set({
        'startDate': null,
        'endDate': null,
        'attendance': [],
      });

      if (mounted) {
        setState(() {
          cycleStartDate = null;
          cycleEndDate = null;
        });
      }
    } catch (e) {
      throw Exception('Error resetting cycle: $e');
    }
  }

  Future<void> _setCycleDates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || cycleStartDate == null || cycleEndDate == null || selectedStudentId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('instructors')
          .doc(user.uid)
          .collection('cycles')
          .doc(selectedStudentId)
          .set({
        'startDate': Timestamp.fromDate(cycleStartDate!),
        'endDate': Timestamp.fromDate(cycleEndDate!),
        'attendance': FieldValue.arrayUnion([]),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(selectedStudentId)
          .collection('cycles')
          .doc(user.uid)
          .set({
        'startDate': Timestamp.fromDate(cycleStartDate!),
        'endDate': Timestamp.fromDate(cycleEndDate!),
        'attendance': FieldValue.arrayUnion([]),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error setting cycle dates: $e');
    }
  }

  Future<void> _submitAttendance() async {
    if (selectedDay == null || selectedStatus == null || selectedStudentId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final attendanceEntry = {
        'date': Timestamp.fromDate(selectedDay!),
        'status': selectedStatus,
      };

      await FirebaseFirestore.instance
          .collection('instructors')
          .doc(user.uid)
          .collection('cycles')
          .doc(selectedStudentId)
          .update({
        'attendance': FieldValue.arrayUnion([attendanceEntry]),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(selectedStudentId)
          .collection('cycles')
          .doc(user.uid)
          .update({
        'attendance': FieldValue.arrayUnion([attendanceEntry]),
      });

      if (mounted) {
        setState(() {
          selectedStatus = null;
          selectedDay = null;
        });
      }
    } catch (e) {
      throw Exception('Error submitting attendance: $e');
    }
  }

  Future<void> _setNextClassDate() async {
    if (nextClassDate == null || nextClassDate!.isBefore(DateTime.now()) || selectedStudentId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('instructors')
          .doc(user.uid)
          .collection('students')
          .doc(selectedStudentId)
          .set({
        'nextClassDate': Timestamp.fromDate(nextClassDate!),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(selectedStudentId)
          .update({
        'nextClassDate': Timestamp.fromDate(nextClassDate!),
      });
    } catch (e) {
      throw Exception('Error setting next class date: $e');
    }
  }

  Future<void> _submitAssignment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || assignmentText == null || selectedStudentId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('instructors')
          .doc(user.uid)
          .collection('students')
          .doc(selectedStudentId)
          .collection('assignments')
          .add({
        'text': assignmentText,
        'timestamp': Timestamp.now(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(selectedStudentId)
          .collection('assignments')
          .add({
        'text': assignmentText,
        'timestamp': Timestamp.now(),
        'fromInstructor': user.uid,
      });

      if (mounted) {
        setState(() {
          assignmentText = null;
        });
      }
    } catch (e) {
      throw Exception('Error submitting assignment: $e');
    }
  }

  Future<void> _submitAnnouncement() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || announcementText == null || selectedStudentId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('instructors')
          .doc(user.uid)
          .collection('students')
          .doc(selectedStudentId)
          .collection('announcements')
          .add({
        'text': announcementText,
        'timestamp': Timestamp.now(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(selectedStudentId)
          .collection('announcements')
          .add({
        'text': announcementText,
        'timestamp': Timestamp.now(),
        'fromInstructor': user.uid,
      });

      if (mounted) {
        setState(() {
          announcementText = null;
        });
      }
    } catch (e) {
      throw Exception('Error submitting announcement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: List.generate(4, (index) => Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
            height: 100,
            color: Colors.white,
          )),
        ),
      );
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

    if (students.isEmpty) {
      return const Center(child: Text('No students found.'));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instructor Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424874),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: DropdownButton<String>(
                hint: const Text('Select Student'),
                value: selectedStudentId,
                isExpanded: true,
                items: students.map((student) {
                  return DropdownMenuItem<String>(
                    value: student['id'],
                    child: Text(student['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  print('Dropdown changed to: $value');
                  setState(() {
                    selectedStudentId = value;
                    cycleStartDate = null;
                    cycleEndDate = null;
                    nextClassDate = null;
                    selectedDay = null;
                    selectedStatus = null;
                    paymentReminder = false; // Reset payment reminder
                    _loadCycleData();
                    _loadPaymentReminder();
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            // Payment Reminder Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedStudentId != null
                    ? () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Payment Reminder'),
                            content: Text(paymentReminder
                                ? 'Turn off payment reminder for this student?'
                                : 'Send a payment reminder to this student?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel', style: TextStyle(color: Color(0xFF2E5077))),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await _togglePaymentReminder();
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  paymentReminder ? 'Turn Off' : 'Send',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: paymentReminder ? const Color(0xFFFFB703) : const Color(0xFF424874),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  paymentReminder ? 'Reminder On' : 'Payment Reminder',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Card(
                    color: const Color(0xFFA6B1E1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SizedBox(
                      height: 140,
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
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () async {
                                  print('Cycle Date button pressed');
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
                                  backgroundColor: const Color(0xFF424874),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(fontSize: 12, color: Colors.white),
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
                    color: const Color(0xFFA6B1E1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SizedBox(
                      height: 140,
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
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () async {
                                  print('Next Class button pressed');
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: nextClassDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
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
                                  backgroundColor: const Color(0xFF424874),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(fontSize: 12, color: Colors.white),
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
            const SizedBox(height: 20),
            Card(
              color: const Color(0xFFA6B1E1),
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
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          print('Attendance Date button pressed');
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDay ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDay = picked;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF424874),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          selectedDay == null
                              ? 'Select Date'
                              : 'Date: ${selectedDay!.toString().substring(0, 10)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: DropdownButton<String>(
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
                          print('Status changed to: $value');
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (selectedDay != null && selectedStatus != null && selectedStudentId != null)
                            ? () {
                                print('Attendance submitted');
                                _submitAttendance();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF424874),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('Submit', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: const Color(0xFFA6B1E1),
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
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: assignmentText != null && assignmentText!.isNotEmpty && selectedStudentId != null
                            ? () {
                                print('Assignment submitted');
                                _submitAssignment();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF424874),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('Submit', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: const Color(0xFFA6B1E1),
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
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: announcementText != null && announcementText!.isNotEmpty && selectedStudentId != null
                            ? () {
                                print('Announcement submitted');
                                _submitAnnouncement();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF424874),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('Submit', style: TextStyle(color: Colors.white)),
                      ),
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
}