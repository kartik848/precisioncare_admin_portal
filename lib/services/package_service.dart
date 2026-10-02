import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_package.dart';

class PackageService {
  static const _cacheKey = 'cached_health_packages';
  FirebaseFirestore? _firestore;

  PackageService() {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (_) {
      _firestore = null;
    }
  }

  Stream<List<HealthPackage>> streamPackages() {
    final fs = _firestore;
    if (fs == null) return Stream.value(const []);
    return fs.collection('packages').snapshots().handleError((e) {
      debugPrint('Package stream notice: $e');
    }).map((snap) => snap.docs.map((d) => HealthPackage.fromMap(d.data(), d.id)).toList());
  }

  Future<List<HealthPackage>> getPackages() async {
    final fs = _firestore;
    if (fs != null) {
      try {
        final snap = await fs.collection('packages').get();
        return snap.docs.map((d) => HealthPackage.fromMap(d.data(), d.id)).toList();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => HealthPackage.fromMap(e)).toList();
  }

  Future<void> _cache(List<HealthPackage> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(list.map((p) => p.toMap()).toList()));
  }

  Future<void> savePackage(HealthPackage pkg) async {
    try {
      await _firestore?.collection('packages').doc(pkg.id).set(pkg.toMap());
    } catch (_) {}
    final current = await getPackages();
    final i = current.indexWhere((p) => p.id == pkg.id);
    i >= 0 ? current[i] = pkg : current.add(pkg);
    await _cache(current);
  }

  Future<void> deletePackage(String id) async {
    try {
      await _firestore?.collection('packages').doc(id).delete();
    } catch (_) {}
    final current = await getPackages()..removeWhere((p) => p.id == id);
    await _cache(current);
  }
}
