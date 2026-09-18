import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/staff_model.dart';

class StaffService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<StaffMember> _defaultStaff = [
    const StaffMember(
      id: 'STAFF-001',
      name: 'Vikram Singh',
      role: 'Senior Phlebotomist',
      phone: '+91 98765 00123',
      specialization: 'Fasting Blood Sample, Pediatric & Geriatric Venipuncture',
      isActive: true,
      completedVisits: 142,
    ),
    const StaffMember(
      id: 'STAFF-002',
      name: 'Anita Sharma',
      role: 'Phlebotomist',
      phone: '+91 98765 00124',
      specialization: 'Routine Biochemistry & Preventive Health Panels',
      isActive: true,
      completedVisits: 98,
    ),
    const StaffMember(
      id: 'STAFF-003',
      name: 'Anil Gupta',
      role: 'Certified Radiographer',
      phone: '+91 98111 22334',
      specialization: 'Digital DR Chest, Spine & Orthopedic X-Ray at Home',
      isActive: true,
      completedVisits: 76,
    ),
    const StaffMember(
      id: 'STAFF-004',
      name: 'Sunita Mehra',
      role: 'Cardiac & ECG Technician',
      phone: '+91 98222 33445',
      specialization: '12-Lead Digital ECG & Holter Lead Placement',
      isActive: true,
      completedVisits: 115,
    ),
    const StaffMember(
      id: 'STAFF-005',
      name: 'Dr. Priya Nair (MPT)',
      role: 'Consultant Physiotherapist',
      phone: '+91 98333 44556',
      specialization: 'Post-Op Knee/Spine Rehab & Neuro Mobilization',
      isActive: true,
      completedVisits: 84,
    ),
    const StaffMember(
      id: 'STAFF-006',
      name: 'Dr. Rahul Saxena (BPT)',
      role: 'Consultant Physiotherapist',
      phone: '+91 98333 44557',
      specialization: 'Geriatric Mobility, Laser Therapy & Pain Management',
      isActive: true,
      completedVisits: 62,
    ),
  ];

  Stream<List<StaffMember>> streamStaffList() {
    return _firestore.collection('staff').snapshots().handleError((e) {
      debugPrint('Staff stream notice: $e');
    }).map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => StaffMember.fromMap(doc.data(), doc.id)).toList();
      }
      return _defaultStaff;
    });
  }

  Future<List<StaffMember>> getStaffList() async {
    try {
      final snapshot = await _firestore.collection('staff').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => StaffMember.fromMap(doc.data(), doc.id)).toList();
      }
    } catch (_) {}

    // Fallback local storage
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('cached_staff_list');
    if (jsonStr != null) {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((e) => StaffMember.fromMap(e)).toList();
    }

    return _defaultStaff;
  }

  Future<void> saveStaffMember(StaffMember staff) async {
    try {
      await _firestore.collection('staff').doc(staff.id).set(staff.toMap());
    } catch (_) {}

    final current = await getStaffList();
    final index = current.indexWhere((s) => s.id == staff.id);
    if (index >= 0) {
      current[index] = staff;
    } else {
      current.add(staff);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_staff_list', jsonEncode(current.map((s) => s.toMap()).toList()));
  }

  Future<void> deleteStaffMember(String id) async {
    try {
      await _firestore.collection('staff').doc(id).delete();
    } catch (_) {}

    final current = await getStaffList();
    current.removeWhere((s) => s.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_staff_list', jsonEncode(current.map((s) => s.toMap()).toList()));
  }
}
