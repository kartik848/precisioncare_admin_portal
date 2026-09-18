import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AppImageView extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppImageView({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildPlaceholder();
    }

    final url = imageUrl!.trim();

    Widget imageWidget;

    if (url.startsWith('data:image')) {
      try {
        final commaIndex = url.indexOf(',');
        final base64Str = commaIndex != -1 ? url.substring(commaIndex + 1) : url;
        final Uint8List bytes = base64Decode(base64Str);
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildError(),
        );
      } catch (_) {
        imageWidget = _buildError();
      }
    } else if (url.startsWith('assets/')) {
      imageWidget = Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildError(),
      );
    } else {
      imageWidget = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: AppColors.background,
                child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              );
        },
        errorBuilder: (_, __, ___) => _buildError(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: AppColors.background,
          child: const Center(child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 24)),
        );
  }

  Widget _buildError() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: AppColors.background,
          child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 24)),
        );
  }
}

/// Helper for CircleAvatar with data URI / network support
ImageProvider? getAppImageProvider(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final clean = url.trim();

  if (clean.startsWith('data:image')) {
    try {
      final commaIndex = clean.indexOf(',');
      final base64Str = commaIndex != -1 ? clean.substring(commaIndex + 1) : clean;
      return MemoryImage(base64Decode(base64Str));
    } catch (_) {
      return null;
    }
  } else if (clean.startsWith('assets/')) {
    return AssetImage(clean);
  } else {
    return NetworkImage(clean);
  }
}
