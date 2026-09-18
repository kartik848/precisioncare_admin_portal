import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/booking_model.dart';
import '../../models/diagnostic_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../services/imgbb_service.dart';
import '../../widgets/app_image_view.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'booking_confirmation_screen.dart';

class ScheduleBookingScreen extends StatefulWidget {
  final DiagnosticService? preSelectedService;

  const ScheduleBookingScreen({super.key, this.preSelectedService});

  @override
  State<ScheduleBookingScreen> createState() => _ScheduleBookingScreenState();
}

class _ScheduleBookingScreenState extends State<ScheduleBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  late List<DiagnosticService> _selectedServices;
  VisitType _visitType = VisitType.homeVisit;
  String _selectedBranch = AppStrings.branch1Address;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = '08:00 AM - 09:30 AM (Morning)';
  String _paymentOption = 'Pay on Collection / Visit';

  // UTR & Payment Proof
  final _utrController = TextEditingController();
  String? _paymentScreenshotUrl;
  bool _isUploadingProof = false;

  // Doctor's Prescription Attachment
  String? _prescriptionUrl;
  bool _isUploadingPrescription = false;

  // Patient info controllers
  bool _isForSelf = true;
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _patientMobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String _patientSex = 'Male';

  @override
  void initState() {
    super.initState();
    _selectedServices = [];
    if (widget.preSelectedService != null) {
      _selectedServices.add(widget.preSelectedService!);
      if (!widget.preSelectedService!.isHomeVisitAvailable && widget.preSelectedService!.isInHouseAvailable) {
        _visitType = VisitType.inHouseCentre;
      }
    }

    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _patientNameController.text = user.name;
      _patientAgeController.text = user.age.toString();
      _patientMobileController.text = user.mobile;
      _patientSex = user.sex;
      _addressController.text = user.address;
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientAgeController.dispose();
    _patientMobileController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _pickPaymentProof() async {
    setState(() => _isUploadingProof = true);
    final url = await ImgBBService.pickAndUploadImage(
      context,
      allowCamera: true,
      imageName: 'upi_payment_proof_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;
    setState(() {
      _isUploadingProof = false;
      if (url != null) _paymentScreenshotUrl = url;
    });

    if (url != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('UPI payment screenshot attached!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _pickPrescriptionPhoto() async {
    setState(() => _isUploadingPrescription = true);
    final url = await ImgBBService.pickAndUploadImage(
      context,
      allowCamera: true,
      imageName: 'booking_rx_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;
    setState(() {
      _isUploadingPrescription = false;
      if (url != null) _prescriptionUrl = url;
    });

    if (url != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor\'s prescription attached to booking!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  double get _totalAmount => _selectedServices.fold(0, (sum, item) => sum + item.price);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showAddMoreServicesSheet() {
    final catalog = context.read<CatalogProvider>().allServices;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add More Diagnostic Tests',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.divider),
                  Expanded(
                    child: ListView.separated(
                      itemCount: catalog.length,
                      separatorBuilder: (_, __) => const Divider(color: AppColors.divider),
                      itemBuilder: (context, index) {
                        final item = catalog[index];
                        final isAlreadyAdded = _selectedServices.any((s) => s.id == item.id);

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${item.categoryName} • ₹${item.price.toInt()}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isAlreadyAdded ? Icons.check_circle : Icons.add_circle_outline,
                              color: isAlreadyAdded ? AppColors.success : AppColors.primary,
                            ),
                            onPressed: () {
                              setState(() {
                                if (isAlreadyAdded) {
                                  _selectedServices.removeWhere((s) => s.id == item.id);
                                } else {
                                  _selectedServices.add(item);
                                }
                              });
                              setModalState(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  CustomButton(
                    text: 'Done (${_selectedServices.length} Selected)',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleConfirmBooking() async {
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one test to schedule!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user != null && user.isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Your account has been temporarily restricted by PrecisionCare Admin. Please contact 24/7 helpline.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (_paymentOption.contains('Online') || _paymentOption.contains('UPI')) {
      if (_utrController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Please enter the 12-Digit UTR / UPI Transaction Reference Number after completing payment.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final bookingProvider = context.read<BookingProvider>();

    final patientAge = int.tryParse(_patientAgeController.text.trim()) ?? 0;
    final isOnlinePayment = _paymentOption.contains('Online') || _paymentOption.contains('UPI');
    final finalPaymentStatus = isOnlinePayment
        ? 'Paid Online (UTR: ${_utrController.text.trim()})'
        : 'Pay on Collection / Visit';

    final booking = await bookingProvider.createBooking(
      userId: user?.uid ?? 'guest_user',
      patientName: _patientNameController.text.trim(),
      patientAge: patientAge,
      patientSex: _patientSex,
      patientMobile: _patientMobileController.text.trim(),
      patientAddress: _visitType == VisitType.homeVisit
          ? _addressController.text.trim()
          : _selectedBranch,
      visitType: _visitType,
      services: _selectedServices,
      scheduledDate: _selectedDate,
      timeSlot: _selectedSlot,
      totalAmount: _totalAmount,
      paymentStatus: finalPaymentStatus,
      utrNumber: isOnlinePayment ? _utrController.text.trim() : null,
      paymentScreenshotUrl: isOnlinePayment ? _paymentScreenshotUrl : null,
      prescriptionUrl: _prescriptionUrl,
      notes: _notesController.text.trim(),
    );

    if (booking != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(booking: booking),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final slots = DateFormatter.getAvailableTimeSlots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Diagnostic Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Selected Services Box
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Selected Tests & Services',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showAddMoreServicesSheet,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add More', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedServices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No tests selected yet. Tap "Add More" to choose tests.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      )
                    else
                      ..._selectedServices.map(
                        (service) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.title,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '₹${service.price.toInt()} • ${service.turnaroundTime}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                                onPressed: () {
                                  setState(() {
                                    _selectedServices.removeWhere((s) => s.id == service.id);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Visit Type Selector (Home Visit vs In-House Centre)
              const Text(
                'Select Visit Mode',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _visitType = VisitType.homeVisit),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _visitType == VisitType.homeVisit ? AppColors.primaryLight.withOpacity(0.4) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _visitType == VisitType.homeVisit ? AppColors.primary : AppColors.border,
                            width: _visitType == VisitType.homeVisit ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.home_work_rounded,
                              color: _visitType == VisitType.homeVisit ? AppColors.primary : AppColors.textSecondary,
                              size: 26,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Home Visit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _visitType == VisitType.homeVisit ? AppColors.primaryDark : AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Sample Collection / Care',
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _visitType = VisitType.inHouseCentre),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _visitType == VisitType.inHouseCentre ? AppColors.primaryLight.withOpacity(0.4) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _visitType == VisitType.inHouseCentre ? AppColors.primary : AppColors.border,
                            width: _visitType == VisitType.inHouseCentre ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.local_hospital_rounded,
                              color: _visitType == VisitType.inHouseCentre ? AppColors.primary : AppColors.textSecondary,
                              size: 26,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'In-House Centre',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _visitType == VisitType.inHouseCentre ? AppColors.primaryDark : AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Diagnostic Centre Lab',
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pune Diagnostic Centre Branch Selection (For In-House Centre)
              if (_visitType == VisitType.inHouseCentre) ...[
                Container(
                  padding: const EdgeInsets.all(14),
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
                          Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Select Pune Diagnostic Centre Branch',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Branch 1 Option
                      GestureDetector(
                        onTap: () => setState(() => _selectedBranch = AppStrings.branch1Address),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedBranch == AppStrings.branch1Address ? AppColors.primaryLight.withOpacity(0.4) : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedBranch == AppStrings.branch1Address ? AppColors.primary : AppColors.border,
                              width: _selectedBranch == AppStrings.branch1Address ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _selectedBranch == AppStrings.branch1Address ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: _selectedBranch == AppStrings.branch1Address ? AppColors.primary : AppColors.textMuted,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Branch 1 (Kondhwa / Lullanagar)',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      AppStrings.branch1Address,
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Branch 2 Option
                      GestureDetector(
                        onTap: () => setState(() => _selectedBranch = AppStrings.branch2Address),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedBranch == AppStrings.branch2Address ? AppColors.primaryLight.withOpacity(0.4) : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedBranch == AppStrings.branch2Address ? AppColors.primary : AppColors.border,
                              width: _selectedBranch == AppStrings.branch2Address ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _selectedBranch == AppStrings.branch2Address ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: _selectedBranch == AppStrings.branch2Address ? AppColors.primary : AppColors.textMuted,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Branch 2 (Parmar Pavan / Fakhri Hills)',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      AppStrings.branch2Address,
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Schedule Date & Time Slot
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
                    const Text(
                      'Schedule Date & Preferred Time Slot',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),

                    // Date Selector Tile
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Appointment Date',
                                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                        Text(
                                          DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Change',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Time Slot Dropdown
                    const Text(
                      'Select Slot Time',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSlot,
                          isExpanded: true,
                          icon: const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                          items: slots.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSlot = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Patient Information Card
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Patient Information',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ChoiceChip(
                              label: const Text('Self', style: TextStyle(fontSize: 11)),
                              selected: _isForSelf,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              onSelected: (val) {
                                setState(() {
                                  _isForSelf = true;
                                  final u = context.read<AuthProvider>().user;
                                  if (u != null) {
                                    _patientNameController.text = u.name;
                                    _patientAgeController.text = u.age.toString();
                                    _patientMobileController.text = u.mobile;
                                    _patientSex = u.sex;
                                    _addressController.text = u.address;
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('Other', style: TextStyle(fontSize: 11)),
                              selected: !_isForSelf,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              onSelected: (val) {
                                setState(() {
                                  _isForSelf = false;
                                  _patientNameController.clear();
                                  _patientAgeController.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      controller: _patientNameController,
                      label: 'Patient Name *',
                      hint: 'Enter full name of patient',
                      prefixIcon: Icons.person_outline,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter patient name' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _patientAgeController,
                            label: 'Age *',
                            hint: 'e.g. 40',
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter age' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sex *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _patientSex,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _patientSex = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      controller: _patientMobileController,
                      label: 'Contact Mobile *',
                      hint: 'For SMS confirmation & phlebotomist call',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter mobile' : null,
                    ),

                    if (_visitType == VisitType.homeVisit) ...[
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _addressController,
                        label: 'Home Sample Collection Address *',
                        hint: 'Flat/House No, Building, Landmark, City & Pin Code',
                        prefixIcon: Icons.home_outlined,
                        maxLines: 2,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter address for home visit' : null,
                      ),
                      const SizedBox(height: 6),
                      // Quick Address Autofill Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            const Text('Quick Fill: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                            ActionChip(
                              label: const Text('My Profile Address', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              onPressed: () {
                                final u = context.read<AuthProvider>().user;
                                if (u != null && u.address.isNotEmpty) {
                                  setState(() => _addressController.text = u.address);
                                }
                              },
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              label: const Text('Kondhwa / Lullanagar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              onPressed: () {
                                setState(() => _addressController.text = AppStrings.branch1Address);
                              },
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              label: const Text('Parmar Pavan / Fakhri Hills', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              onPressed: () {
                                setState(() => _addressController.text = AppStrings.branch2Address);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _notesController,
                      label: 'Special Instructions / Clinical Notes (Optional)',
                      hint: 'e.g. Ring bell twice / Patient is bedridden / Morning fasting sample',
                      prefixIcon: Icons.notes_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Doctor Prescription Attachment Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _prescriptionUrl != null ? AppColors.success : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.description_outlined, color: Color(0xFF2563EB), size: 18),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Doctor\'s Prescription Slip (Optional)',
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      'Attach photo of prescription for lab doctor verification',
                                      style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_isUploadingPrescription)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                    SizedBox(width: 10),
                                    Text('Uploading prescription photo...', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            )
                          else if (_prescriptionUrl != null)
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _prescriptionUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '✅ Prescription Attached',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
                                      ),
                                      Text(
                                        'Lab team will verify against this slip',
                                        style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                                  tooltip: 'Remove prescription',
                                  onPressed: () => setState(() => _prescriptionUrl = null),
                                ),
                              ],
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: _pickPrescriptionPhoto,
                              icon: const Icon(Icons.add_a_photo_outlined, size: 16, color: AppColors.primary),
                              label: const Text(
                                'Attach Doctor Prescription (Camera / Gallery)',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 38),
                                side: const BorderSide(color: AppColors.primary, width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Payment Selection
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
                    const Text(
                      'Payment Method',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: 'Pay on Collection / Visit',
                      groupValue: _paymentOption,
                      activeColor: AppColors.primary,
                      title: const Text('Pay on Collection / Visit (Cash / UPI)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      subtitle: const Text('Pay visiting phlebotomist/technician directly upon sample collection', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      onChanged: (val) => setState(() => _paymentOption = val!),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: 'Pay Online (UPI QR Scanner)',
                      groupValue: _paymentOption,
                      activeColor: AppColors.primary,
                      title: const Row(
                        children: [
                          Expanded(
                            child: Text('Pay Online via UPI QR Scanner', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.qr_code_scanner_rounded, size: 16, color: AppColors.primary),
                        ],
                      ),
                      subtitle: const Text('Scan QR with GPay, PhonePe, Paytm, BHIM & enter UTR', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      onChanged: (val) => setState(() => _paymentOption = val!),
                    ),

                    // UPI QR Scanner & UTR Box
                    if (_paymentOption == 'Pay Online (UPI QR Scanner)') ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified PrecisionCare QR',
                                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // QR Image Frame
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/images/precisioncare_scanner.jpeg',
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Total Amount Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Amount to Pay: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                  Text(
                                    '₹${_totalAmount.toInt()}',
                                    style: const TextStyle(fontSize: 18, color: Color(0xFF15803D), fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            const Text(
                              'Accepted Apps: GPay • PhonePe • Paytm • BHIM • Amazon Pay',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF166534), fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 16),

                            // 12-Digit UTR Input
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CustomTextField(
                                controller: _utrController,
                                label: 'Enter 12-Digit UPI Transaction UTR / Ref No. *',
                                hint: 'e.g. 423871928391',
                                prefixIcon: Icons.receipt_long_rounded,
                                keyboardType: TextInputType.text,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Screenshot Upload (Optional)
                            GestureDetector(
                              onTap: _isUploadingProof ? null : _pickPaymentProof,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _paymentScreenshotUrl != null ? Icons.check_circle_rounded : Icons.add_photo_alternate_rounded,
                                      color: _paymentScreenshotUrl != null ? AppColors.success : AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _isUploadingProof
                                            ? 'Uploading receipt...'
                                            : _paymentScreenshotUrl != null
                                                ? 'Payment Screenshot Attached ✓'
                                                : 'Attach Payment Screenshot (Optional)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _paymentScreenshotUrl != null ? AppColors.success : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                     if (_paymentScreenshotUrl != null)
                                      GestureDetector(
                                        onTap: () {
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
                                                        const Text('Payment Proof Preview', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                                        IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(context)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(10),
                                                      child: Container(
                                                        constraints: const BoxConstraints(maxHeight: 300),
                                                        child: InteractiveViewer(
                                                          child: AppImageView(imageUrl: _paymentScreenshotUrl!, fit: BoxFit.contain),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            decoration: BoxDecoration(border: Border.all(color: AppColors.success, width: 1.5), borderRadius: BorderRadius.circular(6)),
                                            child: SizedBox(
                                              width: 32,
                                              height: 32,
                                              child: AppImageView(imageUrl: _paymentScreenshotUrl!),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Total & Submit
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Total Payable Amount:',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                        Text(
                          '₹${_totalAmount.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Confirm & Schedule Appointment',
                      isLoading: bookingProvider.isLoading,
                      backgroundColor: AppColors.accent,
                      onPressed: _handleConfirmBooking,
                      icon: Icons.check_circle_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
