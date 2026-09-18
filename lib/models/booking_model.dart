import 'package:cloud_firestore/cloud_firestore.dart';
import 'diagnostic_service.dart';

enum BookingStatus {
  pendingApproval,
  confirmed,
  technicianAssigned,
  sampleCollected,
  processing,
  completed,
  cancelled,
}

extension BookingStatusX on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.pendingApproval:
        return 'Pending Approval';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.technicianAssigned:
        return 'Staff Dispatched';
      case BookingStatus.sampleCollected:
        return 'Sample Collected';
      case BookingStatus.processing:
        return 'Processing in Lab';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum VisitType {
  homeVisit,
  inHouseCentre,
}

DateTime _parseDateTime(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is Timestamp) return val.toDate();
  if (val is DateTime) return val;
  if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
  if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
  return DateTime.now();
}

class BookingModel {
  final String id;
  final String userId;
  final String patientName;
  final int patientAge;
  final String patientSex;
  final String patientMobile;
  final String? patientAddress;
  final VisitType visitType;
  final List<DiagnosticService> services;
  final DateTime scheduledDate;
  final String timeSlot;
  final double totalAmount;
  final String paymentStatus; // 'Pay on Collection / Visit', 'Paid Online'
  final BookingStatus status;
  final String? utrNumber;
  final String? paymentScreenshotUrl;
  final String? technicianName;
  final String? technicianPhone;
  final String? notes;
  final String? reportId;
  final String? reportImageUrl;
  final String? prescriptionUrl;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.patientName,
    required this.patientAge,
    required this.patientSex,
    required this.patientMobile,
    this.patientAddress,
    required this.visitType,
    required this.services,
    required this.scheduledDate,
    required this.timeSlot,
    required this.totalAmount,
    this.paymentStatus = 'Pay on Collection / Visit',
    this.status = BookingStatus.pendingApproval,
    this.utrNumber,
    this.paymentScreenshotUrl,
    this.technicianName,
    this.technicianPhone,
    this.notes,
    this.reportId,
    this.reportImageUrl,
    this.prescriptionUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      userId: map['userId'] ?? '',
      patientName: map['patientName'] ?? '',
      patientAge: (map['patientAge'] as num?)?.toInt() ?? 0,
      patientSex: map['patientSex'] ?? 'Male',
      patientMobile: map['patientMobile'] ?? '',
      patientAddress: map['patientAddress'],
      visitType: map['visitType'] == 'inHouseCentre'
          ? VisitType.inHouseCentre
          : VisitType.homeVisit,
      services: (map['services'] as List<dynamic>?)
              ?.map((s) => DiagnosticService.fromMap(Map<String, dynamic>.from(s), s['id'] ?? ''))
              .toList() ??
          [],
      scheduledDate: _parseDateTime(map['scheduledDate']),
      timeSlot: map['timeSlot'] ?? '',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: map['paymentStatus'] ?? 'Pay on Collection / Visit',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.pendingApproval,
      ),
      technicianName: map['technicianName'],
      technicianPhone: map['technicianPhone'],
      utrNumber: map['utrNumber'],
      paymentScreenshotUrl: map['paymentScreenshotUrl'],
      notes: map['notes'],
      reportId: map['reportId'],
      reportImageUrl: map['reportImageUrl'],
      prescriptionUrl: map['prescriptionUrl'],
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'patientName': patientName,
      'patientAge': patientAge,
      'patientSex': patientSex,
      'patientMobile': patientMobile,
      'patientAddress': patientAddress,
      'visitType': visitType.name,
      'services': services.map((s) => s.toMap()..['id'] = s.id).toList(),
      'scheduledDate': scheduledDate.toIso8601String(),
      'timeSlot': timeSlot,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'status': status.name,
      'utrNumber': utrNumber,
      'paymentScreenshotUrl': paymentScreenshotUrl,
      'technicianName': technicianName,
      'technicianPhone': technicianPhone,
      'notes': notes,
      'reportId': reportId,
      'reportImageUrl': reportImageUrl,
      'prescriptionUrl': prescriptionUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? patientName,
    int? patientAge,
    String? patientSex,
    String? patientMobile,
    String? patientAddress,
    VisitType? visitType,
    List<DiagnosticService>? services,
    DateTime? scheduledDate,
    String? timeSlot,
    double? totalAmount,
    String? paymentStatus,
    BookingStatus? status,
    String? utrNumber,
    String? paymentScreenshotUrl,
    String? technicianName,
    String? technicianPhone,
    String? notes,
    String? reportId,
    String? reportImageUrl,
    String? prescriptionUrl,
    DateTime? createdAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientSex: patientSex ?? this.patientSex,
      patientMobile: patientMobile ?? this.patientMobile,
      patientAddress: patientAddress ?? this.patientAddress,
      visitType: visitType ?? this.visitType,
      services: services ?? this.services,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeSlot: timeSlot ?? this.timeSlot,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      utrNumber: utrNumber ?? this.utrNumber,
      paymentScreenshotUrl: paymentScreenshotUrl ?? this.paymentScreenshotUrl,
      technicianName: technicianName ?? this.technicianName,
      technicianPhone: technicianPhone ?? this.technicianPhone,
      notes: notes ?? this.notes,
      reportId: reportId ?? this.reportId,
      reportImageUrl: reportImageUrl ?? this.reportImageUrl,
      prescriptionUrl: prescriptionUrl ?? this.prescriptionUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get statusDisplay {
    switch (status) {
      case BookingStatus.pendingApproval:
        return 'Request Received (Pending Approval)';
      case BookingStatus.confirmed:
        return 'Booking Accepted by Admin';
      case BookingStatus.technicianAssigned:
        return 'Staff / Technician Dispatched';
      case BookingStatus.sampleCollected:
        return 'Sample Collected / Test Performed';
      case BookingStatus.processing:
        return 'Processing in Lab';
      case BookingStatus.completed:
        return 'Report Uploaded & Verified';
      case BookingStatus.cancelled:
        return 'Cancelled / Rejected';
    }
  }
}
