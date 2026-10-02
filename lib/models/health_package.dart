import 'diagnostic_service.dart';

class HealthPackage {
  final String id;
  final String name;
  final String offerText;
  final String? posterUrl;
  final double price;
  final double? originalPrice;
  final List<String> testIds;
  final bool isActive;

  /// Short label on the card image, e.g. "Smart Report" or "Most Frequently Booked".
  final String tag;

  /// Turnaround shown as "Report in …", e.g. "8 hrs".
  final String reportTime;

  /// Number of parameters to advertise ("Contains 86 tests"); falls back to [testIds] length.
  final int? parameterCount;

  /// Featured packages appear in the hero row at the top of the home screen.
  final bool isFeatured;

  const HealthPackage({
    required this.id,
    required this.name,
    this.offerText = '',
    this.posterUrl,
    required this.price,
    this.originalPrice,
    this.testIds = const [],
    this.isActive = true,
    this.tag = '',
    this.reportTime = '',
    this.parameterCount,
    this.isFeatured = false,
  });

  int get discountPercent {
    final mrp = originalPrice;
    if (mrp == null || mrp <= price || mrp <= 0) return 0;
    return (((mrp - price) / mrp) * 100).round();
  }

  int get testCount => (parameterCount != null && parameterCount! > 0) ? parameterCount! : testIds.length;

  List<DiagnosticService> resolveTests(List<DiagnosticService> catalog) =>
      catalog.where((s) => testIds.contains(s.id)).toList();

  HealthPackage copyWith({
    String? name,
    String? offerText,
    String? posterUrl,
    double? price,
    double? originalPrice,
    List<String>? testIds,
    bool? isActive,
    String? tag,
    String? reportTime,
    int? parameterCount,
    bool clearParameterCount = false,
    bool? isFeatured,
  }) {
    return HealthPackage(
      id: id,
      name: name ?? this.name,
      offerText: offerText ?? this.offerText,
      posterUrl: posterUrl ?? this.posterUrl,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      testIds: testIds ?? this.testIds,
      isActive: isActive ?? this.isActive,
      tag: tag ?? this.tag,
      reportTime: reportTime ?? this.reportTime,
      parameterCount: clearParameterCount ? parameterCount : (parameterCount ?? this.parameterCount),
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'offerText': offerText,
        'posterUrl': posterUrl,
        'price': price,
        'originalPrice': originalPrice,
        'testIds': testIds,
        'isActive': isActive,
        'tag': tag,
        'reportTime': reportTime,
        'parameterCount': parameterCount,
        'isFeatured': isFeatured,
      };

  factory HealthPackage.fromMap(Map<String, dynamic> map, [String? id]) {
    return HealthPackage(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      offerText: map['offerText'] ?? '',
      posterUrl: map['posterUrl'],
      price: (map['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble(),
      testIds: List<String>.from(map['testIds'] ?? const []),
      isActive: map['isActive'] ?? true,
      tag: map['tag'] ?? '',
      reportTime: map['reportTime'] ?? '',
      parameterCount: (map['parameterCount'] as num?)?.toInt(),
      isFeatured: map['isFeatured'] ?? false,
    );
  }
}
