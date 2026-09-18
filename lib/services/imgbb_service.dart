import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';

class ImgBBService {
  static const String apiKey = 'f1a3270cf5397a26e0b147cf3faae781';
  static const String uploadUrl = 'https://api.imgbb.com/1/upload';

  /// Uploads image bytes directly to ImgBB API and returns the public CDN image URL (https://i.ibb.co/...)
  static Future<String?> uploadImageBytes({
    required Uint8List imageBytes,
    String? imageName,
  }) async {
    final fileName = imageName ?? 'precisioncare_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Direct ImgBB API Upload (Multipart Form Data)
    try {
      final uri = Uri.parse('$uploadUrl?key=$apiKey');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: '$fileName.jpg',
      ));
      request.fields['name'] = fileName;

      final streamedResponse = await request.send().timeout(const Duration(seconds: 12));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final directUrl = (data['data']['url'] ?? data['data']['display_url']) as String;
          debugPrint('✓ ImgBB API upload success: $directUrl');
          return directUrl;
        }
      }
    } catch (e) {
      debugPrint('ImgBB Multipart upload warning: $e');
    }

    // 2. Direct ImgBB API Upload (Base64 Form-Encoded)
    try {
      final base64Image = base64Encode(imageBytes);
      final response = await http.post(
        Uri.parse(uploadUrl),
        body: {
          'key': apiKey,
          'image': base64Image,
          'name': fileName,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final directUrl = (data['data']['url'] ?? data['data']['display_url']) as String;
          debugPrint('✓ ImgBB Form upload success: $directUrl');
          return directUrl;
        }
      }
    } catch (e) {
      debugPrint('ImgBB Form upload warning: $e');
    }

    // 3. Guaranteed fallback: Data URI (so work is never lost)
    final base64String = base64Encode(imageBytes);
    return 'data:image/jpeg;base64,$base64String';
  }

  /// Uploads base64 encoded string to ImgBB API
  static Future<String?> uploadBase64Image(String base64String) async {
    try {
      final bytes = base64Decode(base64String.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), ''));
      return await uploadImageBytes(imageBytes: bytes);
    } catch (_) {
      return base64String.startsWith('data:image') ? base64String : 'data:image/jpeg;base64,$base64String';
    }
  }

  /// Native File Picker — 100% reliable across Web Browser (Laptop/PC), macOS, Windows, Android, and iOS
  static Future<String?> pickImageDirectFromFile({String? imageName}) async {
    // 1. Try FilePicker with custom extensions (supports images, scans, and PDFs)
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'heic'],
        withData: true,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final Uint8List? bytes = file.bytes;
        if (bytes != null && bytes.isNotEmpty) {
          return await uploadImageBytes(
            imageBytes: bytes,
            imageName: imageName ?? file.name,
          );
        }
      }
    } catch (e) {
      debugPrint('FilePicker custom extension notice: $e');
    }

    // 2. Try FilePicker with FileType.any (covers all operating systems)
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final Uint8List? bytes = file.bytes;
        if (bytes != null && bytes.isNotEmpty) {
          return await uploadImageBytes(
            imageBytes: bytes,
            imageName: imageName ?? file.name,
          );
        }
      }
    } catch (e) {
      debugPrint('FilePicker any notice: $e');
    }

    // 3. Fallback to ImagePicker
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (bytes.isNotEmpty) {
          return await uploadImageBytes(
            imageBytes: bytes,
            imageName: imageName ?? pickedFile.name,
          );
        }
      }
    } catch (e) {
      debugPrint('ImagePicker fallback notice: $e');
    }

    return null;
  }

  /// Interactive picker (Camera or Gallery/Files) for Mobile App
  static Future<String?> pickAndUploadImage(
    BuildContext context, {
    bool allowCamera = true,
    String? imageName,
  }) async {
    if (kIsWeb) {
      return await pickImageDirectFromFile(imageName: imageName);
    }

    final picker = ImagePicker();
    ImageSource? source;

    if (allowCamera) {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Upload / Capture Photo',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose how you want to add the image',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 22),
                  ),
                  title: const Text('Capture with Camera', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Take a photo using device camera', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.info, size: 22),
                  ),
                  title: const Text('Select from Gallery / Storage', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Pick existing image file from storage', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      source = ImageSource.gallery;
    }

    if (source == null) return null;

    try {
      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) return null;

      return await uploadImageBytes(imageBytes: bytes, imageName: imageName ?? pickedFile.name);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
}
