import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/diagnostic_category.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/catalog_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class AddCategoryDialog extends StatefulWidget {
  final DiagnosticCategory? categoryToEdit;

  const AddCategoryDialog({super.key, this.categoryToEdit});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _badgeController;

  String _iconType = 'xray';
  bool _isHomeVisitAvailable = true;
  bool _isInHouseAvailable = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _iconOptions = [
    {'type': 'xray', 'label': 'X-Ray / Radiology', 'icon': Icons.medical_information_rounded},
    {'type': 'blood', 'label': 'Blood / Pathology', 'icon': Icons.water_drop_rounded},
    {'type': 'ecg', 'label': 'ECG / Heart', 'icon': Icons.monitor_heart_rounded},
    {'type': 'usg', 'label': 'Ultrasound / Sonography', 'icon': Icons.waves_rounded},
    {'type': 'pft', 'label': 'PFT / Respiratory', 'icon': Icons.air_rounded},
    {'type': 'physio', 'label': 'Physiotherapy', 'icon': Icons.accessibility_new_rounded},
    {'type': 'package', 'label': 'Health Package', 'icon': Icons.health_and_safety_rounded},
    {'type': 'general', 'label': 'Clinical / General', 'icon': Icons.biotech_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.categoryToEdit?.name ?? '');
    _descController = TextEditingController(text: widget.categoryToEdit?.description ?? '');
    _badgeController = TextEditingController(text: widget.categoryToEdit?.badge ?? '');

    if (widget.categoryToEdit != null) {
      _iconType = widget.categoryToEdit!.iconType;
      _isHomeVisitAvailable = widget.categoryToEdit!.isHomeVisitAvailable;
      _isInHouseAvailable = widget.categoryToEdit!.isInHouseAvailable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final id = widget.categoryToEdit?.id ??
        'cat_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    final category = DiagnosticCategory(
      id: id,
      name: name,
      description: _descController.text.trim(),
      iconType: _iconType,
      badge: _badgeController.text.trim(),
      isHomeVisitAvailable: _isHomeVisitAvailable,
      isInHouseAvailable: _isInHouseAvailable,
      sortOrder: widget.categoryToEdit?.sortOrder ?? 10,
    );

    await context.read<AdminProvider>().addCategory(category);
    if (mounted) {
      context.read<CatalogProvider>().refreshCatalog();
      Navigator.pop(context, category);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$name" created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.categoryToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Form(
          key: _formKey,
          child: Column(
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
                          color: const Color(0xFFFFF0F3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: const Icon(Icons.category_rounded, color: Color(0xFFE11D48), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEditing ? 'Edit Category' : 'Create New Category',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.divider, height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Name
                      CustomTextField(
                        controller: _nameController,
                        label: 'Category Name *',
                        hint: 'e.g. Digital X-Ray, MRI Scan, Blood Tests...',
                        prefixIcon: Icons.label_outline_rounded,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Category name is required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Description
                      CustomTextField(
                        controller: _descController,
                        label: 'Description / Tagline',
                        hint: 'Brief summary of services in this category',
                        prefixIcon: Icons.description_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),

                      // Badge Text
                      CustomTextField(
                        controller: _badgeController,
                        label: 'Badge / Highlight Tag (Optional)',
                        hint: 'e.g. Portable DR, 60 Min, Fast Report, New',
                        prefixIcon: Icons.local_offer_outlined,
                      ),
                      const SizedBox(height: 16),

                      // Icon Type Selector
                      const Text(
                        'Category Icon & Theme *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _iconOptions.map((opt) {
                          final isSel = _iconType == opt['type'];
                          final icon = opt['icon'] as IconData;
                          final label = opt['label'] as String;
                          return InkWell(
                            onTap: () => setState(() => _iconType = opt['type'] as String),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFFFFF0F3) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel ? const Color(0xFFE11D48) : AppColors.border,
                                  width: isSel ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 16, color: isSel ? const Color(0xFFE11D48) : AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                      color: isSel ? const Color(0xFFE11D48) : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Availability checkboxes
                      const Text(
                        'Service Availability',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      CheckboxListTile(
                        value: _isHomeVisitAvailable,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Home Visit Doorstep Available', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Phlebotomist / Portable DR can visit patient home', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _isHomeVisitAvailable = val ?? true),
                      ),
                      CheckboxListTile(
                        value: _isInHouseAvailable,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('In-House Centre Setup Available', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Patients can walk in to Kondhwa centre', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _isInHouseAvailable = val ?? true),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              CustomButton(
                text: isEditing ? 'Update Category' : 'Save Category',
                isLoading: _isSaving,
                onPressed: _handleSave,
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
