import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/diagnostic_category.dart';
import '../../../models/diagnostic_service.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/catalog_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import 'add_category_dialog.dart';

class AddTestDialog extends StatefulWidget {
  final DiagnosticService? testToEdit;
  final String? initialCategoryId;
  final String? initialCategoryName;

  const AddTestDialog({
    super.key,
    this.testToEdit,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<AddTestDialog> createState() => _AddTestDialogState();
}

class _AddTestDialogState extends State<AddTestDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _categoryNameController;
  late TextEditingController _priceController;
  late TextEditingController _origPriceController;
  late TextEditingController _descController;
  late TextEditingController _prepController;
  late TextEditingController _sampleTypeController;
  late TextEditingController _tatController;
  late TextEditingController _badgeController;

  String? _selectedCategoryId;
  String _iconType = 'blood';
  ServiceCategory _category = ServiceCategory.homeVisit;
  bool _isHomeVisitAvailable = true;
  bool _isInHouseAvailable = true;

  final List<String> _iconOptions = ['blood', 'xray', 'ecg', 'physio', 'pft', 'usg', 'heart', 'body'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.testToEdit?.title ?? '');
    _categoryNameController = TextEditingController(text: widget.testToEdit?.categoryName ?? 'Digital X-Ray');
    _priceController = TextEditingController(text: widget.testToEdit?.price.toInt().toString() ?? '499');
    _origPriceController = TextEditingController(text: widget.testToEdit?.originalPrice?.toInt().toString() ?? '899');
    _descController = TextEditingController(text: widget.testToEdit?.description ?? 'Comprehensive diagnostic investigation with verified laboratory reporting.');
    _prepController = TextEditingController(text: widget.testToEdit?.preparation ?? '10-12 hours fasting required. Water intake allowed.');
    _sampleTypeController = TextEditingController(text: widget.testToEdit?.sampleType ?? 'Blood (Serum)');
    _tatController = TextEditingController(text: widget.testToEdit?.turnaroundTime ?? 'Report within 6 Hours');
    _badgeController = TextEditingController(text: widget.testToEdit?.badge ?? 'Popular');

    if (widget.testToEdit != null) {
      _selectedCategoryId = widget.testToEdit!.categoryId;
      _iconType = widget.testToEdit!.iconType;
      _category = widget.testToEdit!.category;
      _isHomeVisitAvailable = widget.testToEdit!.isHomeVisitAvailable;
      _isInHouseAvailable = widget.testToEdit!.isInHouseAvailable;
    } else {
      if (widget.initialCategoryId != null) {
        _selectedCategoryId = widget.initialCategoryId;
      }
      if (widget.initialCategoryName != null) {
        _categoryNameController.text = widget.initialCategoryName!;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryNameController.dispose();
    _priceController.dispose();
    _origPriceController.dispose();
    _descController.dispose();
    _prepController.dispose();
    _sampleTypeController.dispose();
    _tatController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.testToEdit?.id ?? 'test_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final price = double.tryParse(_priceController.text.trim()) ?? 499.0;
    final origPrice = double.tryParse(_origPriceController.text.trim());

    final service = DiagnosticService(
      id: id,
      title: _titleController.text.trim(),
      categoryName: _categoryNameController.text.trim(),
      categoryId: _selectedCategoryId,
      category: _category,
      description: _descController.text.trim(),
      price: price,
      originalPrice: origPrice,
      preparation: _prepController.text.trim(),
      sampleType: _sampleTypeController.text.trim(),
      turnaroundTime: _tatController.text.trim(),
      iconType: _iconType,
      isHomeVisitAvailable: _isHomeVisitAvailable,
      isInHouseAvailable: _isInHouseAvailable,
      badge: _badgeController.text.trim().isNotEmpty ? _badgeController.text.trim() : null,
      includedTests: [
        '${_titleController.text.trim()} Primary Investigation',
        'Clinical Pathology Review & Digital Sign-off',
      ],
    );

    await context.read<AdminProvider>().addDiagnosticTest(service);
    if (mounted) {
      context.read<CatalogProvider>().refreshCatalog();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${service.title} saved under ${service.categoryName}!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.testToEdit != null;
    final adminCats = context.watch<AdminProvider>().categories;

    // Ensure _selectedCategoryId is valid and synchronized
    if (_selectedCategoryId == null && adminCats.isNotEmpty) {
      _selectedCategoryId = adminCats.first.id;
      _categoryNameController.text = adminCats.first.name;
      _iconType = adminCats.first.iconType;
    } else if (!isEditing && _selectedCategoryId != null && adminCats.isNotEmpty) {
      final matching = adminCats.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => adminCats.first,
      );
      if (_categoryNameController.text.isEmpty || _categoryNameController.text == 'Digital X-Ray') {
        _categoryNameController.text = matching.name;
      }
      _iconType = matching.iconType;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
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
                      const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? 'Edit Catalog Item' : 'Add to Catalog',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 6),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Package / Service Name
                      CustomTextField(
                        controller: _titleController,
                        label: 'Package / Investigation Name *',
                        hint: 'e.g. Digital Chest X-Ray PA View, Thyroid Profile...',
                        prefixIcon: Icons.medical_services_outlined,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 12),

                      // Category Selector with + Add New Category button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Select Category *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          InkWell(
                            onTap: () async {
                              final newCat = await showDialog<DiagnosticCategory>(
                                context: context,
                                builder: (_) => const AddCategoryDialog(),
                              );
                              if (newCat != null && mounted) {
                                setState(() {
                                  _selectedCategoryId = newCat.id;
                                  _categoryNameController.text = newCat.name;
                                  _iconType = newCat.iconType;
                                });
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                                  SizedBox(width: 2),
                                  Text(
                                    '+ Add New Category',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: adminCats.any((c) => c.id == _selectedCategoryId)
                                ? _selectedCategoryId
                                : (adminCats.isNotEmpty ? adminCats.first.id : null),
                            isExpanded: true,
                            items: adminCats.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat.id,
                                child: Row(
                                  children: [
                                    Icon(cat.iconData, size: 16, color: cat.color),
                                    const SizedBox(width: 8),
                                    Text(cat.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                    if (cat.badge.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: cat.color.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          cat.badge,
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: cat.color),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (catId) {
                              if (catId != null) {
                                final found = adminCats.firstWhere(
                                  (c) => c.id == catId,
                                  orElse: () => adminCats.first,
                                );
                                setState(() {
                                  _selectedCategoryId = found.id;
                                  _categoryNameController.text = found.name;
                                  _iconType = found.iconType;
                                  if (found.id == 'cat_physio') {
                                    _category = ServiceCategory.physiotherapy;
                                  } else if (found.id == 'cat_packages') {
                                    _category = ServiceCategory.healthPackage;
                                  } else if (found.isHomeVisitAvailable) {
                                    _category = ServiceCategory.homeVisit;
                                  } else {
                                    _category = ServiceCategory.inHouseDiagnostic;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Icon Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: CustomTextField(
                              controller: _categoryNameController,
                              label: 'Category Display Label *',
                              hint: 'e.g. Digital X-Ray',
                              prefixIcon: Icons.bookmark_outline_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('App Icon *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _iconOptions.contains(_iconType) ? _iconType : _iconOptions.first,
                                      isExpanded: true,
                                      items: _iconOptions.map((ic) => DropdownMenuItem(value: ic, child: Text(ic.toUpperCase(), style: const TextStyle(fontSize: 12)))).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _iconType = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Price Row
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _priceController,
                              label: 'Offer Price (₹) *',
                              hint: '499',
                              prefixIcon: Icons.currency_rupee_rounded,
                              keyboardType: TextInputType.number,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter price' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomTextField(
                              controller: _origPriceController,
                              label: 'MRP Price (₹)',
                              hint: '899',
                              prefixIcon: Icons.money_off_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Turnaround time & Badge
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _tatController,
                              label: 'TAT / Report Time',
                              hint: 'e.g. 6 Hours / Same Day',
                              prefixIcon: Icons.timer_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomTextField(
                              controller: _badgeController,
                              label: 'Promo Badge (Optional)',
                              hint: 'e.g. 50% OFF / Recommended',
                              prefixIcon: Icons.local_offer_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Description
                      CustomTextField(
                        controller: _descController,
                        label: 'Clinical Description',
                        maxLines: 2,
                        prefixIcon: Icons.description_outlined,
                      ),
                      const SizedBox(height: 12),

                      // Prep instructions
                      CustomTextField(
                        controller: _prepController,
                        label: 'Fasting / Preparation Guidelines',
                        hint: 'e.g. 10-12 hrs fasting required',
                        prefixIcon: Icons.info_outline,
                      ),
                      const SizedBox(height: 12),

                      // Availability Toggles
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Home Visit Available', style: TextStyle(fontSize: 12)),
                              value: _isHomeVisitAvailable,
                              onChanged: (v) => setState(() => _isHomeVisitAvailable = v ?? true),
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('In-House Centre Available', style: TextStyle(fontSize: 12)),
                              value: _isInHouseAvailable,
                              onChanged: (v) => setState(() => _isInHouseAvailable = v ?? true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              CustomButton(
                text: isEditing ? 'Update Details' : 'Publish to Patient App',
                onPressed: _handleSave,
                icon: Icons.cloud_upload_rounded,
                backgroundColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
