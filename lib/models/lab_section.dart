// Admin-managed "Lab tests & packages" browsing tree shown on the patient home:
// LabAudience (e.g. "For Women") → LabSubcategory (e.g. "Adult Women") → packages & tests.
// Gender and age ranges drive the "Recommended for you" rail.

bool _ageFits(int? age, int? min, int? max) {
  if (age == null || age <= 0) return true;
  if (min != null && age < min) return false;
  if (max != null && age > max) return false;
  return true;
}

int? _intOrNull(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));

class LabSubcategory {
  final String id;
  final String name;
  final String? imageUrl;
  final int? minAge;
  final int? maxAge;
  final List<String> packageIds;
  final List<String> testIds;

  const LabSubcategory({
    required this.id,
    required this.name,
    this.imageUrl,
    this.minAge,
    this.maxAge,
    this.packageIds = const [],
    this.testIds = const [],
  });

  int get itemCount => packageIds.length + testIds.length;

  bool fitsAge(int? age) => _ageFits(age, minAge, maxAge);

  LabSubcategory copyWith({
    String? name,
    String? imageUrl,
    int? minAge,
    int? maxAge,
    bool clearAges = false,
    List<String>? packageIds,
    List<String>? testIds,
  }) {
    return LabSubcategory(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      minAge: clearAges ? minAge : (minAge ?? this.minAge),
      maxAge: clearAges ? maxAge : (maxAge ?? this.maxAge),
      packageIds: packageIds ?? this.packageIds,
      testIds: testIds ?? this.testIds,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'minAge': minAge,
        'maxAge': maxAge,
        'packageIds': packageIds,
        'testIds': testIds,
      };

  factory LabSubcategory.fromMap(Map<String, dynamic> map) {
    return LabSubcategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'],
      minAge: _intOrNull(map['minAge']),
      maxAge: _intOrNull(map['maxAge']),
      packageIds: List<String>.from(map['packageIds'] ?? const []),
      testIds: List<String>.from(map['testIds'] ?? const []),
    );
  }
}

class LabAudience {
  static const genders = ['All', 'Female', 'Male'];

  final String id;
  final String name;
  final String? imageUrl;
  final String gender;
  final int? minAge;
  final int? maxAge;
  final int sortOrder;
  final bool isActive;
  final List<LabSubcategory> subcategories;

  const LabAudience({
    required this.id,
    required this.name,
    this.imageUrl,
    this.gender = 'All',
    this.minAge,
    this.maxAge,
    this.sortOrder = 0,
    this.isActive = true,
    this.subcategories = const [],
  });

  /// "For Women" → "Women", used for the "Explore Packages for …" CTA.
  String get shortName => name.replaceFirst(RegExp(r'^for\s+', caseSensitive: false), '').trim();

  String get targetingLabel {
    final parts = <String>[];
    if (gender != 'All') parts.add(gender);
    if (minAge != null && maxAge != null) {
      parts.add('$minAge–$maxAge yrs');
    } else if (minAge != null) {
      parts.add('$minAge+ yrs');
    } else if (maxAge != null) {
      parts.add('Up to $maxAge yrs');
    }
    return parts.isEmpty ? 'Everyone' : parts.join(' • ');
  }

  /// Whether a patient with this sex/age belongs to this audience.
  /// Unknown sex or age is treated as a match so guests still get suggestions.
  bool matches(String? sex, int? age) {
    final genderOk = gender == 'All' || sex == null || sex.isEmpty || sex.toLowerCase() == gender.toLowerCase();
    return genderOk && _ageFits(age, minAge, maxAge);
  }

  LabAudience copyWith({
    String? name,
    String? imageUrl,
    String? gender,
    int? minAge,
    int? maxAge,
    bool clearAges = false,
    int? sortOrder,
    bool? isActive,
    List<LabSubcategory>? subcategories,
  }) {
    return LabAudience(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      gender: gender ?? this.gender,
      minAge: clearAges ? minAge : (minAge ?? this.minAge),
      maxAge: clearAges ? maxAge : (maxAge ?? this.maxAge),
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      subcategories: subcategories ?? this.subcategories,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'gender': gender,
        'minAge': minAge,
        'maxAge': maxAge,
        'sortOrder': sortOrder,
        'isActive': isActive,
        'subcategories': subcategories.map((s) => s.toMap()).toList(),
      };

  factory LabAudience.fromMap(Map<String, dynamic> map, [String? id]) {
    return LabAudience(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'],
      gender: genders.contains(map['gender']) ? map['gender'] : 'All',
      minAge: _intOrNull(map['minAge']),
      maxAge: _intOrNull(map['maxAge']),
      sortOrder: _intOrNull(map['sortOrder']) ?? 0,
      isActive: map['isActive'] ?? true,
      subcategories: ((map['subcategories'] as List?) ?? const [])
          .map((e) => LabSubcategory.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
