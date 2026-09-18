import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  adminReminder,
  nextTestDue,
  reportReady,
  bookingUpdate,
  healthTip,
}

DateTime _parseDateTime(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is Timestamp) return val.toDate();
  if (val is DateTime) return val;
  if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
  if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
  return DateTime.now();
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionRoute;
  final Map<String, dynamic>? metaData;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    DateTime? timestamp,
    this.isRead = false,
    this.actionRoute,
    this.metaData,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.adminReminder,
      ),
      timestamp: _parseDateTime(map['timestamp']),
      isRead: map['isRead'] ?? false,
      actionRoute: map['actionRoute'],
      metaData: map['metaData'] != null ? Map<String, dynamic>.from(map['metaData']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'actionRoute': actionRoute,
      'metaData': metaData,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? actionRoute,
    Map<String, dynamic>? metaData,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      metaData: metaData ?? this.metaData,
    );
  }
}
