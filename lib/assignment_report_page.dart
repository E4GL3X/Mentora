import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AssignmentReportPage extends StatefulWidget {
  const AssignmentReportPage({super.key});

  @override
  State<AssignmentReportPage> createState() => _AssignmentReportPageState();
}

class _AssignmentReportPageState extends State<AssignmentReportPage> {
  List<Map<String, dynamic>> students = [];
  String? selectedStudentId;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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

    setState(() {
      students = studentsList;
      if (students.isNotEmpty) {
        selectedStudentId = students.first['id'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F0),
      appBar: AppBar(
        title: const Text(
          'Assignment Report',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF424874),
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
                'Select Student',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424874),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
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
                  setState(() {
                    selectedStudentId = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (selectedStudentId != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('instructors')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('students')
                      .doc(selectedStudentId)
                      .collection('assignments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final assignments = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      return {
                        'text': data['text'] ?? 'No description',
                        'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                        'completed': data['completed'] ?? false,
                      };
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assignment Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424874),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (assignments.isEmpty)
                          const Text('No assignments available'),
                        ...assignments.map((assignment) {
                          final bool completed = assignment['completed'] ?? false;
                          return Card(
                            color: const Color(0xFFA6B1E1),
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
                                  Icon(
                                    completed ? Icons.check_circle : Icons.check_circle_outline,
                                    color: completed ? Colors.green : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
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