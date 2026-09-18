import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  static String formatDayMonth(DateTime date) {
    return DateFormat('EEE, dd MMM').format(date);
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDate(dateTime);
    }
  }

  static List<String> getAvailableTimeSlots() {
    return [
      '06:30 AM - 08:00 AM (Fasting Priority)',
      '08:00 AM - 09:30 AM (Morning)',
      '09:30 AM - 11:00 AM',
      '11:00 AM - 12:30 PM',
      '02:00 PM - 03:30 PM (Afternoon)',
      '04:00 PM - 05:30 PM (Evening)',
      '06:00 PM - 07:30 PM (Post-Work)',
    ];
  }
}
