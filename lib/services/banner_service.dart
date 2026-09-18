import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/promo_banner.dart';

class BannerService {
  FirebaseFirestore? _firestore;
  bool _isFirebaseAvailable = false;

  BannerService() {
    try {
      _firestore = FirebaseFirestore.instance;
      _isFirebaseAvailable = true;
    } catch (_) {
      _isFirebaseAvailable = false;
    }
  }

  final List<PromoBanner> _defaultBanners = [
    const PromoBanner(
      id: 'BANNER-001',
      title: 'Free Home Sample Collection',
      subtitle: 'Flat 20% OFF on Full Body Master Checkup (85+ Tests)',
      badge: 'POPULAR OFFER',
      actionText: 'Book Blood Test',
      categoryTarget: 'blood',
    ),
    const PromoBanner(
      id: 'BANNER-002',
      title: 'Digital X-Ray & 12-Lead ECG at Home',
      subtitle: 'Certified Radiographers & Instant MD Cardiologist Reports',
      badge: 'HOME CARE',
      actionText: 'Schedule Home Visit',
      categoryTarget: 'xray',
    ),
    const PromoBanner(
      id: 'BANNER-003',
      title: 'Advanced PFT & Physiotherapy Suite',
      subtitle: 'Computerized Spirometry & Complete Laser/IFT Setup at Centre',
      badge: 'IN-HOUSE CENTRE',
      actionText: 'Explore Packages',
      categoryTarget: 'pft',
    ),
  ];

  Stream<List<PromoBanner>> streamBanners() {
    if (_isFirebaseAvailable && _firestore != null) {
      return _firestore!.collection('banners').snapshots().handleError((e) {
        debugPrint('Banner stream notice: $e');
      }).map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) => PromoBanner.fromMap(doc.data(), doc.id)).toList();
        }
        return _defaultBanners;
      });
    }
    return Stream.value(_defaultBanners);
  }

  Future<List<PromoBanner>> getBanners() async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final snapshot = await _firestore!.collection('banners').get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) => PromoBanner.fromMap(doc.data(), doc.id)).toList();
        }
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('cached_banners_list');
    if (jsonStr != null) {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => PromoBanner.fromMap(e)).toList();
    }

    return _defaultBanners;
  }

  Future<void> saveBanner(PromoBanner banner) async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('banners').doc(banner.id).set(banner.toMap());
      } catch (_) {}
    }

    final current = await getBanners();
    final index = current.indexWhere((b) => b.id == banner.id);
    if (index >= 0) {
      current[index] = banner;
    } else {
      current.add(banner);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_banners_list', jsonEncode(current.map((b) => b.toMap()).toList()));
  }

  Future<void> deleteBanner(String id) async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('banners').doc(id).delete();
      } catch (_) {}
    }

    final current = await getBanners();
    current.removeWhere((b) => b.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_banners_list', jsonEncode(current.map((b) => b.toMap()).toList()));
  }
}
