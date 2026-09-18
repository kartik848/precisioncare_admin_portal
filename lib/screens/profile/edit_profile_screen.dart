import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../services/imgbb_service.dart';
import '../../widgets/app_image_view.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _addressController;
  late TextEditingController _mobileController;
  late TextEditingController _dobController;
  late String _selectedSex;
  DateTime? _selectedDob;
  String? _profileImageUrl;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _ageController = TextEditingController(text: widget.profile.age.toString());
    _addressController = TextEditingController(text: widget.profile.address);
    _mobileController = TextEditingController(text: widget.profile.mobile);
    _selectedSex = widget.profile.sex;
    _selectedDob = widget.profile.dob;
    _profileImageUrl = widget.profile.profileImageUrl;
    _dobController = TextEditingController(
      text: widget.profile.dob != null ? DateFormat('dd/MM/yyyy').format(widget.profile.dob!) : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() => _isUploadingPhoto = true);
    final url = await ImgBBService.pickAndUploadImage(
      context,
      allowCamera: true,
      imageName: 'patient_profile_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;
    setState(() {
      _isUploadingPhoto = false;
      if (url != null) _profileImageUrl = url;
    });

    if (url != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
        final calculatedAge = now.year - picked.year;
        _ageController.text = calculatedAge.toString();
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final age = int.tryParse(_ageController.text.trim()) ?? widget.profile.age;
    final updated = widget.profile.copyWith(
      name: _nameController.text.trim(),
      age: age,
      sex: _selectedSex,
      dob: _selectedDob,
      address: _addressController.text.trim(),
      mobile: _mobileController.text.trim(),
      profileImageUrl: _profileImageUrl,
    );

    final success = await context.read<AuthProvider>().updateProfile(updated);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile details updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Patient Profile'),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Photo Upload Preview with Camera / Gallery trigger
              Center(
                child: GestureDetector(
                  onTap: _isUploadingPhoto ? null : _pickPhoto,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage: getAppImageProvider(_profileImageUrl),
                            child: _isUploadingPhoto
                                ? const CircularProgressIndicator(color: AppColors.primary)
                                : _profileImageUrl == null
                                    ? Text(
                                        widget.profile.name.isNotEmpty ? widget.profile.name[0].toUpperCase() : 'P',
                                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary),
                                      )
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
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Change Photo (Camera / Gallery)', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
                          SizedBox(width: 4),
                          Icon(Icons.touch_app_rounded, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _nameController,
                label: 'Full Name *',
                prefixIcon: Icons.person_outline,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _ageController,
                      label: 'Age *',
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter age' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sex *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                              items: ['Male', 'Female', 'Other'].map((sex) {
                                return DropdownMenuItem(value: sex, child: Text(sex));
                              }).toList(),
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
              const SizedBox(height: 14),

              CustomTextField(
                controller: _dobController,
                label: 'Date of Birth (DOB)',
                readOnly: true,
                onTap: _pickDob,
                prefixIcon: Icons.cake_outlined,
                suffixIcon: const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _mobileController,
                label: 'Mobile Number *',
                prefixIcon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter mobile' : null,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _addressController,
                label: 'Home Sample Collection Address *',
                prefixIcon: Icons.home_outlined,
                maxLines: 2,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: 'Save Updated Profile',
                isLoading: authProvider.isLoading,
                onPressed: _saveProfile,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
