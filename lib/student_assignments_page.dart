import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentAssignmentsPage extends StatelessWidget {
  const StudentAssignmentsPage({super.key});

  void _markAsDone(String assignmentId) {
    FirebaseFirestore.instance
        .collection('assignments')
        .doc(assignmentId)
        .update({'status': 'done'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Student Assignments")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('assignments')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Something went wrong!"));
          }

          final assignments = snapshot.data!.docs;
          return ListView.builder(
            itemCount: assignments.length,
            itemBuilder: (ctx, index) {
              final assignment = assignments[index]['assignment'];
              final assignmentId = assignments[index].id;
              return ListTile(
                title: Text(assignment),
                subtitle: Text(
                  assignments[index]['timestamp'].toDate().toString(),
                ),
                trailing: ElevatedButton(
                  onPressed: () => _markAsDone(assignmentId),
                  child: Text('Mark as Done'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
