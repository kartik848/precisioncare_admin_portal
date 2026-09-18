import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/field_order_pdf_generator.dart';
import '../../../core/utils/prescription_printer.dart';
import '../../../models/booking_model.dart';
import '../../../models/staff_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/app_image_view.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class BookingActionDialog extends StatefulWidget {
  final BookingModel booking;

  const BookingActionDialog({super.key, required this.booking});

  @override
  State<BookingActionDialog> createState() => _BookingActionDialogState();
}

class _BookingActionDialogState extends State<BookingActionDialog> {
  final _formKey = GlobalKey<FormState>();

  final _staffNameController = TextEditingController();
  final _staffPhoneController = TextEditingController();
  final _adminNotesController = TextEditingController();

  StaffMember? _selectedStaff;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      if (admin.activeStaffList.isNotEmpty) {
        final isXray = widget.booking.services.any((s) => s.iconType == 'xray');
        final isEcg = widget.booking.services.any((s) => s.iconType == 'ecg');
        final isPhysio = widget.booking.services.any((s) => s.iconType == 'physio');

        StaffMember matched = admin.activeStaffList.first;
        if (isXray) {
          matched = admin.activeStaffList.firstWhere(
            (s) => s.role.toLowerCase().contains('radio') || s.role.toLowerCase().contains('x-ray'),
            orElse: () => admin.activeStaffList.first,
          );
        } else if (isEcg) {
          matched = admin.activeStaffList.firstWhere(
            (s) => s.role.toLowerCase().contains('ecg') || s.role.toLowerCase().contains('cardiac'),
            orElse: () => admin.activeStaffList.first,
          );
        } else if (isPhysio) {
          matched = admin.activeStaffList.firstWhere(
            (s) => s.role.toLowerCase().contains('physio'),
            orElse: () => admin.activeStaffList.first,
          );
        } else {
          matched = admin.activeStaffList.firstWhere(
            (s) => s.role.toLowerCase().contains('phlebo') || s.role.toLowerCase().contains('blood'),
            orElse: () => admin.activeStaffList.first,
          );
        }

        setState(() {
          _selectedStaff = matched;
          _staffNameController.text = '${matched.name} (${matched.role})';
          _staffPhoneController.text = matched.phone;
        });
      }
    });
  }

  @override
  void dispose() {
    _staffNameController.dispose();
    _staffPhoneController.dispose();
    _adminNotesController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept({bool printOrderSlip = true}) async {
    if (!_formKey.currentState!.validate()) return;

    final admin = context.read<AdminProvider>();
    final staffName = _staffNameController.text.trim();
    final staffPhone = _staffPhoneController.text.trim();
    final adminNotes = _adminNotesController.text.trim();

    final success = await admin.acceptAndAssignTechnician(
      bookingId: widget.booking.id,
      staffName: staffName,
      staffPhone: staffPhone,
      adminNotes: adminNotes,
    );

    if (success && mounted) {
      Navigator.pop(context);

      final updatedBooking = widget.booking.copyWith(
        status: BookingStatus.technicianAssigned,
        technicianName: staffName,
        technicianPhone: staffPhone,
        notes: adminNotes.isNotEmpty ? adminNotes : widget.booking.notes,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Booking #${widget.booking.id} ACCEPTED & Assigned to $staffName!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );

      if (printOrderSlip) {
        // Automatically launch technician field work order slip print
        await FieldWorkOrderPdfGenerator.printOrShareWorkOrder(updatedBooking);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final staffList = admin.activeStaffList;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 510),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                        Icon(Icons.assignment_turned_in_rounded, color: AppColors.primary, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Accept & Assign Staff',
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

                // Patient & Visit Card
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
                      Text('Mobile: ${widget.booking.patientMobile}', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                      Text('Location: ${widget.booking.patientAddress ?? "Centre Visit"}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('Scheduled: ${widget.booking.timeSlot}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Payment Status Indicator with Proof
                if (widget.booking.utrNumber != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                                SizedBox(width: 4),
                                Text('Paid Online via UPI QR', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                              ],
                            ),
                            Text('UTR: ${widget.booking.utrNumber}', style: const TextStyle(fontSize: 11, color: Color(0xFF166534))),
                          ],
                        ),
                        if (widget.booking.paymentScreenshotUrl != null)
                          OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('UPI Payment Screenshot', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(context)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: AppImageView(imageUrl: widget.booking.paymentScreenshotUrl!),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.receipt_long_rounded, size: 13),
                            label: const Text('View Proof', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF15803D),
                              side: const BorderSide(color: Color(0xFF16A34A)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Doctor Prescription Slip Attached Card
                if (widget.booking.prescriptionUrl != null && widget.booking.prescriptionUrl!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF7C3AED),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.document_scanner_rounded, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Doctor\'s Prescription Attached', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6D28D9))),
                                Text('Verified doctor test slip attached by patient', style: TextStyle(fontSize: 10, color: Color(0xFF7C3AED))),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Doctor\'s Prescription Slip', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(context)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: AppImageView(imageUrl: widget.booking.prescriptionUrl!),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility_outlined, size: 13),
                              label: const Text('View', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF7C3AED),
                                side: const BorderSide(color: Color(0xFF8B5CF6)),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              onPressed: () => PrescriptionPrinter.printPrescription(
                                prescriptionUrl: widget.booking.prescriptionUrl!,
                                patientName: widget.booking.patientName,
                                patientMobile: widget.booking.patientMobile,
                                bookingId: widget.booking.id,
                                notes: widget.booking.notes,
                                date: widget.booking.createdAt,
                              ),
                              icon: const Icon(Icons.print_rounded, size: 13, color: Colors.white),
                              label: const Text('Print Slip', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Choose Staff Dropdown
                const Text('Select Medical Technician / Phlebotomist *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),

                DropdownButtonFormField<StaffMember>(
                  value: _selectedStaff,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  hint: const Text('Choose Staff from Directory', style: TextStyle(fontSize: 13)),
                  items: staffList.map((staff) {
                    return DropdownMenuItem<StaffMember>(
                      value: staff,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.person, size: 14, color: AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${staff.name} — ${staff.role}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (selected) {
                    if (selected != null) {
                      setState(() {
                        _selectedStaff = selected;
                        _staffNameController.text = '${selected.name} (${selected.role})';
                        _staffPhoneController.text = selected.phone;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Staff Name
                CustomTextField(
                  controller: _staffNameController,
                  label: 'Staff Full Name & Role',
                  hint: 'e.g. Vikram Singh (Senior Phlebotomist)',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter staff name' : null,
                ),
                const SizedBox(height: 12),

                // Staff Phone
                CustomTextField(
                  controller: _staffPhoneController,
                  label: 'Staff Mobile Number',
                  hint: 'e.g. +91 98765 00123',
                  prefixIcon: Icons.phone_android_rounded,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter staff mobile' : null,
                ),
                const SizedBox(height: 12),

                // Dispatch instructions
                CustomTextField(
                  controller: _adminNotesController,
                  label: 'Dispatch Instructions (Optional)',
                  hint: 'e.g. Carry portable digital X-Ray & fasting blood tubes',
                  prefixIcon: Icons.edit_note_rounded,
                ),
                const SizedBox(height: 20),

                // Primary CTA: Accept & Print Work Order Slip (PDF)
                CustomButton(
                  text: 'Accept & Print Work Order Slip (PDF)',
                  isLoading: admin.isLoading,
                  onPressed: () => _handleAccept(printOrderSlip: true),
                  icon: Icons.print_rounded,
                  backgroundColor: AppColors.primary,
                ),
                const SizedBox(height: 10),

                // Secondary CTA: Accept Only
                Center(
                  child: TextButton.icon(
                    onPressed: () => _handleAccept(printOrderSlip: false),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Accept Without Printing Slip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
