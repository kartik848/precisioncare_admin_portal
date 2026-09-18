import 'dart:async';
import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/diagnostic_service.dart';
import '../services/booking_service.dart';

class BookingProvider with ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<BookingModel>>? _userBookingsSub;
  String? _currentUserId;

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<BookingModel> get activeBookings => _bookings
      .where((b) => b.status != BookingStatus.completed && b.status != BookingStatus.cancelled)
      .toList();

  List<BookingModel> get completedBookings => _bookings
      .where((b) => b.status == BookingStatus.completed || b.status == BookingStatus.cancelled)
      .toList();

  @override
  void dispose() {
    _userBookingsSub?.cancel();
    super.dispose();
  }

  void subscribeToUserBookings(String userId) {
    if (_currentUserId == userId && _userBookingsSub != null) return;
    _currentUserId = userId;

    _userBookingsSub?.cancel();
    _userBookingsSub = _bookingService.streamUserBookings(userId).listen((list) {
      _bookings = list;
      notifyListeners();
    });
  }

  Future<void> fetchBookings(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bookings = await _bookingService.getUserBookings(userId);
      subscribeToUserBookings(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BookingModel?> createBooking({
    required String userId,
    required String patientName,
    required int patientAge,
    required String patientSex,
    required String patientMobile,
    String? patientAddress,
    required VisitType visitType,
    required List<DiagnosticService> services,
    required DateTime scheduledDate,
    required String timeSlot,
    required double totalAmount,
    String paymentStatus = 'Pay on Collection / Visit',
    String? utrNumber,
    String? paymentScreenshotUrl,
    String? prescriptionUrl,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final booking = await _bookingService.createBooking(
        userId: userId,
        patientName: patientName,
        patientAge: patientAge,
        patientSex: patientSex,
        patientMobile: patientMobile,
        patientAddress: patientAddress,
        visitType: visitType,
        services: services,
        scheduledDate: scheduledDate,
        timeSlot: timeSlot,
        totalAmount: totalAmount,
        paymentStatus: paymentStatus,
        utrNumber: utrNumber,
        paymentScreenshotUrl: paymentScreenshotUrl,
        prescriptionUrl: prescriptionUrl,
        notes: notes,
      );

      _bookings.removeWhere((b) => b.id == booking.id);
      _bookings.insert(0, booking);
      subscribeToUserBookings(userId);
      _isLoading = false;
      notifyListeners();
      return booking;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      final success = await _bookingService.cancelBooking(bookingId);
      if (success) {
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          final b = _bookings[index];
          _bookings[index] = b.copyWith(status: BookingStatus.cancelled);
          notifyListeners();
        }
      }
      return success;
    } catch (_) {
      return false;
    }
  }
}
