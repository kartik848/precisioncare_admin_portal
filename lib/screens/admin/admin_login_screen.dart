import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/motion_logo_widget.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Admin portal is standalone (web); there is no patient app to return to.
  void _navigateToPatientApp() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  Future<void> _handleAdminLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email != 'admin@gmail.com' || password != '1234') {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid credentials. Enter admin@gmail.com and password 1234.';
      });
      return;
    }

    try {
      final success = await context.read<AuthProvider>().signIn(
            email: email,
            password: password,
          );

      if (!mounted) return;

      if (success && context.read<AuthProvider>().isAdmin) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid credentials. Enter admin@gmail.com and password 1234.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sign in failed: ${e.toString().replaceAll('Exception:', '').trim()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAlreadyAdmin = authProvider.isAuthenticated && authProvider.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Elegant dark slate admin theme
      appBar: !kIsWeb
          ? AppBar(
              backgroundColor: const Color(0xFF0F172A),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: _navigateToPatientApp,
              ),
              title: const Text(
                'Back to Patient App',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
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
            child: isAlreadyAdmin
                ? _buildActiveSessionView(authProvider)
                : _buildLoginForm(),
          ),
        ),
      ),
    );
  }

  // Shown when an admin session is already active
  Widget _buildActiveSessionView(AuthProvider auth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: MotionLogo(
            size: 68,
            showRipples: true,
            showShimmer: true,
            showFloating: true,
            showHeartbeat: true,
            badgeText: 'ACTIVE',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Active Admin Session',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.secondary,
                child: Icon(Icons.admin_panel_settings_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.user?.name.isNotEmpty == true ? auth.user!.name : 'Admin Officer',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      auth.user?.email ?? 'admin@precisioncare.com',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Open Admin Dashboard',
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              (route) => false,
            );
          },
          icon: Icons.dashboard_rounded,
          backgroundColor: AppColors.secondary,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            await auth.signOut();
            setState(() {});
          },
          icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
          label: const Text(
            'Sign Out Admin',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFFECDD3)),
            backgroundColor: const Color(0xFFFFF1F2),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (!kIsWeb) ...[
          const SizedBox(height: 14),
          Center(
            child: TextButton.icon(
              onPressed: _navigateToPatientApp,
              icon: const Icon(Icons.arrow_back_rounded, size: 15, color: AppColors.textSecondary),
              label: const Text(
                'Return to Patient App',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Standard Admin Login Form
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Animated Motion Logo
          const Center(
            child: MotionLogo(
              size: 64,
              showRipples: true,
              showShimmer: true,
              showFloating: true,
              showHeartbeat: true,
              badgeText: 'ADMIN',
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'PrecisionCare Admin Portal',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Operations, Diagnostic Queues & Lab Reports Control',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Email
          CustomTextField(
            controller: _emailController,
            label: 'Admin Email ID',
            hint: 'Enter admin email',
            prefixIcon: Icons.admin_panel_settings_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter admin email' : null,
          ),
          const SizedBox(height: 16),

          // Password
          CustomTextField(
            controller: _passwordController,
            label: 'Admin Password',
            hint: 'Enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleAdminLogin(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Enter admin password' : null,
          ),
          const SizedBox(height: 24),

          // Login CTA
          CustomButton(
            text: 'Sign In to Admin Dashboard',
            isLoading: _isLoading,
            onPressed: _handleAdminLogin,
            icon: Icons.login_rounded,
            backgroundColor: AppColors.secondary,
          ),
          const SizedBox(height: 14),

          Center(
            child: TextButton.icon(
              onPressed: () {
                _emailController.text = 'admin@gmail.com';
                _passwordController.text = '1234';
                setState(() => _errorMessage = null);
              },
              icon: const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.accent),
              label: const Text(
                'Auto-fill Admin (admin@gmail.com / 1234)',
                style: TextStyle(fontSize: 11.5, color: AppColors.accent, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          if (!kIsWeb) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _navigateToPatientApp,
                icon: const Icon(Icons.arrow_back_rounded, size: 15, color: AppColors.textSecondary),
                label: const Text(
                  'Return to Patient App',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
