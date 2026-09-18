import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/vibration_helper.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<AppNotification>>? _notifsSub;
  String? _currentUserId;

  final Set<String> _knownIds = {};
  bool _hasInitialLoaded = false;
  AppNotification? _latestIncomingNotification;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppNotification? get latestIncomingNotification => _latestIncomingNotification;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void dispose() {
    _notifsSub?.cancel();
    super.dispose();
  }

  void subscribeToNotifications(String userId, {String? userMobile, String? userEmail}) {
    if (_currentUserId == userId && _notifsSub != null) return;
    _currentUserId = userId;

    _notifsSub?.cancel();
    _notifsSub = _notificationService.streamNotifications(
      userId,
      userMobile: userMobile,
      userEmail: userEmail,
    ).listen((list) {
      _processIncomingNotifications(list);
    });
  }

  void _processIncomingNotifications(List<AppNotification> newList) {
    if (_hasInitialLoaded) {
      // Find if there are any brand new unread notifications
      final newItems = newList.where((n) => !_knownIds.contains(n.id) && !n.isRead).toList();
      if (newItems.isNotEmpty) {
        // Trigger phone dual-pulse vibration
        VibrationHelper.triggerNotificationVibration();
        _latestIncomingNotification = newItems.first;
      }
    }

    _knownIds.addAll(newList.map((n) => n.id));
    _hasInitialLoaded = true;
    _notifications = newList;
    notifyListeners();
  }

  Future<void> fetchNotifications(String userId, {String? userMobile, String? userEmail}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.getNotifications(
        userId,
        userMobile: userMobile,
        userEmail: userEmail,
      );
      _knownIds.addAll(_notifications.map((n) => n.id));
      _hasInitialLoaded = true;
      subscribeToNotifications(userId, userMobile: userMobile, userEmail: userEmail);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notifId) async {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      await _notificationService.markAsRead(notifId);
    }
  }

  Future<void> markAllAsRead(String userId) async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    await _notificationService.markAllAsRead(userId);
  }

  Future<AppNotification> sendAdminNotification({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.adminReminder,
    String? actionRoute,
    Map<String, dynamic>? metaData,
  }) async {
    final notif = await _notificationService.sendAdminNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
      actionRoute: actionRoute,
      metaData: metaData,
    );

    _notifications.removeWhere((n) => n.id == notif.id);
    _notifications.insert(0, notif);
    _knownIds.add(notif.id);
    VibrationHelper.triggerNotificationVibration();
    notifyListeners();
    return notif;
  }
}
