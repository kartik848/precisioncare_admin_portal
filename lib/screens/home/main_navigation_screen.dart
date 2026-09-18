import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/report_provider.dart';
import 'home_screen.dart';
import '../catalog/catalog_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../reports/reports_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notification_center_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  String? _lastShownNotifId;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final user = auth.user;
      final userId = user?.uid ?? 'guest_user';
      context.read<BookingProvider>().fetchBookings(userId);
      context.read<ReportProvider>().fetchReports(userId);
      context.read<NotificationProvider>().fetchNotifications(
        userId,
        userMobile: user?.mobile,
        userEmail: user?.email,
      );
      context.read<CatalogProvider>().refreshCatalog();
    });
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _checkAndShowInAppBanner(AppNotification notif) {
    if (_lastShownNotifId == notif.id) return;
    _lastShownNotifId = notif.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 20),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notif.message,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'View',
            textColor: AppColors.accent,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationCenterScreen(),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final unreadCount = notifProvider.unreadCount;
    final latestNotif = notifProvider.latestIncomingNotification;

    if (latestNotif != null) {
      _checkAndShowInAppBanner(latestNotif);
    }

    final screens = [
      HomeScreen(onNavigateTab: _onTabTapped),
      const CatalogScreen(),
      const MyBookingsScreen(),
      const ReportsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textMuted,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            elevation: 0,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.medical_services_outlined),
                activeIcon: Icon(Icons.medical_services_rounded),
                label: 'Tests',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_month_rounded),
                label: 'Bookings',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.description_outlined),
                activeIcon: Icon(Icons.description_rounded),
                label: 'Reports',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  backgroundColor: AppColors.accent,
                  child: const Icon(Icons.person_outline_rounded),
                ),
                activeIcon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  backgroundColor: AppColors.accent,
                  child: const Icon(Icons.person_rounded),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
