import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/search_matcher.dart';
import '../../../providers/catalog_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/lab_section.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/app_image_view.dart';
import 'edit_lab_audience_dialog.dart';
import 'image_upload_field.dart';

/// Create / edit a sub-category (e.g. "Adult Women") and choose the packages and tests inside it.
/// Also used for the groups/tiles of a home collection via [onSave].
class EditLabSubcategoryDialog extends StatefulWidget {
  final LabAudience? audience;
  final LabSubcategory? subcategory;

  /// Saves somewhere other than a lab section (e.g. a home collection group).
  final Future<void> Function(LabSubcategory sub)? onSave;
  final String? parentName;
  final bool showAgeRange;

  const EditLabSubcategoryDialog({
    super.key,
    this.audience,
    this.subcategory,
    this.onSave,
    this.parentName,
    this.showAgeRange = true,
  }) : assert(audience != null || onSave != null);

  String get _parentLabel => parentName ?? audience?.name ?? '';

  @override
  State<EditLabSubcategoryDialog> createState() => _EditLabSubcategoryDialogState();
}

class _EditLabSubcategoryDialogState extends State<EditLabSubcategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _minAge;
  late final TextEditingController _maxAge;
  late Set<String> _packageIds;
  late Set<String> _testIds;
  String? _imageUrl;
  bool _showTests = false;
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.subcategory;
    _name = TextEditingController(text: s?.name ?? '');
    _minAge = TextEditingController(text: s?.minAge?.toString() ?? '');
    _maxAge = TextEditingController(text: s?.maxAge?.toString() ?? '');
    _packageIds = {...?s?.packageIds};
    _testIds = {...?s?.testIds};
    _imageUrl = s?.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _minAge.dispose();
    _maxAge.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final admin = context.read<AdminProvider>();
    final sub = LabSubcategory(
      id: widget.subcategory?.id ?? 'sub_${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      imageUrl: _imageUrl,
      minAge: int.tryParse(_minAge.text.trim()),
      maxAge: int.tryParse(_maxAge.text.trim()),
      packageIds: _packageIds.toList(),
      testIds: _testIds.toList(),
    );
    try {
      if (widget.onSave != null) {
        await widget.onSave!(sub);
      } else {
        // Re-read the parent so we don't overwrite sub-categories edited elsewhere meanwhile.
        final a = widget.audience!;
        final parent = admin.labAudiences.firstWhere((x) => x.id == a.id, orElse: () => a);
        await admin.saveLabSubcategory(parent, sub);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${sub.name}" saved with ${sub.itemCount} items'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final packages = SearchMatcher.rank(admin.packages, _query, CatalogProvider.packageSearchFieldsOf);
    final tests = SearchMatcher.rank(admin.catalogServices, _query, CatalogProvider.searchFieldsOf);

    return LabDialogShell(
      title: widget.subcategory == null ? 'New item in ${widget._parentLabel}' : 'Edit ${widget.subcategory!.name}',
      icon: Icons.dashboard_customize_rounded,
      saving: _saving,
      onSave: _save,
      saveText: 'Save Sub-category',
      maxWidth: 620,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: ImageUploadField(
                    imageUrl: _imageUrl,
                    aspectRatio: 1.1,
                    hint: 'Tile photo',
                    namePrefix: 'precisioncare_subcategory',
                    onChanged: (v) => setState(() => _imageUrl = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      labLabel('Sub-category name'),
                      TextFormField(
                        controller: _name,
                        decoration: labDecoration('e.g. Adult Women'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.showAgeRange) ...[
              const SizedBox(height: 16),
              AgeRangeFields(
                min: _minAge,
                max: _maxAge,
                label: 'Recommend to ages (blank = same as ${widget._parentLabel})',
              ),
            ],
            const SizedBox(height: 20),
            labLabel('Items in this sub-category'),
            Row(
              children: [
                _tab('Packages', _packageIds.length, !_showTests, () => setState(() => _showTests = false)),
                const SizedBox(width: 8),
                _tab('Tests', _testIds.length, _showTests, () => setState(() => _showTests = true)),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: labDecoration(_showTests ? 'Search tests…' : 'Search packages…')
                  .copyWith(prefixIcon: const Icon(Icons.search_rounded, size: 20)),
            ),
            const SizedBox(height: 8),
            Container(
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: _showTests
                  ? ListView.separated(
                      itemCount: tests.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (_, i) {
                        final t = tests[i];
                        return CheckboxListTile(
                          dense: true,
                          value: _testIds.contains(t.id),
                          activeColor: AppColors.primary,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (v) => setState(() => v == true ? _testIds.add(t.id) : _testIds.remove(t.id)),
                          title: Text(t.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          subtitle: Text('${t.categoryName} • ₹${t.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                        );
                      },
                    )
                  : packages.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No health packages yet.\nCreate them in the "Health Packages" tab first.',
                                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        )
                      : ListView.separated(
                          itemCount: packages.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                          itemBuilder: (_, i) {
                            final p = packages[i];
                            return CheckboxListTile(
                              dense: true,
                              value: _packageIds.contains(p.id),
                              activeColor: AppColors.primary,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (v) => setState(() => v == true ? _packageIds.add(p.id) : _packageIds.remove(p.id)),
                              secondary: p.posterUrl != null
                                  ? AppImageView(
                                      imageUrl: p.posterUrl,
                                      width: 40,
                                      height: 40,
                                      borderRadius: BorderRadius.circular(8),
                                    )
                                  : null,
                              title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              subtitle: Text('${p.testCount} tests • ₹${p.price.toStringAsFixed(0)}${p.isActive ? '' : ' • hidden'}',
                                  style: const TextStyle(fontSize: 11)),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, int count, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? AppColors.textPrimary : const Color(0xFFE2E8F0)),
        ),
        child: Text('$label ($count)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }
}
