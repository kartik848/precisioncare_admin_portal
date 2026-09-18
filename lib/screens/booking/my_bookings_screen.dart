import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/app_image_view.dart';
import '../../widgets/empty_state.dart';
import '../reports/reports_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<BookingProvider>().fetchBookings(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final activeBookings = bookingProvider.activeBookings;
    final pastBookings = bookingProvider.completedBookings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Scheduled Bookings'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Active / Upcoming (${activeBookings.length})'),
            Tab(text: 'Past / Completed (${pastBookings.length})'),
          ],
        ),
      ),
      body: bookingProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(activeBookings, isActive: true),
                _buildBookingsList(pastBookings, isActive: false),
              ],
            ),
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings, {required bool isActive}) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_today_outlined,
        title: isActive ? 'No Active Appointments' : 'No Past Appointments',
        description: isActive
            ? 'You do not have any pending diagnostic visits. Schedule a blood test, X-ray, ECG, or physio session now!'
            : 'Your completed diagnostic appointments will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(bookings[index]);
      },
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final isHomeVisit = booking.visitType == VisitType.homeVisit;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Booking ID + Visit Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID: ${booking.id}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isHomeVisit ? AppColors.primaryLight.withOpacity(0.5) : AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHomeVisit ? Icons.home_rounded : Icons.local_hospital_rounded,
                      size: 13,
                      color: isHomeVisit ? AppColors.primaryDark : AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isHomeVisit ? 'Home Visit' : 'In-House Centre',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isHomeVisit ? AppColors.primaryDark : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Services list
          ...booking.services.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Date & Time Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEE, dd MMM yyyy').format(booking.scheduledDate),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  booking.timeSlot.split('(').first.trim(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Location / Address Row
          if (booking.patientAddress != null && booking.patientAddress!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isHomeVisit ? Icons.location_on_outlined : Icons.business_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isHomeVisit ? 'Visit Address: ${booking.patientAddress}' : 'Centre Branch: ${booking.patientAddress}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Live Progress Stepper
          _buildStatusTracker(booking.status),
          const SizedBox(height: 12),

          // Assigned Staff Details
          if (booking.technicianName != null) ...[
            Row(
              children: [
                const Icon(Icons.person_pin_circle_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Staff: ${booking.technicianName}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // UTR Status Chip & Payment Screenshot Preview Trigger
          if (booking.utrNumber != null || booking.paymentStatus.contains('Online') || booking.paymentStatus.contains('Paid')) ...[
            GestureDetector(
              onTap: () => _showPaymentProofDialog(context, booking),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'UPI Paid • ${booking.utrNumber ?? "Verified"}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 10, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'Proof',
                            style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          const Divider(height: 16, color: AppColors.divider),

          // Bottom: Amount + Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${booking.totalAmount.toInt()}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              if (booking.status == BookingStatus.completed)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    );
                  },
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text('View Report', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                )
              else if (booking.status != BookingStatus.cancelled)
                OutlinedButton(
                  onPressed: () => _confirmCancelBooking(booking.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTracker(BookingStatus status) {
    if (status == BookingStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
            SizedBox(width: 6),
            Text('Appointment Cancelled', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      );
    }

    if (status == BookingStatus.pendingApproval) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, size: 16, color: AppColors.accent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Request Received: Waiting for Admin Approval & Staff Assignment',
                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }

    final steps = ['Confirmed', 'Dispatched', 'Sample Taken', 'In Lab', 'Completed'];
    int currentStep = 0;
    switch (status) {
      case BookingStatus.pendingApproval:
        currentStep = 0;
        break;
      case BookingStatus.confirmed:
        currentStep = 0;
        break;
      case BookingStatus.technicianAssigned:
        currentStep = 1;
        break;
      case BookingStatus.sampleCollected:
        currentStep = 2;
        break;
      case BookingStatus.processing:
        currentStep = 3;
        break;
      case BookingStatus.completed:
        currentStep = 4;
        break;
      case BookingStatus.cancelled:
        currentStep = 0;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Status: ${steps[currentStep]}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            Text(
              'Step ${currentStep + 1} of 5',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: (currentStep + 1) / 5,
          backgroundColor: AppColors.border,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  void _showPaymentProofDialog(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Payment Proof & Receipt',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 10),

                // Payment Info Details
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount Paid', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('₹${booking.totalAmount.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Mode', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('UPI QR Instant Transfer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      if (booking.utrNumber != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('12-Digit UTR / Ref', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  booking.utrNumber!,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: booking.utrNumber!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('UTR Number copied to clipboard!'), duration: Duration(seconds: 2)),
                                    );
                                  },
                                  child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Uploaded Screenshot Preview
                if (booking.paymentScreenshotUrl != null && booking.paymentScreenshotUrl!.isNotEmpty) ...[
                  const Text('Uploaded Payment Screenshot:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 320),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 3.0,
                        child: AppImageView(imageUrl: booking.paymentScreenshotUrl!, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text('Pinch / Zoom to examine screenshot proof', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 24),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'UPI Transaction Reference Verified by PrecisionCare Diagnostics.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmCancelBooking(String bookingId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text('Are you sure you want to cancel this diagnostic test appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<BookingProvider>().cancelBooking(bookingId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment has been cancelled.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }
}
