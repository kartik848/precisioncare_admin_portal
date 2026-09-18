import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_strings.dart';
import '../../models/booking_model.dart';
import '../../models/diagnostic_service.dart';
import 'date_formatter.dart';

class FieldWorkOrderPdfGenerator {
  /// Generates printable Field Work Order / Technician Job Sheet PDF
  static Future<Uint8List> generateWorkOrderPdf(BookingModel booking) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 1. HEADER
            _buildHeader(booking),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1.5, color: const PdfColor.fromInt(0xFF0E8388)),
            pw.SizedBox(height: 6),

            // 2. WORK ORDER META & VISIT INFO
            _buildOrderInfoBanner(booking),
            pw.SizedBox(height: 8),

            // 3. PATIENT DEMOGRAPHICS & ADDRESS
            _buildPatientDetailsCard(booking),
            pw.SizedBox(height: 8),

            // 4. ASSIGNED TECHNICIAN DETAILS
            _buildTechnicianCard(booking),
            pw.SizedBox(height: 8),

            // 5. TEST(S) TO COLLECT & SPECIMEN TUBE GUIDE
            _buildTestListAndTubeGuide(booking),
            pw.SizedBox(height: 8),

            // 6. BILLING & PAYMENT STATUS
            _buildPaymentCard(booking),
            pw.SizedBox(height: 10),

            // 7. SPECIMEN VERIFICATION, BARCODE & SIGNATURES
            _buildVerificationAndSignatures(booking),

            pw.Spacer(),

            // 8. FOOTER
            _buildFooter(context),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(BookingModel booking) {
    return pw.Row(
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
                'NABL & ICMR ACCREDITED HOME COLLECTION & DIAGNOSTICS DIVISION',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF144272),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Branch 1: ${AppStrings.branch1Address}',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                maxLines: 1,
              ),
              pw.Text(
                'Branch 2: ${AppStrings.branch2Address}',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                maxLines: 1,
              ),
              pw.Text(
                '24x7 Support & Helpline: ${AppStrings.helplineNumber}',
                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0E8388)),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF0E8388),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'SAMPLE DISPATCH SLIP',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'PHLEBOTOMIST JOB ORDER',
                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildOrderInfoBanner(BookingModel booking) {
    final visitLabel = booking.visitType == VisitType.homeVisit
        ? '🏠 HOME VISIT (DOORSTEP SAMPLE COLLECTION)'
        : '🏥 CENTRE VISIT (IN-HOUSE PRECISIONCARE)';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF1F5F9),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('BOOKING ID: ${booking.id}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A))),
          pw.Text(visitLabel, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0E8388))),
          pw.Text('SLOT: ${booking.timeSlot}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildPatientDetailsCard(BookingModel booking) {
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
            '1. PATIENT DEMOGRAPHICS & COLLECTION ADDRESS',
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1E293B)),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _metaRow('Patient Name:', booking.patientName, isBold: true),
                    _metaRow('Age / Gender:', '${booking.patientAge} Years / ${booking.patientSex}'),
                    _metaRow('Patient Mobile:', booking.patientMobile, isBold: true),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 4,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _metaRow(
                      booking.visitType == VisitType.homeVisit ? 'Visit Address:' : 'Centre Branch:',
                      booking.patientAddress ?? AppStrings.branch1Address,
                      isBold: true,
                    ),
                    if (booking.notes != null && booking.notes!.isNotEmpty)
                      _metaRow('Patient Note:', booking.notes!),
                    _metaRow('Scheduled Date:', DateFormatter.formatDate(booking.scheduledDate)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTechnicianCard(BookingModel booking) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFEFF6FF),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ASSIGNED PHLEBOTOMIST / RADIOGRAPHER:',
                style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                booking.technicianName ?? 'PrecisionCare Senior Phlebotomist',
                style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1D4ED8)),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('DISPATCH STATUS:', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
              pw.Text(
                booking.status.displayName.toUpperCase(),
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0E8388)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTestListAndTubeGuide(BookingModel booking) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: const PdfColor.fromInt(0xFFF8FAFC),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 3, child: pw.Text('DIAGNOSTIC TEST / PACKAGE', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                pw.Expanded(flex: 2, child: pw.Text('SPECIMEN / VIAL REQUIRED', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                pw.Expanded(flex: 2, child: pw.Text('PATIENT PREPARATION', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                pw.SizedBox(width: 50, child: pw.Text('PRICE', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
              ],
            ),
          ),
          ...booking.services.map((service) => _buildServiceRow(service)),
        ],
      ),
    );
  }

  static pw.Widget _buildServiceRow(DiagnosticService s) {
    String tubeGuide = 'Purple EDTA / Serum Gel';
    if (s.title.toLowerCase().contains('glucose') || s.title.toLowerCase().contains('sugar')) {
      tubeGuide = 'Grey Top (Fluoride Tube)';
    } else if (s.title.toLowerCase().contains('x-ray')) {
      tubeGuide = 'Digital Portable DR Plate';
    } else if (s.title.toLowerCase().contains('ecg')) {
      tubeGuide = '12-Lead ECG Machine Kit';
    } else if (s.title.toLowerCase().contains('pft') || s.title.toLowerCase().contains('spirometry')) {
      tubeGuide = 'Spirometry Mouthpiece + Nose Clip';
    } else if (s.title.toLowerCase().contains('physio')) {
      tubeGuide = 'Portable TENS / IFT Kit';
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(s.title, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                pw.Text(s.categoryName, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
              ],
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(tubeGuide, style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF0E8388))),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(s.preparation.split('.').first, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700), maxLines: 2),
          ),
          pw.SizedBox(
            width: 50,
            child: pw.Text('Rs. ${s.price.toInt()}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentCard(BookingModel booking) {
    final isOnline = booking.paymentStatus.contains('Online') || booking.paymentStatus.contains('Paid');
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: isOnline ? const PdfColor.fromInt(0xFFF0FDF4) : const PdfColor.fromInt(0xFFFFFBEB),
        border: pw.Border.all(color: isOnline ? const PdfColor.fromInt(0xFF86EFAC) : const PdfColor.fromInt(0xFFFDE68A)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                isOnline ? 'PAYMENT VERIFIED ONLINE (DO NOT COLLECT CASH)' : 'COLLECT PAYMENT FROM PATIENT AT DOORSTEP / VISIT',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: isOnline ? const PdfColor.fromInt(0xFF15803D) : const PdfColor.fromInt(0xFFB45309)),
              ),
              if (booking.utrNumber != null)
                pw.Text('UPI UTR / Reference: ${booking.utrNumber}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            ],
          ),
          pw.Text('TOTAL: Rs. ${booking.totalAmount.toInt()}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A))),
        ],
      ),
    );
  }

  static pw.Widget _buildVerificationAndSignatures(BookingModel booking) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('SPECIMEN COLLECTION VERIFICATION', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('[  ] Sample collected at correct temperature', style: const pw.TextStyle(fontSize: 7)),
                pw.Text('[  ] Barcode tubes labelled in patient presence', style: const pw.TextStyle(fontSize: 7)),
                pw.Text('[  ] Ice box / Cold chain maintained', style: const pw.TextStyle(fontSize: 7)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('SIGNATURES & HANDOVER', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 14),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Phlebotomist Sign: _________', style: const pw.TextStyle(fontSize: 7)),
                    pw.Text('Patient Sign: _________', style: const pw.TextStyle(fontSize: 7)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _metaRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 75, child: pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700))),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 7.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('PrecisionCare Diagnostic Centre Clinical Operations System', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
            pw.Text('Printed: ${DateFormatter.formatDateTime(DateTime.now())}', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }

  static Future<void> printOrShareWorkOrder(BookingModel booking) async {
    final pdfBytes = await generateWorkOrderPdf(booking);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'PrecisionCare_Job_Slip_${booking.id}.pdf',
    );
  }
}
