import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/test_report.dart';

class ReportService {
  FirebaseFirestore? _firestore;
  bool _isFirebaseAvailable = false;

  ReportService() {
    try {
      _firestore = FirebaseFirestore.instance;
      _isFirebaseAvailable = true;
    } catch (_) {
      _isFirebaseAvailable = false;
    }
  }

  // Create a real diagnostic report (Admin Panel action)
  Future<TestReport> createReport(TestReport report) async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('reports').doc(report.id).set(report.toMap());
      } catch (_) {}
    }

    await _saveReportLocally(report);
    return report;
  }

  // Real-time stream of all reports for Admin Panel
  Stream<List<TestReport>> streamAllReports() {
    if (_isFirebaseAvailable && _firestore != null) {
      return _firestore!.collection('reports').snapshots().handleError((e) {
        debugPrint('Report streamAll notice: $e');
      }).map((snapshot) {
        final list = snapshot.docs.map((doc) => TestReport.fromMap(doc.data(), doc.id)).toList();
        list.sort((a, b) => b.reportGeneratedDate.compareTo(a.reportGeneratedDate));
        return list;
      });
    }
    return Stream.value([]);
  }

  // Real-time stream of reports for patient mobile app
  Stream<List<TestReport>> streamUserReports(String userId) {
    if (_isFirebaseAvailable && _firestore != null) {
      return _firestore!.collection('reports').snapshots().handleError((e) {
        debugPrint('Report streamUser notice: $e');
      }).map((snapshot) {
        final list = snapshot.docs
            .map((doc) => TestReport.fromMap(doc.data(), doc.id))
            .where((r) {
              if (userId.isEmpty) return true;
              return r.userId == userId;
            })
            .toList();
        list.sort((a, b) => b.reportGeneratedDate.compareTo(a.reportGeneratedDate));
        return list;
      });
    }
    return Stream.value([]);
  }

  // Get real reports for logged-in patient
  Future<List<TestReport>> getUserReports(String userId) async {
    final List<TestReport> combined = [];

    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final snapshot = await _firestore!.collection('reports').get();
        for (final doc in snapshot.docs) {
          final r = TestReport.fromMap(doc.data(), doc.id);
          if (userId.isEmpty || r.userId == userId) {
            combined.add(r);
          }
        }
      } catch (_) {}
    }

    final local = await _getLocalReports();
    for (final r in local) {
      if (userId.isEmpty || r.userId == userId) {
        if (!combined.any((item) => item.id == r.id)) {
          combined.add(r);
        }
      }
    }

    combined.sort((a, b) => b.reportGeneratedDate.compareTo(a.reportGeneratedDate));
    return combined;
  }

  Future<void> _saveReportLocally(TestReport report) async {
    final existing = await _getLocalReports();
    existing.removeWhere((r) => r.id == report.id);
    existing.insert(0, report);
    await _saveAllReportsLocally(existing);
  }

  Future<void> _saveAllReportsLocally(List<TestReport> reports) async {
    final prefs = await SharedPreferences.getInstance();
    final list = reports.map((r) => r.toMap()..['id'] = r.id).toList();
    await prefs.setString('precisioncare_reports', jsonEncode(list));
  }

  Future<List<TestReport>> _getLocalReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('precisioncare_reports');
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => TestReport.fromMap(Map<String, dynamic>.from(e), e['id'] ?? ''))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearLocalTestReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('precisioncare_reports');
  }
}
