import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final String role;
  final String? studentId; // Optional: For instructors viewing a student's profile

  const ProfilePage({super.key, required this.role, this.studentId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with AutomaticKeepAliveClientMixin {
  String? name;
  String? email;
  String? school;
  String? college;
  String? university;
  String? address;
  String? phone;
  String? bloodGroup;
  String? studentNumber;
  bool isEditing = false;
  String? avatarUrl;
  List<Map<String, dynamic>> pendingRequests = [];
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController schoolController = TextEditingController();
  TextEditingController collegeController = TextEditingController();
  TextEditingController universityController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController bloodGroupController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.studentId != null) {
      _loadStudentData(widget.studentId!); // Load student data if viewing a student
    } else {
      _loadCachedData();
      _loadProfileData();
      if (widget.role == 'Student') {
        _loadPendingRequests();
      }
    }
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      name = prefs.getString('name_${user.uid}') ?? 'No name';
      email = prefs.getString('email_${user.uid}') ?? 'No email';
      school = prefs.getString('school_${user.uid}') ?? '';
      college = prefs.getString('college_${user.uid}') ?? '';
      university = prefs.getString('university_${user.uid}') ?? '';
      address = prefs.getString('address_${user.uid}') ?? '';
      phone = prefs.getString('phone_${user.uid}') ?? '';
      bloodGroup = prefs.getString('bloodGroup_${user.uid}') ?? '';
      studentNumber = prefs.getString('studentNumber_${user.uid}');
      nameController.text = name ?? '';
      emailController.text = email ?? '';
      schoolController.text = school ?? '';
      collegeController.text = college ?? '';
      universityController.text = university ?? '';
      addressController.text = address ?? '';
      phoneController.text = phone ?? '';
      bloodGroupController.text = bloodGroup ?? '';
      avatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name ?? 'No name')}&size=200&background=A6B1E1&color=fff';
    });
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          name = doc.data()?['name'] ?? 'No name';
          email = user.email ?? 'No email';
          school = doc.data()?['school'] ?? '';
          college = doc.data()?['college'] ?? '';
          university = doc.data()?['university'] ?? '';
          address = doc.data()?['address'] ?? '';
          phone = doc.data()?['phone'] ?? '';
          bloodGroup = doc.data()?['bloodGroup'] ?? '';
          studentNumber = doc.data()?['studentNumber'];
          nameController.text = name ?? '';
          emailController.text = email ?? '';
          schoolController.text = school ?? '';
          collegeController.text = college ?? '';
          universityController.text = university ?? '';
          addressController.text = address ?? '';
          phoneController.text = phone ?? '';
          bloodGroupController.text = bloodGroup ?? '';
          avatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name ?? 'No name')}&size=200&background=A6B1E1&color=fff';
        });

        await prefs.setString('name_${user.uid}', name ?? '');
        await prefs.setString('email_${user.uid}', email ?? '');
        await prefs.setString('school_${user.uid}', school ?? '');
        await prefs.setString('college_${user.uid}', college ?? '');
        await prefs.setString('university_${user.uid}', university ?? '');
        await prefs.setString('address_${user.uid}', address ?? '');
        await prefs.setString('phone_${user.uid}', phone ?? '');
        await prefs.setString('bloodGroup_${user.uid}', bloodGroup ?? '');
        if (studentNumber != null) {
          await prefs.setString('studentNumber_${user.uid}', studentNumber!);
        }
      }
    } catch (e) {
      print('Error fetching from Firestore: $e');
    }
  }

  Future<void> _loadStudentData(String studentId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();
      if (doc.exists) {
        setState(() {
          name = doc.data()?['name'] ?? 'No name';
          email = doc.data()?['email'] ?? 'No email';
          school = doc.data()?['school'] ?? '';
          college = doc.data()?['college'] ?? '';
          university = doc.data()?['university'] ?? '';
          address = doc.data()?['address'] ?? '';
          phone = doc.data()?['phone'] ?? '';
          bloodGroup = doc.data()?['bloodGroup'] ?? '';
          studentNumber = doc.data()?['studentNumber'];
          avatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name ?? 'No name')}&size=200&background=A6B1E1&color=fff';
        });
      }
    } catch (e) {
      print('Error fetching student data: $e');
    }
  }

  Future<void> _loadPendingRequests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final query = await FirebaseFirestore.instance
        .collection('requests')
        .where('to', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    final requests = await Future.wait(query.docs.map((doc) async {
      final requestData = doc.data();
      final instructorId = requestData['from'];
      final instructorDoc = await FirebaseFirestore.instance.collection('users').doc(instructorId).get();
      return {
        'requestId': doc.id,
        'instructorName': instructorDoc.data()?['name'] ?? 'Unknown',
        'instructorId': instructorId,
      };
    }));

    setState(() {
      pendingRequests = requests;
    });
  }

  Future<void> _acceptRequest(String requestId, String instructorId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Add to relationships collection
      await FirebaseFirestore.instance.collection('relationships').add({
        'instructorId': instructorId,
        'studentId': user.uid,
      });

      // Delete request
      await FirebaseFirestore.instance.collection('requests').doc(requestId).delete();

      // Refresh requests
      await _loadPendingRequests();
    } catch (e) {
      print('Error accepting request: $e');
    }
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(requestId).delete();
      await _loadPendingRequests();
    } catch (e) {
      print('Error declining request: $e');
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': nameController.text,
        'email': emailController.text,
        'school': schoolController.text,
        'college': collegeController.text,
        'university': universityController.text,
        'address': addressController.text,
        'phone': phoneController.text,
        'bloodGroup': bloodGroupController.text,
        'role': widget.role,
        if (widget.role == 'Student') 'studentNumber': studentNumber,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving to Firestore: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name_${user.uid}', nameController.text);
    await prefs.setString('email_${user.uid}', emailController.text);
    await prefs.setString('school_${user.uid}', schoolController.text);
    await prefs.setString('college_${user.uid}', collegeController.text);
    await prefs.setString('university_${user.uid}', universityController.text);
    await prefs.setString('address_${user.uid}', addressController.text);
    await prefs.setString('phone_${user.uid}', phoneController.text);
    await prefs.setString('bloodGroup_${user.uid}', bloodGroupController.text);

    setState(() {
      name = nameController.text;
      email = emailController.text;
      school = schoolController.text;
      college = collegeController.text;
      university = universityController.text;
      address = addressController.text;
      phone = phoneController.text;
      bloodGroup = bloodGroupController.text;
      isEditing = false;
      avatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name ?? 'No name')}&size=200&background=A6B1E1&color=fff';
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      widget.studentId != null ? 'Student Profile' : widget.role,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424874),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 20),
                if (avatarUrl != null)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(avatarUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  widget.studentId != null ? 'Student Details' : '${widget.role} Details',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF424874),
                  ),
                ),
                const SizedBox(height: 10),
                if (!isEditing || widget.studentId != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: $name', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Email: $email', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Phone: $phone', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('School: $school', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('College: $college', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('University: $university', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Address: $address', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Blood Group: $bloodGroup', style: const TextStyle(fontSize: 16)),
                      if (studentNumber != null) ...[
                        const SizedBox(height: 8),
                        Text('Student Number: $studentNumber', style: const TextStyle(fontSize: 16)),
                      ],
                      if (widget.studentId == null && widget.role == 'Student') ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Pending Requests',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424874),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (pendingRequests.isEmpty)
                          const Text('No pending requests', style: TextStyle(fontSize: 16)),
                        ...pendingRequests.map((request) {
                          return ListTile(
                            title: Text('From: ${request['instructorName']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () => _acceptRequest(request['requestId'], request['instructorId']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _declineRequest(request['requestId']),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      if (widget.studentId == null) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isEditing = !isEditing;
                              });
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFA6B1E1),
                              child: const Icon(Icons.edit, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                if (isEditing && widget.studentId == null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: schoolController,
                        decoration: const InputDecoration(labelText: 'School'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: collegeController,
                        decoration: const InputDecoration(labelText: 'College'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: universityController,
                        decoration: const InputDecoration(labelText: 'University'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: bloodGroupController,
                        decoration: const InputDecoration(labelText: 'Blood Group'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF424874),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Save', style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isEditing = false;
                                nameController.text = name ?? '';
                                emailController.text = email ?? '';
                                schoolController.text = school ?? '';
                                collegeController.text = college ?? '';
                                universityController.text = university ?? '';
                                addressController.text = address ?? '';
                                phoneController.text = phone ?? '';
                                bloodGroupController.text = bloodGroup ?? '';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA6B1E1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}