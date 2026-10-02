import 'lab_section.dart';

/// Admin-curated home section, e.g. "Checkups & Vaccination for Fever" (a card rail) or
/// "Specialised tests tailored to your health profile" (a grid of photo tiles).
///
/// Each group is a tab (rail layout) or a tile (tiles layout) holding packages and tests.
class HomeCollection {
  static const layoutRail = 'rail';
  static const layoutTiles = 'tiles';

  final String id;
  final String title;
  final String subtitle;
  final String layout;
  final int sortOrder;
  final bool isActive;
  final List<LabSubcategory> groups;

  const HomeCollection({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.layout = layoutRail,
    this.sortOrder = 0,
    this.isActive = true,
    this.groups = const [],
  });

  bool get isTiles => layout == layoutTiles;

  HomeCollection copyWith({
    String? title,
    String? subtitle,
    String? layout,
    int? sortOrder,
    bool? isActive,
    List<LabSubcategory>? groups,
  }) {
    return HomeCollection(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      layout: layout ?? this.layout,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      groups: groups ?? this.groups,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'layout': layout,
        'sortOrder': sortOrder,
        'isActive': isActive,
        'groups': groups.map((g) => g.toMap()).toList(),
      };

  factory HomeCollection.fromMap(Map<String, dynamic> map, [String? id]) {
    return HomeCollection(
      id: id ?? map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      layout: map['layout'] == layoutTiles ? layoutTiles : layoutRail,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] ?? true,
      groups: ((map['groups'] as List?) ?? const [])
          .map((e) => LabSubcategory.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
