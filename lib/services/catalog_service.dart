import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diagnostic_service.dart';

class CatalogService {
  FirebaseFirestore? _firestore;
  bool _isFirebaseAvailable = false;

  CatalogService() {
    try {
      _firestore = FirebaseFirestore.instance;
      _isFirebaseAvailable = true;
    } catch (_) {
      _isFirebaseAvailable = false;
    }
  }

  static final List<DiagnosticService> initialServices = [
    // 1. HEALTH PACKAGES & BLOOD TESTS
    const DiagnosticService(
      id: 'bt_full_body',
      title: 'Precision Full Body Health Checkup',
      categoryName: 'Health Packages',
      categoryId: 'cat_packages',
      category: ServiceCategory.healthPackage,
      description: 'Comprehensive 85+ parameters package covering Liver, Kidney, Lipid, Thyroid, HbA1c, CBC, Iron, Calcium & Vitamins.',
      price: 1499.0,
      originalPrice: 3499.0,
      preparation: '10-12 hours overnight fasting required. Water intake allowed.',
      sampleType: 'Blood (Serum & EDTA) & Urine',
      turnaroundTime: 'Report within 12 Hours',
      iconType: 'blood',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      badge: 'Most Popular',
      includedTests: [
        'Complete Blood Count (CBC + ESR)',
        'Complete Lipid Profile (Cholesterol, HDL, LDL, VLDL, Triglycerides)',
        'Liver Function Test (SGOT, SGPT, Bilirubin, Albumin, Globulin)',
        'Kidney Function Test (Creatinine, Urea, Uric Acid, BUN)',
        'Thyroid Profile (T3, T4, TSH)',
        'Diabetes Screen (HbA1c & Fasting Glucose)',
        'Vitamin D (25-OH) & Vitamin B12',
        'Calcium, Phosphorus & Electrolytes',
        'Urine Routine & Microscopic',
      ],
    ),
    const DiagnosticService(
      id: 'bt_cbc',
      title: 'Complete Blood Count (CBC + ESR)',
      categoryName: 'Blood Tests',
      categoryId: 'cat_blood',
      category: ServiceCategory.homeVisit,
      description: 'Measures red blood cells, white blood cells, hemoglobin, platelets, and ESR to assess overall health and detect infections/anemia.',
      price: 299.0,
      originalPrice: 450.0,
      preparation: 'No fasting required. Maintain normal hydration.',
      sampleType: 'Blood (EDTA Tube)',
      turnaroundTime: 'Report within 4 Hours',
      iconType: 'blood',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      badge: 'Essential',
      includedTests: [
        'Hemoglobin (Hb)',
        'Total Leukocyte Count (TLC/WBC)',
        'Differential Leukocyte Count (DLC)',
        'Platelet Count',
        'RBC Count & Indices (MCV, MCH, MCHC, RDW)',
        'Erythrocyte Sedimentation Rate (ESR)',
      ],
    ),
    const DiagnosticService(
      id: 'bt_diabetes',
      title: 'Diabetes Comprehensive Profile (HbA1c + Glucose)',
      categoryName: 'Blood Tests',
      categoryId: 'cat_blood',
      category: ServiceCategory.homeVisit,
      description: 'Evaluate 3-month average blood sugar control with HbA1c along with Fasting and Post-Prandial Plasma Glucose.',
      price: 499.0,
      originalPrice: 900.0,
      preparation: '10 hours fasting for Fasting sample, followed by 2 hours post-meal sample.',
      sampleType: 'Blood (EDTA & Fluoride)',
      turnaroundTime: 'Report within 6 Hours',
      iconType: 'blood',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      includedTests: [
        'HbA1c (Glycosylated Hemoglobin) by HPLC',
        'Estimated Average Glucose (eAG)',
        'Fasting Blood Sugar (FBS)',
        'Post-Prandial Blood Sugar (PPBS)',
      ],
    ),
    const DiagnosticService(
      id: 'bt_lipid',
      title: 'Advanced Lipid Profile (Cardiac Risk)',
      categoryName: 'Blood Tests',
      categoryId: 'cat_blood',
      category: ServiceCategory.homeVisit,
      description: 'Accurate measurement of cholesterol fractions to determine cardiovascular risk and arterial health.',
      price: 450.0,
      originalPrice: 800.0,
      preparation: 'Strict 12 hours overnight fasting mandatory.',
      sampleType: 'Blood (Serum Separator)',
      turnaroundTime: 'Report within 6 Hours',
      iconType: 'blood',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      includedTests: [
        'Total Cholesterol',
        'HDL (Good Cholesterol)',
        'LDL (Bad Cholesterol)',
        'VLDL & Triglycerides',
        'Cholesterol / HDL Ratio',
        'LDL / HDL Risk Ratio',
      ],
    ),
    const DiagnosticService(
      id: 'bt_thyroid',
      title: 'Thyroid Total Profile (T3, T4, Ultra TSH)',
      categoryName: 'Blood Tests',
      categoryId: 'cat_blood',
      category: ServiceCategory.homeVisit,
      description: 'Screening for hypothyroidism and hyperthyroidism with high sensitivity CLIA method.',
      price: 399.0,
      originalPrice: 750.0,
      preparation: 'Early morning fasting preferred. Avoid thyroid medication before sample collection.',
      sampleType: 'Blood (Serum)',
      turnaroundTime: 'Report within 6 Hours',
      iconType: 'blood',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      includedTests: [
        'Total Triiodothyronine (T3)',
        'Total Thyroxine (T4)',
        'Ultrasensitive Thyroid Stimulating Hormone (TSH)',
      ],
    ),

    // 2. DIGITAL X-RAY (ONLY X-RAY TESTS)
    const DiagnosticService(
      id: 'xr_chest_home',
      title: 'Home Visit Digital Chest X-Ray',
      categoryName: 'Digital X-Ray',
      categoryId: 'cat_xray',
      category: ServiceCategory.homeVisit,
      description: 'High-frequency portable DR digital chest X-ray performed in the comfort of your home. Ideal for elderly and bedridden patients.',
      price: 1299.0,
      originalPrice: 2000.0,
      preparation: 'Wear loose clothing without metal buttons, zippers, or necklaces.',
      sampleType: 'Digital Direct Radiography (DR)',
      turnaroundTime: 'Digital film + Radiologist Report in 3 Hours',
      iconType: 'xray',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      badge: 'Home Portable DR',
      includedTests: [
        'Chest PA / AP View Digital Radiograph',
        'Lung Parenchyma Assessment',
        'Cardiomegaly & Diaphragm Evaluation',
        'Senior Radiologist Verified Report',
        'High-Res DICOM & PDF Delivery',
      ],
    ),
    const DiagnosticService(
      id: 'xr_spine_home',
      title: 'Digital Spine X-Ray (Cervical / Lumbar)',
      categoryName: 'Digital X-Ray',
      categoryId: 'cat_xray',
      category: ServiceCategory.homeVisit,
      description: 'Targeted digital radiography for spine degenerative changes, arthritis, fractures, and bone alignment.',
      price: 1399.0,
      originalPrice: 2200.0,
      preparation: 'Remove belts, metallic jewelry, or restrictive clothing.',
      sampleType: 'Digital Direct Radiography (DR)',
      turnaroundTime: 'Report in 4 Hours',
      iconType: 'xray',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      includedTests: [
        'AP & Lateral Views (2 Views)',
        'Vertebral Alignment & Disc Space Analysis',
        'Osteophyte / Degenerative Evaluation',
        'Digital High-Res Image Access',
      ],
    ),
    const DiagnosticService(
      id: 'xr_knee_bilateral',
      title: 'Digital X-Ray Both Knee Joints (AP & Lat)',
      categoryName: 'Digital X-Ray',
      categoryId: 'cat_xray',
      category: ServiceCategory.inHouseDiagnostic,
      description: 'Standing weight-bearing bilateral knee radiography to assess joint space narrowing, osteoarthritis, and cartilage health.',
      price: 999.0,
      originalPrice: 1600.0,
      preparation: 'Wear loose pants or shorts that can be rolled above knees.',
      sampleType: 'Digital Radiography (Weight-bearing)',
      turnaroundTime: 'Digital Film & Report in 2 Hours',
      iconType: 'xray',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      badge: 'Orthopedic Choice',
      includedTests: [
        'Bilateral Standing AP View',
        'Lateral Flexion Views',
        'Tibiofemoral & Patellofemoral Joint Assessment',
        'Radiologist Joint Staging',
      ],
    ),
    const DiagnosticService(
      id: 'xr_pelvis_hip',
      title: 'Pelvis with Both Hip Joints X-Ray (AP View)',
      categoryName: 'Digital X-Ray',
      categoryId: 'cat_xray',
      category: ServiceCategory.inHouseDiagnostic,
      description: 'Evaluation of hip joints, sacroiliac joints, acetabulum, and pelvic brim for avascular necrosis, fractures, or arthritis.',
      price: 899.0,
      originalPrice: 1400.0,
      preparation: 'Remove garments containing metal hooks, zippers, or pins.',
      sampleType: 'Direct Digital Radiography (DR)',
      turnaroundTime: 'Report in 3 Hours',
      iconType: 'xray',
      isHomeVisitAvailable: false,
      isInHouseAvailable: true,
      includedTests: [
        'Pelvis AP True View',
        'Femoral Head & Neck Sphericity Check',
        'Sacroiliac (SI) Joint Alignment',
      ],
    ),
    const DiagnosticService(
      id: 'xr_pns_sinus',
      title: 'PNS Digital X-Ray (Water\'s View)',
      categoryName: 'Digital X-Ray',
      categoryId: 'cat_xray',
      category: ServiceCategory.inHouseDiagnostic,
      description: 'Specialized view for sinusitis, nasal septum deviation, mucosal thickening, and fluid level in maxillary sinuses.',
      price: 750.0,
      originalPrice: 1200.0,
      preparation: 'Remove spectacles, earrings, dentures, and hairpins.',
      sampleType: 'Digital Radiography (Occipitomental)',
      turnaroundTime: 'Report in 2 Hours',
      iconType: 'xray',
      isHomeVisitAvailable: false,
      isInHouseAvailable: true,
      includedTests: [
        'Water\'s View (Occipito-Mental)',
        'Maxillary, Frontal & Ethmoid Sinus Clearness',
        'Nasal Septum & Turbinate Assessment',
      ],
    ),

    // 3. ECG & CARDIOLOGY
    const DiagnosticService(
      id: 'ecg_home',
      title: 'Home Visit 12-Lead Digital ECG',
      categoryName: 'ECG & Cardiology',
      categoryId: 'cat_ecg',
      category: ServiceCategory.homeVisit,
      description: 'Immediate 12-lead cardiac electrocardiogram at home with digital tracing sent to cardiologists for rapid evaluation.',
      price: 599.0,
      originalPrice: 1000.0,
      preparation: 'Wear easy to open upper garments. Stay relaxed 5 mins prior to recording.',
      sampleType: '12-Lead Electrocardiography Tracing',
      turnaroundTime: 'Instant Result Tracing + MD Cardiologist Sign-off in 2 Hours',
      iconType: 'ecg',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      badge: 'Instant Tracing',
      includedTests: [
        'Standard 12-Lead Cardiac Rhythm Tracing',
        'Heart Rate & Rhythm Analysis (Sinus, Arrhythmia, Bradycardia)',
        'ST-T Segment & Ischemia Screen',
        'PR, QRS, QT/QTc Interval Calculation',
        'Cardiologist Summary and Risk Staging',
      ],
    ),
    const DiagnosticService(
      id: 'stress_test_tmt',
      title: 'Cardiac Stress Test (TMT / Treadmill Test)',
      categoryName: 'ECG & Cardiology',
      categoryId: 'cat_ecg',
      category: ServiceCategory.inHouseDiagnostic,
      description: 'Continuous 12-lead ECG and BP monitored Treadmill Exercise Stress Test (Bruce Protocol) to detect occult coronary artery disease.',
      price: 1899.0,
      originalPrice: 2800.0,
      preparation: 'Light meal 2-3 hours prior. Wear sports shoes and comfortable athletic clothing. Bring previous ECGs.',
      sampleType: 'Bruce Protocol Motorized Treadmill Exercise',
      turnaroundTime: 'Immediate Report with Cardiologist Consultation',
      iconType: 'stress_test',
      isHomeVisitAvailable: false,
      isInHouseAvailable: true,
      badge: 'Cardiologist Supervised',
      includedTests: [
        'Multi-stage Bruce Protocol Exercise Monitoring',
        'Continuous 12-Lead ST-T Ischemia Recording',
        'Blood Pressure & METs (Metabolic Equivalents) Tracking',
        'Target Heart Rate Achieved % Calculation',
        'Recovery Phase ECG & Arrhythmia Monitoring',
        'Comprehensive Senior Cardiologist Consultation',
      ],
    ),
    const DiagnosticService(
      id: 'echo_2d',
      title: '2D Echocardiography with Color Doppler',
      categoryName: 'ECG & Cardiology',
      categoryId: 'cat_ecg',
      category: ServiceCategory.inHouseDiagnostic,
      description: 'Ultrasound visualization of heart chambers, valves, ejection fraction (EF), and myocardial wall motion.',
      price: 2199.0,
      originalPrice: 3200.0,
      preparation: 'No fasting required. Bring previous prescriptions and ECG reports.',
      sampleType: 'Echocardiographic Doppler Imaging',
      turnaroundTime: 'Report in 2 Hours',
      iconType: 'ecg',
      isHomeVisitAvailable: false,
      isInHouseAvailable: true,
      badge: 'Advanced Cardiac',
      includedTests: [
        'Left Ventricular Ejection Fraction (LVEF)',
        'Valvular Regurgitation & Stenosis Assessment',
        'Color Doppler Flow & Pulmonary Artery Pressure',
        'Chamber Dimensions & Wall Motion Analysis',
      ],
    ),

    // 4. ULTRASOUND (USG)
    const DiagnosticService(
      id: 'usg_abdomen',
      title: 'Ultrasound Whole Abdomen & Pelvis',
      categoryName: 'Ultrasound (USG)',
      categoryId: 'cat_usg',
      category: ServiceCategory.inHouseDiagnostic,
      description: 'High-resolution sonography of Liver, Gallbladder, Pancreas, Spleen, Kidneys, Urinary Bladder, and Pelvic organs.',
      price: 1450.0,
      originalPrice: 2200.0,
      preparation: '4-6 hours fasting for upper abdomen. Full bladder (drink 1L water 1 hour prior).',
      sampleType: 'High-Resolution 4D Ultrasound',
      turnaroundTime: 'Same Day with Radiologist Consultation',
      iconType: 'usg',
      isHomeVisitAvailable: false,
      isInHouseAvailable: true,
      badge: 'High-Res 4D',
      includedTests: [
        'Liver & Biliary Tree Assessment (Fatty Liver / Stones)',
        'Kidney, Ureter & Bladder (KUB) Calculus Screen',
        'Pancreas & Spleen Morphology',
        'Prostate / Uterus & Adnexa Evaluation',
      ],
    ),

    // 5. PFT TEST
    const DiagnosticService(
      id: 'pft_inhouse',
      title: 'In-House PFT Test (Computerized Spirometry)',
      categoryName: 'PFT (Lung Test)',
      categoryId: 'cat_pft',
      category: ServiceCategory.inHouseDiagnostic,
      description: 'Gold standard computerized lung capacity test measuring FVC, FEV1, FEF25-75% for Asthma, COPD, and post-Covid pulmonary evaluation.',
      price: 1199.0,
      originalPrice: 1800.0,
      preparation: 'Avoid heavy meals 2 hours before. Avoid inhalers/bronchodilators 4-6 hours prior if advised by doctor.',
      sampleType: 'Computerized Flow-Volume Spirometry',
      turnaroundTime: 'Immediate Graph + Pulmonologist Report in 2 Hours',
      iconType: 'pft',
      isHomeVisitAvailable: false,
      isInHouseAvailable: true,
      badge: 'In-House Tech',
      includedTests: [
        'Forced Vital Capacity (FVC)',
        'Forced Expiratory Volume in 1 sec (FEV1)',
        'FEV1 / FVC Ratio Analysis',
        'Peak Expiratory Flow Rate (PEFR)',
        'Pre & Post Bronchodilator Reversibility Test',
        'Flow-Volume Loops & Pulmonology Interpretation',
      ],
    ),

    // 6. PHYSIOTHERAPY
    const DiagnosticService(
      id: 'physio_home_ortho',
      title: 'Home Visit Orthopedic & Post-Op Physiotherapy',
      categoryName: 'Physiotherapy',
      categoryId: 'cat_physio',
      category: ServiceCategory.physiotherapy,
      description: 'Certified physiotherapist home visit for knee/hip replacement rehab, fracture recovery, arthritis, and joint mobilization.',
      price: 899.0,
      originalPrice: 1400.0,
      preparation: 'Wear comfortable stretchable clothing. Have your discharge summary / prescription ready.',
      sampleType: '45-Min 1-on-1 Physiotherapy Session',
      turnaroundTime: 'Same Day Session',
      iconType: 'physio',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      badge: 'Certified Physio',
      includedTests: [
        'Comprehensive Range of Motion (ROM) Assessment',
        'Targeted Joint Mobilization & Passive/Active Stretching',
        'Portable TENS & Ultrasound Pain Relief Treatment',
        'Isometric & Isotonic Muscle Strengthening Routine',
        'Gait Training & Ergonomics Guidance',
      ],
    ),
    const DiagnosticService(
      id: 'physio_home_neuro',
      title: 'Home Visit Neuro & Geriatric Mobility Physiotherapy',
      categoryName: 'Physiotherapy',
      categoryId: 'cat_physio',
      category: ServiceCategory.physiotherapy,
      description: 'Specialized home rehabilitation for stroke recovery, Parkinson’s mobility, spinal cord injury, and fall prevention in seniors.',
      price: 999.0,
      originalPrice: 1600.0,
      preparation: 'Ensure a quiet, safe, well-lit room with sturdy chair or bed.',
      sampleType: '50-Min Specialized Neurological Session',
      turnaroundTime: 'Scheduled Slot',
      iconType: 'physio',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      includedTests: [
        'Neurological Tone & Reflex Evaluation',
        'Neuro-Developmental Technique (NDT/Bobath)',
        'Balance, Proprioception & Coordination Drills',
        'Bed Mobility & Transfer Independence Training',
        'Caregiver Support & Ergonomic Counseling',
      ],
    ),
    const DiagnosticService(
      id: 'physio_inhouse_setup',
      title: 'Complete In-House Physiotherapy & Advanced Rehab Setup',
      categoryName: 'Physiotherapy',
      categoryId: 'cat_physio',
      category: ServiceCategory.physiotherapy,
      description: 'Access full clinical physiotherapy infrastructure: Interferential Therapy (IFT), Ultrasonic Therapy, Class 4 Deep Laser, Cervical/Lumbar Decompression Traction, and Resistance Gym.',
      price: 799.0,
      originalPrice: 1200.0,
      preparation: 'Wear active gym wear. Arrive 10 minutes before your slot.',
      sampleType: 'Clinical Physiotherapy Suite Session',
      turnaroundTime: '60 Min Full Modality Session',
      iconType: 'physio',
      isHomeVisitAvailable: false,
      isInHouseAvailable: true,
      badge: 'Full Equipment Suite',
      includedTests: [
        'Interferential Current Therapy (IFT) & TENS',
        'Therapeutic Ultrasound (1 & 3 MHz)',
        'Computerized Spinal Decompression Traction Unit',
        'Deep Tissue Matrix & Laser Therapy',
        'Theraband, Swiss Ball & Resistance Core Strengthening',
        'Posture & Gait Ergonomics Correction',
      ],
    ),
  ];

  static List<DiagnosticService> _cachedServices = List.from(initialServices);

  /// Real-time stream of all diagnostic services for Patient App and Admin Portal
  Stream<List<DiagnosticService>> streamServices() {
    if (_isFirebaseAvailable && _firestore != null) {
      return _firestore!.collection('catalog').snapshots().handleError((e) {
        debugPrint('Catalog stream notice: $e');
      }).map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final list = snapshot.docs.map((doc) => DiagnosticService.fromMap(doc.data(), doc.id)).toList();
          _cachedServices = list;
          _saveServicesLocally(list);
          return list;
        } else {
          _seedDefaultServices();
          return _cachedServices;
        }
      });
    }
    return Stream.value(_cachedServices);
  }

  /// Get all services (from Firestore or local cache / defaults)
  Future<List<DiagnosticService>> getAllServices() async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final snapshot = await _firestore!.collection('catalog').get();
        if (snapshot.docs.isNotEmpty) {
          final list = snapshot.docs.map((doc) => DiagnosticService.fromMap(doc.data(), doc.id)).toList();
          _cachedServices = list;
          await _saveServicesLocally(list);
          return list;
        } else {
          await _seedDefaultServices();
          return _cachedServices;
        }
      } catch (_) {}
    }

    final local = await _getLocalServices();
    if (local.isNotEmpty) {
      _cachedServices = local;
      return local;
    }

    return _cachedServices;
  }

  /// Save / update diagnostic service in Firestore and local cache
  Future<void> saveService(DiagnosticService service) async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('catalog').doc(service.id).set(service.toMap());
      } catch (_) {}
    }

    final current = List<DiagnosticService>.from(_cachedServices);
    final index = current.indexWhere((s) => s.id == service.id);
    if (index >= 0) {
      current[index] = service;
    } else {
      current.insert(0, service);
    }
    _cachedServices = current;
    await _saveServicesLocally(current);
  }

  /// Delete diagnostic service from Firestore and local cache
  Future<void> deleteService(String id) async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('catalog').doc(id).delete();
      } catch (_) {}
    }

    final current = List<DiagnosticService>.from(_cachedServices);
    current.removeWhere((s) => s.id == id);
    _cachedServices = current;
    await _saveServicesLocally(current);
  }

  Future<void> _seedDefaultServices() async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final batch = _firestore!.batch();
        for (final s in initialServices) {
          final docRef = _firestore!.collection('catalog').doc(s.id);
          batch.set(docRef, s.toMap());
        }
        await batch.commit();
      } catch (_) {}
    }
    _cachedServices = List.from(initialServices);
    await _saveServicesLocally(_cachedServices);
  }

  Future<void> _saveServicesLocally(List<DiagnosticService> services) async {
    final prefs = await SharedPreferences.getInstance();
    final data = services.map((s) => s.toMap()..['id'] = s.id).toList();
    await prefs.setString('cached_catalog_services', jsonEncode(data));
  }

  Future<List<DiagnosticService>> _getLocalServices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cached_catalog_services');
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => DiagnosticService.fromMap(Map<String, dynamic>.from(e), e['id'] ?? '')).toList();
    } catch (_) {
      return [];
    }
  }

  // Static helpers for quick sync access
  static List<DiagnosticService> get currentServices => _cachedServices;
  static List<DiagnosticService> getHomeVisitServices() => _cachedServices.where((s) => s.isHomeVisitAvailable).toList();
  static List<DiagnosticService> getInHouseServices() => _cachedServices.where((s) => s.isInHouseAvailable).toList();
  static List<DiagnosticService> getPhysioServices() => _cachedServices.where((s) => s.category == ServiceCategory.physiotherapy).toList();

  static DiagnosticService? getServiceById(String id) {
    try {
      return _cachedServices.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
