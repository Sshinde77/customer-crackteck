class QuickServiceResponse {
  final List<QuickService>? quickServices;

  QuickServiceResponse({this.quickServices});

  factory QuickServiceResponse.fromJson(Map<String, dynamic> json) {
    return QuickServiceResponse(
      quickServices: json['quick_services'] != null
          ? (json['quick_services'] as List)
              .map((i) => QuickService.fromJson(i))
              .toList()
          : null,
    );
  }
}

class QuickService {
  final int? id;
  final String? itemCode;
  final String? serviceType;
  final String? serviceName;
  final String? serviceCharge;
  final String? status;
  final List<String>? diagnosisList;
  final String? createdAt;
  final String? updatedAt;

  QuickService({
    this.id,
    this.itemCode,
    this.serviceType,
    this.serviceName,
    this.serviceCharge,
    this.status,
    this.diagnosisList,
    this.createdAt,
    this.updatedAt,
  });

  factory QuickService.fromJson(Map<String, dynamic> json) {
    return QuickService(
      id: json['id'],
      itemCode: json['item_code'],
      serviceType: json['service_type'],
      serviceName: json['service_name'],
      serviceCharge: json['service_charge'],
      status: json['status'],
      diagnosisList: json['diagnosis_list'] != null
          ? List<String>.from(json['diagnosis_list'])
          : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
