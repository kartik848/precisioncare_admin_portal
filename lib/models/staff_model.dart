class StaffMember {
  final String id;
  final String name;
  final String role; // 'Phlebotomist', 'Radiographer', 'ECG Technician', 'Physiotherapist', 'Lab Officer'
  final String phone;
  final String specialization;
  final bool isActive;
  final int completedVisits;

  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.specialization,
    this.isActive = true,
    this.completedVisits = 0,
  });

  StaffMember copyWith({
    String? id,
    String? name,
    String? role,
    String? phone,
    String? specialization,
    bool? isActive,
    int? completedVisits,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      isActive: isActive ?? this.isActive,
      completedVisits: completedVisits ?? this.completedVisits,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'phone': phone,
      'specialization': specialization,
      'isActive': isActive,
      'completedVisits': completedVisits,
    };
  }

  factory StaffMember.fromMap(Map<String, dynamic> map, [String? id]) {
    return StaffMember(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'Phlebotomist',
      phone: map['phone'] ?? '',
      specialization: map['specialization'] ?? 'Home Visit & Diagnostics',
      isActive: map['isActive'] ?? true,
      completedVisits: map['completedVisits'] ?? 0,
    );
  }
}
