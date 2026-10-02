import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/utils/search_matcher.dart';
import '../../providers/catalog_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../models/diagnostic_service.dart';
import '../../models/promo_banner.dart';
import '../../models/staff_model.dart';
import '../../models/user_profile.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_login_screen.dart';
import '../../widgets/app_image_view.dart';
import '../../widgets/empty_state.dart';
import 'widgets/add_staff_dialog.dart';
import 'widgets/add_test_dialog.dart';
import 'widgets/add_category_dialog.dart';
import 'widgets/booking_action_dialog.dart';
import 'widgets/edit_banner_dialog.dart';
import 'widgets/edit_package_dialog.dart';
import 'widgets/lab_sections_tab.dart';
import 'widgets/home_collections_tab.dart';
import '../../models/health_package.dart';
import 'widgets/upload_report_dialog.dart';
import 'widgets/send_patient_reminder_dialog.dart';
import '../../core/utils/field_order_pdf_generator.dart';
import '../../core/utils/prescription_printer.dart';
import '../../models/diagnostic_category.dart';
import '../../models/prescription_model.dart';
import '../../services/prescription_service.dart';
import '../../widgets/motion_logo_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedNavIndex = 4; // Default to Diagnostic Test Catalog & Category Management

  final List<String> _navTitles = [
    'Incoming Booking Requests',
    'Active Home Visits & Dispatches',
    'Medical Staff & Technicians',
    'Diagnostic Categories & Departments',
    'Diagnostic Test Catalog',
    'Promotional Banners & Offers',
    'Patient Users Directory',
    'Health Packages & Offers',
    'Lab Sections (Women, Men, Children…)',
    'Home Sections (Fever, Lifestyle, Athlete…)',
  ];

  final TextEditingController _catalogSearchController = TextEditingController();
  String _catalogSearchQuery = '';
  String _catalogCategoryFilter = 'All';
  DiagnosticCategory? _selectedCategory;

  @override
  void dispose() {
    _catalogSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().initAdminData();
    });
  }

  void _openAcceptDialog(BookingModel booking) {
    showDialog(context: context, builder: (_) => BookingActionDialog(booking: booking));
  }

  void _openUploadReportDialog(BookingModel booking) {
    showDialog(context: context, builder: (_) => UploadReportDialog(booking: booking));
  }

  void _openSendReminderDialog({String? patientId, String? patientName}) {
    showDialog(
      context: context,
      builder: (_) => SendPatientReminderDialog(
        initialUserId: patientId,
        initialPatientName: patientName,
      ),
    );
  }

  void _openAddStaffDialog([StaffMember? staff]) {
    showDialog(context: context, builder: (_) => AddStaffDialog(staffToEdit: staff));
  }

  void _openAddTestDialog([DiagnosticService? service, String? categoryId, String? categoryName]) {
    showDialog(
      context: context,
      builder: (_) => AddTestDialog(
        testToEdit: service,
        initialCategoryId: categoryId,
        initialCategoryName: categoryName,
      ),
    );
  }

  void _openAddCategoryDialog([DiagnosticCategory? category]) {
    showDialog(context: context, builder: (_) => AddCategoryDialog(categoryToEdit: category));
  }

  void _openEditBannerDialog(PromoBanner banner) {
    showDialog(context: context, builder: (_) => EditBannerDialog(banner: banner));
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Sign Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out from the PrecisionCare Admin Portal?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signed out from Admin Portal'),
                    backgroundColor: AppColors.secondary,
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _openPrescriptionViewerDialog({String? targetUserId, String? targetPatientName}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          height: MediaQuery.of(context).size.height * 0.82,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF7C3AED), size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            targetPatientName != null ? 'Prescriptions: $targetPatientName' : 'Uploaded Doctor Prescriptions',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          const Text(
                            'Click thumbnail to enlarge or Print official prescription slip',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: StreamBuilder<List<PrescriptionModel>>(
                  stream: PrescriptionService.streamAllPrescriptions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var prescriptions = snapshot.data ?? [];
                    if (targetUserId != null) {
                      prescriptions = prescriptions.where((p) => p.userId == targetUserId).toList();
                    }

                    if (prescriptions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            const Text('No Prescriptions Uploaded Yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              targetPatientName != null
                                  ? 'This patient has not uploaded any doctor prescription slips.'
                                  : 'When patients upload prescription slips from the app, they will appear here.',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: prescriptions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = prescriptions[index];
                        final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(item.uploadedAt);

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Prescription: ${item.patientName}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(context)),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: AppImageView(imageUrl: item.prescriptionUrl),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.prescriptionUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 56,
                                      height: 56,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported_outlined, size: 24, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(item.patientName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(item.status, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('📱 ${item.patientPhone} • $dateStr', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text('Notes: "${item.notes}"', style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
                                    ],
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => PrescriptionPrinter.printPrescription(
                                  prescriptionUrl: item.prescriptionUrl,
                                  patientName: item.patientName,
                                  patientMobile: item.patientPhone,
                                  notes: item.notes,
                                  date: item.uploadedAt,
                                ),
                                icon: const Icon(Icons.print_rounded, size: 14, color: Colors.white),
                                label: const Text('Print', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnauthorizedAccessView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_person_rounded, size: 48, color: AppColors.error),
              ),
              const SizedBox(height: 20),
              const Text(
                'Admin Authentication Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You must be signed in with an authorized Administrator account to view and manage PrecisionCare diagnostic operations.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.login_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    'Sign In as Admin',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated || !auth.isAdmin) {
      return _buildUnauthorizedAccessView();
    }

    final admin = context.watch<AdminProvider>();

    final pending = admin.pendingRequests;
    final active = admin.activeVisits;
    final staff = admin.staffList;
    final catalog = admin.catalogServices;
    final banners = admin.banners;
    final users = admin.usersList;

    final categories = admin.categories;
    final isLargeScreen = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isLargeScreen
          ? null
          : Drawer(
              child: _buildSidebar(
                admin,
                pending.length,
                active.length,
                staff.length,
                categories.length,
                catalog.length,
                banners.length,
                users.length,
                isDrawer: true,
              ),
            ),
      appBar: isLargeScreen
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF0F172A),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset('assets/images/precisioncare_logo.jpeg', fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _navTitles[_selectedNavIndex],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  tooltip: 'Refresh Data',
                  onPressed: () => admin.initAdminData(),
                ),
                IconButton(
                  icon: const Icon(Icons.notification_add_rounded, color: AppColors.accent, size: 20),
                  tooltip: 'Push Patient Reminder',
                  onPressed: () => _openSendReminderDialog(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmSignOut(context),
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFFFCA5A5), size: 14),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0x66FCA5A5)),
                      backgroundColor: const Color(0x26EF4444),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ],
            ),
      body: Row(
        children: [
          // 1. LEFT SIDEBAR (On Large Screens)
          if (isLargeScreen)
            _buildSidebar(
              admin,
              pending.length,
              active.length,
              staff.length,
              categories.length,
              catalog.length,
              banners.length,
              users.length,
            ),

          // 2. MAIN CONTENT AREA
          Expanded(
            child: Column(
              children: [
                // Top Header Bar (Desktop/Web only)
                if (isLargeScreen) _buildTopAppBar(admin),

                // Top Metrics Quick Strip
                _buildMetricsStrip(admin, isLargeScreen: isLargeScreen),
                const Divider(height: 1, color: AppColors.border),

                // Mobile Horizontal Navigation Tabs
                if (!isLargeScreen) _buildMobileNavBar(pending.length, active.length, categories.length),

                // Active View Body
                Expanded(
                  child: admin.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildActiveContentView(
                          index: _selectedNavIndex,
                          pending: pending,
                          active: active,
                          staff: staff,
                          categories: categories,
                          catalog: catalog,
                          banners: banners,
                          users: users,
                          admin: admin,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // LEFT SIDEBAR WIDGET
  Widget _buildSidebar(
    AdminProvider admin,
    int pendingCount,
    int activeCount,
    int staffCount,
    int categoriesCount,
    int catalogCount,
    int bannersCount,
    int usersCount, {
    bool isDrawer = false,
  }) {
    return Container(
      width: isDrawer ? double.infinity : 260,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Dark Slate Theme
        border: Border(right: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Brand Header with Logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  const MotionLogo(
                    size: 36,
                    showRipples: false,
                    showFloating: true,
                    showHeartbeat: true,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRECISIONCARE',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
                        ),
                        Text(
                          'Admin Operations Panel',
                          style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  if (isDrawer)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),

            // Sidebar Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                children: [
                  _buildSidebarItem(
                    index: 0,
                    icon: Icons.pending_actions_rounded,
                    label: 'Pending Requests',
                    badgeCount: pendingCount,
                    badgeColor: AppColors.accent,
                    isDrawer: isDrawer,
                  ),
                  _buildSidebarItem(
                    index: 1,
                    icon: Icons.run_circle_outlined,
                    label: 'Active Dispatches',
                    badgeCount: activeCount,
                    badgeColor: AppColors.info,
                    isDrawer: isDrawer,
                  ),
                  _buildSidebarItem(
                    index: 2,
                    icon: Icons.badge_outlined,
                    label: 'Staff Directory',
                    badgeCount: staffCount,
                    isDrawer: isDrawer,
                  ),
                  _buildSidebarItem(
                    index: 3,
                    icon: Icons.category_rounded,
                    label: 'Test Categories',
                    badgeCount: categoriesCount,
                    badgeColor: AppColors.primary,
                    isDrawer: isDrawer,
                  ),
                  _buildSidebarItem(
                    index: 4,
                    icon: Icons.science_outlined,
                    label: 'Test Catalog & Prices',
                    badgeCount: catalogCount,
                    isDrawer: isDrawer,
                  ),
                  _buildSidebarItem(
                    index: 5,
                    icon: Icons.view_carousel_outlined,
                    label: 'Promotional Banners',
                    badgeCount: bannersCount,
                    isDrawer: isDrawer,
                  ),
                  _buildSidebarItem(
                    index: 6,
                    icon: Icons.people_alt_outlined,
                    label: 'Patient Users Directory',
                    badgeCount: usersCount,
                    isDrawer: isDrawer,
                  ),
                  _buildSidebarItem(
                    index: 7,
                    icon: Icons.inventory_2_outlined,
                    label: 'Health Packages',
                    badgeCount: admin.packages.length,
                    isDrawer: isDrawer,
                  ),
                  _buildSidebarItem(
                    index: 8,
                    icon: Icons.groups_rounded,
                    label: 'Lab Sections',
                    badgeCount: admin.labAudiences.length,
                    isDrawer: isDrawer,
                  ),
                  _buildSidebarItem(
                    index: 9,
                    icon: Icons.view_agenda_rounded,
                    label: 'Home Sections',
                    badgeCount: admin.homeCollections.length,
                    isDrawer: isDrawer,
                  ),
                ],
              ),
            ),

            // Bottom Sidebar Actions
            Builder(
              builder: (ctx) {
                final auth = ctx.watch<AuthProvider>();
                final email = auth.user?.email.isNotEmpty == true ? auth.user!.email : 'admin@precisioncare.com';
                final name = auth.user?.name.isNotEmpty == true ? auth.user!.name : 'Clinic Admin';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0B1120),
                    border: Border(top: BorderSide(color: Color(0xFF1E293B))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFF1E293B),
                            child: Icon(Icons.shield_rounded, size: 16, color: AppColors.accent),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  email,
                                  style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (isDrawer) Navigator.pop(context);
                            _confirmSignOut(context);
                          },
                          icon: const Icon(Icons.logout_rounded, size: 14, color: Color(0xFFF87171)),
                          label: const Text(
                            'Logout Admin',
                            style: TextStyle(color: Color(0xFFF87171), fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0x33F87171)),
                            backgroundColor: const Color(0x1AF87171),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String label,
    int? badgeCount,
    Color badgeColor = const Color(0xFF334155),
    bool isDrawer = false,
  }) {
    final isSelected = _selectedNavIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          setState(() => _selectedNavIndex = index);
          if (isDrawer) Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
              if (badgeCount != null && badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.25) : badgeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // MOBILE HORIZONTAL TAB SWITCHER
  Widget _buildMobileNavBar(int pendingCount, int activeCount, int categoriesCount) {
    final shortTabs = [
      {'title': 'Pending', 'badge': pendingCount, 'icon': Icons.pending_actions_rounded},
      {'title': 'Active', 'badge': activeCount, 'icon': Icons.run_circle_outlined},
      {'title': 'Staff', 'badge': null, 'icon': Icons.badge_outlined},
      {'title': 'Categories', 'badge': categoriesCount, 'icon': Icons.category_rounded},
      {'title': 'Catalog', 'badge': null, 'icon': Icons.science_outlined},
      {'title': 'Banners', 'badge': null, 'icon': Icons.view_carousel_outlined},
      {'title': 'Users', 'badge': null, 'icon': Icons.people_alt_outlined},
      {'title': 'Packages', 'badge': null, 'icon': Icons.inventory_2_outlined},
      {'title': 'Lab Sections', 'badge': null, 'icon': Icons.groups_rounded},
      {'title': 'Home Sections', 'badge': null, 'icon': Icons.view_agenda_rounded},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(shortTabs.length, (idx) {
            final isSelected = _selectedNavIndex == idx;
            final item = shortTabs[idx];
            final badge = item['badge'] as int?;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 14,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (badge != null && badge > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badge',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? AppColors.primary : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.background,
                onSelected: (_) => setState(() => _selectedNavIndex = idx),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                showCheckmark: false,
              ),
            );
          }),
        ),
      ),
    );
  }

  // TOP APP BAR (Desktop / Web)
  Widget _buildTopAppBar(AdminProvider admin) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_customize_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                _navTitles[_selectedNavIndex],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => admin.initAdminData(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh Data', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _openSendReminderDialog(),
                icon: const Icon(Icons.notification_add_rounded, size: 16, color: Colors.white),
                label: const Text('Push Reminder', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _confirmSignOut(context),
                icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFECDD3)),
                  backgroundColor: const Color(0xFFFFF1F2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TOP METRICS STRIP (Responsive for Mobile & Desktop)
  Widget _buildMetricsStrip(AdminProvider admin, {required bool isLargeScreen}) {
    final statCards = [
      _buildStatCard('Pending Requests', '${admin.pendingRequests.length}', AppColors.accent, Icons.pending_actions_rounded),
      _buildStatCard('Active Dispatches', '${admin.activeVisits.length}', AppColors.info, Icons.run_circle_outlined),
      _buildStatCard('Active Staff', '${admin.activeStaffList.length}', AppColors.secondary, Icons.badge_outlined),
      _buildStatCard('Completed Reports', '${admin.completedBookings.length}', AppColors.success, Icons.task_alt_rounded),
      _buildStatCard('Total Revenue', '₹${admin.totalRevenue.toInt()}', AppColors.primary, Icons.account_balance_wallet_outlined),
    ];

    if (isLargeScreen) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: statCards.map((card) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: card))).toList(),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statCards.map((card) => Container(width: 145, margin: const EdgeInsets.only(right: 8), child: card)).toList(),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: color), maxLines: 1),
                Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveContentView({
    required int index,
    required List<BookingModel> pending,
    required List<BookingModel> active,
    required List<StaffMember> staff,
    required List<DiagnosticCategory> categories,
    required List<DiagnosticService> catalog,
    required List<PromoBanner> banners,
    required List<UserProfile> users,
    required AdminProvider admin,
  }) {
    switch (index) {
      case 0:
        return _buildBookingsQueue(pending, isPendingQueue: true);
      case 1:
        return _buildBookingsQueue(active, isActiveQueue: true);
      case 2:
        return _buildStaffTab(staff);
      case 3:
        return _buildCategoriesTab(admin, categories, catalog);
      case 4:
        return _buildCatalogTab(catalog);
      case 5:
        return _buildBannersTab(banners);
      case 6:
        return _buildUsersTab(users);
      case 7:
        return _buildPackagesTab(admin);
      case 8:
        return const LabSectionsTab();
      case 9:
        return const HomeCollectionsTab();
      default:
        return _buildBookingsQueue(pending);
    }
  }

  Widget? _buildFab() {
    if (_selectedNavIndex == 2) {
      return FloatingActionButton.extended(
        onPressed: () => _openAddStaffDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Staff Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      );
    } else if (_selectedNavIndex == 3) {
      return FloatingActionButton.extended(
        onPressed: () => _openAddCategoryDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.category_rounded, color: Colors.white),
        label: const Text('+ Add Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      );
    } else if (_selectedNavIndex == 4) {
      return FloatingActionButton.extended(
        onPressed: () => _openAddTestDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text('Add to Catalog', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      );
    } else if (_selectedNavIndex == 7) {
      return FloatingActionButton.extended(
        onPressed: _openNewPackage,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Package', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      );
    } else if (_selectedNavIndex == 8 && context.read<AdminProvider>().labAudiences.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: () => LabSectionsTab.openNewSection(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Section', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      );
    } else if (_selectedNavIndex == 9 && context.read<AdminProvider>().homeCollections.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: () => HomeCollectionsTab.openNew(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Home Section', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      );
    }
    return null;
  }

  void _openNewPackage() {
    showDialog(
      context: context,
      builder: (_) => EditPackageDialog(
        isNew: true,
        package: HealthPackage(id: 'PKG-${DateTime.now().millisecondsSinceEpoch}', name: '', price: 0),
      ),
    );
  }

  // 7. HEALTH PACKAGES TAB
  Widget _buildPackagesTab(AdminProvider admin) {
    final packages = admin.packages;
    if (packages.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No Health Packages Yet',
        description: 'Create a package with a poster, offer and the tests it includes. It appears on the patient home screen.',
        buttonText: 'Create Package',
        onButtonPressed: _openNewPackage,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: packages.length,
      itemBuilder: (context, i) {
        final pkg = packages[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pkg.posterUrl != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AppImageView(imageUrl: pkg.posterUrl!, fit: BoxFit.cover),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                              if (pkg.isFeatured) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                              ],
                              if (pkg.tag.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFF1D4ED8), borderRadius: BorderRadius.circular(4)),
                                  child: Text(pkg.tag, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ],
                          ),
                          if (pkg.offerText.isNotEmpty)
                            Text(pkg.offerText, style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            '${pkg.testCount} tests • ₹${pkg.price.toStringAsFixed(0)}${pkg.reportTime.isNotEmpty ? ' • Report in ${pkg.reportTime}' : ''}${pkg.isActive ? '' : ' • HIDDEN'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.info),
                      onPressed: () => showDialog(context: context, builder: (_) => EditPackageDialog(package: pkg)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      onPressed: () => admin.deletePackage(pkg.id),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 1 & 2. BOOKINGS QUEUE
  Widget _buildBookingsQueue(
    List<BookingModel> bookings, {
    bool isPendingQueue = false,
    bool isActiveQueue = false,
  }) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: isPendingQueue ? 'No Pending Booking Requests' : 'No Active Visits',
        description: isPendingQueue
            ? 'All incoming diagnostic requests have been accepted and dispatched to phlebotomists.'
            : 'New appointments scheduled in Patient App will appear here in real-time.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final isHomeVisit = booking.visitType == VisitType.homeVisit;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: booking.status == BookingStatus.pendingApproval ? AppColors.accent : AppColors.border,
              width: booking.status == BookingStatus.pendingApproval ? 1.5 : 1,
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('BOOKING #${booking.id}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => FieldWorkOrderPdfGenerator.printOrShareWorkOrder(booking),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.print_rounded, size: 12, color: AppColors.primary),
                              SizedBox(width: 3),
                              Text('Print Slip', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isHomeVisit ? AppColors.primaryLight : AppColors.infoLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isHomeVisit ? 'HOME VISIT' : 'IN-HOUSE CENTRE',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isHomeVisit ? AppColors.primaryDark : AppColors.info),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 18, backgroundColor: AppColors.background, child: Icon(Icons.person, color: AppColors.primary, size: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${booking.patientName} (${booking.patientAge}y, ${booking.patientSex})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        Text('Ph: ${booking.patientMobile}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text('₹${booking.totalAmount.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...booking.services.map((s) => Text('• ${s.title}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    const SizedBox(height: 4),
                    Text('Slot: ${DateFormat("EEE, dd MMM").format(booking.scheduledDate)} (${booking.timeSlot})', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    if (isHomeVisit && booking.patientAddress != null)
                      Text('Address: ${booking.patientAddress}', style: const TextStyle(fontSize: 11, color: AppColors.primaryDark)),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // UTR Payment Verification Badge
              if (booking.utrNumber != null || booking.paymentStatus.contains('Online') || booking.paymentStatus.contains('Paid')) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'UPI Paid • UTR: ${booking.utrNumber ?? "Verified Online"}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                        ),
                      ),
                      if (booking.paymentScreenshotUrl != null)
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('UPI Payment Proof', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(context)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: AppImageView(imageUrl: booking.paymentScreenshotUrl!),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('View Proof', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.payments_outlined, size: 14, color: Color(0xFFD97706)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text('Pay on Visit / Collection (Cash / UPI)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              if (booking.technicianName != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.successLight.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Assigned Staff: ${booking.technicianName} (${booking.technicianPhone ?? ""})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Actions
              Row(
                children: [
                  if (booking.status == BookingStatus.pendingApproval) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openAcceptDialog(booking),
                        icon: const Icon(Icons.person_pin_rounded, size: 16),
                        label: const Text('Select Staff & Accept', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => context.read<AdminProvider>().cancelOrRejectBooking(booking.id, 'Slot unavailable'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                      child: const Text('Reject', style: TextStyle(fontSize: 12)),
                    ),
                  ] else if (booking.status != BookingStatus.completed && booking.status != BookingStatus.cancelled) ...[
                    if (booking.status == BookingStatus.technicianAssigned || booking.status == BookingStatus.confirmed)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.read<AdminProvider>().updateStatus(bookingId: booking.id, newStatus: BookingStatus.sampleCollected),
                          icon: const Icon(Icons.science_outlined, size: 16),
                          label: const Text('Sample Taken', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openUploadReportDialog(booking),
                        icon: const Icon(Icons.upload_file_rounded, size: 16),
                        label: const Text('Upload Report', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. STAFF DIRECTORY TAB
  Widget _buildStaffTab(List<StaffMember> staffList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: staffList.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Medical Staff & Technicians Directory', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    Text('Total certified field & lab personnel: ${staffList.length}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _openAddStaffDialog(),
                  icon: const Icon(Icons.person_add, size: 14, color: Colors.white),
                  label: const Text('Add Staff', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                ),
              ],
            ),
          );
        }

        final staff = staffList[index - 1];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                  style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: staff.isActive ? AppColors.successLight : AppColors.errorLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            staff.isActive ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: staff.isActive ? AppColors.success : AppColors.error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(staff.role, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text('Ph: ${staff.phone}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    Text(staff.specialization, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Text('Completed Field Visits: ${staff.completedVisits}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                    onPressed: () => _openAddStaffDialog(staff),
                    tooltip: 'Edit Staff',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Staff Member?'),
                          content: Text('Remove ${staff.name} from directory?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () {
                                context.read<AdminProvider>().deleteStaff(staff.id);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: 'Delete Staff',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. DIAGNOSTIC TEST CATEGORIES MANAGEMENT TAB
  Widget _buildCategoriesTab(
    AdminProvider admin,
    List<DiagnosticCategory> categories,
    List<DiagnosticService> catalog,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Top Management Header Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.category_rounded, color: AppColors.primary, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Diagnostic Categories & Departments',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total ${categories.length} Categories • Add or manage categories to strictly isolate and organize tests',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openAddCategoryDialog(),
                    icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.white),
                    label: const Text(
                      '+ Add New Category',
                      style: TextStyle(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Summary Metrics Row
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildCategoryMetricChip(
                    '${categories.length} Departments',
                    Icons.account_tree_outlined,
                    AppColors.primary,
                  ),
                  _buildCategoryMetricChip(
                    '${categories.where((c) => c.isHomeVisitAvailable).length} Home Collection Enabled',
                    Icons.home_outlined,
                    AppColors.info,
                  ),
                  _buildCategoryMetricChip(
                    '${categories.where((c) => c.isInHouseAvailable).length} Lab In-House Enabled',
                    Icons.local_hospital_outlined,
                    AppColors.success,
                  ),
                  _buildCategoryMetricChip(
                    '${catalog.length} Total Tests Linked',
                    Icons.science_outlined,
                    AppColors.secondary,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Categories List / Cards
        if (categories.isEmpty)
          const EmptyState(
            title: 'No Categories Found',
            description: 'Click "+ Add New Category" above to create your first diagnostic category.',
            icon: Icons.category_outlined,
          )
        else
          ...categories.map((category) {
            final linkedTests = catalog.where((s) => _testBelongsToCategory(s, category)).toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Icon Box
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: category.color.withOpacity(0.25)),
                        ),
                        child: Icon(category.iconData, color: category.color, size: 24),
                      ),
                      const SizedBox(width: 14),

                      // Category Title & Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    category.name,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                if (category.badge != null && category.badge!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: category.color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      category.badge!,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: category.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category.description,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                            ),
                          ],
                        ),
                      ),

                      // Tests Count Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '${linkedTests.length} Tests',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),

                  // Bottom Row: Capabilities Chips & Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Capabilities
                      Wrap(
                        spacing: 6,
                        children: [
                          if (category.isHomeVisitAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '🏠 Home Collection',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                              ),
                            ),
                          if (category.isInHouseAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '🏥 Lab In-House',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                              ),
                            ),
                        ],
                      ),

                      // Action Buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openAddTestDialog(null, category.id, category.name),
                            icon: const Icon(Icons.add, size: 13, color: AppColors.primary),
                            label: const Text('Add Test', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w800)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary, width: 1.2),
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                            tooltip: 'Edit Category',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () => _openAddCategoryDialog(category),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                            tooltip: 'Delete Category',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () => _confirmDeleteCategory(admin, category),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCategoryMetricChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(AdminProvider admin, DiagnosticCategory category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${category.name}"?', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text(
          'Are you sure you want to delete the "${category.name}" category? Tests under this category will remain in the catalog but will no longer be grouped under this category.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await admin.deleteCategory(category.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Category "${category.name}" deleted'), backgroundColor: AppColors.success),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String iconType) {
    switch (iconType) {
      case 'blood':
        return Icons.water_drop_rounded;
      case 'xray':
        return Icons.camera_enhance_rounded;
      case 'ecg':
        return Icons.monitor_heart_rounded;
      case 'stress_test':
        return Icons.directions_run_rounded;
      case 'usg':
        return Icons.waves_rounded;
      case 'pft':
        return Icons.air_rounded;
      case 'physio':
        return Icons.accessibility_new_rounded;
      case 'package':
        return Icons.inventory_2_outlined;
      default:
        return Icons.medical_services_rounded;
    }
  }

  Color _getServiceBadgeColor(String iconType) {
    switch (iconType) {
      case 'blood':
        return AppColors.bloodTestBadge;
      case 'xray':
        return AppColors.xrayBadge;
      case 'ecg':
        return AppColors.ecgBadge;
      case 'stress_test':
        return AppColors.stressTestBadge;
      case 'usg':
        return const Color(0xFF0891B2);
      case 'pft':
        return AppColors.pftBadge;
      case 'physio':
        return AppColors.physioBadge;
      case 'package':
        return const Color(0xFFD97706);
      default:
        return AppColors.primary;
    }
  }

  // Helper to determine if a test belongs to a specific category
  bool _testBelongsToCategory(DiagnosticService test, DiagnosticCategory cat) {
    final catLower = cat.name.trim().toLowerCase();
    final catIdLower = cat.id.toLowerCase();
    final titleLower = test.title.toLowerCase();
    final testCatNameLower = test.categoryName.trim().toLowerCase();

    // 1. Digital X-Ray - STRICT: Exclude blood and other non-xray modalities
    if (catIdLower == 'cat_xray' || catLower.contains('x-ray') || catLower.contains('xray')) {
      if (test.categoryId == 'cat_blood' ||
          test.iconType == 'blood' ||
          testCatNameLower.contains('blood') ||
          titleLower.contains('blood') ||
          titleLower.contains('cbc') ||
          titleLower.contains('lipid') ||
          titleLower.contains('thyroid') ||
          titleLower.contains('glucose') ||
          titleLower.contains('sugar') ||
          titleLower.contains('diabetes') ||
          titleLower.contains('hemoglobin') ||
          titleLower.contains('hba1c') ||
          titleLower.contains('serum')) {
        return false;
      }
      if (test.categoryId == 'cat_ecg' || test.iconType == 'ecg' || titleLower.contains('ecg') || testCatNameLower.contains('ecg')) return false;
      if (test.categoryId == 'cat_usg' || test.iconType == 'usg' || titleLower.contains('ultrasound') || testCatNameLower.contains('ultrasound')) return false;
      if (test.categoryId == 'cat_pft' || test.iconType == 'pft' || titleLower.contains('pft') || testCatNameLower.contains('pft')) return false;
      if (test.categoryId == 'cat_physio' || test.iconType == 'physio' || test.category == ServiceCategory.physiotherapy) return false;
      if (test.categoryId == 'cat_packages' || test.category == ServiceCategory.healthPackage) return false;

      return test.categoryId == 'cat_xray' ||
          test.iconType == 'xray' ||
          testCatNameLower.contains('x-ray') ||
          testCatNameLower.contains('xray') ||
          titleLower.contains('x-ray') ||
          titleLower.contains('xray') ||
          titleLower.contains('radiograph');
    }

    // 2. Blood Tests - STRICT: Exclude X-Ray and other non-blood modalities
    if (catIdLower == 'cat_blood' || catLower.contains('blood')) {
      final isXray = test.iconType == 'xray' ||
          test.categoryId == 'cat_xray' ||
          testCatNameLower.contains('x-ray') ||
          testCatNameLower.contains('xray') ||
          titleLower.contains('x-ray') ||
          titleLower.contains('xray') ||
          titleLower.contains('radiograph');
      if (isXray || test.categoryId == 'cat_packages' || test.category == ServiceCategory.healthPackage) return false;
      if (test.categoryId == 'cat_ecg' || test.categoryId == 'cat_usg' || test.categoryId == 'cat_pft' || test.categoryId == 'cat_physio') {
        return false;
      }
      return test.categoryId == 'cat_blood' ||
          test.iconType == 'blood' ||
          testCatNameLower.contains('blood') ||
          titleLower.contains('blood') ||
          titleLower.contains('cbc') ||
          titleLower.contains('lipid') ||
          titleLower.contains('thyroid') ||
          titleLower.contains('diabetes') ||
          titleLower.contains('sugar') ||
          titleLower.contains('glucose');
    }

    if (test.categoryId != null && test.categoryId == cat.id) return true;

    // 3. ECG & Cardiology - STRICT
    if (catIdLower == 'cat_ecg' || catLower.contains('ecg') || catLower.contains('cardio') || catLower.contains('heart')) {
      if (test.categoryId == 'cat_xray' || test.categoryId == 'cat_blood' || test.categoryId == 'cat_usg' || test.categoryId == 'cat_pft' || test.categoryId == 'cat_physio' || test.categoryId == 'cat_packages') {
        return false;
      }
      return test.categoryId == 'cat_ecg' ||
          test.iconType == 'ecg' ||
          test.iconType == 'stress_test' ||
          test.categoryName.toLowerCase().contains('ecg') ||
          test.title.toLowerCase().contains('ecg') ||
          test.title.toLowerCase().contains('stress test') ||
          test.title.toLowerCase().contains('echocardiography');
    }

    // 4. Ultrasound (USG) - STRICT
    if (catIdLower == 'cat_usg' || catLower.contains('usg') || catLower.contains('ultrasound') || catLower.contains('sonography')) {
      if (test.categoryId == 'cat_xray' || test.categoryId == 'cat_blood' || test.categoryId == 'cat_ecg' || test.categoryId == 'cat_pft' || test.categoryId == 'cat_physio' || test.categoryId == 'cat_packages') {
        return false;
      }
      return test.categoryId == 'cat_usg' ||
          test.iconType == 'usg' ||
          test.categoryName.toLowerCase().contains('ultrasound') ||
          test.categoryName.toLowerCase().contains('usg') ||
          test.title.toLowerCase().contains('ultrasound');
    }

    // 5. PFT (Lung Test) - STRICT
    if (catIdLower == 'cat_pft' || catLower.contains('pft') || catLower.contains('spirometry') || catLower.contains('lung')) {
      return test.categoryId == 'cat_pft' ||
          test.iconType == 'pft' ||
          test.categoryName.toLowerCase().contains('pft') ||
          test.title.toLowerCase().contains('pft') ||
          test.title.toLowerCase().contains('spirometry');
    }

    // 6. Physiotherapy - STRICT
    if (catIdLower == 'cat_physio' || catLower.contains('physio')) {
      return test.categoryId == 'cat_physio' ||
          test.category == ServiceCategory.physiotherapy ||
          test.iconType == 'physio' ||
          test.categoryName.toLowerCase().contains('physio');
    }

    // 7. Health Packages - STRICT
    if (catIdLower == 'cat_packages' || catLower.contains('package') || catLower.contains('full body')) {
      return test.categoryId == 'cat_packages' ||
          test.category == ServiceCategory.healthPackage ||
          test.categoryName.toLowerCase().contains('package') ||
          test.includedTests.length > 5;
    }

    // 8. Custom Admin Categories
    return (test.categoryId != null && test.categoryId!.toLowerCase() == catIdLower) ||
        test.categoryName.trim().toLowerCase() == catLower;
  }

  int _getCategoryTestCount(DiagnosticCategory cat, List<DiagnosticService> catalog) {
    return catalog.where((t) => _testBelongsToCategory(t, cat)).length;
  }

  // 4. TEST CATALOG TAB WITH SEARCH, CATEGORY MANAGEMENT & ISOLATED FILTERING
  Widget _buildCatalogTab(List<DiagnosticService> catalog) {
    final adminProvider = context.watch<AdminProvider>();
    final categories = adminProvider.categories;

    // 1. Strict Category Filtering
    var filtered = catalog.where((test) {
      if (_catalogCategoryFilter == 'All') return true;

      // Legacy broad filters
      if (_catalogCategoryFilter == 'Home Visits') {
        return test.isHomeVisitAvailable || test.category == ServiceCategory.homeVisit;
      } else if (_catalogCategoryFilter == 'In-House') {
        return test.isInHouseAvailable || test.category == ServiceCategory.inHouseDiagnostic;
      }

      if (_selectedCategory != null) {
        return _testBelongsToCategory(test, _selectedCategory!);
      }

      final matchedCat = categories.cast<DiagnosticCategory?>().firstWhere(
        (c) => c != null && (c.name.toLowerCase() == _catalogCategoryFilter.toLowerCase() || c.id.toLowerCase() == _catalogCategoryFilter.toLowerCase()),
        orElse: () => null,
      );
      if (matchedCat != null) {
        return _testBelongsToCategory(test, matchedCat);
      }

      final filterLower = _catalogCategoryFilter.trim().toLowerCase();
      return (test.categoryId != null && test.categoryId!.toLowerCase() == filterLower) ||
          test.categoryName.trim().toLowerCase() == filterLower;
    }).toList();

    // 2. Filter by search query (name, category, price, description)
    final query = _catalogSearchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = SearchMatcher.rank(filtered, query, (test) => [
            ...CatalogProvider.searchFieldsOf(test),
            test.price.toInt().toString(),
            test.originalPrice?.toInt().toString(),
          ]);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.isEmpty ? 2 : filtered.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title + Add Category & Add Test Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Diagnostic Services & Packages Live Catalog',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total Catalog: ${catalog.length} services • Filtered: ${filtered.length}',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        // Add Category Button
                        OutlinedButton.icon(
                          onPressed: () => _openAddCategoryDialog(),
                          icon: const Icon(Icons.category_rounded, size: 14, color: AppColors.primary),
                          label: const Text('+ Category', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w800)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.3),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        // Add Test Button
                        ElevatedButton.icon(
                          onPressed: () => _openAddTestDialog(null, _selectedCategory?.id, _selectedCategory?.name),
                          icon: const Icon(Icons.add_circle_outline, size: 15, color: Colors.white),
                          label: const Text('Add Test', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Search Bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _catalogSearchController,
                    onChanged: (val) {
                      setState(() {
                        _catalogSearchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by test name, category, or price (e.g. Thyroid, X-Ray, 499)...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                      suffixIcon: _catalogSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                              onPressed: () {
                                _catalogSearchController.clear();
                                setState(() {
                                  _catalogSearchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),

                // Categories Management & Filter Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.folder_special_rounded, size: 14, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Test Categories',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${categories.length}',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _openAddCategoryDialog(),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline, size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              '+ Add New Category',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Horizontal Category Cards with Edit, Delete & Filter
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, catIndex) {
                      if (catIndex == 0) {
                        final isSelected = _catalogCategoryFilter == 'All';
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _catalogCategoryFilter = 'All';
                              _selectedCategory = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 125,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withOpacity(0.08) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.8 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.grid_view_rounded, size: 18, color: isSelected ? Colors.white : const Color(0xFF475569)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'All Tests',
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                          fontSize: 12,
                                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${catalog.length} tests',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final cat = categories[catIndex - 1];
                      final isSelected = (_selectedCategory?.id == cat.id) || (_catalogCategoryFilter == cat.name);
                      final testCount = _getCategoryTestCount(cat, catalog);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected && _catalogCategoryFilter != 'All') {
                              _catalogCategoryFilter = 'All';
                              _selectedCategory = null;
                            } else {
                              _catalogCategoryFilter = cat.name;
                              _selectedCategory = cat;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? cat.color.withOpacity(0.09) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? cat.color : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: cat.color.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon Box
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isSelected ? cat.color : cat.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(cat.iconData, size: 18, color: isSelected ? Colors.white : cat.color),
                              ),
                              const SizedBox(width: 8),

                              // Name & Test Count
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 130),
                                        child: Text(
                                          cat.name,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                            fontSize: 12,
                                            color: isSelected ? cat.color : AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (cat.badge.isNotEmpty) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: cat.color.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            cat.badge,
                                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: cat.color),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '$testCount tests',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: isSelected ? cat.color : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),

                              // Edit Category Icon Button
                              Tooltip(
                                message: 'Edit ${cat.name}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => _openAddCategoryDialog(cat),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Icon(Icons.edit_outlined, size: 16, color: isSelected ? cat.color : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ),
                              ),

                              // Delete Category Icon Button
                              Tooltip(
                                message: 'Delete ${cat.name}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () {
                                      _confirmDeleteCategory(adminProvider, cat);
                                      if (_selectedCategory?.id == cat.id) {
                                        setState(() {
                                          _catalogCategoryFilter = 'All';
                                          _selectedCategory = null;
                                        });
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Active Category Filter Indicator with direct + Add Test shortcut
                if (_selectedCategory != null && _catalogCategoryFilter != 'All') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedCategory!.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _selectedCategory!.color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(_selectedCategory!.iconData, size: 16, color: _selectedCategory!.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Active Category: ${_selectedCategory!.name} (${filtered.length} tests)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _selectedCategory!.color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openAddTestDialog(null, _selectedCategory!.id, _selectedCategory!.name),
                          icon: const Icon(Icons.add, size: 13, color: Colors.white),
                          label: Text(
                            'Add to ${_selectedCategory!.name}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedCategory!.color,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _catalogCategoryFilter = 'All';
                              _selectedCategory = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        // Empty Search Results State
        if (filtered.isEmpty) {
          return Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search_off_rounded, size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  _catalogSearchQuery.isNotEmpty
                      ? 'No investigations found matching "$_catalogSearchQuery"'
                      : 'No items in this category',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Try searching with a different keyword or reset filters',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    _catalogSearchController.clear();
                    setState(() {
                      _catalogSearchQuery = '';
                      _catalogCategoryFilter = 'All';
                      _selectedCategory = null;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reset All Filters', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          );
        }

        final test = filtered[index - 1];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getServiceBadgeColor(test.iconType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getServiceIcon(test.iconType), color: _getServiceBadgeColor(test.iconType), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            test.title,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF0F172A)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getServiceBadgeColor(test.iconType).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            test.categoryName,
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: _getServiceBadgeColor(test.iconType)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      test.description,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Price & Badges Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '₹${test.price.toInt()}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                          ),
                        ),
                        if (test.originalPrice != null && test.originalPrice! > test.price) ...[
                          const SizedBox(width: 6),
                          Text(
                            '₹${test.originalPrice!.toInt()}',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, decoration: TextDecoration.lineThrough),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${(((test.originalPrice! - test.price) / test.originalPrice!) * 100).toInt()}% OFF)',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFEA580C)),
                          ),
                        ],
                        const SizedBox(width: 10),
                        if (test.isHomeVisitAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                            child: const Text('Home Visit', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
                          ),
                        if (test.isInHouseAvailable) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(4)),
                            child: const Text('In-House', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF7E22CE))),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 19, color: AppColors.primary),
                    onPressed: () => _openAddTestDialog(test),
                    tooltip: 'Edit Item',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 19, color: AppColors.error),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Item?'),
                          content: Text('Remove ${test.title} from catalog?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () {
                                context.read<AdminProvider>().deleteDiagnosticTest(test.id);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: 'Delete Item',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCatalogFilterChip(String filterKey, String label) {
    final isSelected = _catalogCategoryFilter == filterKey;
    return InkWell(
      onTap: () {
        setState(() {
          _catalogCategoryFilter = filterKey;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // 5. PROMOTIONAL BANNERS TAB
  Widget _buildBannersTab(List<PromoBanner> banners) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: banners.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Home Banners & Offers (Top + Mid-page)',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Active promotional slides: ${banners.length} • Exact Ratio: 2:1',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openEditBannerDialog(
                        PromoBanner(
                          id: 'BANNER-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                          title: '',
                          subtitle: '',
                          badge: 'SPECIAL OFFER',
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 15, color: Colors.white),
                      label: const Text('New Banner', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              // Banner Dimensions & Ratio Info Card
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.aspect_ratio_rounded, color: Color(0xFF16A34A), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Accurate Banner Ratio: 2:1 (Width : Height)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '• 100% No-Crop Fit',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            '🌟 Canva Size: 1200 × 600 px  |  📱 Mobile Size: 1000 × 500 px  |  ⚡ HD: 800 × 400 px',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Canva me Custom Size daalein: 1200 x 600 px. Yeh size patient app me bilkul accurate bina cut hue fit hoga.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final banner = banners[index - 1];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.local_offer_rounded, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(4)),
                          child: Text(banner.badge, style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(banner.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(banner.subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      '${banner.placement == PromoBanner.placementMiddle ? 'Mid-page banner' : 'Top carousel'}'
                      '${banner.isActive ? '' : ' • HIDDEN'}'
                      ' • Opens: ${banner.linkUrl.isNotEmpty ? banner.linkUrl : banner.categoryTarget}',
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                    onPressed: () => _openEditBannerDialog(banner),
                    tooltip: 'Edit Banner',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    onPressed: () => context.read<AdminProvider>().deleteBanner(banner.id),
                    tooltip: 'Delete Banner',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 6. PATIENT USERS DIRECTORY TAB
  Widget _buildUsersTab(List<UserProfile> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Registered Patient Users Directory', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    Text('Total registered patients: ${users.length}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _openPrescriptionViewerDialog(),
                      icon: const Icon(Icons.document_scanner_rounded, size: 14, color: Colors.white),
                      label: const Text('Prescriptions', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _openSendReminderDialog(),
                      icon: const Icon(Icons.campaign_rounded, size: 14, color: Colors.white),
                      label: const Text('Broadcast Alert', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final user = users[index - 1];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: user.isBlocked ? AppColors.error : AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'P',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('${user.name} (${user.age}y, ${user.sex})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                        if (user.isBlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(4)),
                            child: const Text('RESTRICTED', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.error)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Email: ${user.email}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    Text('Phone: ${user.mobile}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    Text('Address: ${user.address}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.description_outlined, size: 18, color: Color(0xFF7C3AED)),
                    tooltip: 'View & Print Doctor Prescriptions',
                    onPressed: () => _openPrescriptionViewerDialog(targetUserId: user.uid, targetPatientName: user.name),
                  ),
                  IconButton(
                    icon: const Icon(Icons.alarm_add_rounded, size: 18, color: AppColors.accent),
                    tooltip: 'Send Test Due Reminder',
                    onPressed: () => _openSendReminderDialog(patientId: user.uid, patientName: user.name),
                  ),
                  IconButton(
                    icon: Icon(
                      user.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                      size: 18,
                      color: user.isBlocked ? AppColors.success : AppColors.error,
                    ),
                    tooltip: user.isBlocked ? 'Unblock Patient' : 'Restrict Patient Account',
                    onPressed: () {
                      context.read<AdminProvider>().toggleBlockUser(user.uid, !user.isBlocked);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
