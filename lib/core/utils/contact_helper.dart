import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class ContactHelper {
  static const String phoneNumber = '9270988595';
  static const String displayPhone = '+91 92709 88595';

  static Future<void> callHelpline(BuildContext context) async {
    final uri = Uri.parse('tel:+919270988595');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Helpline: +91 92709 88595 (Call or WhatsApp)'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  static Future<void> openWhatsApp(BuildContext context, {String? customMessage}) async {
    final msg = customMessage ?? 'Hello PrecisionCare, I would like to inquire about a diagnostic test / home visit booking.';
    final encoded = Uri.encodeComponent(msg);
    final uri = Uri.parse('https://wa.me/919270988595?text=$encoded');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp Support: +91 92709 88595'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}
