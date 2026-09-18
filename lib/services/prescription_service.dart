import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/prescription_model.dart';

class PrescriptionService {
  static final CollectionReference _collection =
      FirebaseFirestore.instance.collection('prescriptions');

  /// Upload prescription record to Firestore
  static Future<String?> savePrescription({
    required String userId,
    required String patientName,
    required String patientPhone,
    String? patientEmail,
    required String prescriptionUrl,
    String? notes,
  }) async {
    try {
      final docRef = _collection.doc();
      final prescription = PrescriptionModel(
        id: docRef.id,
        userId: userId,
        patientName: patientName,
        patientPhone: patientPhone,
        patientEmail: patientEmail,
        prescriptionUrl: prescriptionUrl,
        notes: notes,
        status: 'Pending Review',
        uploadedAt: DateTime.now(),
      );

      await docRef.set(prescription.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error saving prescription: $e');
      return null;
    }
  }

  /// Stream all prescriptions for Admin Portal
  static Stream<List<PrescriptionModel>> streamAllPrescriptions() {
    return _collection
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PrescriptionModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Stream prescriptions for a specific patient/user
  static Stream<List<PrescriptionModel>> streamUserPrescriptions(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return PrescriptionModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }

  /// Update prescription status (Admin action)
  static Future<void> updateStatus(String id, String newStatus) async {
    try {
      await _collection.doc(id).update({'status': newStatus});
    } catch (e) {
      debugPrint('Error updating prescription status: $e');
    }
  }
}
