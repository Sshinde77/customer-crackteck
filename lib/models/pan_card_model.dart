class PanCardResponse {
  final PanCard? panCard;

  PanCardResponse({this.panCard});

  factory PanCardResponse.fromJson(Map<String, dynamic> json) {
    return PanCardResponse(
      panCard: json['pan_card'] != null ? PanCard.fromJson(json['pan_card']) : null,
    );
  }
}

class PanCard {
  final int? id;
  final int? customerId;
  final String? panNumber;
  final String? panCardFrontPath;
  final String? panCardBackPath;
  final String? createdAt;
  final String? updatedAt;

  PanCard({
    this.id,
    this.customerId,
    this.panNumber,
    this.panCardFrontPath,
    this.panCardBackPath,
    this.createdAt,
    this.updatedAt,
  });

  factory PanCard.fromJson(Map<String, dynamic> json) {
    return PanCard(
      id: json['id'],
      customerId: json['customer_id'] is String ? int.tryParse(json['customer_id']) : json['customer_id'],
      panNumber: json['pan_number'],
      panCardFrontPath: json['pan_card_front_path'],
      panCardBackPath: json['pan_card_back_path'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'pan_number': panNumber,
      'pan_card_front_path': panCardFrontPath,
      'pan_card_back_path': panCardBackPath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
