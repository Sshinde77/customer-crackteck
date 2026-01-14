class AadharCardResponse {
  final AadharCard? aadharCard;

  AadharCardResponse({this.aadharCard});

  factory AadharCardResponse.fromJson(Map<String, dynamic> json) {
    return AadharCardResponse(
      aadharCard: json['aadhar_card'] != null ? AadharCard.fromJson(json['aadhar_card']) : null,
    );
  }
}

class AadharCard {
  final int? id;
  final int? customerId;
  final String? aadharNumber;
  final String? aadharFrontPath;
  final String? aadharBackPath;
  final String? createdAt;
  final String? updatedAt;

  AadharCard({
    this.id,
    this.customerId,
    this.aadharNumber,
    this.aadharFrontPath,
    this.aadharBackPath,
    this.createdAt,
    this.updatedAt,
  });

  factory AadharCard.fromJson(Map<String, dynamic> json) {
    return AadharCard(
      id: json['id'],
      customerId: json['customer_id'] is String ? int.tryParse(json['customer_id']) : json['customer_id'],
      aadharNumber: json['aadhar_number'],
      aadharFrontPath: json['aadhar_front_path'],
      aadharBackPath: json['aadhar_back_path'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'aadhar_number': aadharNumber,
      'aadhar_front_path': aadharFrontPath,
      'aadhar_back_path': aadharBackPath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
