import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/specialist.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/app_image_view.dart';
import 'edit_lab_audience_dialog.dart';
import 'image_upload_field.dart';

/// Admin manager for the home "Consult specialists & lab doctors" rail.
class SpecialistsTab extends StatelessWidget {
  const SpecialistsTab({super.key});

  static void openNew(BuildContext context) {
    final count = context.read<AdminProvider>().specialists.length;
    showDialog(context: context, builder: (_) => EditSpecialistDialog(nextSortOrder: count));
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final list = admin.specialists;

    if (list.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.medical_services_rounded, size: 44, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text('Specialists are using the built-in list', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text(
                  'Patients currently see the 5 default doctors. Import them to change photos, names, '
                  'badges and which category opens on tap — or add your own.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.45),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => admin.seedStarterSpecialists(),
                    icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                    label: const Text('Import current doctors', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ),
                TextButton(
                  onPressed: () => openNew(context),
                  child: const Text('Or add a specialist from scratch', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12, left: 4),
          child: Text('Shown on the patient home as "Consult Specialists & Lab Doctors" (in this order).',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [for (final s in list) _SpecialistCard(specialist: s)],
        ),
      ],
    );
  }
}

class _SpecialistCard extends StatelessWidget {
  final Specialist specialist;
  const _SpecialistCard({required this.specialist});

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminProvider>();
    final s = specialist;
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryLight,
                child: ClipOval(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: AppImageView(
                      imageUrl: s.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: const Icon(Icons.person_rounded, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
                    Text(s.specialty, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    if (s.badge.isNotEmpty)
                      Text(s.badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${s.categoryTarget.isEmpty ? 'No link' : 'Opens: ${s.categoryTarget}'} • #${s.sortOrder}${s.isActive ? '' : ' • HIDDEN'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: s.isActive ? 'Hide' : 'Show',
                icon: Icon(s.isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    size: 18, color: s.isActive ? AppColors.success : AppColors.textMuted),
                onPressed: () => admin.saveSpecialist(s.copyWith(isActive: !s.isActive)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.info),
                onPressed: () => showDialog(context: context, builder: (_) => EditSpecialistDialog(specialist: s)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Delete ${s.name}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) await admin.deleteSpecialist(s.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EditSpecialistDialog extends StatefulWidget {
  final Specialist? specialist;
  final int nextSortOrder;

  const EditSpecialistDialog({super.key, this.specialist, this.nextSortOrder = 0});

  @override
  State<EditSpecialistDialog> createState() => _EditSpecialistDialogState();
}

class _EditSpecialistDialogState extends State<EditSpecialistDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.specialist?.name ?? '');
  late final TextEditingController _specialty = TextEditingController(text: widget.specialist?.specialty ?? '');
  late final TextEditingController _badge = TextEditingController(text: widget.specialist?.badge ?? '');
  late final TextEditingController _sort =
      TextEditingController(text: (widget.specialist?.sortOrder ?? widget.nextSortOrder).toString());
  late String? _imageUrl = widget.specialist?.imageUrl;
  late String _category = widget.specialist?.categoryTarget ?? '';
  late bool _isActive = widget.specialist?.isActive ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _specialty.dispose();
    _badge.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final s = Specialist(
      id: widget.specialist?.id ?? 'spec_${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      specialty: _specialty.text.trim(),
      badge: _badge.text.trim().toUpperCase(),
      imageUrl: _imageUrl,
      categoryTarget: _category,
      sortOrder: int.tryParse(_sort.text.trim()) ?? 0,
      isActive: _isActive,
    );
    try {
      await context.read<AdminProvider>().saveSpecialist(s);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${s.name}" saved'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<AdminProvider>().categories.map((c) => c.name).toList();
    if (_category.isNotEmpty && !categories.contains(_category)) categories.add(_category);

    return LabDialogShell(
      title: widget.specialist == null ? 'New Specialist' : 'Edit Specialist',
      icon: Icons.medical_services_rounded,
      saving: _saving,
      onSave: _save,
      saveText: 'Save Specialist',
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
                    hint: 'Doctor\nphoto',
                    namePrefix: 'precisioncare_doctor',
                    onChanged: (v) => setState(() => _imageUrl = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      labLabel('Name / title'),
                      TextFormField(
                        controller: _name,
                        decoration: labDecoration('e.g. Clinical Pathologist'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                      ),
                      const SizedBox(height: 12),
                      labLabel('Specialty line'),
                      TextFormField(controller: _specialty, decoration: labDecoration('e.g. Blood & Lab Tests')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            labLabel('Badge (optional)'),
            TextFormField(controller: _badge, decoration: labDecoration('e.g. NABL ACCREDITED')),
            const SizedBox(height: 14),
            labLabel('On tap, open category'),
            DropdownButtonFormField<String>(
              value: _category,
              isExpanded: true,
              decoration: labDecoration(''),
              items: [
                const DropdownMenuItem(value: '', child: Text('Nothing (not tappable)')),
                for (final c in categories) DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _category = v ?? ''),
            ),
            const SizedBox(height: 14),
            labLabel('Display order'),
            SizedBox(
              width: 120,
              child: TextFormField(controller: _sort, keyboardType: TextInputType.number, decoration: labDecoration('0')),
            ),
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
