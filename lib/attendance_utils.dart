import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceUtils {
  static Future<void> updateAttendanceInBothCollections(
    String studentId,
    Map<String, dynamic> attendanceData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final instructorId = user.uid;
    print('Attempting to update attendance for studentId: $studentId, instructorId: $instructorId');

    try {
      // Update instructor's collection with instructor's UID as document ID
      await FirebaseFirestore.instance
          .collection('instructors')
          .doc(instructorId)
          .collection('cycles')
          .doc(instructorId)
          .set({
            'attendance': FieldValue.arrayUnion([attendanceData])
          }, SetOptions(merge: true));
      print('Successfully updated instructors/$instructorId/cycles/$instructorId');

      // Update student's collection with instructor's UID as document ID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .collection('cycles')
          .doc(instructorId)
          .set({
            'attendance': FieldValue.arrayUnion([attendanceData])
          }, SetOptions(merge: true));
      print('Successfully updated users/$studentId/cycles/$instructorId');
    } catch (e) {
      print('Error updating attendance: $e');
      throw e; // Re-throw to handle errors upstream
    }
  }
}