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
    );
  }
}
