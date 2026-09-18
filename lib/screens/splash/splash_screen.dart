import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/motion_logo_widget.dart';
import '../auth/login_screen.dart';
import '../home/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isDisposed = false;
  Timer? _authPollTimer;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _checkSessionAndNavigate();
  }

  void _checkSessionAndNavigate() {
    final authProvider = context.read<AuthProvider>();

    // If AuthProvider is already done loading
    if (!authProvider.isLoading) {
      _scheduleNavigation();
      return;
    }

    // Otherwise poll until done or max 2000ms
    int pollCount = 0;
    _authPollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      pollCount++;
      if (!context.read<AuthProvider>().isLoading || pollCount > 40) {
        timer.cancel();
        _scheduleNavigation();
      }
    });
  }

  void _scheduleNavigation() {
    if (_isDisposed) return;
    _navTimer = Timer(const Duration(milliseconds: 1400), () {
      if (_isDisposed || !mounted) return;
      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = authProvider.isAuthenticated;
      final user = authProvider.user;

      if (isAuthenticated && user != null) {
        context.read<BookingProvider>().fetchBookings(user.uid);
        context.read<ReportProvider>().fetchReports(user.uid);
        context.read<NotificationProvider>().fetchNotifications(user.uid);
      }

      final target = isAuthenticated
          ? const MainNavigationScreen()
          : const LoginScreen();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: target,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authPollTimer?.cancel();
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background subtle ambient gradients
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.05),
              ),
            ),
          ),

          // Center Animated Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Motion Logo
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: const MotionLogo(
                      size: 88,
                      showRipples: true,
                      showShimmer: true,
                      showFloating: true,
                      showHeartbeat: true,
                      badgeText: 'NABL',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Animated Text
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'PrecisionCare',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'DIAGNOSTIC CENTRE & PATHOLOGY LAB',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, color: AppColors.primary, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'NABL Standard • 60-Min Home Collection',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Loading & Footer
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Column(
                children: [
                  SizedBox(
                    width: 120,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _controller.value,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          borderRadius: BorderRadius.circular(10),
                          minHeight: 3,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Precision Diagnostics at Your Doorstep',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
