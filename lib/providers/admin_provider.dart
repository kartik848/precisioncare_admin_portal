import 'dart:async';
import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/test_report.dart';
import '../models/app_notification.dart';
import '../models/staff_model.dart';
import '../models/promo_banner.dart';
import '../models/user_profile.dart';
import '../models/diagnostic_service.dart';
import '../models/diagnostic_category.dart';
import '../services/booking_service.dart';
import '../services/report_service.dart';
import '../services/notification_service.dart';
import '../services/staff_service.dart';
import '../services/banner_service.dart';
import '../services/auth_service.dart';
import '../services/catalog_service.dart';
import '../services/category_service.dart';

class AdminProvider with ChangeNotifier {
  final BookingService _bookingService = BookingService();
  final ReportService _reportService = ReportService();
  final NotificationService _notificationService = NotificationService();
  final StaffService _staffService = StaffService();
  final BannerService _bannerService = BannerService();
  final AuthService _authService = AuthService();
  final CatalogService _catalogService = CatalogService();
  final CategoryService _categoryService = CategoryService();

  StreamSubscription<List<BookingModel>>? _bookingStreamSub;
  StreamSubscription<List<UserProfile>>? _usersStreamSub;
  StreamSubscription<List<StaffMember>>? _staffStreamSub;
  StreamSubscription<List<PromoBanner>>? _bannersStreamSub;
  StreamSubscription<List<DiagnosticService>>? _catalogStreamSub;
  StreamSubscription<List<DiagnosticCategory>>? _categoriesStreamSub;

  List<BookingModel> _allBookings = [];
  List<StaffMember> _staffList = [];
  List<PromoBanner> _banners = [];
  List<UserProfile> _usersList = [];
  List<DiagnosticService> _catalogServices = [];
  List<DiagnosticCategory> _categories = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<BookingModel> get allBookings => _allBookings;
  List<StaffMember> get staffList => _staffList;
  List<StaffMember> get activeStaffList => _staffList.where((s) => s.isActive).toList();
  List<PromoBanner> get banners => _banners;
  List<UserProfile> get usersList => _usersList;
  List<DiagnosticCategory> get categories =>
      _categories.isNotEmpty ? _categories : CategoryService.defaultCategories;
  List<DiagnosticService> get catalogServices =>
      _catalogServices.isNotEmpty ? _catalogServices : CatalogService.initialServices;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<BookingModel> get pendingRequests =>
      _allBookings.where((b) => b.status == BookingStatus.pendingApproval).toList();

  List<BookingModel> get activeVisits => _allBookings
      .where((b) =>
          b.status == BookingStatus.confirmed ||
          b.status == BookingStatus.technicianAssigned ||
          b.status == BookingStatus.sampleCollected ||
          b.status == BookingStatus.processing)
      .toList();

  List<BookingModel> get completedVisits =>
      _allBookings.where((b) => b.status == BookingStatus.completed).toList();

  List<BookingModel> get completedBookings => completedVisits;

  double get totalRevenue => _allBookings
      .where((b) => b.status != BookingStatus.cancelled)
      .fold(0.0, (sum, b) => sum + b.totalAmount);

  AdminProvider() {
    initAdminData();
    _startBookingSync();
    _startUsersSync();
    _startStaffSync();
    _startBannersSync();
    _startCatalogSync();
    _startCategoriesSync();
  }

  void _startBookingSync() {
    _bookingStreamSub?.cancel();
    _bookingStreamSub = _bookingService.streamAllBookings().listen((bookings) {
      _allBookings = bookings;
      notifyListeners();
    });
  }

  void _startUsersSync() {
    _usersStreamSub?.cancel();
    _usersStreamSub = _authService.streamAllUsers().listen((users) {
      _usersList = users;
      notifyListeners();
    });
  }

  void _startStaffSync() {
    _staffStreamSub?.cancel();
    _staffStreamSub = _staffService.streamStaffList().listen((staff) {
      _staffList = staff;
      notifyListeners();
    });
  }

  void _startBannersSync() {
    _bannersStreamSub?.cancel();
    _bannersStreamSub = _bannerService.streamBanners().listen((banners) {
      _banners = banners;
      notifyListeners();
    });
  }

  void _startCatalogSync() {
    _catalogStreamSub?.cancel();
    _catalogStreamSub = _catalogService.streamServices().listen((services) {
      _catalogServices = services;
      notifyListeners();
    });
  }

  void _startCategoriesSync() {
    _categoriesStreamSub?.cancel();
    _categoriesStreamSub = _categoryService.streamCategories().listen((cats) {
      _categories = cats;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _bookingStreamSub?.cancel();
    _usersStreamSub?.cancel();
    _staffStreamSub?.cancel();
    _bannersStreamSub?.cancel();
    _catalogStreamSub?.cancel();
    _categoriesStreamSub?.cancel();
    super.dispose();
  }

  Future<void> initAdminData() async {
    await Future.wait([
      fetchAllBookings(),
      fetchStaff(),
      fetchBanners(),
      fetchUsers(),
      fetchCatalog(),
      fetchCategories(),
    ]);
  }

  Future<void> fetchAllBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allBookings = await _bookingService.getAllBookings();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // STAFF MANAGEMENT
  Future<void> fetchStaff() async {
    _staffList = await _staffService.getStaffList();
    notifyListeners();
  }

  Future<bool> addOrUpdateStaff(StaffMember staff) async {
    await _staffService.saveStaffMember(staff);
    await fetchStaff();
    return true;
  }

  Future<bool> deleteStaff(String id) async {
    await _staffService.deleteStaffMember(id);
    await fetchStaff();
    return true;
  }

  Future<void> toggleStaffActive(StaffMember staff) async {
    final updated = staff.copyWith(isActive: !staff.isActive);
    await addOrUpdateStaff(updated);
  }

  // BANNER MANAGEMENT
  Future<void> fetchBanners() async {
    _banners = await _bannerService.getBanners();
    notifyListeners();
  }

  Future<bool> addOrUpdateBanner(PromoBanner banner) async {
    await _bannerService.saveBanner(banner);
    await fetchBanners();
    return true;
  }

  Future<bool> deleteBanner(String id) async {
    await _bannerService.deleteBanner(id);
    await fetchBanners();
    return true;
  }

  // USER DIRECTORY & BLOCKING
  Future<void> fetchUsers() async {
    _usersList = await _authService.getAllUsers();
    notifyListeners();
  }

  Future<void> toggleBlockUser(String uid, bool blockStatus) async {
    await _authService.toggleBlockUser(uid, blockStatus);
    final index = _usersList.indexWhere((u) => u.uid == uid);
    if (index >= 0) {
      _usersList[index] = _usersList[index].copyWith(isBlocked: blockStatus);
      notifyListeners();
    }
  }

  // DIAGNOSTIC CATALOG MANAGEMENT
  Future<void> fetchCatalog() async {
    _catalogServices = await _catalogService.getAllServices();
    notifyListeners();
  }

  Future<void> addDiagnosticTest(DiagnosticService service) async {
    await _catalogService.saveService(service);
    await fetchCatalog();
  }

  Future<void> deleteDiagnosticTest(String id) async {
    await _catalogService.deleteService(id);
    await fetchCatalog();
  }

  // CATEGORY MANAGEMENT
  Future<void> fetchCategories() async {
    _categories = await _categoryService.getAllCategories();
    notifyListeners();
  }

  Future<void> addCategory(DiagnosticCategory category) async {
    await _categoryService.saveCategory(category);
    await fetchCategories();
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoryService.deleteCategory(categoryId);
    await fetchCategories();
  }

  // 1. ADMIN ACTION: Accept Booking & Assign Phlebotomist/Technician
  Future<bool> acceptAndAssignTechnician({
    required String bookingId,
    required String staffName,
    required String staffPhone,
    String? adminNotes,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final index = _allBookings.indexWhere((b) => b.id == bookingId);
      if (index == -1) return false;

      final booking = _allBookings[index];
      final updated = booking.copyWith(
        status: BookingStatus.technicianAssigned,
        technicianName: staffName.trim(),
        technicianPhone: staffPhone.trim(),
        notes: adminNotes != null && adminNotes.isNotEmpty
            ? '${booking.notes ?? ""}\nAdmin: $adminNotes'.trim()
            : booking.notes,
      );

      await _bookingService.updateBooking(updated);
      _allBookings[index] = updated;

      // Increment completed visits for the assigned staff if in directory
      final staffIndex = _staffList.indexWhere((s) => s.name.toLowerCase() == staffName.toLowerCase() || s.phone == staffPhone);
      if (staffIndex >= 0) {
        final st = _staffList[staffIndex];
        await _staffService.saveStaffMember(st.copyWith(completedVisits: st.completedVisits + 1));
      }

      // Send Instant Realtime Notification to Patient
      await _notificationService.sendAdminNotification(
        userId: booking.userId,
        title: '✅ Booking Accepted & Staff Assigned',
        message: 'Your ${booking.services.map((s) => s.title).join(", ")} appointment has been confirmed! Medical Staff: $staffName (Ph: $staffPhone) has been assigned for your ${booking.visitType == VisitType.homeVisit ? "Home Visit" : "In-House Centre"} appointment on ${booking.timeSlot}.',
        type: NotificationType.bookingUpdate,
        metaData: {'bookingId': booking.id},
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 2. ADMIN ACTION: Update Status (Sample Collected, Processing, etc.)
  Future<bool> updateStatus({
    required String bookingId,
    required BookingStatus newStatus,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final index = _allBookings.indexWhere((b) => b.id == bookingId);
      if (index == -1) return false;

      final booking = _allBookings[index];
      final updated = booking.copyWith(status: newStatus);

      await _bookingService.updateBooking(updated);
      _allBookings[index] = updated;

      // Send appropriate notification
      String title = 'Diagnostic Test Update';
      String message = 'Your appointment status has been updated to ${updated.statusDisplay}.';

      if (newStatus == BookingStatus.sampleCollected) {
        title = '🩸 Sample Collected / Test Completed';
        message = 'Sample collection for ${booking.patientName} has been completed successfully and received for laboratory clinical processing.';
      } else if (newStatus == BookingStatus.processing) {
        title = '🔬 Lab Processing Underway';
        message = 'Your diagnostic test is currently undergoing clinical biochemistry & radiological examination at PrecisionCare Reference Lab.';
      }

      await _notificationService.sendAdminNotification(
        userId: booking.userId,
        title: title,
        message: message,
        type: NotificationType.bookingUpdate,
        metaData: {'bookingId': booking.id},
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 3. ADMIN ACTION: Upload Report & Mark Completed
  Future<bool> uploadLabReportAndComplete({
    required BookingModel booking,
    required String summary,
    String? doctorNotes,
    required String pathologistName,
    required List<ReportParameter> parameters,
    String? reportImageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final reportId = 'REP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final testTitle = booking.services.isNotEmpty
          ? booking.services.map((s) => s.title).join(' & ')
          : 'Complete Diagnostic Health Panel';

      final categoryName = booking.services.isNotEmpty
          ? booking.services.first.categoryName
          : 'Clinical Pathology';

      final report = TestReport(
        id: reportId,
        bookingId: booking.id,
        userId: booking.userId,
        patientName: booking.patientName,
        patientAge: booking.patientAge,
        patientSex: booking.patientSex,
        testTitle: testTitle,
        categoryName: categoryName,
        testDate: booking.scheduledDate,
        reportGeneratedDate: DateTime.now(),
        status: 'Ready',
        summary: summary,
        doctorNotes: doctorNotes,
        pathologistName: pathologistName,
        pdfDownloadUrl: reportImageUrl,
        parameters: parameters,
      );

      await _reportService.createReport(report);

      final updatedBooking = booking.copyWith(
        status: BookingStatus.completed,
        reportId: reportId,
        reportImageUrl: reportImageUrl,
      );
      await _bookingService.updateBooking(updatedBooking);

      final index = _allBookings.indexWhere((b) => b.id == booking.id);
      if (index != -1) {
        _allBookings[index] = updatedBooking;
      }

      await _notificationService.sendAdminNotification(
        userId: booking.userId,
        title: '📄 Verified Diagnostic Report Ready',
        message: 'Your laboratory report for $testTitle has been signed off by $pathologistName and is now ready to download in PDF.',
        type: NotificationType.reportReady,
        metaData: {'reportId': reportId, 'bookingId': booking.id},
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 4. ADMIN ACTION: Send Next Test Follow-Up Alert to Patient
  Future<bool> sendPatientReminder({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.nextTestDue,
    Map<String, dynamic>? metaData,
  }) async {
    try {
      await _notificationService.sendAdminNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        metaData: metaData,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Broadcast reminder / advisory to ALL registered patients
  Future<int> broadcastReminderToAllPatients({
    required String title,
    required String message,
    NotificationType type = NotificationType.nextTestDue,
  }) async {
    int sentCount = 0;
    try {
      final targetUids = <String>{
        ..._usersList.map((u) => u.uid),
        ..._allBookings.map((b) => b.userId),
      };

      for (final uid in targetUids) {
        if (uid.isNotEmpty) {
          await _notificationService.sendAdminNotification(
            userId: uid,
            title: title,
            message: message,
            type: type,
          );
          sentCount++;
        }
      }
    } catch (_) {}
    return sentCount;
  }

  // 5. ADMIN ACTION: Reject / Cancel Booking
  Future<bool> cancelOrRejectBooking(String bookingId, String reason) async {
    try {
      final index = _allBookings.indexWhere((b) => b.id == bookingId);
      if (index == -1) return false;

      final booking = _allBookings[index];
      final updated = booking.copyWith(
        status: BookingStatus.cancelled,
        notes: '${booking.notes ?? ""}\nCancellation Reason: $reason'.trim(),
      );

      await _bookingService.updateBooking(updated);
      _allBookings[index] = updated;

      await _notificationService.sendAdminNotification(
        userId: booking.userId,
        title: '⚠️ Appointment Cancelled',
        message: 'Your booking ($bookingId) could not be scheduled. Reason: $reason. Please contact our 24/7 helpline.',
        type: NotificationType.bookingUpdate,
      );

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
