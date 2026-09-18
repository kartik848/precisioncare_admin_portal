import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/contact_helper.dart';
import '../../providers/auth_provider.dart';
import '../../services/imgbb_service.dart';
import '../../widgets/app_image_view.dart';
import '../auth/login_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../admin/admin_login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Health Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
              );
            },
          ),
        ],
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_circle_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('No Patient Profile Logged In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text('Sign In to Account'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Patient ID Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'PRECISIONCARE PATIENT ID',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'PID-${user.uid.substring(0, user.uid.length > 6 ? 6 : user.uid.length).toUpperCase()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        if (user.isBlocked) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.block_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Account Temporarily Restricted by Admin',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final auth = context.read<AuthProvider>();
                                final messenger = ScaffoldMessenger.of(context);
                                final url = await ImgBBService.pickAndUploadImage(
                                  context,
                                  allowCamera: true,
                                  imageName: 'patient_${user.uid}',
                                );
                                if (url != null) {
                                  final updated = user.copyWith(profileImageUrl: url);
                                  await auth.updateProfile(updated);
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Profile photo updated!'), backgroundColor: AppColors.success),
                                  );
                                }
                              },
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.white,
                                    backgroundImage: getAppImageProvider(user.profileImageUrl),
                                    child: user.profileImageUrl == null
                                        ? Text(
                                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'P',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3.5),
                                      decoration: const BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${user.age} Years • ${user.sex}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Profile Details Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Personal Health Info',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EditProfileScreen(profile: user),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit, size: 15),
                              label: const Text('Edit', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const Divider(height: 16, color: AppColors.divider),
                        _buildInfoTile(Icons.phone_outlined, 'Mobile Number', user.mobile),
                        const Divider(height: 16, color: AppColors.divider),
                        _buildInfoTile(Icons.email_outlined, 'Email Address', user.email),
                        const Divider(height: 16, color: AppColors.divider),
                        _buildInfoTile(
                          Icons.cake_outlined,
                          'Date of Birth (DOB)',
                          user.dob != null ? DateFormat('dd MMMM yyyy').format(user.dob!) : 'Not Specified',
                        ),
                        const Divider(height: 16, color: AppColors.divider),
                        _buildInfoTile(Icons.home_outlined, 'Home Visit Address', user.address),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Diagnostics Centre Support & Helpline
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PrecisionCare Diagnostic Centres (Pune)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSupportRow(
                          Icons.business_rounded,
                          'Branch 1 (Kondhwa / Lullanagar)',
                          AppStrings.branch1Address,
                        ),
                        const SizedBox(height: 10),
                        _buildSupportRow(
                          Icons.local_hospital_rounded,
                          'Branch 2 (Parmar Pavan / Fakhri Hills)',
                          AppStrings.branch2Address,
                        ),
                        const SizedBox(height: 10),
                        _buildSupportRow(
                          Icons.phone_in_talk_rounded,
                          '24/7 Diagnostics Helpline',
                          AppStrings.helplineNumber,
                        ),
                        const SizedBox(height: 10),
                        _buildSupportRow(
                          Icons.verified_rounded,
                          'Accreditations',
                          AppStrings.labAccreditation,
                        ),
                        const SizedBox(height: 14),

                        // Action Buttons: Direct Call & WhatsApp
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => ContactHelper.callHelpline(context),
                                icon: const Icon(Icons.call_rounded, size: 15, color: Colors.white),
                                label: const Text('Call Helpline', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => ContactHelper.openWhatsApp(context),
                                icon: const Icon(Icons.chat_bubble_rounded, size: 15, color: Colors.white),
                                label: const Text('WhatsApp Chat', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Admin & Staff Operations Portal Access
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.accent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin & Staff Portal',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Manage categories, catalog, dispatches & staff',
                                  style: TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 13),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sign Out Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      await authProvider.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                    label: const Text(
                      'Sign Out of Account',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.errorLight, width: 1.5),
                      backgroundColor: AppColors.errorLight.withOpacity(0.3),
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Text(
                desc,
                style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
