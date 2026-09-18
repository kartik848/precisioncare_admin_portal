import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/pdf_generator.dart';
import '../../models/test_report.dart';
import '../../widgets/app_image_view.dart';

class ReportViewerScreen extends StatelessWidget {
  final TestReport report;

  const ReportViewerScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share PDF',
            onPressed: () => PdfReportGenerator.shareReport(report),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download & Print PDF',
            onPressed: () => PdfReportGenerator.printOrShareReport(report),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lab Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRECISIONCARE DIAGNOSTIC CENTRE',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'NABL & ICMR Accredited Lab (Pune)',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'VERIFIED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.divider),

                  // Patient & Test Meta
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoItem('Patient Name', report.patientName),
                            const SizedBox(height: 6),
                            _infoItem('Age / Sex', '${report.patientAge} Yrs / ${report.patientSex}'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoItem('Report ID', report.id),
                            const SizedBox(height: 6),
                            _infoItem('Test Date', DateFormatter.formatDate(report.testDate)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Test Title
            Text(
              report.testTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // 1. Attached Diagnostic Report Scan / Photo (Prominently Rendered)
            if (report.pdfDownloadUrl != null && report.pdfDownloadUrl!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.verified_user_rounded, size: 18, color: Color(0xFF16A34A)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Uploaded Diagnostic Lab Report / Film',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Tap to zoom', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            backgroundColor: Colors.black,
                            insetPadding: const EdgeInsets.all(8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Stack(
                              children: [
                                Center(
                                  child: InteractiveViewer(
                                    maxScale: 4.0,
                                    child: AppImageView(imageUrl: report.pdfDownloadUrl!, fit: BoxFit.contain),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 380),
                          width: double.infinity,
                          child: AppImageView(imageUrl: report.pdfDownloadUrl!, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 2. Parameters Table (If parameters entered)
            if (report.parameters.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Investigation',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Result',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Normal Range',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),

                    // Table Rows
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: report.parameters.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (context, index) {
                        final p = report.parameters[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  p.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: p.isAbnormal ? FontWeight.w700 : FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${p.value} ${p.unit}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: p.isAbnormal ? AppColors.error : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (p.isAbnormal) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
                                    ],
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  p.normalRange,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 3. Clinical Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assignment_outlined, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Clinical Summary & Interpretation',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.summary,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                  ),
                  if (report.doctorNotes != null && report.doctorNotes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Doctor\'s Advice: ${report.doctorNotes!}',
                              style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Pathologist / Doctor Signature Card
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
                        Text(
                          'NABL QA Certificate:',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        Text(
                          'QA-2026-9812-NABL',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Digitally Signed',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          report.pathologistName,
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => PdfReportGenerator.shareReport(report),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Share PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => PdfReportGenerator.printOrShareReport(report),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download / Print'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
