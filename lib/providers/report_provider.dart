import 'dart:async';
import 'package:flutter/material.dart';
import '../models/test_report.dart';
import '../services/report_service.dart';
import '../core/utils/pdf_generator.dart';

class ReportProvider with ChangeNotifier {
  final ReportService _reportService = ReportService();

  List<TestReport> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<TestReport>>? _reportsSub;
  String? _currentUserId;

  List<TestReport> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _reportsSub?.cancel();
    super.dispose();
  }

  void subscribeToUserReports(String userId) {
    if (_currentUserId == userId && _reportsSub != null) return;
    _currentUserId = userId;

    _reportsSub?.cancel();
    _reportsSub = _reportService.streamUserReports(userId).listen((list) {
      _reports = list;
      notifyListeners();
    });
  }

  Future<void> fetchReports(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reports = await _reportService.getUserReports(userId);
      subscribeToUserReports(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  TestReport? getReportById(String reportId) {
    try {
      return _reports.firstWhere((r) => r.id == reportId);
    } catch (_) {
      return null;
    }
  }

  Future<void> downloadOrPrintPdf(TestReport report) async {
    await PdfReportGenerator.printOrShareReport(report);
  }

  Future<void> sharePdf(TestReport report) async {
    await PdfReportGenerator.shareReport(report);
  }
}
