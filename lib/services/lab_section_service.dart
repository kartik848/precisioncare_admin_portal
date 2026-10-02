import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lab_section.dart';

class LabSectionService {
  static const _collection = 'lab_audiences';
  FirebaseFirestore? _firestore;

  LabSectionService() {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (_) {
      _firestore = null;
    }
  }

  /// Starter tree the admin can seed with one tap, then add photos and items to.
  static List<LabAudience> get starterSections {
    LabSubcategory sub(String id, String name, {int? min, int? max}) =>
        LabSubcategory(id: id, name: name, minAge: min, maxAge: max);
    return [
      LabAudience(
        id: 'aud_women',
        name: 'For Women',
        gender: 'Female',
        minAge: 15,
        sortOrder: 0,
        subcategories: [
          sub('sub_women_adult', 'Adult Women', min: 15, max: 45),
          sub('sub_women_senior', 'Senior Women', min: 46),
          sub('sub_women_fitness', 'Fitness'),
        ],
      ),
      LabAudience(
        id: 'aud_men',
        name: 'For Men',
        gender: 'Male',
        minAge: 15,
        sortOrder: 1,
        subcategories: [
          sub('sub_men_adult', 'Adult Men', min: 15, max: 45),
          sub('sub_men_senior', 'Senior Men', min: 46),
          sub('sub_men_fitness', 'Fitness'),
        ],
      ),
      LabAudience(
        id: 'aud_children',
        name: 'For Children',
        maxAge: 14,
        sortOrder: 2,
        subcategories: [
          sub('sub_kids_fullbody', 'Full Body Checkup'),
          sub('sub_kids_growth', 'Growth & Nutrition'),
          sub('sub_kids_allergy', 'Allergy & Infection'),
        ],
      ),
      LabAudience(
        id: 'aud_seniors',
        name: 'For Seniors',
        minAge: 60,
        sortOrder: 3,
        subcategories: [
          sub('sub_senior_heart', 'Heart Health'),
          sub('sub_senior_diabetes', 'Diabetes Care'),
          sub('sub_senior_bone', 'Bone & Joint'),
        ],
      ),
    ];
  }

  Stream<List<LabAudience>> streamAudiences() {
    final fs = _firestore;
    if (fs == null) return Stream.value(const []);
    return fs.collection(_collection).snapshots().handleError((e) {
      debugPrint('Lab section stream notice: $e');
    }).map((snap) {
      final list = snap.docs.map((d) => LabAudience.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  Future<void> saveAudience(LabAudience audience) async {
    await _firestore?.collection(_collection).doc(audience.id).set(audience.toMap());
  }

  Future<void> deleteAudience(String id) async {
    await _firestore?.collection(_collection).doc(id).delete();
  }
}
