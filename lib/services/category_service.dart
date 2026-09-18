import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diagnostic_category.dart';

class CategoryService {
  FirebaseFirestore? _firestore;
  bool _isFirebaseAvailable = false;

  CategoryService() {
    try {
      _firestore = FirebaseFirestore.instance;
      _isFirebaseAvailable = true;
    } catch (_) {
      _isFirebaseAvailable = false;
    }
  }

  static final List<DiagnosticCategory> defaultCategories = [
    const DiagnosticCategory(
      id: 'cat_xray',
      name: 'Digital X-Ray',
      description: 'High-frequency portable DR digital radiography at home & centre',
      iconType: 'xray',
      badge: 'Portable DR',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      sortOrder: 1,
    ),
    const DiagnosticCategory(
      id: 'cat_blood',
      name: 'Blood Tests',
      description: 'NABL certified biochemistry, hematology, lipid & thyroid profiles',
      iconType: 'blood',
      badge: '60 Min Dispatch',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      sortOrder: 2,
    ),
    const DiagnosticCategory(
      id: 'cat_ecg',
      name: 'ECG & Cardiology',
      description: '12-lead digital ECG, 2D Echo Doppler & treadmill stress test (TMT)',
      iconType: 'ecg',
      badge: 'MD Signed',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      sortOrder: 3,
    ),
    const DiagnosticCategory(
      id: 'cat_usg',
      name: 'Ultrasound (USG)',
      description: 'High-resolution sonography of abdomen, pelvis & organ morphology',
      iconType: 'usg',
      badge: 'Radiologist Verified',
      isHomeVisitAvailable: false,
      isInHouseAvailable: true,
      sortOrder: 4,
    ),
    const DiagnosticCategory(
      id: 'cat_pft',
      name: 'PFT (Lung Test)',
      description: 'Computerized flow-volume spirometry for Asthma & COPD screening',
      iconType: 'pft',
      badge: 'Spirometry',
      isHomeVisitAvailable: false,
      isInHouseAvailable: true,
      sortOrder: 5,
    ),
    const DiagnosticCategory(
      id: 'cat_physio',
      name: 'Physiotherapy',
      description: 'Certified orthopedic, neurological rehabilitation & clinical modalities',
      iconType: 'physio',
      badge: '1-on-1 Care',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      sortOrder: 6,
    ),
    const DiagnosticCategory(
      id: 'cat_packages',
      name: 'Health Packages',
      description: 'Comprehensive 85+ parameter preventive health checkup packages',
      iconType: 'package',
      badge: 'Best Value',
      isHomeVisitAvailable: true,
      isInHouseAvailable: true,
      sortOrder: 7,
    ),
  ];

  static List<DiagnosticCategory> _cachedCategories = List.from(defaultCategories);

  Stream<List<DiagnosticCategory>> streamCategories() {
    if (_isFirebaseAvailable && _firestore != null) {
      return _firestore!
          .collection('categories')
          .orderBy('sortOrder')
          .snapshots()
          .handleError((e) {
        debugPrint('Categories stream notice: $e');
      }).map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final list = snapshot.docs
              .map((doc) => DiagnosticCategory.fromMap(doc.data(), doc.id))
              .toList();
          _cachedCategories = list;
          _saveLocally(list);
          return list;
        } else {
          _seedDefaultCategories();
          return _cachedCategories;
        }
      });
    }
    return Stream.value(_cachedCategories);
  }

  Future<List<DiagnosticCategory>> getAllCategories() async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final snapshot = await _firestore!
            .collection('categories')
            .orderBy('sortOrder')
            .get();
        if (snapshot.docs.isNotEmpty) {
          final list = snapshot.docs
              .map((doc) => DiagnosticCategory.fromMap(doc.data(), doc.id))
              .toList();
          _cachedCategories = list;
          await _saveLocally(list);
          return list;
        } else {
          await _seedDefaultCategories();
          return _cachedCategories;
        }
      } catch (_) {}
    }

    final local = await _getLocalCategories();
    if (local.isNotEmpty) {
      _cachedCategories = local;
      return local;
    }

    return _cachedCategories;
  }

  Future<void> saveCategory(DiagnosticCategory category) async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!
            .collection('categories')
            .doc(category.id)
            .set(category.toMap());
      } catch (_) {}
    }

    final current = List<DiagnosticCategory>.from(_cachedCategories);
    final idx = current.indexWhere((c) => c.id == category.id);
    if (idx >= 0) {
      current[idx] = category;
    } else {
      current.add(category);
    }
    current.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _cachedCategories = current;
    await _saveLocally(current);
  }

  Future<void> deleteCategory(String categoryId) async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('categories').doc(categoryId).delete();
      } catch (_) {}
    }

    final current = List<DiagnosticCategory>.from(_cachedCategories);
    current.removeWhere((c) => c.id == categoryId);
    _cachedCategories = current;
    await _saveLocally(current);
  }

  Future<void> _seedDefaultCategories() async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final batch = _firestore!.batch();
        for (final c in defaultCategories) {
          final doc = _firestore!.collection('categories').doc(c.id);
          batch.set(doc, c.toMap());
        }
        await batch.commit();
      } catch (_) {}
    }
    _cachedCategories = List.from(defaultCategories);
    await _saveLocally(_cachedCategories);
  }

  Future<void> _saveLocally(List<DiagnosticCategory> list) async {
    final prefs = await SharedPreferences.getInstance();
    final data = list.map((c) => c.toMap()..['id'] = c.id).toList();
    await prefs.setString('cached_categories', jsonEncode(data));
  }

  Future<List<DiagnosticCategory>> _getLocalCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cached_categories');
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => DiagnosticCategory.fromMap(
              Map<String, dynamic>.from(e), e['id'] ?? ''))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static List<DiagnosticCategory> get currentCategories => _cachedCategories;
}
