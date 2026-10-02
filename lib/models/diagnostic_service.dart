enum ServiceCategory {
  homeVisit,
  inHouseDiagnostic,
  physiotherapy,
  healthPackage,
}

class DiagnosticService {
  final String id;
  final String title;
  final String categoryName;
  final String? categoryId;
  final ServiceCategory category;
  final String description;
  final double price;
  final double? originalPrice;
  final String preparation;
  final String sampleType;
  final String turnaroundTime;
  final String iconType;
  final bool isHomeVisitAvailable;
  final bool isInHouseAvailable;
  final String? badge;
  final List<String> includedTests;

  const DiagnosticService({
    required this.id,
    required this.title,
    required this.categoryName,
    this.categoryId,
    required this.category,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.preparation,
    required this.sampleType,
    required this.turnaroundTime,
    required this.iconType,
    this.isHomeVisitAvailable = true,
    this.isInHouseAvailable = true,
    this.badge,
    this.includedTests = const [],
  });

  factory DiagnosticService.fromMap(Map<String, dynamic> map, String id) {
    var catId = map['categoryId'] as String?;
    var catName = (map['categoryName'] ?? 'General') as String;
    var icon = (map['iconType'] ?? 'blood') as String;
    var sampleType = (map['sampleType'] ?? 'N/A') as String;
    var preparation = (map['preparation'] ?? 'No special preparation needed') as String;
    final title = (map['title'] ?? '') as String;
    final titleLower = title.toLowerCase();

    // Auto-heal / sanitize miscategorized items from database:
    // 1. If it's a blood test, strictly assign to Blood Tests (NOT X-Ray)
    if (titleLower.contains('blood') ||
        titleLower.contains('cbc') ||
        titleLower.contains('lipid') ||
        titleLower.contains('thyroid') ||
        titleLower.contains('glucose') ||
        titleLower.contains('sugar') ||
        titleLower.contains('diabetes') ||
        titleLower.contains('hemoglobin') ||
        titleLower.contains('hba1c') ||
        titleLower.contains('platelet') ||
        titleLower.contains('cholesterol') ||
        titleLower.contains('serum')) {
      if (catId == 'cat_xray' || catName.toLowerCase().contains('x-ray') || catName.toLowerCase().contains('xray')) {
        catId = 'cat_blood';
        catName = 'Blood Tests';
        icon = 'blood';
        if (sampleType.toLowerCase().contains('radiography') || sampleType == 'N/A') {
          sampleType = 'Blood (Serum)';
        }
      }
    }
    // 2. If it's an X-Ray test, strictly assign to Digital X-Ray
    else if (titleLower.contains('x-ray') ||
        titleLower.contains('xray') ||
        titleLower.contains('radiograph') ||
        titleLower.contains('pns') ||
        titleLower.contains('sinus') ||
        titleLower.contains('knee joints') ||
        titleLower.contains('pelvis with') ||
        titleLower.contains('spine x-ray') ||
        titleLower.contains('chest x-ray')) {
      catId = 'cat_xray';
      catName = 'Digital X-Ray';
      icon = 'xray';
      if (sampleType.toLowerCase().contains('blood') || sampleType == 'N/A') {
        sampleType = 'Direct Digital Radiography (DR)';
      }
      if (preparation.toLowerCase().contains('fasting')) {
        preparation = 'Wear loose clothing without metal buttons, zippers, or jewelry.';
      }
    }

    return DiagnosticService(
      id: id,
      title: title,
      categoryName: catName,
      categoryId: catId,
      category: ServiceCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => ServiceCategory.homeVisit,
      ),
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble(),
      preparation: preparation,
      sampleType: sampleType,
      turnaroundTime: map['turnaroundTime'] ?? 'Same Day (6-12 Hours)',
      iconType: icon,
      isHomeVisitAvailable: map['isHomeVisitAvailable'] ?? true,
      isInHouseAvailable: map['isInHouseAvailable'] ?? true,
      badge: map['badge'],
      includedTests: List<String>.from(map['includedTests'] ?? []),
    );
  }

  DiagnosticService copyWith({
    String? id,
    String? title,
    String? categoryName,
    String? categoryId,
    ServiceCategory? category,
    String? description,
    double? price,
    double? originalPrice,
    String? preparation,
    String? sampleType,
    String? turnaroundTime,
    String? iconType,
    bool? isHomeVisitAvailable,
    bool? isInHouseAvailable,
    String? badge,
    List<String>? includedTests,
  }) {
    return DiagnosticService(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryName: categoryName ?? this.categoryName,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      preparation: preparation ?? this.preparation,
      sampleType: sampleType ?? this.sampleType,
      turnaroundTime: turnaroundTime ?? this.turnaroundTime,
      iconType: iconType ?? this.iconType,
      isHomeVisitAvailable: isHomeVisitAvailable ?? this.isHomeVisitAvailable,
      isInHouseAvailable: isInHouseAvailable ?? this.isInHouseAvailable,
      badge: badge ?? this.badge,
      includedTests: includedTests ?? this.includedTests,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'categoryName': categoryName,
      'categoryId': categoryId,
      'category': category.name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'preparation': preparation,
      'sampleType': sampleType,
      'turnaroundTime': turnaroundTime,
      'iconType': iconType,
      'isHomeVisitAvailable': isHomeVisitAvailable,
      'isInHouseAvailable': isInHouseAvailable,
      'badge': badge,
      'includedTests': includedTests,
    };
  }
}
