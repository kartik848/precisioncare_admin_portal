import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/lab_section.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/app_image_view.dart';
import 'edit_lab_audience_dialog.dart';
import 'edit_lab_subcategory_dialog.dart';

/// Admin manager for the patient home "Lab tests & packages" tree.
class LabSectionsTab extends StatelessWidget {
  const LabSectionsTab({super.key});

  static void openNewSection(BuildContext context) {
    final count = context.read<AdminProvider>().labAudiences.length;
    showDialog(context: context, builder: (_) => EditLabAudienceDialog(nextSortOrder: count));
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final audiences = admin.labAudiences;

    if (audiences.isEmpty) return _empty(context, admin);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _intro(context),
        const SizedBox(height: 16),
        for (final a in audiences) _AudienceCard(audience: a),
      ],
    );
  }

  Widget _intro(BuildContext context) {
    Widget step(String n, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: AppColors.primary,
              child: Text(n, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 6),
            Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        );
    const arrow = Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textMuted);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lab tests & packages (patient home)',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
                    SizedBox(height: 2),
                    Text('Gender & age on each section decide what patients see in "Recommended for you".',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => openNewSection(context),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [step('1', 'Section (For Women)'), arrow, step('2', 'Sub-category (Adult Women)'), arrow, step('3', 'Packages & Tests')],
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, AdminProvider admin) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.groups_rounded, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text('No lab sections yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text(
                'Sections like "For Women", "For Men" and "For Children" appear as round photo tabs on the patient home. '
                'Start with our ready-made set, then add photos and packages.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await admin.seedStarterLabSections();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Starter sections created. Add photos and packages to each.'),
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
                onPressed: () => openNewSection(context),
                child: const Text('Or create a section from scratch', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  final LabAudience audience;
  const _AudienceCard({required this.audience});

  Future<void> _confirmDelete(BuildContext context, String what, Future<void> Function() onDelete) async {
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

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminProvider>();
    final a = audience;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFFC084FC), Color(0xFFF472B6)]),
                  ),
                  child: ClipOval(
                    child: a.imageUrl != null
                        ? AppImageView(imageUrl: a.imageUrl, fit: BoxFit.cover)
                        : Container(color: Colors.white, child: const Icon(Icons.add_a_photo_outlined, color: AppColors.textMuted)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(a.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                          ),
                          if (!a.isActive) ...[
                            const SizedBox(width: 8),
                            _chip('HIDDEN', AppColors.textMuted),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _chip(a.targetingLabel, AppColors.info),
                          _chip('${a.subcategories.length} sub-categories', AppColors.secondary),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: a.isActive ? 'Hide from patients' : 'Show to patients',
                  icon: Icon(a.isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: a.isActive ? AppColors.success : AppColors.textMuted, size: 20),
                  onPressed: () => admin.saveLabAudience(a.copyWith(isActive: !a.isActive)),
                ),
                IconButton(
                  tooltip: 'Edit section',
                  icon: const Icon(Icons.edit_outlined, color: AppColors.info, size: 20),
                  onPressed: () => showDialog(context: context, builder: (_) => EditLabAudienceDialog(audience: a)),
                ),
                IconButton(
                  tooltip: 'Delete section',
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  onPressed: () => _confirmDelete(context, a.name, () => admin.deleteLabAudience(a.id)),
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
                for (final s in a.subcategories) _subTile(context, admin, s),
                _addTile(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _subTile(BuildContext context, AdminProvider admin, LabSubcategory s) {
    final age = s.minAge != null || s.maxAge != null
        ? (s.minAge != null && s.maxAge != null ? '${s.minAge}–${s.maxAge} yrs' : s.minAge != null ? '${s.minAge}+ yrs' : '≤${s.maxAge} yrs')
        : null;
    return SizedBox(
      width: 150,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showDialog(
          context: context,
          builder: (_) => EditLabSubcategoryDialog(audience: audience, subcategory: s),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.1,
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFFFFE4EC), borderRadius: BorderRadius.circular(14)),
                    clipBehavior: Clip.antiAlias,
                    child: s.imageUrl != null
                        ? AppImageView(imageUrl: s.imageUrl, fit: BoxFit.cover)
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
                      onTap: () => _confirmDelete(context, s.name, () => admin.deleteLabSubcategory(audience, s.id)),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.error),
                      ),
                    ),
                  ),
                ),
                if (s.itemCount == 0)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: _chip('EMPTY', AppColors.warning, solid: true),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            Text(
              '${s.packageIds.length} packages • ${s.testIds.length} tests${age != null ? '\n$age' : ''}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addTile(BuildContext context) {
    return SizedBox(
      width: 150,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showDialog(context: context, builder: (_) => EditLabSubcategoryDialog(audience: audience)),
        child: AspectRatio(
          aspectRatio: 1.1,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.4),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
                SizedBox(height: 6),
                Text('Add sub-category',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _chip(String text, Color color, {bool solid = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: solid ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: solid ? Colors.white : color)),
      );
}
