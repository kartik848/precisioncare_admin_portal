import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../constants/app_strings.dart';

class PrescriptionPrinter {
  /// Print or export official Doctor Prescription slip document
  static Future<void> printPrescription({
    required String prescriptionUrl,
    required String patientName,
    required String patientMobile,
    String? bookingId,
    String? notes,
    DateTime? date,
  }) async {
    try {
      final doc = pw.Document();
      final uploadDate = date ?? DateTime.now();
      final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(uploadDate);

      // Download prescription image bytes
      pw.Widget imageWidget;
      try {
        final response = await http.get(Uri.parse(prescriptionUrl));
        if (response.statusCode == 200) {
          final imageBytes = response.bodyBytes;
          final pwImage = pw.MemoryImage(imageBytes);
          imageWidget = pw.Container(
            height: 480,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 7,
              verticalRadius: 7,
              child: pw.Image(pwImage, fit: pw.BoxFit.contain),
            ),
          );
        } else {
          imageWidget = pw.Container(
            height: 200,
            alignment: pw.Alignment.center,
            child: pw.Text('Could not load prescription image: HTTP ${response.statusCode}'),
          );
        }
      } catch (e) {
        imageWidget = pw.Container(
          height: 200,
          alignment: pw.Alignment.center,
          child: pw.Text('Error fetching prescription image: $e'),
        );
      }

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 1. Header with Centre details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          AppStrings.appName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'NABL Accredited & Certified Diagnostic Lab Network (Pune)',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          'Helpline: +91 90212 37070 • Website: precisioncare.vercel.app',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        border: pw.Border.all(color: PdfColors.blue300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'DOCTOR\'S PRESCRIPTION',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                          ),
                          if (bookingId != null)
                            pw.Text('Ref: $bookingId', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.teal800),
                pw.SizedBox(height: 8),

                // 2. Patient Demographics Strip
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Patient Name: $patientName', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 2),
                          pw.Text('Phone: $patientMobile', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800)),
                        ],
                      ),
                      if (notes != null && notes.isNotEmpty)
                        pw.Expanded(
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 16),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Clinical Notes / Instructions:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                                pw.Text(notes, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // 3. Prescription Scan Image
                pw.Text('Prescription Document / Slip Copy:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                pw.SizedBox(height: 6),
                imageWidget,
                pw.Spacer(),

                // 4. Footer & Lab Verification Stamp
                pw.Divider(color: PdfColors.grey400),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Opposite Fakhri Hills, Lullanagar / Kondhwa, Pune, MH 411040',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      'Printed via PrecisionCare Diagnostic Lab System',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'Prescription_${patientName.replaceAll(' ', '_')}_$dateStr.pdf',
      );
    } catch (e) {
      debugPrint('Error printing prescription: $e');
    }
  }
}
