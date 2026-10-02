import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/imgbb_service.dart';
import '../../../widgets/app_image_view.dart';

/// Tap-to-upload photo box used by the lab section dialogs (uploads to ImgBB).
class ImageUploadField extends StatefulWidget {
  final String? imageUrl;
  final ValueChanged<String?> onChanged;
  final double aspectRatio;
  final bool circle;
  final String hint;
  final String namePrefix;

  const ImageUploadField({
    super.key,
    required this.imageUrl,
    required this.onChanged,
    this.aspectRatio = 1,
    this.circle = false,
    this.hint = 'Upload photo',
    this.namePrefix = 'precisioncare_lab',
  });

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  bool _uploading = false;

  Future<void> _pick() async {
    setState(() => _uploading = true);
    final url = await ImgBBService.pickImageDirectFromFile(
      imageName: '${widget.namePrefix}_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    if (url != null) widget.onChanged(url);
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl;
    final radius = widget.circle ? null : BorderRadius.circular(16);
    return Stack(
      children: [
        GestureDetector(
          onTap: _uploading ? null : _pick,
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: radius,
                border: Border.all(color: AppColors.borderSubtle, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: _uploading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
                  : url != null
                      ? AppImageView(imageUrl: url, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 28),
                            const SizedBox(height: 6),
                            Text(widget.hint,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w700)),
                          ],
                        ),
            ),
          ),
        ),
        if (url != null && !_uploading)
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => widget.onChanged(null),
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
