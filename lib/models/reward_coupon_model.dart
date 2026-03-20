class RewardCoupon {
  final String id;
  final String title;
  final String description;
  final String code;
  final String sourceType;
  final String sourceId;
  final bool scratched;
  final String validTill;
  final String accentHex;
  final String iconName;
  final String createdAt;
  final List<RewardRuleItem> applicableCategories;
  final List<RewardRuleItem> applicableBrands;
  final List<RewardRuleItem> excludedProducts;

  const RewardCoupon({
    required this.id,
    required this.title,
    required this.description,
    required this.code,
    required this.sourceType,
    required this.sourceId,
    required this.scratched,
    required this.validTill,
    required this.accentHex,
    required this.iconName,
    required this.createdAt,
    this.applicableCategories = const <RewardRuleItem>[],
    this.applicableBrands = const <RewardRuleItem>[],
    this.excludedProducts = const <RewardRuleItem>[],
  });

  RewardCoupon copyWith({
    String? id,
    String? title,
    String? description,
    String? code,
    String? sourceType,
    String? sourceId,
    bool? scratched,
    String? validTill,
    String? accentHex,
    String? iconName,
    String? createdAt,
    List<RewardRuleItem>? applicableCategories,
    List<RewardRuleItem>? applicableBrands,
    List<RewardRuleItem>? excludedProducts,
  }) {
    return RewardCoupon(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      code: code ?? this.code,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      scratched: scratched ?? this.scratched,
      validTill: validTill ?? this.validTill,
      accentHex: accentHex ?? this.accentHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      applicableCategories: applicableCategories ?? this.applicableCategories,
      applicableBrands: applicableBrands ?? this.applicableBrands,
      excludedProducts: excludedProducts ?? this.excludedProducts,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'code': code,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'scratched': scratched,
      'validTill': validTill,
      'accentHex': accentHex,
      'iconName': iconName,
      'createdAt': createdAt,
      'applicableCategories':
          applicableCategories.map((item) => item.toJson()).toList(),
      'applicableBrands': applicableBrands.map((item) => item.toJson()).toList(),
      'excludedProducts': excludedProducts.map((item) => item.toJson()).toList(),
    };
  }

  factory RewardCoupon.fromJson(Map<String, dynamic> json) {
    return RewardCoupon(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      sourceType: (json['sourceType'] ?? '').toString(),
      sourceId: (json['sourceId'] ?? '').toString(),
      scratched: json['scratched'] == true,
      validTill: (json['validTill'] ?? '').toString(),
      accentHex: (json['accentHex'] ?? '').toString(),
      iconName: (json['iconName'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      applicableCategories:
          RewardRuleItem.listFromJson(json['applicableCategories']),
      applicableBrands: RewardRuleItem.listFromJson(json['applicableBrands']),
      excludedProducts: RewardRuleItem.listFromJson(json['excludedProducts']),
    );
  }
}

class RewardRuleItem {
  final String id;
  final String title;
  final String subtitle;

  const RewardRuleItem({
    required this.id,
    required this.title,
    this.subtitle = '',
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
    };
  }

  factory RewardRuleItem.fromJson(Map<String, dynamic> json) {
    return RewardRuleItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
    );
  }

  static List<RewardRuleItem> listFromJson(dynamic raw) {
    if (raw is! List) return const <RewardRuleItem>[];

    return raw
        .whereType<Map>()
        .map((item) => RewardRuleItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
