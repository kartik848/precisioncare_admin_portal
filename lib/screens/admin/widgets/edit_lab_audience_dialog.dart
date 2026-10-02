import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/lab_section.dart';
import '../../../providers/admin_provider.dart';
import 'image_upload_field.dart';

/// Create / edit a top-level lab section such as "For Women".
class EditLabAudienceDialog extends StatefulWidget {
  final LabAudience? audience;
  final int nextSortOrder;

  const EditLabAudienceDialog({super.key, this.audience, this.nextSortOrder = 0});

  @override
  State<EditLabAudienceDialog> createState() => _EditLabAudienceDialogState();
}

class _EditLabAudienceDialogState extends State<EditLabAudienceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _minAge;
  late final TextEditingController _maxAge;
  late final TextEditingController _sort;
  String? _imageUrl;
  String _gender = 'All';
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.audience;
    _name = TextEditingController(text: a?.name ?? '');
    _minAge = TextEditingController(text: a?.minAge?.toString() ?? '');
    _maxAge = TextEditingController(text: a?.maxAge?.toString() ?? '');
    _sort = TextEditingController(text: (a?.sortOrder ?? widget.nextSortOrder).toString());
    _imageUrl = a?.imageUrl;
    _gender = a?.gender ?? 'All';
    _isActive = a?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _minAge.dispose();
    _maxAge.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final a = widget.audience;
    final updated = LabAudience(
      id: a?.id ?? 'aud_${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      imageUrl: _imageUrl,
      gender: _gender,
      minAge: int.tryParse(_minAge.text.trim()),
      maxAge: int.tryParse(_maxAge.text.trim()),
      sortOrder: int.tryParse(_sort.text.trim()) ?? 0,
      isActive: _isActive,
      subcategories: a?.subcategories ?? const [],
    );
    try {
      await context.read<AdminProvider>().saveLabAudience(updated);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Section "${updated.name}" saved'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LabDialogShell(
      title: widget.audience == null ? 'New Lab Section' : 'Edit Lab Section',
      icon: Icons.groups_rounded,
      saving: _saving,
      onSave: _save,
      saveText: 'Save Section',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: ImageUploadField(
                    imageUrl: _imageUrl,
                    circle: true,
                    hint: 'Round\nphoto',
                    namePrefix: 'precisioncare_section',
                    onChanged: (v) => setState(() => _imageUrl = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      labLabel('Section name'),
                      TextFormField(
                        controller: _name,
                        decoration: labDecoration('e.g. For Women'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                      ),
                      const SizedBox(height: 8),
                      const Text('Shown as a round photo tab under "Lab tests & packages".',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            labLabel('Who is this for? (drives "Recommended for you")'),
            Wrap(
              spacing: 8,
              children: [
                for (final g in LabAudience.genders)
                  ChoiceChip(
                    label: Text(g == 'All' ? 'Everyone' : g),
                    selected: _gender == g,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.w700, color: _gender == g ? Colors.white : AppColors.textPrimary),
                    onSelected: (_) => setState(() => _gender = g),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            AgeRangeFields(min: _minAge, max: _maxAge),
            const SizedBox(height: 14),
            labLabel('Display order'),
            SizedBox(
              width: 120,
              child: TextFormField(
                controller: _sort,
                keyboardType: TextInputType.number,
                decoration: labDecoration('0'),
              ),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
              title: const Text('Visible to patients', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Shared dialog bits ─────────────────────────

Widget labLabel(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
    );

InputDecoration labDecoration(String hint) => InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    );

class AgeRangeFields extends StatelessWidget {
  final TextEditingController min;
  final TextEditingController max;
  final String label;

  const AgeRangeFields({super.key, required this.min, required this.max, this.label = 'Age range (leave blank for any age)'});

  String? _validate(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    return (n == null || n < 0 || n > 120) ? '0–120' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labLabel(label),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: min,
                keyboardType: TextInputType.number,
                decoration: labDecoration('Min age'),
                validator: _validate,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('to', style: TextStyle(color: AppColors.textSecondary)),
            ),
            Expanded(
              child: TextFormField(
                controller: max,
                keyboardType: TextInputType.number,
                decoration: labDecoration('Max age'),
                validator: (v) {
                  final err = _validate(v);
                  if (err != null) return err;
                  final lo = int.tryParse(min.text.trim());
                  final hi = int.tryParse((v ?? '').trim());
                  return (lo != null && hi != null && hi < lo) ? 'Must be ≥ min' : null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Branded dialog frame: gradient header, scrollable body, sticky save button.
class LabDialogShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool saving;
  final VoidCallback onSave;
  final String saveText;
  final double maxWidth;

  const LabDialogShell({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.saving,
    required this.onSave,
    required this.saveText,
    this.maxWidth = 560,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 780),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
              decoration: const BoxDecoration(gradient: AppColors.brandGradient),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: child),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: saving ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(saveText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
