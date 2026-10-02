import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/promo_banner.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/catalog_provider.dart';
import '../../../services/imgbb_service.dart';
import '../../../widgets/app_image_view.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class EditBannerDialog extends StatefulWidget {
  final PromoBanner banner;

  const EditBannerDialog({super.key, required this.banner});

  @override
  State<EditBannerDialog> createState() => _EditBannerDialogState();
}

class _EditBannerDialogState extends State<EditBannerDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _badgeController;
  late TextEditingController _actionTextController;

  late TextEditingController _urlController;

  String? _uploadedImageUrl;
  bool _isActive = true;
  String _placement = PromoBanner.placementTop;
  // none | url | package | test | section | category
  String _linkType = 'none';
  String? _linkValue;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.banner.title);
    _subtitleController = TextEditingController(text: widget.banner.subtitle);
    _badgeController = TextEditingController(text: widget.banner.badge);
    _actionTextController = TextEditingController(text: widget.banner.actionText);
    _uploadedImageUrl = widget.banner.imageUrl;
    _isActive = widget.banner.isActive;
    _placement = widget.banner.placement;
    _urlController = TextEditingController();
    _parseLink(widget.banner.linkUrl);

    _titleController.addListener(() => setState(() {}));
    _subtitleController.addListener(() => setState(() {}));
    _badgeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _badgeController.dispose();
    _actionTextController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _parseLink(String link) {
    final sep = link.indexOf(':');
    final scheme = sep > 0 ? link.substring(0, sep) : '';
    if (link.isEmpty) {
      _linkType = 'none';
    } else if (const ['package', 'test', 'section', 'category'].contains(scheme)) {
      _linkType = scheme;
      _linkValue = link.substring(sep + 1);
    } else {
      _linkType = 'url';
      _urlController.text = link;
    }
  }

  String _composeLink() {
    switch (_linkType) {
      case 'url':
        return _urlController.text.trim();
      case 'none':
        return '';
      default:
        return (_linkValue == null || _linkValue!.isEmpty) ? '' : '$_linkType:$_linkValue';
    }
  }

  Future<void> _handleDirectDeviceUpload() async {
    final url = await ImgBBService.pickImageDirectFromFile(
      imageName: 'precisioncare_banner_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;
    setState(() {
      _isUploading = false;
      if (url != null) {
        _uploadedImageUrl = url;
      }
    });

    if (url != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banner photo uploaded to ImgBB successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.banner.copyWith(
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      badge: _badgeController.text.trim(),
      actionText: _actionTextController.text.trim(),
      imageUrl: _uploadedImageUrl,
      clearImage: true,
      isActive: _isActive,
      placement: _placement,
      linkUrl: _composeLink(),
    );

    await context.read<AdminProvider>().addOrUpdateBanner(updated);
    if (mounted) {
      context.read<CatalogProvider>().loadBanners();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Banner "${updated.title}" updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 520),
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
                    const Row(
                      children: [
                        Icon(Icons.view_carousel_rounded, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Edit Promotional Banner',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 10),

                // Live Banner Visual Preview Box (Exact 2:1 Aspect Ratio Matching Patient App)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Live App Preview (Exact 2:1 Ratio):', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                          child: const Text('2:1 Scale Locked', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AspectRatio(
                      aspectRatio: 2.0, // Exact 2:1 ratio matching the mobile carousel
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          gradient: _uploadedImageUrl == null
                              ? const LinearGradient(
                                  colors: [Color(0xFF0E8388), Color(0xFF2E4F4F)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          image: _uploadedImageUrl != null
                              ? DecorationImage(
                                  image: getAppImageProvider(_uploadedImageUrl)!,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            if (_uploadedImageUrl != null && (_titleController.text.isNotEmpty || _subtitleController.text.isNotEmpty))
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withValues(alpha: 0.65),
                                        Colors.black.withValues(alpha: 0.2),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.45, 1.0],
                                      begin: Alignment.bottomLeft,
                                      end: Alignment.topRight,
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (_badgeController.text.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _badgeController.text,
                                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800),
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_titleController.text.isNotEmpty)
                                        Text(
                                          _titleController.text,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (_subtitleController.text.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          _subtitleController.text,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontSize: 10.5,
                                            shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Accurate Banner Aspect Ratio & Size Guidance Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF86EFAC), width: 1.3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                            child: const Icon(Icons.aspect_ratio_rounded, size: 18, color: Color(0xFF16A34A)),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Exact Required Banner Ratio: 2:1',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                              ),
                              Text(
                                'Width hamesha Height se do-guna (2x) honi chahiye',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '🌟 Recommended / Canva Size: 1200 × 600 px (Exact 2:1)',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '📱 Standard Mobile Size: 1000 × 500 px (Exact 2:1)',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '⚡ Compact HD Size: 800 × 400 px (Exact 2:1)',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '💡 Canva Instructions:\n1. Canva me "Create a Design" -> "Custom Size" select karein.\n2. Width: 1200 px aur Height: 600 px enter karein.\n3. Agar banner me pehle se text likha hai, toh niche Title & Subtitle box ko blank chhod dein taaki image clean dikhe.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF166534), height: 1.45, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Direct File Upload from Device Button (ImgBB API)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Banner Image (ImgBB API)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                            ),
                            Text(
                              _uploadedImageUrl != null ? '✅ Photo Uploaded & Linked' : 'Recommended: 1200 x 600 px (2:1 Ratio)',
                              style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (_isUploading)
                        const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      else ...[
                        ElevatedButton.icon(
                          onPressed: _handleDirectDeviceUpload,
                          icon: const Icon(Icons.file_upload_outlined, size: 14, color: Colors.white),
                          label: Text(_uploadedImageUrl != null ? 'Change Photo' : 'Upload Photo', style: const TextStyle(fontSize: 11, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                        if (_uploadedImageUrl != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            tooltip: 'Remove photo (Use gradient)',
                            onPressed: () => setState(() => _uploadedImageUrl = null),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _titleController,
                  label: 'Banner Main Headline',
                  hint: 'e.g. Free Home Sample Collection',
                  prefixIcon: Icons.title_rounded,
                  validator: (v) =>
                      _uploadedImageUrl == null && (v == null || v.trim().isEmpty) ? 'Enter headline (or upload a photo)' : null,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _subtitleController,
                  label: 'Subtitle / Offer Details',
                  hint: 'e.g. Flat 20% OFF on Full Body Master Checkup',
                  prefixIcon: Icons.subtitles_outlined,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _badgeController,
                        label: 'Badge Tag',
                        hint: 'POPULAR OFFER',
                        prefixIcon: Icons.bookmark_border_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomTextField(
                        controller: _actionTextController,
                        label: 'CTA Button Text',
                        hint: 'Book Blood Test',
                        prefixIcon: Icons.touch_app_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _sectionLabel('Where on the home screen?'),
                Wrap(
                  spacing: 8,
                  children: [
                    _choice('Top carousel', _placement == PromoBanner.placementTop,
                        () => setState(() => _placement = PromoBanner.placementTop)),
                    _choice('Mid-page (after Most booked)', _placement == PromoBanner.placementMiddle,
                        () => setState(() => _placement = PromoBanner.placementMiddle)),
                  ],
                ),
                const SizedBox(height: 14),
                _sectionLabel('When a patient taps the banner, open…'),
                _buildLinkPicker(),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show Banner in Patient App', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 16),

                CustomButton(
                  text: 'Save & Publish Banner',
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

  Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
      );

  Widget _choice(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: selected ? Colors.white : AppColors.textPrimary),
        onSelected: (_) => onTap(),
      );

  InputDecoration _dropdownDecoration(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _buildLinkPicker() {
    final admin = context.watch<AdminProvider>();
    const types = {
      'none': 'Default (category listing)',
      'url': 'Website / external link',
      'package': 'A health package',
      'test': 'A single test',
      'section': 'A lab section (e.g. For Women)',
      'category': 'A test category',
    };

    Widget valuePicker;
    switch (_linkType) {
      case 'url':
        valuePicker = CustomTextField(
          controller: _urlController,
          label: 'Link URL',
          hint: 'https://precisioncare.in/offer',
          prefixIcon: Icons.link_rounded,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a link' : null,
        );
        break;
      case 'package':
        valuePicker = _valueDropdown('Choose package', {for (final p in admin.packages) p.id: p.name});
        break;
      case 'test':
        valuePicker = _valueDropdown('Choose test', {for (final t in admin.catalogServices) t.id: t.title});
        break;
      case 'section':
        valuePicker = _valueDropdown('Choose section', {for (final a in admin.labAudiences) a.id: a.name});
        break;
      case 'category':
        valuePicker = _valueDropdown('Choose category', {for (final c in admin.categories) c.name: c.name});
        break;
      default:
        valuePicker = const SizedBox.shrink();
    }

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _linkType,
          isExpanded: true,
          decoration: _dropdownDecoration('Tap action'),
          items: [for (final e in types.entries) DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)))],
          onChanged: (v) => setState(() {
            _linkType = v ?? 'none';
            _linkValue = null;
          }),
        ),
        if (_linkType != 'none') ...[
          const SizedBox(height: 10),
          // Fresh field state per link type so a stale selection never leaks across types.
          KeyedSubtree(key: ValueKey(_linkType), child: valuePicker),
        ],
      ],
    );
  }

  Widget _valueDropdown(String hint, Map<String, String> options) {
    return DropdownButtonFormField<String>(
      value: options.containsKey(_linkValue) ? _linkValue : null,
      isExpanded: true,
      decoration: _dropdownDecoration(hint),
      hint: Text(options.isEmpty ? 'Nothing to choose yet' : hint, style: const TextStyle(fontSize: 13)),
      items: [
        for (final e in options.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
      ],
      validator: (v) => v == null ? 'Pick one' : null,
      onChanged: (v) => setState(() => _linkValue = v),
    );
  }
}
