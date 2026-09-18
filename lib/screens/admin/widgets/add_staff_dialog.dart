import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/staff_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class AddStaffDialog extends StatefulWidget {
  final StaffMember? staffToEdit;

  const AddStaffDialog({super.key, this.staffToEdit});

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _specController;
  String _selectedRole = 'Senior Phlebotomist';

  final List<String> _roles = [
    'Senior Phlebotomist',
    'Phlebotomist (Blood Sample)',
    'Certified Radiographer (X-Ray)',
    'Cardiac & ECG Technician',
    'Consultant Physiotherapist',
    'Laboratory Technologist',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staffToEdit?.name ?? '');
    _phoneController = TextEditingController(text: widget.staffToEdit?.phone ?? '+91 ');
    _specController = TextEditingController(text: widget.staffToEdit?.specialization ?? 'Home Sample Collection & Diagnostics');
    if (widget.staffToEdit != null && _roles.contains(widget.staffToEdit!.role)) {
      _selectedRole = widget.staffToEdit!.role;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.staffToEdit?.id ?? 'STAFF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final staff = StaffMember(
      id: id,
      name: _nameController.text.trim(),
      role: _selectedRole,
      phone: _phoneController.text.trim(),
      specialization: _specController.text.trim(),
      isActive: widget.staffToEdit?.isActive ?? true,
      completedVisits: widget.staffToEdit?.completedVisits ?? 0,
    );

    await context.read<AdminProvider>().addOrUpdateStaff(staff);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${staff.name} saved to Medical Staff Directory!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.staffToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Edit Staff Member' : 'Add Medical Staff',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 10),

                // Role Dropdown
                const Text('Staff Role / Designation *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _roles.contains(_selectedRole) ? _selectedRole : _roles.first,
                      isExpanded: true,
                      items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name *',
                  hint: 'e.g. Vikram Singh / Dr. Priya Nair',
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter staff name' : null,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _phoneController,
                  label: 'Mobile Number *',
                  hint: '+91 98765 00123',
                  prefixIcon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter mobile number' : null,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _specController,
                  label: 'Specialization / Skills',
                  hint: 'e.g. Fasting venipuncture, DR X-Ray, IFT Laser',
                  prefixIcon: Icons.medical_services_outlined,
                ),
                const SizedBox(height: 20),

                CustomButton(
                  text: isEditing ? 'Update Staff Member' : 'Save to Directory',
                  onPressed: _handleSave,
                  icon: Icons.check_circle_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
