import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/diagnostic_service.dart';
import '../test_detail_screen.dart';
import '../../booking/schedule_booking_screen.dart';

class TestCard extends StatelessWidget {
  final DiagnosticService service;
  final VoidCallback? onBookTap;
  final VoidCallback? onTap;
  final bool isCompact;

  const TestCard({
    super.key,
    required this.service,
    this.onBookTap,
    this.onTap,
    this.isCompact = false,
  });

  IconData _getServiceIcon(String type) {
    switch (type) {
      case 'blood':
        return Icons.water_drop_rounded;
      case 'xray':
        return Icons.camera_enhance_rounded;
      case 'ecg':
        return Icons.monitor_heart_rounded;
      case 'physio':
        return Icons.accessibility_new_rounded;
      case 'pft':
        return Icons.air_rounded;
      case 'stress_test':
        return Icons.directions_run_rounded;
      default:
        return Icons.medical_services_rounded;
    }
  }

  Color _getBadgeColor(String type) {
    switch (type) {
      case 'blood':
        return AppColors.bloodTestBadge;
      case 'xray':
        return AppColors.xrayBadge;
      case 'ecg':
        return AppColors.ecgBadge;
      case 'physio':
        return AppColors.physioBadge;
      case 'pft':
        return AppColors.pftBadge;
      case 'stress_test':
        return AppColors.stressTestBadge;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor(service.iconType);

    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TestDetailScreen(service: service),
              ),
            );
          },
      child: Container(
        margin: EdgeInsets.only(bottom: isCompact ? 0 : 12),
        padding: EdgeInsets.all(isCompact ? 12 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. Top Row: Category Tag + Badges + Visit Availability
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      service.categoryName,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (service.isHomeVisitAvailable && !isCompact)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home_rounded, size: 9, color: AppColors.success),
                        SizedBox(width: 2),
                        Text(
                          'Home Visit',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                if (service.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      service.badge!,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // 2. Middle: Title + Icon + Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getServiceIcon(service.iconType),
                    size: 18,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: TextStyle(
                          fontSize: isCompact ? 13 : 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: isCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        service.description,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                          height: 1.25,
                        ),
                        maxLines: isCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 3. Prep & TAT Chips (Full mode)
            if (!isCompact) ...[
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      service.turnaroundTime,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.info_outline_rounded, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      service.preparation.split('.').first,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      service.turnaroundTime,
                      style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 6),

            // 4. Bottom: Pricing and Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '₹${service.price.toInt()}',
                            style: TextStyle(
                              fontSize: isCompact ? 14 : 16.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (service.originalPrice != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '₹${service.originalPrice!.toInt()}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Text(
                        'Includes Digital Report',
                        style: TextStyle(fontSize: 8.5, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onBookTap ??
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ScheduleBookingScreen(preSelectedService: service),
                          ),
                        );
                      },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 14, vertical: isCompact ? 5 : 7),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Book Test', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded, size: 11),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
