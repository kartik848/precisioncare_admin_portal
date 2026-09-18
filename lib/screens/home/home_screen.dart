import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/contact_helper.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/catalog_service.dart';
import '../../widgets/app_image_view.dart';
import '../../widgets/section_header.dart';
import '../booking/schedule_booking_screen.dart';
import '../catalog/catalog_screen.dart';
import '../catalog/test_detail_screen.dart';
import '../catalog/widgets/test_card.dart';
import '../notifications/notification_center_screen.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/quick_category_card.dart';
import 'widgets/trust_badges_section.dart';
import 'widgets/tata_quick_actions.dart';
import 'widgets/doctor_specialists_section.dart';
import 'widgets/upload_prescription_sheet.dart';
import '../../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(int index)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _detectedLocation = 'Kondhwa, Pune 411048';
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshUser();
      _initLocation();
    });
  }

  Future<void> _initLocation() async {
    final cached = await LocationService.getSavedLocation();
    if (mounted) setState(() => _detectedLocation = cached);

    setState(() => _isLocating = true);
    final live = await LocationService.fetchCurrentDeviceLocation();
    if (mounted) {
      setState(() {
        _isLocating = false;
        if (live != null) _detectedLocation = live;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  void _showBranchLocationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.location_on_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'PrecisionCare Diagnostic Centres (Pune)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Branch 1
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business_rounded, color: AppColors.primaryDark, size: 16),
                        SizedBox(width: 6),
                        Text('Branch 1 (Kondhwa / Lullanagar)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryDark)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppStrings.branch1Address,
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Branch 2
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_hospital_rounded, color: AppColors.secondary, size: 16),
                        SizedBox(width: 6),
                        Text('Branch 2 (Parmar Pavan / Fakhri Hills)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.secondary)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppStrings.branch2Address,
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _initLocation();
                  },
                  icon: const Icon(Icons.my_location_rounded, size: 16, color: AppColors.primary),
                  label: const Text('Detect Live GPS Location', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Confirm Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final notifications = context.watch<NotificationProvider>().notifications;
    final allServices = context.watch<CatalogProvider>().allServices;
    final featuredPackages = allServices.take(6).toList();

    final nextTestAlert = notifications.where((n) => !n.isRead && (n.type == NotificationType.nextTestDue || n.type == NotificationType.adminReminder || n.type == NotificationType.reportReady || n.type == NotificationType.bookingUpdate)).toList();
    final firstName = (user != null && user.name.isNotEmpty) ? user.name.split(' ').first : 'Patient';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. BRAND & USER HEADER
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Patient Profile Photo Avatar
                        GestureDetector(
                          onTap: () => widget.onNavigateTab?.call(4),
                          child: Stack(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                  border: Border.all(color: AppColors.primaryLight, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty)
                                      ? AppImageView(imageUrl: user.profileImageUrl!, fit: BoxFit.cover)
                                      : Center(
                                          child: Text(
                                            firstName.isNotEmpty ? firstName[0].toUpperCase() : 'P',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 19,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 8, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Greeting & Demographic Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.successLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'VERIFIED',
                                      style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: AppColors.success),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                firstName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Notifications Bell
                        Stack(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 20),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                                  );
                                },
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 8),

                    // TATA 1MG STYLE LIVE LOCATION BAR
                    GestureDetector(
                      onTap: () => _showBranchLocationsSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.near_me_rounded, color: Colors.white, size: 12),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Delivering & Sample Collection in',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _detectedLocation,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: AppColors.primary),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (_isLocating)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: const Text(
                                  'Change',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. SEARCH BAR
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CatalogScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Search Blood Tests, X-Ray, ECG, Physio...',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.tune_rounded, size: 14, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. CLINICAL REMINDER ALERT (When Admin Broadcasts or Pushes)
              if (nextTestAlert.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDBA74)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEA580C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    nextTestAlert.first.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF9A3412),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEA580C),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('DUE', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextTestAlert.first.message,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF7C2D12), height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ScheduleBookingScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEA580C),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Schedule Doorstep Visit', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, size: 11, color: Colors.white),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 4. TOP PROMOTIONAL BANNERS CAROUSEL
              BannerCarousel(
                onBannerTap: (category) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CatalogScreen(initialCategory: category),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),

              // 4.1 TATA 1MG 4 TOP QUICK ACTIONS
              TataQuickActions(
                onFullBodyTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CatalogScreen(initialCategory: 'Full Body Checkups'),
                    ),
                  );
                },
                onCallTap: () => ContactHelper.callHelpline(context),
                onWhatsAppTap: () => ContactHelper.openWhatsApp(
                  context,
                  customMessage: 'Hello PrecisionCare Diagnostic Centre, I would like to book a diagnostic test.',
                ),
                onUploadPrescriptionTap: () => UploadPrescriptionSheet.show(context),
              ),
              const SizedBox(height: 20),

              // 4.2 TATA 1MG 3D CARTOON DOCTOR SPECIALISTS
              DoctorSpecialistsSection(
                onSpecialtyTap: (category) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CatalogScreen(initialCategory: category),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // 5. HOME VISIT SERVICES GRID
              SectionHeader(
                title: 'Home Visit Diagnostics & Care',
                subtitle: 'NABL Certified phlebotomists at your doorstep in 60 Mins',
                actionText: 'View All',
                onActionTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CatalogScreen(initialCategory: 'Home Visits'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.05,
                children: [
                  QuickCategoryCard(
                    title: 'Home Visit Blood Test',
                    subtitle: 'CBC, Lipid, Sugar, Thyroid',
                    imageAsset: 'assets/images/3d/service_blood_test.jpg',
                    iconColor: AppColors.bloodTestBadge,
                    backgroundColor: AppColors.bloodTestBadge.withOpacity(0.1),
                    badge: '60 Min Dispatch',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CatalogScreen(initialCategory: 'Blood Tests')),
                      );
                    },
                  ),
                  QuickCategoryCard(
                    title: 'Home Visit Digital X-Ray',
                    subtitle: 'Chest, Spine, Knee DR',
                    imageAsset: 'assets/images/3d/service_xray.jpg',
                    iconColor: AppColors.xrayBadge,
                    backgroundColor: AppColors.xrayBadge.withOpacity(0.1),
                    badge: 'Portable DR',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CatalogScreen(initialCategory: 'Digital X-Ray')),
                      );
                    },
                  ),
                  QuickCategoryCard(
                    title: 'Home Visit 12-Lead ECG',
                    subtitle: 'Instant Cardiologist Tracing',
                    imageAsset: 'assets/images/3d/service_ecg.jpg',
                    iconColor: AppColors.ecgBadge,
                    backgroundColor: AppColors.ecgBadge.withOpacity(0.1),
                    badge: 'Instant',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CatalogScreen(initialCategory: 'ECG & Cardiology')),
                      );
                    },
                  ),
                  QuickCategoryCard(
                    title: 'Home Visit Physiotherapy',
                    subtitle: 'Ortho, Neuro & Rehab',
                    imageAsset: 'assets/images/3d/service_physio.jpg',
                    iconColor: AppColors.physioBadge,
                    backgroundColor: AppColors.physioBadge.withOpacity(0.1),
                    badge: '1-on-1 Care',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CatalogScreen(initialCategory: 'Physiotherapy')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 6. IN-HOUSE DIAGNOSTICS & PHYSIOTHERAPY SUITE
              SectionHeader(
                title: 'In-House Advanced Diagnostic Centre',
                subtitle: 'Supervised clinical setups with computerized reporting',
                actionText: 'Explore',
                onActionTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CatalogScreen(initialCategory: 'In-House Tests'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.82,
                children: [
                  _buildInHouseCard(
                    title: 'PFT Test (Spirometry)',
                    desc: 'Lung Capacity',
                    imageAsset: 'assets/images/3d/service_pft.jpg',
                    color: AppColors.pftBadge,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CatalogScreen(initialCategory: 'PFT (Lung Test)')),
                      );
                    },
                  ),
                  _buildInHouseCard(
                    title: 'Cardiac Stress (TMT)',
                    desc: 'Bruce Protocol',
                    imageAsset: 'assets/images/3d/doc_cardiologist.jpg',
                    color: AppColors.stressTestBadge,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CatalogScreen(initialCategory: 'ECG & Cardiology')),
                      );
                    },
                  ),
                  _buildInHouseCard(
                    title: 'Physio Rehab Suite',
                    desc: 'Laser / IFT / Trac',
                    imageAsset: 'assets/images/3d/service_physio.jpg',
                    color: AppColors.physioBadge,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CatalogScreen(initialCategory: 'Physiotherapy')),
                      );
                    },
                  ),
                  _buildInHouseCard(
                    title: '2D Echocardiography',
                    desc: 'Color Doppler',
                    imageAsset: 'assets/images/3d/service_ecg.jpg',
                    color: AppColors.ecgBadge,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CatalogScreen(initialCategory: 'ECG & Cardiology')),
                      );
                    },
                  ),
                  _buildInHouseCard(
                    title: 'Ultrasound (USG)',
                    desc: '4D Sonography',
                    imageAsset: 'assets/images/3d/female_doctor.jpg',
                    color: AppColors.xrayBadge,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CatalogScreen(initialCategory: 'Ultrasound (USG)')),
                      );
                    },
                  ),
                  _buildInHouseCard(
                    title: 'Stress Test (TMT)',
                    desc: 'Bruce Protocol',
                    imageAsset: 'assets/images/3d/doc_cardiologist.jpg',
                    color: AppColors.stressTestBadge,
                    onTap: () {
                      final service = context.read<CatalogProvider>().allServices.firstWhere(
                            (s) => s.id == 'stress_test_tmt',
                            orElse: () => CatalogService.initialServices[11],
                          );
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ScheduleBookingScreen(preSelectedService: service)),
                      );
                    },
                  ),
                  _buildInHouseCard(
                    title: 'Physio Setup Suite',
                    desc: 'IFT / Laser / Traction',
                    imageAsset: 'assets/images/3d/service_physio.jpg',
                    color: AppColors.physioBadge,
                    onTap: () {
                      final service = context.read<CatalogProvider>().allServices.firstWhere(
                            (s) => s.id == 'physio_inhouse_setup',
                            orElse: () => CatalogService.initialServices[12],
                          );
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ScheduleBookingScreen(preSelectedService: service)),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 7. PREVENTIVE HEALTH PACKAGES
              SectionHeader(
                title: 'Preventive Health Packages',
                subtitle: 'Subsidized health screening with verified digital reports',
                actionText: 'View All',
                onActionTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CatalogScreen(initialCategory: 'Health Packages'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: featuredPackages.length,
                  itemBuilder: (context, index) {
                    final pkg = featuredPackages[index];
                    return Container(
                      width: 280,
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : 10,
                        right: index == featuredPackages.length - 1 ? 0 : 10,
                      ),
                      child: TestCard(
                        service: pkg,
                        isCompact: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TestDetailScreen(service: pkg),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),

              // 8. TRUST BADGES
              const TrustBadgesSection(),
              const SizedBox(height: 18),

              // 9. LUXURY 24/7 HELPLINE BANNER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                          ),
                          child: ClipOval(
                            child: Image.asset('assets/images/3d/call_helpline.jpg', fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need Medical Consultation?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '24/7 Dedicated Helpline: +91 92709 88595',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => ContactHelper.callHelpline(context),
                            icon: const Icon(Icons.call_rounded, size: 14, color: Colors.white),
                            label: const Text('Call Helpline', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => ContactHelper.openWhatsApp(context),
                            icon: const Icon(Icons.chat_bubble_rounded, size: 14, color: Colors.white),
                            label: const Text('WhatsApp Chat', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInHouseCard({
    required String title,
    required String desc,
    IconData? icon,
    String? imageAsset,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCE7EC), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAsset != null)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFECDD3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(imageAsset, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon ?? Icons.science_rounded, color: color, size: 18),
              ),
            const SizedBox(height: 5),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
