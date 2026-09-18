import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TrustBadgesSection extends StatelessWidget {
  const TrustBadgesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'PrecisionCare Diagnostic Standard',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBadgeItem(
                icon: Icons.verified_rounded,
                title: 'NABL & ICMR',
                desc: 'Certified Labs',
              ),
              _buildDivider(),
              _buildBadgeItem(
                icon: Icons.speed_rounded,
                title: '6-12 Hours',
                desc: 'Report Delivery',
              ),
              _buildDivider(),
              _buildBadgeItem(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Barcoded',
                desc: '100% Error Free',
              ),
              _buildDivider(),
              _buildBadgeItem(
                icon: Icons.medical_information_rounded,
                title: 'MD Doctors',
                desc: 'Verified Reports',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.secondary),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 32,
      width: 1,
      color: AppColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}
