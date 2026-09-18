import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';
import '../models/diagnostic_service.dart';

class BookingService {
  FirebaseFirestore? _firestore;
  bool _isFirebaseAvailable = false;

  BookingService() {
    try {
      _firestore = FirebaseFirestore.instance;
      _isFirebaseAvailable = true;
    } catch (_) {
      _isFirebaseAvailable = false;
    }
  }

  // Create a new real booking from Patient Mobile App
  Future<BookingModel> createBooking({
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
    final bookingId = 'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final booking = BookingModel(
      id: bookingId,
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
      status: BookingStatus.pendingApproval,
      utrNumber: utrNumber,
      paymentScreenshotUrl: paymentScreenshotUrl,
      prescriptionUrl: prescriptionUrl,
      technicianName: null,
      technicianPhone: null,
      notes: notes,
      createdAt: DateTime.now(),
    );

    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('bookings').doc(bookingId).set(booking.toMap());
      } catch (_) {}
    }

    await _saveBookingLocally(booking);
    return booking;
  }

  /// Real-time stream of all real bookings for Admin Web Panel sync
  Stream<List<BookingModel>> streamAllBookings() {
    if (_isFirebaseAvailable && _firestore != null) {
      return _firestore!.collection('bookings').snapshots().handleError((e) {
        debugPrint('Booking streamAll notice: $e');
      }).map((snapshot) {
        final list = snapshot.docs.map((doc) => BookingModel.fromMap(doc.data(), doc.id)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    }
    return Stream.value([]);
  }

  /// Real-time stream of bookings for a specific Patient in Mobile App
  Stream<List<BookingModel>> streamUserBookings(String userId) {
    if (_isFirebaseAvailable && _firestore != null) {
      return _firestore!.collection('bookings').snapshots().handleError((e) {
        debugPrint('Booking streamUser notice: $e');
      }).map((snapshot) {
        final list = snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
            .where((b) {
              if (userId.isEmpty) return true;
              return b.userId == userId;
            })
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    }
    return Stream.value([]);
  }

  // Get all real bookings (Used by Admin Panel)
  Future<List<BookingModel>> getAllBookings() async {
    final List<BookingModel> combined = [];

    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final query = await _firestore!.collection('bookings').get();
        for (final doc in query.docs) {
          combined.add(BookingModel.fromMap(doc.data(), doc.id));
        }
      } catch (_) {}
    }

    final local = await _getLocalBookings();
    for (final b in local) {
      if (!combined.any((item) => item.id == b.id)) {
        combined.add(b);
      }
    }

    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined;
  }

  // Get real bookings for a specific patient
  Future<List<BookingModel>> getUserBookings(String userId) async {
    final List<BookingModel> combined = [];

    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final query = await _firestore!.collection('bookings').get();
        for (final doc in query.docs) {
          final b = BookingModel.fromMap(doc.data(), doc.id);
          if (userId.isEmpty || b.userId == userId) {
            combined.add(b);
          }
        }
      } catch (_) {}
    }

    final localBookings = await _getLocalBookings();
    for (final b in localBookings) {
      if (userId.isEmpty || b.userId == userId) {
        if (!combined.any((item) => item.id == b.id)) {
          combined.add(b);
        }
      }
    }

    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined;
  }

  // Update real booking (Admin action: Accept, Assign Technician, Update Status, Complete)
  Future<BookingModel> updateBooking(BookingModel updatedBooking) async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('bookings').doc(updatedBooking.id).update(updatedBooking.toMap());
      } catch (_) {}
    }

    await _saveBookingLocally(updatedBooking);
    return updatedBooking;
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId) async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('bookings').doc(bookingId).update({
          'status': BookingStatus.cancelled.name,
        });
      } catch (_) {}
    }

    final local = await _getLocalBookings();
    final updated = local.map((b) {
      if (b.id == bookingId) {
        return b.copyWith(status: BookingStatus.cancelled);
      }
      return b;
    }).toList();

    await _saveAllBookingsLocally(updated);
    return true;
  }

  Future<void> _saveBookingLocally(BookingModel booking) async {
    final existing = await _getLocalBookings();
    final index = existing.indexWhere((b) => b.id == booking.id);
    if (index != -1) {
      existing[index] = booking;
    } else {
      existing.insert(0, booking);
    }
    await _saveAllBookingsLocally(existing);
  }

  Future<void> _saveAllBookingsLocally(List<BookingModel> bookings) async {
    final prefs = await SharedPreferences.getInstance();
    final list = bookings.map((b) => b.toMap()..['id'] = b.id).toList();
    await prefs.setString('precisioncare_bookings', jsonEncode(list));
  }

  Future<List<BookingModel>> _getLocalBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('precisioncare_bookings');
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => BookingModel.fromMap(Map<String, dynamic>.from(e), e['id'] ?? '')).toList();
    } catch (_) {
      return [];
    }
  }

  /// Clean dummy / test data from local storage
  Future<void> clearLocalTestBookings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('precisioncare_bookings');
  }
}
