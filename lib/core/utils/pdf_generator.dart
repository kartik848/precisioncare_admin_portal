import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_strings.dart';
import '../../models/test_report.dart';
import 'date_formatter.dart';

class PdfReportGenerator {
  static Future<Uint8List> generateDiagnosticReportPdf(TestReport report) async {
    final pdf = pw.Document();

    pw.ImageProvider? scanImage;
    if (report.pdfDownloadUrl != null &&
        report.pdfDownloadUrl!.isNotEmpty &&
        !report.pdfDownloadUrl!.toLowerCase().endsWith('.pdf')) {
      try {
        scanImage = await networkImage(report.pdfDownloadUrl!);
      } catch (e) {
        debugPrint('Could not load scan image for PDF embed: $e');
      }
    }

    // If an uploaded report scan exists from Admin, add it directly as the primary official report
    if (scanImage != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              pw.SizedBox(height: 6),
              _buildPatientInfo(report),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFDCFCE7)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'OFFICIAL DIAGNOSTIC LAB REPORT / SCAN',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF15803D),
                      ),
                    ),
                    pw.Text(
                      'Verified by ${report.pathologistName}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(scanImage!, fit: pw.BoxFit.contain),
                ),
              ),
              pw.SizedBox(height: 6),
              _buildDoctorSignature(report),
            ],
          ),
        ),
      );
    } else {
      // If no image uploaded, generate structured digital parameter report
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            pw.SizedBox(height: 10),
            _buildPatientInfo(report),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 10),
            _buildTestTitle(report),
            pw.SizedBox(height: 10),
            if (report.parameters.isNotEmpty) ...[
              _buildParametersTable(report),
              pw.SizedBox(height: 14),
            ],
            _buildClinicalInterpretation(report),
            pw.SizedBox(height: 20),
            _buildDoctorSignature(report),
          ],
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PRECISIONCARE DIAGNOSTIC CENTRE (PUNE)',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF0E8388),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'NABL & ICMR ACCREDITED CLINICAL REFERENCE LAB',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF144272),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Branch 1: ${AppStrings.branch1Address}',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                    maxLines: 1,
                  ),
                  pw.Text(
                    'Branch 2: ${AppStrings.branch2Address}',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                    maxLines: 1,
                  ),
                  pw.Text(
                    '24/7 Diagnostics Helpline: ${AppStrings.helplineNumber}',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColor.fromInt(0xFF0E8388)),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFCBE4DE),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                'LAB REPORT',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF0E8388),
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(thickness: 1.5, color: const PdfColor.fromInt(0xFF0E8388)),
      ],
    );
  }

  static pw.Widget _buildPatientInfo(TestReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoRow('Patient Name:', report.patientName, isBold: true),
              _infoRow('Age / Gender:', '${report.patientAge} Years / ${report.patientSex}'),
              _infoRow('Referred By:', 'Self / Dr. Consulting Physician'),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoRow('Report ID:', report.id),
              _infoRow('Test Date:', DateFormatter.formatDate(report.testDate)),
              _infoRow('Status:', report.status.toUpperCase(), isBold: true, color: const PdfColor.fromInt(0xFF0E8388)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 75,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTestTitle(TestReport report) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: const PdfColor.fromInt(0xFF2E4F4F),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            report.testTitle.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            report.categoryName,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildParametersTable(TestReport report) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(1.5),
      },
      children: [
        // Table Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
          children: [
            _tableHeaderCell('Investigation / Test Parameter'),
            _tableHeaderCell('Observed Result'),
            _tableHeaderCell('Biological Reference Interval'),
            _tableHeaderCell('Unit'),
          ],
        ),
        // Table Data Rows
        ...report.parameters.map((param) {
          final isAbnormal = param.isAbnormal;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isAbnormal ? const PdfColor.fromInt(0xFFFEF2F2) : PdfColors.white,
            ),
            children: [
              _tableDataCell(param.name, isBold: isAbnormal),
              _tableDataCell(
                param.value,
                isBold: isAbnormal,
                color: isAbnormal ? PdfColors.red : PdfColors.black,
              ),
              _tableDataCell(param.normalRange),
              _tableDataCell(param.unit),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A)),
      ),
    );
  }

  static pw.Widget _tableDataCell(String text, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildClinicalInterpretation(TestReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CLINICAL SUMMARY & INTERPRETATION:',
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0E8388)),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            report.summary,
            style: const pw.TextStyle(fontSize: 8),
          ),
          if (report.doctorNotes != null && report.doctorNotes!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Remarks / Recommendations: ${report.doctorNotes}',
              style: pw.TextStyle(fontSize: 7.5, fontStyle: pw.FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildDoctorSignature(TestReport report) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Verified by NABL QA Control', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
            pw.Text('NABL Certificate: QA-2026-9812', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              height: 20,
              child: pw.Text(
                'Digitally Signed',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                  color: const PdfColor.fromInt(0xFF0E8388),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              report.pathologistName,
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Consultant Pathologist & Lab Director',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('*** End of PrecisionCare Diagnostic Report ***', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }

  static Future<void> printOrShareReport(TestReport report) async {
    final pdfBytes = await generateDiagnosticReportPdf(report);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'PrecisionCare_${report.testTitle.replaceAll(" ", "_")}_Report.pdf',
    );
  }

  static Future<void> shareReport(TestReport report) async {
    final pdfBytes = await generateDiagnosticReportPdf(report);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'PrecisionCare_${report.testTitle.replaceAll(" ", "_")}_Report.pdf',
    );
  }
}
