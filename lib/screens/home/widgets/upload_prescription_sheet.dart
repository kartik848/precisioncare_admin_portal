import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/imgbb_service.dart';
import '../../../services/prescription_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class UploadPrescriptionSheet extends StatefulWidget {
  const UploadPrescriptionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UploadPrescriptionSheet(),
    );
  }

  @override
  State<UploadPrescriptionSheet> createState() => _UploadPrescriptionSheetState();
}

class _UploadPrescriptionSheetState extends State<UploadPrescriptionSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;

  String? _prescriptionImageUrl;
  bool _isUploadingImage = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.mobile ?? '');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPrescriptionPhoto() async {
    setState(() => _isUploadingImage = true);
    final url = await ImgBBService.pickImageDirectFromFile(
      imageName: 'prescription_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;
    setState(() {
      _isUploadingImage = false;
      if (url != null) {
        _prescriptionImageUrl = url;
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_prescriptionImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload or take a photo of your doctor\'s prescription'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final user = context.read<AuthProvider>().user;

    final id = await PrescriptionService.savePrescription(
      userId: user?.uid ?? 'guest_user',
      patientName: _nameController.text.trim(),
      patientPhone: _phoneController.text.trim(),
      patientEmail: user?.email,
      prescriptionUrl: _prescriptionImageUrl!,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (id != null) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              SizedBox(width: 8),
              Text('Prescription Uploaded!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          content: const Text(
            'Your prescription has been sent directly to our diagnostic lab team. Our certified pathologist will review your test requirements and call you shortly with the best package and appointment time.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit prescription. Please check internet connection.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Doctor\'s Prescription',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Our lab team will review tests & call you back in 15 mins',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Upload Photo Box
              GestureDetector(
                onTap: _isUploadingImage ? null : _pickPrescriptionPhoto,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _prescriptionImageUrl != null ? AppColors.success : const Color(0xFFCBD5E1),
                      width: _prescriptionImageUrl != null ? 2 : 1.5,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: _isUploadingImage
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(strokeWidth: 2.5),
                              SizedBox(height: 10),
                              Text('Uploading prescription image...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : _prescriptionImageUrl != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    _prescriptionImageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                                      onPressed: _pickPrescriptionPhoto,
                                      tooltip: 'Retake photo',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check, color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text('Prescription Attached', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.primary),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to Click Photo or Select from Gallery',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Supports JPG, PNG (Clear photo of doctor prescription slip)',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _nameController,
                label: 'Patient Full Name *',
                hint: 'e.g. Ramesh Kulkarni',
                prefixIcon: Icons.person_outline,
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter patient name' : null,
              ),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _phoneController,
                label: 'Contact Mobile Number *',
                hint: '10-digit mobile for appointment confirmation',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Mobile number is required';
                  final clean = val.replaceAll(RegExp(r'\D'), '');
                  if (clean.length < 10) return 'Enter a valid 10-digit phone number';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              CustomTextField(
                controller: _notesController,
                label: 'Doctor Notes / Special Requirements (Optional)',
                hint: 'e.g. Fasting sugar, doctor advised home sample collection, etc.',
                prefixIcon: Icons.edit_note_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              CustomButton(
                text: 'Send Prescription to Lab Team',
                isLoading: _isSubmitting,
                icon: Icons.send_rounded,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
