import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/pdf_generator.dart';
import '../../models/test_report.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/empty_state.dart';
import 'report_viewer_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<ReportProvider>().fetchReports(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final allReports = reportProvider.reports;
    final filteredReports = allReports.where((r) {
      return _query.isEmpty ||
          r.testTitle.toLowerCase().contains(_query.toLowerCase()) ||
          r.categoryName.toLowerCase().contains(_query.toLowerCase()) ||
          r.id.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Test Reports'),
      ),
      body: Column(
        children: [
          // Search Box
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                hintText: 'Search report by test name or ID...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                fillColor: AppColors.background,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Reports List
          Expanded(
            child: reportProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredReports.isEmpty
                    ? const EmptyState(
                        icon: Icons.description_outlined,
                        title: 'No Diagnostic Reports Found',
                        description: 'Your verified medical reports will appear here as soon as laboratory testing is completed.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredReports.length,
                        itemBuilder: (context, index) {
                          return _buildReportCard(filteredReports[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(TestReport report) {
    final hasAbnormal = report.parameters.any((p) => p.isAbnormal);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
          // Header: Category & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    report.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      report.status.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title & Doctor
          Text(
            report.testTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Verified by: ${report.pathologistName}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),

          // Date & Parameter badges
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatDate(report.testDate),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              if (hasAbnormal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 10, color: AppColors.warning),
                      SizedBox(width: 3),
                      Text('Attention Needed', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.warning)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('All Normal', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.success)),
                ),
            ],
          ),
          if (report.pdfDownloadUrl != null && report.pdfDownloadUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined, size: 13, color: Color(0xFF16A34A)),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Attached Lab Scan / Film Available',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          // Actions: View Details & Download PDF (Expanded to avoid overflow)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReportViewerScreen(report: report),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 15),
                  label: const Text('View Report', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => PdfReportGenerator.printOrShareReport(report),
                  icon: const Icon(Icons.file_download_outlined, size: 15),
                  label: const Text('Download PDF', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
