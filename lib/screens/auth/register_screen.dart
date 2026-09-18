import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/imgbb_service.dart';
import '../../widgets/app_image_view.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../home/main_navigation_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();

  String _selectedSex = 'Male';
  DateTime? _selectedDob;
  String? _uploadedPhotoUrl;
  bool _isUploadingPhoto = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    setState(() => _isUploadingPhoto = true);
    final url = await ImgBBService.pickAndUploadImage(
      context,
      allowCamera: true,
      imageName: 'patient_profile_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;
    setState(() {
      _isUploadingPhoto = false;
      if (url != null) _uploadedPhotoUrl = url;
    });

    if (url != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient photo uploaded successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
        // Auto calculate age
        final calculatedAge = now.year - picked.year - ((now.month > picked.month || (now.month == picked.month && now.day >= picked.day)) ? 0 : 1);
        _ageController.text = calculatedAge.toString();
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final rawAge = int.tryParse(_ageController.text.trim()) ?? 25;
    final age = rawAge > 0 ? rawAge : 25;

    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      age: age,
      sex: _selectedSex,
      dob: _selectedDob,
      address: _addressController.text.trim(),
      mobile: _mobileController.text.trim(),
      profileImageUrl: _uploadedPhotoUrl,
    );

    if (success && mounted) {
      final user = authProvider.user;
      if (user != null) {
        context.read<BookingProvider>().fetchBookings(user.uid);
        context.read<ReportProvider>().fetchReports(user.uid);
        context.read<NotificationProvider>().fetchNotifications(user.uid);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient ID Created Successfully! Welcome to PrecisionCare.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Patient Profile'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Official Brand Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/precisioncare_logo.jpeg',
                        height: 75,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.badge_outlined, color: AppColors.primary, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.registerTitle,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Your information ensures accurate medical records & home visit reports',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Patient Profile Photo Picker (Camera / Gallery)
                Center(
                  child: GestureDetector(
                    onTap: _isUploadingPhoto ? null : _pickProfilePhoto,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: getAppImageProvider(_uploadedPhotoUrl),
                              child: _isUploadingPhoto
                                  ? const CircularProgressIndicator(color: AppColors.primary)
                                  : _uploadedPhotoUrl == null
                                      ? const Icon(Icons.person_rounded, size: 46, color: AppColors.primary)
                                      : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _uploadedPhotoUrl != null ? 'Change Photo (Camera / Gallery)' : 'Tap to Add Photo (Camera / Gallery)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.touch_app_rounded, size: 14, color: AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 1. Full Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name *',
                  hint: 'e.g. Ramesh Chandra',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: 16),

                // 2. Age and Sex Row
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: CustomTextField(
                        controller: _ageController,
                        label: 'Age (Years) *',
                        hint: 'e.g. 35',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.calendar_today_outlined,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter age';
                          if (int.tryParse(val) == null || int.parse(val) <= 0) return 'Invalid age';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sex *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSex,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                                items: const [
                                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedSex = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Date of Birth (DOB)
                CustomTextField(
                  controller: _dobController,
                  label: 'Date of Birth (DOB)',
                  hint: 'Select your birth date',
                  prefixIcon: Icons.cake_outlined,
                  readOnly: true,
                  onTap: _pickDob,
                  suffixIcon: const Icon(Icons.event, color: AppColors.primary),
                ),
                const SizedBox(height: 16),

                // 4. Mobile Number
                CustomTextField(
                  controller: _mobileController,
                  label: 'Mobile Number *',
                  hint: '10-digit mobile number for SMS alerts',
                  prefixIcon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter mobile number';
                    if (val.trim().length < 10) return 'Enter valid 10-digit mobile';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 5. Complete Address (Essential for Home Sample Collection / Home Visits)
                CustomTextField(
                  controller: _addressController,
                  label: 'Complete Home Address *',
                  hint: 'House/Flat No, Landmark, Sector, City, Pin Code (Used for Home Visit)',
                  prefixIcon: Icons.home_outlined,
                  maxLines: 2,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter complete home address' : null,
                ),
                const SizedBox(height: 16),

                // 6. Email Address
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address *',
                  hint: 'For sending PDF reports & booking receipts',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter email';
                    if (!val.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 7. Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'Account Password *',
                  hint: 'At least 6 characters',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter password';
                    if (val.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 8. Confirm Password
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password *',
                  hint: 'Re-enter password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Re-enter password';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: 'Create Patient ID & Proceed',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleRegister,
                  icon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
