import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentora/profile_page.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final TextEditingController _studentNumberController = TextEditingController();
  Map<String, dynamic>? _foundStudent;
  String? _errorMessage;
  List<Map<String, dynamic>> _myStudents = [];

  @override
  void initState() {
    super.initState();
    _loadMyStudents();
  }

  Future<void> _loadMyStudents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final query = await FirebaseFirestore.instance
        .collection('relationships')
        .where('instructorId', isEqualTo: user.uid)
        .get();

    final students = await Future.wait(query.docs.map((doc) async {
      final studentId = doc.data()['studentId'];
      final studentDoc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();
      return {
        'studentId': studentId,
        'name': studentDoc.data()?['name'] ?? 'Unknown',
        'studentNumber': studentDoc.data()?['studentNumber'] ?? '',
      };
    }));

    setState(() {
      _myStudents = students;
    });
  }

  Future<void> _searchStudent() async {
    final studentNumber = _studentNumberController.text.trim();
    if (studentNumber.isEmpty || !studentNumber.startsWith('STU-') || studentNumber.length != 10) {
      setState(() {
        _errorMessage = 'Please enter a valid student number (e.g., STU-123456)';
        _foundStudent = null;
      });
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('studentNumber', isEqualTo: studentNumber)
          .where('role', isEqualTo: 'Student')
          .get();

      if (query.docs.isEmpty) {
        setState(() {
          _errorMessage = 'No student found with this number';
          _foundStudent = null;
        });
        return;
      }

      final studentDoc = query.docs.first;
      setState(() {
        _foundStudent = {
          'id': studentDoc.id,
          'name': studentDoc.data()['name'] ?? 'Unknown',
          'studentNumber': studentDoc.data()['studentNumber'],
        };
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching student: $e';
        _foundStudent = null;
      });
    }
  }

  Future<void> _sendRequest(String studentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check if a request already exists
      final existingRequest = await FirebaseFirestore.instance
          .collection('requests')
          .where('from', isEqualTo: user.uid)
          .where('to', isEqualTo: studentId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        setState(() {
          _errorMessage = 'Request already sent to this student';
        });
        return;
      }

      // Check if already in a relationship
      final existingRelationship = await FirebaseFirestore.instance
          .collection('relationships')
          .where('instructorId', isEqualTo: user.uid)
          .where('studentId', isEqualTo: studentId)
          .get();

      if (existingRelationship.docs.isNotEmpty) {
        setState(() {
          _errorMessage = 'This student is already in your list';
        });
        return;
      }

      // Send request
      await FirebaseFirestore.instance.collection('requests').add({
        'from': user.uid,
        'to': studentId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _errorMessage = 'Request sent successfully';
        _foundStudent = null;
        _studentNumberController.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sending request: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Students',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424874),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add New Student',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424874),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _studentNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Student Number (e.g., STU-123456)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed: _searchStudent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF424874),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Search', style: TextStyle(color: Colors.white)),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                if (_foundStudent != null) ...[
                  const SizedBox(height: 20),
                  ListTile(
                    title: Text('Name: ${_foundStudent!['name']}'),
                    subtitle: Text('Student Number: ${_foundStudent!['studentNumber']}'),
                    trailing: ElevatedButton(
                      onPressed: () => _sendRequest(_foundStudent!['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA6B1E1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Send Request', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'My Students',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424874),
                  ),
                ),
                const SizedBox(height: 10),
                if (_myStudents.isEmpty)
                  const Text('No students added yet', style: TextStyle(fontSize: 16)),
                ..._myStudents.map((student) {
                  return ListTile(
                    title: Text(student['name']),
                    subtitle: Text('Student Number: ${student['studentNumber']}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(
                            role: 'Student',
                            studentId: student['studentId'],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}