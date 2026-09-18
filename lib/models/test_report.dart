import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDateTime(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is Timestamp) return val.toDate();
  if (val is DateTime) return val;
  if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
  if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
  return DateTime.now();
}

class ReportParameter {
  final String name;
  final String value;
  final String unit;
  final String normalRange;
  final bool isAbnormal;

  const ReportParameter({
    required this.name,
    required this.value,
    required this.unit,
    required this.normalRange,
    this.isAbnormal = false,
  });

  factory ReportParameter.fromMap(Map<String, dynamic> map) {
    return ReportParameter(
      name: map['name'] ?? '',
      value: map['value'] ?? '',
      unit: map['unit'] ?? '',
      normalRange: map['normalRange'] ?? '',
      isAbnormal: map['isAbnormal'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'normalRange': normalRange,
      'isAbnormal': isAbnormal,
    };
  }
}

class TestReport {
  final String id;
  final String bookingId;
  final String userId;
  final String patientName;
  final int patientAge;
  final String patientSex;
  final String testTitle;
  final String categoryName;
  final DateTime testDate;
  final DateTime reportGeneratedDate;
  final String status; // 'Ready', 'In Progress'
  final String summary;
  final String? doctorNotes;
  final String pathologistName;
  final String? pdfDownloadUrl;
  final List<ReportParameter> parameters;

  TestReport({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.patientName,
    required this.patientAge,
    required this.patientSex,
    required this.testTitle,
    required this.categoryName,
    required this.testDate,
    DateTime? reportGeneratedDate,
    this.status = 'Ready',
    required this.summary,
    this.doctorNotes,
    this.pathologistName = 'Dr. S. K. Verma, MD (Pathology)',
    this.pdfDownloadUrl,
    this.parameters = const [],
  }) : reportGeneratedDate = reportGeneratedDate ?? DateTime.now();

  factory TestReport.fromMap(Map<String, dynamic> map, String id) {
    return TestReport(
      id: id,
      bookingId: map['bookingId'] ?? '',
      userId: map['userId'] ?? '',
      patientName: map['patientName'] ?? '',
      patientAge: (map['patientAge'] as num?)?.toInt() ?? 0,
      patientSex: map['patientSex'] ?? 'Male',
      testTitle: map['testTitle'] ?? '',
      categoryName: map['categoryName'] ?? 'Diagnostic',
      testDate: _parseDateTime(map['testDate']),
      reportGeneratedDate: _parseDateTime(map['reportGeneratedDate']),
      status: map['status'] ?? 'Ready',
      summary: map['summary'] ?? '',
      doctorNotes: map['doctorNotes'],
      pathologistName: map['pathologistName'] ?? 'Dr. S. K. Verma, MD (Pathology)',
      pdfDownloadUrl: map['pdfDownloadUrl'],
      parameters: (map['parameters'] as List<dynamic>?)
              ?.map((p) => ReportParameter.fromMap(Map<String, dynamic>.from(p)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'patientName': patientName,
      'patientAge': patientAge,
      'patientSex': patientSex,
      'testTitle': testTitle,
      'categoryName': categoryName,
      'testDate': testDate.toIso8601String(),
      'reportGeneratedDate': reportGeneratedDate.toIso8601String(),
      'status': status,
      'summary': summary,
      'doctorNotes': doctorNotes,
      'pathologistName': pathologistName,
      'pdfDownloadUrl': pdfDownloadUrl,
      'parameters': parameters.map((p) => p.toMap()).toList(),
    };
  }
}
