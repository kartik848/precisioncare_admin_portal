import 'package:flutter/material.dart';

class DiagnosticCategory {
  final String id;
  final String name;
  final String description;
  final String iconType;
  final String badge;
  final bool isHomeVisitAvailable;
  final bool isInHouseAvailable;
  final int sortOrder;

  const DiagnosticCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.iconType = 'blood',
    this.badge = '',
    this.isHomeVisitAvailable = true,
    this.isInHouseAvailable = true,
    this.sortOrder = 0,
  });

  factory DiagnosticCategory.fromMap(Map<String, dynamic> map, String id) {
    return DiagnosticCategory(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconType: map['iconType'] ?? 'blood',
      badge: map['badge'] ?? '',
      isHomeVisitAvailable: map['isHomeVisitAvailable'] ?? true,
      isInHouseAvailable: map['isInHouseAvailable'] ?? true,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconType': iconType,
      'badge': badge,
      'isHomeVisitAvailable': isHomeVisitAvailable,
      'isInHouseAvailable': isInHouseAvailable,
      'sortOrder': sortOrder,
    };
  }

  IconData get iconData {
    switch (iconType.toLowerCase()) {
      case 'xray':
      case 'x-ray':
        return Icons.medical_information_rounded;
      case 'blood':
        return Icons.water_drop_rounded;
      case 'ecg':
      case 'heart':
      case 'cardio':
        return Icons.monitor_heart_rounded;
      case 'physio':
        return Icons.accessibility_new_rounded;
      case 'pft':
      case 'lungs':
        return Icons.air_rounded;
      case 'usg':
      case 'ultrasound':
        return Icons.waves_rounded;
      case 'package':
      case 'fullbody':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.biotech_rounded;
    }
  }

  Color get color {
    switch (iconType.toLowerCase()) {
      case 'xray':
      case 'x-ray':
        return const Color(0xFF4F46E5);
      case 'blood':
        return const Color(0xFFE11D48);
      case 'ecg':
      case 'heart':
        return const Color(0xFF0284C7);
      case 'physio':
        return const Color(0xFF0D9488);
      case 'pft':
        return const Color(0xFF7C3AED);
      case 'usg':
      case 'ultrasound':
        return const Color(0xFF0891B2);
      case 'package':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF0E8388);
    }
  }
}
