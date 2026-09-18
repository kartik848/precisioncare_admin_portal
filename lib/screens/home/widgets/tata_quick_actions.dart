import 'package:flutter/material.dart';

class TataQuickActions extends StatelessWidget {
  final VoidCallback onFullBodyTap;
  final VoidCallback onCallTap;
  final VoidCallback onWhatsAppTap;
  final VoidCallback onUploadPrescriptionTap;

  const TataQuickActions({
    super.key,
    required this.onFullBodyTap,
    required this.onCallTap,
    required this.onWhatsAppTap,
    required this.onUploadPrescriptionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: const Text(
                '⚡ TOP HEALTH SERVICES',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFBE123C),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 1. Full Body Packages
            Expanded(
              child: _buildTata3DActionCard(
                tag: 'UPTO 60% OFF',
                tagBg: const Color(0xFFFFEDD5),
                tagColor: const Color(0xFFC2410C),
                title: 'Full Body\nPackages',
                subtitle: '80+ Vital Tests',
                imageAsset: 'assets/images/3d/fullbody_package.jpg',
                cardGradient: const [Color(0xFFFFF7ED), Color(0xFFFFFFFF)],
                borderColor: const Color(0xFFFED7AA),
                onTap: onFullBodyTap,
              ),
            ),
            const SizedBox(width: 12),

            // 2. Book via Call
            Expanded(
              child: _buildTata3DActionCard(
                tag: '24x7 HELPLINE',
                tagBg: const Color(0xFFDBEAFE),
                tagColor: const Color(0xFF1D4ED8),
                title: 'Book via\nDirect Call',
                subtitle: 'Instant Lab Desk',
                imageAsset: 'assets/images/3d/call_helpline.jpg',
                cardGradient: const [Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
                borderColor: const Color(0xFFBFDBFE),
                onTap: onCallTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 3. Book via WhatsApp
            Expanded(
              child: _buildTata3DActionCard(
                tag: 'QUICK 2-MIN',
                tagBg: const Color(0xFFDCFCE7),
                tagColor: const Color(0xFF15803D),
                title: 'Book via\nWhatsApp',
                subtitle: 'Direct Chat Slot',
                imageAsset: 'assets/images/3d/whatsapp_booking.jpg',
                cardGradient: const [Color(0xFFF0FDF4), Color(0xFFFFFFFF)],
                borderColor: const Color(0xFFBBF7D0),
                onTap: onWhatsAppTap,
              ),
            ),
            const SizedBox(width: 12),

            // 4. Upload Prescription
            Expanded(
              child: _buildTata3DActionCard(
                tag: '1-TAP ORDER',
                tagBg: const Color(0xFFF3E8FF),
                tagColor: const Color(0xFF7E22CE),
                title: 'Upload\nPrescription',
                subtitle: 'Call in 15 mins',
                imageAsset: 'assets/images/3d/upload_rx.jpg',
                cardGradient: const [Color(0xFFFAF5FF), Color(0xFFFFFFFF)],
                borderColor: const Color(0xFFE9D5FF),
                onTap: onUploadPrescriptionTap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTata3DActionCard({
    required String tag,
    required Color tagBg,
    required Color tagColor,
    required String title,
    required String subtitle,
    required String imageAsset,
    required List<Color> cardGradient,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: cardGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: tagColor,
                      ),
                    ),
                  ),
                ),
                // 3D Bitmoji Art Thumbnail
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF94A3B8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
