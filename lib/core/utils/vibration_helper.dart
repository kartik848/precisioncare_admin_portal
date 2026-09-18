import 'package:flutter/services.dart';

class VibrationHelper {
  static const MethodChannel _channel = MethodChannel('com.precisioncare.precisioncare_app/vibration');

  /// Trigger a strong hardware vibration motor pattern on phone
  static Future<void> triggerNotificationVibration() async {
    try {
      await _channel.invokeMethod('vibratePattern');
    } catch (_) {
      try {
        await _channel.invokeMethod('vibrate', {'duration': 500});
      } catch (_) {
        try {
          await HapticFeedback.vibrate();
          await HapticFeedback.heavyImpact();
        } catch (_) {}
      }
    }
  }

  /// Light haptic feedback
  static Future<void> lightFeedback() async {
    try {
      await _channel.invokeMethod('vibrate', {'duration': 40});
    } catch (_) {
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
    }
  }
}
