class PromoBanner {
  static const placementTop = 'top';
  static const placementMiddle = 'middle';

  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String? imageUrl;
  final String actionText;
  final String categoryTarget;
  final bool isActive;

  /// Where the banner is shown on the home screen: [placementTop] or [placementMiddle].
  final String placement;

  /// What happens on tap. Supports `https://…`, `tel:…`, `package:<id>`, `test:<id>`,
  /// `section:<audienceId>` and `category:<name>`. Empty falls back to [categoryTarget].
  final String linkUrl;

  const PromoBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.imageUrl,
    this.actionText = 'Book Now',
    this.categoryTarget = 'all',
    this.isActive = true,
    this.placement = placementTop,
    this.linkUrl = '',
  });

  PromoBanner copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? badge,
    String? imageUrl,
    bool clearImage = false,
    String? actionText,
    String? categoryTarget,
    bool? isActive,
    String? placement,
    String? linkUrl,
  }) {
    return PromoBanner(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      badge: badge ?? this.badge,
      imageUrl: clearImage ? imageUrl : (imageUrl ?? this.imageUrl),
      actionText: actionText ?? this.actionText,
      categoryTarget: categoryTarget ?? this.categoryTarget,
      isActive: isActive ?? this.isActive,
      placement: placement ?? this.placement,
      linkUrl: linkUrl ?? this.linkUrl,
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
      'placement': placement,
      'linkUrl': linkUrl,
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
      placement: map['placement'] == placementMiddle ? placementMiddle : placementTop,
      linkUrl: map['linkUrl'] ?? '',
    );
  }
}
