class PromoBanner {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String? imageUrl;
  final String actionText;
  final String categoryTarget;
  final bool isActive;

  const PromoBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.imageUrl,
    this.actionText = 'Book Now',
    this.categoryTarget = 'all',
    this.isActive = true,
  });

  PromoBanner copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? badge,
    String? imageUrl,
    String? actionText,
    String? categoryTarget,
    bool? isActive,
  }) {
    return PromoBanner(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      badge: badge ?? this.badge,
      imageUrl: imageUrl ?? this.imageUrl,
      actionText: actionText ?? this.actionText,
      categoryTarget: categoryTarget ?? this.categoryTarget,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'badge': badge,
      'imageUrl': imageUrl,
      'actionText': actionText,
      'categoryTarget': categoryTarget,
      'isActive': isActive,
    };
  }

  factory PromoBanner.fromMap(Map<String, dynamic> map, [String? id]) {
    return PromoBanner(
      id: id ?? map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      badge: map['badge'] ?? 'OFFER',
      imageUrl: map['imageUrl'],
      actionText: map['actionText'] ?? 'Book Now',
      categoryTarget: map['categoryTarget'] ?? 'all',
      isActive: map['isActive'] ?? true,
    );
  }
}
