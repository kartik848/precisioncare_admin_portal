import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/home_collection.dart';
import '../../../models/lab_section.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/app_image_view.dart';
import 'edit_lab_audience_dialog.dart';
import 'edit_lab_subcategory_dialog.dart';

/// Admin manager for curated patient-home sections (Fever, Lifestyle, Athlete, Specialised tests…).
class HomeCollectionsTab extends StatelessWidget {
  const HomeCollectionsTab({super.key});

  static void openNew(BuildContext context) {
    final count = context.read<AdminProvider>().homeCollections.length;
    showDialog(context: context, builder: (_) => EditHomeCollectionDialog(nextSortOrder: count));
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final list = admin.homeCollections;

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
                  child: const Icon(Icons.view_agenda_rounded, size: 44, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text('No home sections yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text(
                  'Patients currently see ready-made sections built from your catalog '
                  '(Fever, Specialised tests, Lifestyle, Athlete, Children). '
                  'Create them here to edit titles, photos, tabs and the tests inside.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.45),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await admin.seedStarterCollections();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Home sections created from your catalog. Edit or add photos anytime.'),
                          backgroundColor: AppColors.success,
                        ));
                      }
                    },
                    icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                    label: const Text('Create starter sections', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => openNew(context),
                  child: const Text('Or create a section from scratch', style: TextStyle(fontWeight: FontWeight.w700)),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Curated home sections', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
                    SizedBox(height: 2),
                    Text('Card rail: one group = one rail, several groups = pill tabs. Photo tiles: each group is a tile with "Starting at ₹".',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => openNew(context),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('New Section', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final c in list) _CollectionCard(collection: c),
      ],
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final HomeCollection collection;
  const _CollectionCard({required this.collection});

  Future<void> _confirm(BuildContext context, String what, Future<void> Function() onDelete) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $what?'),
        content: const Text('Patients will no longer see it. Packages and tests themselves are not deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok == true) await onDelete();
  }

  void _editGroup(BuildContext context, [LabSubcategory? group]) {
    final admin = context.read<AdminProvider>();
    showDialog(
      context: context,
      builder: (_) => EditLabSubcategoryDialog(
        subcategory: group,
        parentName: collection.title,
        showAgeRange: false,
        onSave: (g) => admin.saveCollectionGroup(collection, g),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminProvider>();
    final c = collection;
    Widget chip(String t, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(t, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                      if (c.subtitle.isNotEmpty)
                        Text(c.subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        chip(c.isTiles ? 'Photo tiles' : (c.groups.length > 1 ? 'Rail with tabs' : 'Card rail'), AppColors.info),
                        chip('${c.groups.length} group(s)', AppColors.secondary),
                        chip('Order ${c.sortOrder}', AppColors.textSecondary),
                        if (!c.isActive) chip('HIDDEN', AppColors.textMuted),
                      ]),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: c.isActive ? 'Hide from patients' : 'Show to patients',
                  icon: Icon(c.isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: c.isActive ? AppColors.success : AppColors.textMuted, size: 20),
                  onPressed: () => admin.saveHomeCollection(c.copyWith(isActive: !c.isActive)),
                ),
                IconButton(
                  tooltip: 'Edit section',
                  icon: const Icon(Icons.edit_outlined, color: AppColors.info, size: 20),
                  onPressed: () => showDialog(context: context, builder: (_) => EditHomeCollectionDialog(collection: c)),
                ),
                IconButton(
                  tooltip: 'Delete section',
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  onPressed: () => _confirm(context, c.title, () => admin.deleteHomeCollection(c.id)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final g in c.groups)
                  SizedBox(
                    width: 150,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _editGroup(context, g),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 1.1,
                                child: Container(
                                  decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(14)),
                                  clipBehavior: Clip.antiAlias,
                                  child: g.imageUrl != null
                                      ? AppImageView(imageUrl: g.imageUrl, fit: BoxFit.cover)
                                      : const Center(child: Icon(Icons.add_a_photo_outlined, color: AppColors.primary)),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  elevation: 1,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => _confirm(context, g.name, () => admin.deleteCollectionGroup(c, g.id)),
                                    child: const Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.error),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(g.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          Text('${g.packageIds.length} packages • ${g.testIds.length} tests',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                SizedBox(
                  width: 150,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _editGroup(context),
                    child: AspectRatio(
                      aspectRatio: 1.1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.4),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
                            const SizedBox(height: 6),
                            Text(c.isTiles ? 'Add tile' : 'Add tab / group',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Create / edit a curated section's title, layout and order.
class EditHomeCollectionDialog extends StatefulWidget {
  final HomeCollection? collection;
  final int nextSortOrder;

  const EditHomeCollectionDialog({super.key, this.collection, this.nextSortOrder = 0});

  @override
  State<EditHomeCollectionDialog> createState() => _EditHomeCollectionDialogState();
}

class _EditHomeCollectionDialogState extends State<EditHomeCollectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(text: widget.collection?.title ?? '');
  late final TextEditingController _subtitle = TextEditingController(text: widget.collection?.subtitle ?? '');
  late final TextEditingController _sort =
      TextEditingController(text: (widget.collection?.sortOrder ?? widget.nextSortOrder).toString());
  late String _layout = widget.collection?.layout ?? HomeCollection.layoutRail;
  late bool _isActive = widget.collection?.isActive ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final c = widget.collection;
    final updated = HomeCollection(
      id: c?.id ?? 'col_${DateTime.now().millisecondsSinceEpoch}',
      title: _title.text.trim(),
      subtitle: _subtitle.text.trim(),
      layout: _layout,
      sortOrder: int.tryParse(_sort.text.trim()) ?? 0,
      isActive: _isActive,
      groups: c?.groups ?? const [],
    );
    try {
      await context.read<AdminProvider>().saveHomeCollection(updated);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Section "${updated.title}" saved'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget layoutChip(String value, String label, IconData icon) {
      final selected = _layout == value;
      return ChoiceChip(
        avatar: Icon(icon, size: 16, color: selected ? Colors.white : AppColors.textSecondary),
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textPrimary),
        onSelected: (_) => setState(() => _layout = value),
      );
    }

    return LabDialogShell(
      title: widget.collection == null ? 'New Home Section' : 'Edit Home Section',
      icon: Icons.view_agenda_rounded,
      saving: _saving,
      onSave: _save,
      saveText: 'Save Section',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labLabel('Section title'),
            TextFormField(
              controller: _title,
              decoration: labDecoration('e.g. Checkups & Vaccination for Fever'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 14),
            labLabel('Subtitle (optional)'),
            TextFormField(controller: _subtitle, decoration: labDecoration('e.g. Explore targeted checkups…')),
            const SizedBox(height: 18),
            labLabel('Layout'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              layoutChip(HomeCollection.layoutRail, 'Card rail / tabs', Icons.view_carousel_rounded),
              layoutChip(HomeCollection.layoutTiles, 'Photo tiles + banner', Icons.grid_view_rounded),
            ]),
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
