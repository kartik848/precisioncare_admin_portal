import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/search_matcher.dart';
import '../../../providers/catalog_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/diagnostic_service.dart';
import '../../../models/health_package.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/imgbb_service.dart';
import '../../../widgets/app_image_view.dart';

class EditPackageDialog extends StatefulWidget {
  final HealthPackage package;
  final bool isNew;

  const EditPackageDialog({super.key, required this.package, this.isNew = false});

  @override
  State<EditPackageDialog> createState() => _EditPackageDialogState();
}

class _EditPackageDialogState extends State<EditPackageDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _offer;
  late final TextEditingController _price;
  late final TextEditingController _search;
  late final TextEditingController _tag;
  late final TextEditingController _reportTime;
  late final TextEditingController _paramCount;
  bool _isFeatured = false;
  late Set<String> _selected;
  String? _posterUrl;
  bool _isActive = true;
  bool _uploading = false;
  bool _saving = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final p = widget.package;
    _name = TextEditingController(text: p.name)..addListener(() => setState(() {}));
    _offer = TextEditingController(text: p.offerText)..addListener(() => setState(() {}));
    _price = TextEditingController(text: p.price > 0 ? p.price.toStringAsFixed(0) : '')
      ..addListener(() => setState(() {}));
    _search = TextEditingController();
    _tag = TextEditingController(text: p.tag);
    _reportTime = TextEditingController(text: p.reportTime);
    _paramCount = TextEditingController(text: p.parameterCount?.toString() ?? '');
    _isFeatured = p.isFeatured;
    _selected = {...p.testIds};
    _posterUrl = p.posterUrl;
    _isActive = p.isActive;
  }

  @override
  void dispose() {
    _name.dispose();
    _offer.dispose();
    _price.dispose();
    _search.dispose();
    _tag.dispose();
    _reportTime.dispose();
    _paramCount.dispose();
    super.dispose();
  }

  double _mrp(List<DiagnosticService> catalog) =>
      catalog.where((s) => _selected.contains(s.id)).fold(0.0, (sum, s) => sum + s.price);

  Future<void> _pickPoster() async {
    setState(() => _uploading = true);
    final url = await ImgBBService.pickImageDirectFromFile(
      imageName: 'precisioncare_package_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (!mounted) return;
    setState(() {
      _uploading = false;
      if (url != null) _posterUrl = url;
    });
  }

  Future<void> _save(List<DiagnosticService> catalog) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one test for this package'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _saving = true);
    final mrp = _mrp(catalog);
    final price = double.tryParse(_price.text.trim()) ?? mrp;
    final updated = widget.package.copyWith(
      name: _name.text.trim(),
      offerText: _offer.text.trim(),
      posterUrl: _posterUrl,
      price: price,
      originalPrice: mrp > price ? mrp : null,
      testIds: _selected.toList(),
      isActive: _isActive,
      tag: _tag.text.trim(),
      reportTime: _reportTime.text.trim(),
      parameterCount: int.tryParse(_paramCount.text.trim()),
      clearParameterCount: true,
      isFeatured: _isFeatured,
    );
    await context.read<AdminProvider>().addOrUpdatePackage(updated);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Package "${updated.name}" saved'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<AdminProvider>().catalogServices;
    final visible = SearchMatcher.rank(catalog, _query, CatalogProvider.searchFieldsOf);
    final mrp = _mrp(catalog);
    final price = double.tryParse(_price.text.trim());
    final discount = (price != null && mrp > price && mrp > 0) ? (((mrp - price) / mrp) * 100).round() : 0;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                decoration: const BoxDecoration(gradient: AppColors.brandGradient),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.isNew ? 'Create Health Package' : 'Edit Health Package',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _label('Package photo (square works best on the patient home)'),
                    GestureDetector(
                      onTap: _uploading ? null : _pickPoster,
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.primaryLight,
                            border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                            image: _posterUrl != null
                                ? DecorationImage(image: getAppImageProvider(_posterUrl)!, fit: BoxFit.cover)
                                : null,
                          ),
                          child: _uploading
                              ? const Center(child: CircularProgressIndicator())
                              : _posterUrl == null
                                  ? const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 36),
                                        SizedBox(height: 6),
                                        Text('Tap to upload poster',
                                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                                      ],
                                    )
                                  : Align(
                                      alignment: Alignment.bottomRight,
                                      child: Container(
                                        margin: const EdgeInsets.all(8),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                            color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                                        child: const Text('Change',
                                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _field(_name, 'Package name', 'e.g. Full Body Master Checkup',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a package name' : null),
                    const SizedBox(height: 12),
                    _field(_offer, 'Offer text', 'e.g. Flat 40% OFF • Free home collection'),
                    const SizedBox(height: 12),
                    _field(_tag, 'Card tag (optional)', 'e.g. Smart Report / Most Frequently Booked'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field(_reportTime, 'Report time', 'e.g. 8 hrs')),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(_paramCount, 'Tests to advertise', 'e.g. 86',
                              keyboardType: TextInputType.number,
                              validator: (v) => (v == null || v.trim().isEmpty || int.tryParse(v.trim()) != null)
                                  ? null
                                  : 'Enter a number'),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('"Tests to advertise" shows as "Contains 86 tests". Blank = number of tests selected below.',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ),
                    const SizedBox(height: 18),

                    _label('Select tests included (${_selected.length} selected)'),
                    TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                      decoration: _decoration('Search tests…').copyWith(
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 230,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ListView.separated(
                          itemCount: visible.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                          itemBuilder: (_, i) {
                            final s = visible[i];
                            return CheckboxListTile(
                              dense: true,
                              value: _selected.contains(s.id),
                              activeColor: AppColors.primary,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (v) => setState(() => v == true ? _selected.add(s.id) : _selected.remove(s.id)),
                              title: Text(s.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              subtitle: Text('${s.categoryName} • ₹${s.price.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 11)),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    _label('Pricing'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total of selected tests (MRP)', style: TextStyle(fontSize: 12.5)),
                              Text('₹${mrp.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, decoration: TextDecoration.lineThrough)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _price,
                            keyboardType: TextInputType.number,
                            decoration: _decoration('Package offer price (₹)'),
                            validator: (v) => double.tryParse((v ?? '').trim()) == null ? 'Enter a valid price' : null,
                          ),
                          if (discount > 0) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Patients see $discount% OFF',
                                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 12.5)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      title: const Text('Visible to patients', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      title: const Text('Feature at top of home', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      subtitle: const Text('Shown in the hero row under the banners (best with 3 packages)',
                          style: TextStyle(fontSize: 11.5)),
                      value: _isFeatured,
                      onChanged: (v) => setState(() => _isFeatured = v),
                    ),
                  ],
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _save(catalog),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Package',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
      );

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      );

  Widget _field(TextEditingController c, String label, String hint,
          {String? Function(String?)? validator, TextInputType? keyboardType}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          TextFormField(controller: c, decoration: _decoration(hint), validator: validator, keyboardType: keyboardType),
        ],
      );
}
