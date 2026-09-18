import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/motion_logo_widget.dart';
import '../home/main_navigation_screen.dart';
import 'register_screen.dart';

class PrecisionCareLoginScreen extends StatefulWidget {
  const PrecisionCareLoginScreen({super.key});

  @override
  State<PrecisionCareLoginScreen> createState() => _PrecisionCareLoginScreenState();
}

class _PrecisionCareLoginScreenState extends State<PrecisionCareLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  late final AnimationController _entranceController;
  late final Animation<double> _headerFadeAnimation;
  late final Animation<Offset> _sheetSlideAnimation;
  late final Animation<double> _sheetFadeAnimation;

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Entrance animation: top banner fades in, bottom card slides up smoothly
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _headerFadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _sheetSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _sheetFadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    // Floating breathing animation for 3D team characters
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0.0, end: -7.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _skipToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      email: email,
      password: password,
    );

    if (success && mounted) {
      final user = authProvider.user;
      if (user != null) {
        context.read<BookingProvider>().fetchBookings(user.uid);
        context.read<ReportProvider>().fetchReports(user.uid);
        context.read<NotificationProvider>().fetchNotifications(user.uid);
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const SingleChildScrollView(
          child: Text(
            'Welcome to PrecisionCare Diagnostic Centre.\n\n'
            '1. Patient reports and bookings are confidential, HIPAA compliant, and encrypted.\n'
            '2. Home visit sample collection is performed by certified phlebotomists.\n'
            '3. Reports are verified and digitally signed by clinical pathologists and radiologists.\n'
            '4. In emergency cases, please contact our 24x7 emergency helpline.',
            style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const SingleChildScrollView(
          child: Text(
            'PrecisionCare Diagnostic Centre is committed to protecting patient health data privacy.\n\n'
            '• HIPAA and NABL compliant diagnostic records management.\n'
            '• Medical investigation data is only shared with the registered patient and verified doctors.\n'
            '• No patient information is sold or distributed to third parties.',
            style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final screenHeight = MediaQuery.of(context).size.height;
    // Responsive top banner height
    final bannerHeight = (screenHeight * 0.44).clamp(310.0, 420.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // =============================================================
              // 1. TOP BRAND BANNER (CUSTOM 3D HEALTHCARE TEAM ARTWORK)
              // =============================================================
              Container(
                height: bannerHeight,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFF55E4D),
                      Color(0xFFE84C3D),
                      Color(0xFFDE4335),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Top Row: Skip > Button aligned to top right
                      Padding(
                        padding: const EdgeInsets.only(top: 8, right: 18),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: FadeTransition(
                            opacity: _headerFadeAnimation,
                            child: InkWell(
                              onTap: _skipToHome,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Skip',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 11,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Centered Brand Logo & Tagline Header
                      FadeTransition(
                        opacity: _headerFadeAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Animated Motion Logo
                                const MotionLogo(
                                  size: 38,
                                  showRipples: false,
                                  showShimmer: true,
                                  showFloating: true,
                                  showHeartbeat: true,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'PrecisionCare',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text(
                                    'LAB',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Bringing care to health',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3D Team Graphic with Breathing Float Animation
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _floatAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatAnimation.value),
                              child: child,
                            );
                          },
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Image.asset(
                              'assets/images/precisioncare_team_3d.jpg',
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                              errorBuilder: (_, __, ___) => _buildFallback3DCharacters(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // =============================================================
              // 2. BOTTOM CURVED CARD (PREVIOUS LOGIN & SIGN UP FORM)
              // =============================================================
              Transform.translate(
                offset: const Offset(0, -18),
                child: SlideTransition(
                  position: _sheetSlideAnimation,
                  child: FadeTransition(
                    opacity: _sheetFadeAnimation,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // "Log in or sign up" divider with lines (just like inspiration photo)
                            Row(
                              children: [
                                Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'Log in or sign up',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                                Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Welcome Header & Secure Lock Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Patient Portal Sign In',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Access your test reports & bookings',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F3),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFFECDD3)),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 19,
                                    color: Color(0xFFE11D48),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // 1. Registered Email Field (Original Form)
                            CustomTextField(
                              controller: _emailController,
                              label: 'Registered Email Address',
                              hint: 'e.g. rahul.sharma@gmail.com',
                              prefixIcon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // 2. Account Password Field (Original Form)
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Account Password',
                              hint: 'Enter your password',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 4) {
                                  return 'Password must be at least 4 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // 3. Sign In Button (Original Form)
                            CustomButton(
                              text: 'Sign In to Health Portal',
                              isLoading: authProvider.isLoading,
                              onPressed: _handleLogin,
                              icon: Icons.arrow_forward_rounded,
                              backgroundColor: const Color(0xFFE11D48),
                            ),
                            const SizedBox(height: 18),

                            // 4. Register Link (Original Form)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "New to PrecisionCare? ",
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                    );
                                  },
                                  child: const Text(
                                    "Create Patient Account",
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Security Guarantee Footer (Original Form)
                            const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shield_outlined, size: 14, color: Color(0xFF94A3B8)),
                                  SizedBox(width: 5),
                                  Text(
                                    '256-Bit SSL Encrypted & HIPAA Compliant Health Portal',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 7. Terms & Conditions and Privacy Policy (From inspiration image)
                            Column(
                              children: [
                                const Text(
                                  'By Signing in you agree to our',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: _showTermsDialog,
                                      child: const Text(
                                        'Terms & Conditions',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF334155),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    const Text(' and ', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                    GestureDetector(
                                      onTap: _showPrivacyDialog,
                                      child: const Text(
                                        'Privacy Policy',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF334155),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback3DCharacters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _build3DAvatar('assets/images/3d/service_blood_test.jpg', 60),
          _build3DAvatar('assets/images/3d/doctor_mascot.jpg', 80),
          _build3DAvatar('assets/images/3d/female_doctor.jpg', 64),
        ],
      ),
    );
  }

  Widget _build3DAvatar(String assetPath, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(assetPath, fit: BoxFit.cover),
      ),
    );
  }
}
