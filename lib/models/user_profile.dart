import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDateTime(dynamic val) {
  if (val == null) return DateTime.now();
  if (val is Timestamp) return val.toDate();
  if (val is DateTime) return val;
  if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
  if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
  return DateTime.now();
}

DateTime? _parseNullableDateTime(dynamic val) {
  if (val == null) return null;
  if (val is Timestamp) return val.toDate();
  if (val is DateTime) return val;
  if (val is String) return DateTime.tryParse(val);
  if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
  return null;
}

class UserProfile {
  final String uid;
  final String name;
  final int age;
  final String sex; // 'Male', 'Female', 'Other'
  final DateTime? dob;
  final String address;
  final String mobile;
  final String email;
  final String? profileImageUrl;
  final bool isBlocked;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.age,
    required this.sex,
    this.dob,
    required this.address,
    required this.mobile,
    required this.email,
    this.profileImageUrl,
    this.isBlocked = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      uid: id,
      name: map['name'] ?? '',
      age: map['age'] is int ? map['age'] : int.tryParse(map['age']?.toString() ?? '0') ?? 0,
      sex: map['sex'] ?? 'Male',
      dob: _parseNullableDateTime(map['dob']),
      address: map['address'] ?? '',
      mobile: map['mobile'] ?? '',
      email: map['email'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      isBlocked: map['isBlocked'] ?? false,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'sex': sex,
      'dob': dob?.toIso8601String(),
      'address': address,
      'mobile': mobile,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'isBlocked': isBlocked,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    int? age,
    String? sex,
    DateTime? dob,
    String? address,
    String? mobile,
    String? email,
    String? profileImageUrl,
    bool? isBlocked,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
