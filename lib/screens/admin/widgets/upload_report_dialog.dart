import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/booking_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/imgbb_service.dart';
import '../../../widgets/app_image_view.dart';
import '../../../widgets/custom_button.dart';

class UploadReportDialog extends StatefulWidget {
  final BookingModel booking;

  const UploadReportDialog({super.key, required this.booking});

  @override
  State<UploadReportDialog> createState() => _UploadReportDialogState();
}

class _UploadReportDialogState extends State<UploadReportDialog> {
  final _doctorNotesController = TextEditingController(text: 'All diagnostic findings clinically verified.');
  final _pathologistController = TextEditingController(text: 'Dr. S. K. Verma, MD (Pathology & Lab Director)');
  final _urlController = TextEditingController();
  String? _reportFileUrl;
  bool _isUploading = false;
  bool _showUrlField = false;

  @override
  void dispose() {
    _doctorNotesController.dispose();
    _pathologistController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadReport() async {
    setState(() => _isUploading = true);
    try {
      final url = await ImgBBService.pickImageDirectFromFile(imageName: 'report_${widget.booking.id}');
      if (mounted) {
        setState(() {
          _isUploading = false;
          if (url != null && url.isNotEmpty) {
            _reportFileUrl = url;
          }
        });
        if (url != null && url.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Diagnostic report uploaded via ImgBB!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload notice: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveAndReleaseReport() async {
    if (_reportFileUrl == null || _reportFileUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please attach or upload a diagnostic report file first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final admin = context.read<AdminProvider>();
    final testTitle = widget.booking.services.isNotEmpty
        ? widget.booking.services.map((s) => s.title).join(', ')
        : 'Diagnostic Test';

    final success = await admin.uploadLabReportAndComplete(
      booking: widget.booking,
      summary: _doctorNotesController.text.trim().isNotEmpty
          ? _doctorNotesController.text.trim()
          : 'Diagnostic report for $testTitle verified.',
      doctorNotes: _doctorNotesController.text.trim(),
      pathologistName: _pathologistController.text.trim().isNotEmpty
          ? _pathologistController.text.trim()
          : 'Dr. S. K. Verma, MD (Pathology)',
      parameters: [],
      reportImageUrl: _reportFileUrl,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Report for Booking #${widget.booking.id} Released to Patient!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final testNames = widget.booking.services.map((s) => s.title).join(', ');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Upload Diagnostic Report',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 8),

              // Booking Overview Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('BOOKING #${widget.booking.id}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primary)),
                        Text('₹${widget.booking.totalAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Patient: ${widget.booking.patientName} (${widget.booking.patientAge}y, ${widget.booking.patientSex})', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    Text('Test(s): $testNames', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // REAL REPORT UPLOAD DROPZONE
              const Text('Attach Diagnostic Report File / Photo / Scan *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadReport,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _reportFileUrl != null ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _reportFileUrl != null ? const Color(0xFF16A34A) : AppColors.primary.withOpacity(0.4),
                      width: _reportFileUrl != null ? 1.5 : 1.2,
                    ),
                  ),
                  child: _isUploading
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(strokeWidth: 2.5),
                            SizedBox(height: 10),
                            Text('Uploading report to ImgBB...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          ],
                        )
                      : _reportFileUrl != null
                          ? Column(
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 64,
                                        height: 64,
                                        child: AppImageView(imageUrl: _reportFileUrl!, fit: BoxFit.cover),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                                              SizedBox(width: 4),
                                              Text('Report Attached Successfully', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                                            ],
                                          ),
                                          SizedBox(height: 2),
                                          Text('Ready for patient download & view', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _pickAndUploadReport,
                                      icon: const Icon(Icons.refresh_rounded, size: 14),
                                      label: const Text('Change File', style: TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        side: const BorderSide(color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => setState(() => _reportFileUrl = null),
                                      child: const Text('Remove', style: TextStyle(color: AppColors.error, fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                const Icon(Icons.cloud_upload_rounded, size: 42, color: AppColors.primary),
                                const SizedBox(height: 8),
                                const Text(
                                  'Click to Upload Report File / Scan / Photo',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Choose from Device / Laptop / Phone Storage',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.folder_open_rounded, size: 16),
                                  label: const Text('Browse Report File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                  onPressed: _pickAndUploadReport,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 12),

              // Optional Direct URL Paste Accordion
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showUrlField = !_showUrlField),
                  icon: Icon(_showUrlField ? Icons.keyboard_arrow_up : Icons.link_rounded, size: 14),
                  label: Text(_showUrlField ? 'Hide URL Option' : 'Or Paste Direct Image Link', style: const TextStyle(fontSize: 11)),
                ),
              ),
              if (_showUrlField) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          hintText: 'https://example.com/report.jpg',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_urlController.text.trim().isNotEmpty) {
                          setState(() => _reportFileUrl = _urlController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      child: const Text('Set', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Verifying Doctor (Single Line)
              TextField(
                controller: _pathologistController,
                decoration: const InputDecoration(
                  labelText: 'Verifying Pathologist / Specialist',
                  prefixIcon: Icon(Icons.verified_user_rounded, size: 18, color: AppColors.primary),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                style: const TextStyle(fontSize: 12.5),
              ),
              const SizedBox(height: 12),

              // Doctor Remarks
              TextField(
                controller: _doctorNotesController,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Doctor Advice (Optional)',
                  prefixIcon: Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                style: const TextStyle(fontSize: 12.5),
              ),
              const SizedBox(height: 20),

              // Submit Button
              CustomButton(
                text: 'Upload Report & Complete Visit',
                isLoading: admin.isLoading,
                onPressed: _handleSaveAndReleaseReport,
                icon: Icons.check_circle_rounded,
                backgroundColor: AppColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
