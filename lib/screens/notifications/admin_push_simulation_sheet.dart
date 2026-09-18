import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AdminPushSimulationSheet extends StatefulWidget {
  const AdminPushSimulationSheet({super.key});

  @override
  State<AdminPushSimulationSheet> createState() => _AdminPushSimulationSheetState();
}

class _AdminPushSimulationSheetState extends State<AdminPushSimulationSheet> {
  final _titleController = TextEditingController(text: '🔔 Next Test Reminder: 3-Month Diabetes Review');
  final _messageController = TextEditingController(
    text: 'Dear Patient, your quarterly HbA1c & Lipid Profile follow-up is due as per your doctor prescription. Book your home visit slot today.',
  );
  NotificationType _selectedType = NotificationType.nextTestDue;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _applyQuickTemplate(String title, String message, NotificationType type) {
    setState(() {
      _titleController.text = title;
      _messageController.text = message;
      _selectedType = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final notifProvider = context.read<NotificationProvider>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Admin Panel Notification Sender',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Text(
              'Simulate sending personalized medical alerts and next test reminders from the PrecisionCare Admin Panel.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            // Quick Templates
            const Text(
              'Quick Admin Templates:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    label: const Text('Diabetes Next Test Due', style: TextStyle(fontSize: 11)),
                    onPressed: () => _applyQuickTemplate(
                      '🔔 Next Test Reminder: 3-Month Diabetes Review',
                      'Dear Patient, your quarterly HbA1c & Fasting Glucose follow-up is due as per your doctor prescription. Schedule your home visit now!',
                      NotificationType.nextTestDue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Physiotherapy Review', style: TextStyle(fontSize: 11)),
                    onPressed: () => _applyQuickTemplate(
                      '🏃 Physiotherapy Follow-up Session Due',
                      'Your next spinal decompression & joint rehabilitation session is scheduled for this weekend. Please confirm your availability.',
                      NotificationType.nextTestDue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Annual Full Body Checkup', style: TextStyle(fontSize: 11)),
                    onPressed: () => _applyQuickTemplate(
                      '🩺 Annual Preventive Health Review Due',
                      'It has been 12 months since your last Master Health Checkup. Book our NABL-accredited 85-parameter package at 50% discount.',
                      NotificationType.adminReminder,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Title
            CustomTextField(
              controller: _titleController,
              label: 'Notification Title *',
              hint: 'e.g. Next Test Due Alert',
            ),
            const SizedBox(height: 12),

            // Message
            CustomTextField(
              controller: _messageController,
              label: 'Notification Message *',
              hint: 'Type detailed reminder message...',
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Send CTA
            CustomButton(
              text: 'Push Alert to Patient App',
              icon: Icons.send_rounded,
              onPressed: () async {
                if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
                  return;
                }

                await notifProvider.sendAdminNotification(
                  userId: user?.uid ?? 'all_patients',
                  title: _titleController.text.trim(),
                  message: _messageController.text.trim(),
                  type: _selectedType,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Admin Notification sent successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
