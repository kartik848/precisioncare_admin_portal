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

  Future<void> _handleAdminLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Verify Admin Credentials
    if (email == 'admin@gmail.com' && password == '1234') {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      }
      return;
    }

    // Try Firebase auth if configured
    try {
      final success = await context.read<AuthProvider>().signIn(
            email: email,
            password: password,
          );
      if (success && mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid email or password. Please try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid email or password. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Elegant dark slate admin theme
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
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
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
                    hint: 'Enter your admin email',
                    prefixIcon: Icons.admin_panel_settings_outlined,
                    keyboardType: TextInputType.emailAddress,
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
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        _emailController.text = 'admin@gmail.com';
                        _passwordController.text = '1234';
                      },
                      icon: const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.accent),
                      label: const Text(
                        'Auto-fill Admin (admin@gmail.com / 1234)',
                        style: TextStyle(fontSize: 11.5, color: AppColors.accent, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
