import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDateTime(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is Timestamp) return val.toDate();
  if (val is DateTime) return val;
  if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
  if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
  return DateTime.now();
}

class PrescriptionModel {
  final String id;
  final String userId;
  final String patientName;
  final String patientPhone;
  final String? patientEmail;
  final String prescriptionUrl;
  final String? notes;
  final String status; // 'Pending Review', 'Contacted', 'Test Scheduled'
  final DateTime uploadedAt;

  PrescriptionModel({
    required this.id,
    required this.userId,
    required this.patientName,
    required this.patientPhone,
    this.patientEmail,
    required this.prescriptionUrl,
    this.notes,
    this.status = 'Pending Review',
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  factory PrescriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return PrescriptionModel(
      id: id,
      userId: map['userId'] ?? '',
      patientName: map['patientName'] ?? 'Valued Patient',
      patientPhone: map['patientPhone'] ?? '',
      patientEmail: map['patientEmail'],
      prescriptionUrl: map['prescriptionUrl'] ?? '',
      notes: map['notes'],
      status: map['status'] ?? 'Pending Review',
      uploadedAt: _parseDateTime(map['uploadedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'patientEmail': patientEmail,
      'prescriptionUrl': prescriptionUrl,
      'notes': notes,
      'status': status,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}
