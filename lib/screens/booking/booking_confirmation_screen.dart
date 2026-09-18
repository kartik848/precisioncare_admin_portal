import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../widgets/app_image_view.dart';
import '../home/main_navigation_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final BookingModel booking;

  const BookingConfirmationScreen({super.key, required this.booking});

  void _showProofDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Proof Screenshot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 8),
              if (booking.utrNumber != null)
                Text('UTR / Reference: ${booking.utrNumber}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF15803D), fontSize: 13)),
              const SizedBox(height: 10),
              if (booking.paymentScreenshotUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: InteractiveViewer(
                      child: AppImageView(imageUrl: booking.paymentScreenshotUrl!, fit: BoxFit.contain),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Badge
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Appointment Scheduled Successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Booking Reference ID: ${booking.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // Booking Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryRow(
                        'Visit Mode:',
                        booking.visitType == VisitType.homeVisit
                            ? 'Home Visit (Sample Collection)'
                            : 'In-House Diagnostic Centre',
                        isHighlighted: true,
                      ),
                      const Divider(height: 18, color: AppColors.divider),
                      _buildSummaryRow('Patient Name:', booking.patientName),
                      const Divider(height: 18, color: AppColors.divider),
                      _buildSummaryRow(
                        'Appointment Date:',
                        DateFormat('EEE, dd MMM yyyy').format(booking.scheduledDate),
                      ),
                      const Divider(height: 18, color: AppColors.divider),
                      _buildSummaryRow('Time Slot:', booking.timeSlot),
                      if (booking.visitType == VisitType.homeVisit && booking.patientAddress != null) ...[
                        const Divider(height: 18, color: AppColors.divider),
                        _buildSummaryRow('Home Address:', booking.patientAddress!),
                      ] else if (booking.patientAddress != null) ...[
                        const Divider(height: 18, color: AppColors.divider),
                        _buildSummaryRow('Centre Branch:', booking.patientAddress!),
                      ],
                      const Divider(height: 18, color: AppColors.divider),
                      _buildSummaryRow('Assigned Staff:', booking.technicianName ?? 'PrecisionCare Phlebotomist'),
                      const Divider(height: 18, color: AppColors.divider),
                      _buildSummaryRow(
                        'Total Payable:',
                        '₹${booking.totalAmount.toInt()} (${booking.paymentStatus})',
                        isHighlighted: true,
                      ),
                      if (booking.paymentScreenshotUrl != null || booking.utrNumber != null) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _showProofDialog(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_outlined, size: 16, color: Color(0xFF16A34A)),
                                SizedBox(width: 6),
                                Text(
                                  'View Uploaded Payment Screenshot / Proof',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const MainNavigationScreen(initialIndex: 2), // Index 2 is My Bookings
                      ),
                    );
                  },
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Track Booking in My Bookings'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 0)),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Return to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
              color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
