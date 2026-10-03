/// A doctor card in the home "Consult specialists & lab doctors" rail (admin-managed).
class Specialist {
  final String id;
  final String name;
  final String specialty;
  final String badge;
  final String? imageUrl;

  /// Catalog category opened on tap, e.g. "Blood Tests".
  final String categoryTarget;
  final int sortOrder;
  final bool isActive;

  const Specialist({
    required this.id,
    required this.name,
    this.specialty = '',
    this.badge = '',
    this.imageUrl,
    this.categoryTarget = '',
    this.sortOrder = 0,
    this.isActive = true,
  });

  Specialist copyWith({bool? isActive}) => Specialist(
        id: id,
        name: name,
        specialty: specialty,
        badge: badge,
        imageUrl: imageUrl,
        categoryTarget: categoryTarget,
        sortOrder: sortOrder,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'specialty': specialty,
        'badge': badge,
        'imageUrl': imageUrl,
        'categoryTarget': categoryTarget,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };

  factory Specialist.fromMap(Map<String, dynamic> map, [String? id]) => Specialist(
        id: id ?? map['id'] ?? '',
        name: map['name'] ?? '',
        specialty: map['specialty'] ?? '',
        badge: map['badge'] ?? '',
        imageUrl: (map['imageUrl'] as String?)?.trim().isEmpty ?? true ? null : map['imageUrl'] as String,
        categoryTarget: map['categoryTarget'] ?? '',
        sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
        isActive: map['isActive'] ?? true,
      );
}
