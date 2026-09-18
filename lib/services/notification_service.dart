import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';

class NotificationService {
  FirebaseFirestore? _firestore;
  bool _isFirebaseAvailable = false;

  NotificationService() {
    try {
      _firestore = FirebaseFirestore.instance;
      _isFirebaseAvailable = true;
    } catch (_) {
      _isFirebaseAvailable = false;
    }
  }

  static String _cleanPhone(String? p) {
    if (p == null) return '';
    final digits = p.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  bool _doesNotificationMatch(AppNotification n, String userId, String? userMobile, String? userEmail) {
    // 1. Broadcast to all patients
    if (n.userId == 'all_patients' || userId.isEmpty) return true;

    final target = n.userId.trim().toLowerCase();
    final targetClean = _cleanPhone(n.userId);
    final userCleanMobile = _cleanPhone(userMobile);
    final userCleanEmail = (userEmail ?? '').trim().toLowerCase();

    // 2. Direct UID match
    if (target == userId.trim().toLowerCase()) return true;

    // 3. Mobile phone number match (10 digits)
    if (userCleanMobile.isNotEmpty && targetClean.isNotEmpty) {
      if (userCleanMobile == targetClean) return true;
    }

    // 4. Email match
    if (userCleanEmail.isNotEmpty && target == userCleanEmail) return true;

    // 5. Metadata fields match
    if (n.metaData != null) {
      final mUid = (n.metaData!['targetUid'] ?? '').toString().trim().toLowerCase();
      if (mUid.isNotEmpty && mUid == userId.trim().toLowerCase()) return true;

      final mPhone = _cleanPhone(n.metaData!['targetMobile']?.toString());
      if (userCleanMobile.isNotEmpty && mPhone.isNotEmpty && mPhone == userCleanMobile) return true;

      final mEmail = (n.metaData!['targetEmail'] ?? '').toString().trim().toLowerCase();
      if (userCleanEmail.isNotEmpty && mEmail.isNotEmpty && mEmail == userCleanEmail) return true;
    }

    return false;
  }

  // Real-time stream of notifications for patient app
  Stream<List<AppNotification>> streamNotifications(String userId, {String? userMobile, String? userEmail}) {
    if (_isFirebaseAvailable && _firestore != null) {
      return _firestore!
          .collection('notifications')
          .snapshots()
          .handleError((e) {
        debugPrint('Notification stream notice: $e');
      }).map((snapshot) {
        final list = snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
            .where((n) => _doesNotificationMatch(n, userId, userMobile, userEmail))
            .toList();
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      });
    }
    return Stream.value([]);
  }

  // Get notifications for user
  Future<List<AppNotification>> getNotifications(String userId, {String? userMobile, String? userEmail}) async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final query = await _firestore!
            .collection('notifications')
            .get();

        if (query.docs.isNotEmpty) {
          final list = query.docs
              .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
              .where((n) => _doesNotificationMatch(n, userId, userMobile, userEmail))
              .toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        }
      } catch (_) {}
    }

    // Local / fallback
    final local = await _getLocalNotifications();
    if (local.isNotEmpty) {
      final filtered = local
          .where((n) => _doesNotificationMatch(n, userId, userMobile, userEmail))
          .toList();
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return filtered;
    }

    return [];
  }

  // Send admin notification (Admin panel trigger)
  Future<AppNotification> sendAdminNotification({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.adminReminder,
    String? actionRoute,
    Map<String, dynamic>? metaData,
  }) async {
    final notifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final notif = AppNotification(
      id: notifId,
      userId: userId,
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      actionRoute: actionRoute,
      metaData: metaData,
    );

    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('notifications').doc(notifId).set(notif.toMap());
      } catch (_) {}
    }

    await _saveNotificationLocally(notif);
    return notif;
  }

  // Mark single as read
  Future<void> markAsRead(String notifId) async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('notifications').doc(notifId).update({'isRead': true});
      } catch (_) {}
    }

    final local = await _getLocalNotifications();
    final updated = local.map((n) {
      if (n.id == notifId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    await _saveAllNotificationsLocally(updated);
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final batch = _firestore!.batch();
        final query = await _firestore!
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();
        for (final doc in query.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      } catch (_) {}
    }

    final local = await _getLocalNotifications();
    final updated = local.map((n) {
      if (n.userId == userId || n.userId == 'all_patients') {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    await _saveAllNotificationsLocally(updated);
  }

  Future<void> _saveNotificationLocally(AppNotification notification) async {
    final existing = await _getLocalNotifications();
    existing.removeWhere((n) => n.id == notification.id);
    existing.insert(0, notification);
    await _saveAllNotificationsLocally(existing);
  }

  Future<void> _saveAllNotificationsLocally(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final list = notifications.map((n) => n.toMap()).toList();
    await prefs.setString('precisioncare_notifications', jsonEncode(list));
  }

  Future<List<AppNotification>> _getLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('precisioncare_notifications');
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => AppNotification.fromMap(Map<String, dynamic>.from(e), e['id'] ?? '')).toList();
    } catch (_) {
      return [];
    }
  }
}
