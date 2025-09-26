import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoctorService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> loadDoctors() async {
    final snapshot = await _firestore.collection('doctors').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      if (data['availability'] != null) {
        data['availability'] = (data['availability'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, List<String>.from(value)));
      }
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> loadDoctorsByDepartment(
    String department,
  ) async {
    final snapshot = await _firestore
        .collection('doctors')
        .where('department', isEqualTo: department)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        ...data,
        'id': doc.id,
        'availability': Map<String, List<String>>.from(
          (data['availability'] as Map).map(
            (key, value) => MapEntry(
              key,
              value is List ? List<String>.from(value) : <String>[],
            ),
          ),
        ),
      };
    }).toList();
  }

  Future<void> addDoctor(Map<String, dynamic> doctor) async {
    await _firestore.collection('doctors').add(doctor);
    notifyListeners();
  }

  Future<void> updateDoctor(String id, Map<String, dynamic> doctor) async {
    await _firestore.collection('doctors').doc(id).update(doctor);
    notifyListeners();
  }

  Future<void> deleteDoctor(String id) async {
    await _firestore.collection('doctors').doc(id).delete();
    notifyListeners();
  }
}
