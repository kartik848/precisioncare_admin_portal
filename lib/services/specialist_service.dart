import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/specialist.dart';

class SpecialistService {
  static const _collection = 'specialists';
  FirebaseFirestore? _firestore;

  SpecialistService() {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (_) {
      _firestore = null;
    }
  }

  /// The doctors the home showed before this was admin-managed; used until the admin adds their own.
  static const defaults = [
    Specialist(id: 'spec_pathologist', name: 'Clinical Pathologist', specialty: 'Blood & Lab Tests', badge: 'NABL ACCREDITED',
        imageUrl: 'assets/images/3d/doc_pathologist.jpg', categoryTarget: 'Blood Tests', sortOrder: 0),
    Specialist(id: 'spec_cardiologist', name: 'Senior Cardiologist', specialty: 'ECG, TMT & Heart', badge: 'INSTANT REPORT',
        imageUrl: 'assets/images/3d/doc_cardiologist.jpg', categoryTarget: 'ECG & Cardiology', sortOrder: 1),
    Specialist(id: 'spec_physician', name: 'General Physician', specialty: 'Full Body Prevention', badge: '80+ PARAMETERS',
        imageUrl: 'assets/images/3d/doctor_mascot.jpg', categoryTarget: 'Health Packages', sortOrder: 2),
    Specialist(id: 'spec_radiologist', name: 'Consultant Radiologist', specialty: 'Digital X-Ray & PFT', badge: 'CHEST & LUNGS',
        imageUrl: 'assets/images/3d/female_doctor.jpg', categoryTarget: 'Digital X-Ray', sortOrder: 3),
    Specialist(id: 'spec_physio', name: 'Senior Physiotherapist', specialty: 'Ortho & Rehab Therapy', badge: '1-ON-1 SESSIONS',
        imageUrl: 'assets/images/3d/call_helpline.jpg', categoryTarget: 'Physiotherapy', sortOrder: 4),
  ];

  Stream<List<Specialist>> streamSpecialists() {
    final fs = _firestore;
    if (fs == null) return Stream.value(const []);
    return fs.collection(_collection).snapshots().handleError((e) {
      debugPrint('Specialist stream notice: $e');
    }).map((snap) {
      final list = snap.docs.map((d) => Specialist.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  Future<void> save(Specialist s) async => _firestore?.collection(_collection).doc(s.id).set(s.toMap());

  Future<void> delete(String id) async => _firestore?.collection(_collection).doc(id).delete();
}
