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
    return DiagnosticService(
      id: id,
      title: map['title'] ?? '',
      categoryName: map['categoryName'] ?? 'General',
      categoryId: map['categoryId'],
      category: ServiceCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => ServiceCategory.homeVisit,
      ),
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble(),
      preparation: map['preparation'] ?? 'No special preparation needed',
      sampleType: map['sampleType'] ?? 'N/A',
      turnaroundTime: map['turnaroundTime'] ?? 'Same Day (6-12 Hours)',
      iconType: map['iconType'] ?? 'blood',
      isHomeVisitAvailable: map['isHomeVisitAvailable'] ?? true,
      isInHouseAvailable: map['isInHouseAvailable'] ?? true,
      badge: map['badge'],
      includedTests: List<String>.from(map['includedTests'] ?? []),
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
