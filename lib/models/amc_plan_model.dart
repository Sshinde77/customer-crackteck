class AmcPlanResponse {
  final List<AmcPlanItem>? amcPlans;

  AmcPlanResponse({this.amcPlans});

  factory AmcPlanResponse.fromJson(Map<String, dynamic> json) {
    return AmcPlanResponse(
      amcPlans: json['amc_plans'] != null
          ? (json['amc_plans'] as List)
                .map((i) => AmcPlanItem.fromJson(i))
                .toList()
          : null,
    );
  }
}

// AMC Plan Detail Response (for single plan details)
class AmcPlanDetailResponse {
  final AmcPlan? amcPlan;
  final List<CoveredItem>? coveredItems;

  AmcPlanDetailResponse({this.amcPlan, this.coveredItems});

  factory AmcPlanDetailResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return AmcPlanDetailResponse(
      amcPlan: data?['amc_plan'] != null
          ? AmcPlan.fromJson(data!['amc_plan'])
          : null,
      coveredItems: data?['covered_items'] != null
          ? (data!['covered_items'] as List)
                .map((i) => CoveredItem.fromJson(i))
                .toList()
          : null,
    );
  }
}

class AmcPlanItem {
  final AmcPlan? plan;
  final List<CoveredItem>? coveredItems;

  AmcPlanItem({this.plan, this.coveredItems});

  factory AmcPlanItem.fromJson(Map<String, dynamic> json) {
    return AmcPlanItem(
      plan: json['plan'] != null ? AmcPlan.fromJson(json['plan']) : null,
      coveredItems: json['covered_items'] != null
          ? (json['covered_items'] as List)
                .map((i) => CoveredItem.fromJson(i))
                .toList()
          : null,
    );
  }
}

class AmcPlan {
  final int? id;
  final String? planName;
  final String? planCode;
  final String? description;
  final int? duration;
  final int? totalVisits;
  final String? planCost;
  final String? tax;
  final String? totalCost;
  final String? payTerms;
  final String? supportType;
  final List<int>? coveredItems;
  final String? brochure;
  final String? tandc;
  final String? replacementPolicy;
  final String? status;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;

  AmcPlan({
    this.id,
    this.planName,
    this.planCode,
    this.description,
    this.duration,
    this.totalVisits,
    this.planCost,
    this.tax,
    this.totalCost,
    this.payTerms,
    this.supportType,
    this.coveredItems,
    this.brochure,
    this.tandc,
    this.replacementPolicy,
    this.status,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory AmcPlan.fromJson(Map<String, dynamic> json) {
    return AmcPlan(
      id: json['id'],
      planName: json['plan_name'],
      planCode: json['plan_code'],
      description: json['description'],
      duration: json['duration'],
      totalVisits: json['total_visits'],
      planCost: json['plan_cost'],
      tax: json['tax'],
      totalCost: json['total_cost'],
      payTerms: json['pay_terms'],
      supportType: json['support_type'],
      coveredItems: json['covered_items'] != null
          ? List<int>.from(json['covered_items'])
          : null,
      brochure: json['brochure'],
      tandc: json['tandc'],
      replacementPolicy: json['replacement_policy'],
      status: json['status'],
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_name': planName,
      'plan_code': planCode,
      'description': description,
      'duration': duration,
      'total_visits': totalVisits,
      'plan_cost': planCost,
      'tax': tax,
      'total_cost': totalCost,
      'pay_terms': payTerms,
      'support_type': supportType,
      'covered_items': coveredItems,
      'brochure': brochure,
      'tandc': tandc,
      'replacement_policy': replacementPolicy,
      'status': status,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class CoveredItem {
  final int? id;
  final String? itemCode;
  final String? serviceType;
  final String? serviceName;
  final String? serviceCharge;
  final String? status;
  final List<String>? diagnosisList;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;

  CoveredItem({
    this.id,
    this.itemCode,
    this.serviceType,
    this.serviceName,
    this.serviceCharge,
    this.status,
    this.diagnosisList,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory CoveredItem.fromJson(Map<String, dynamic> json) {
    return CoveredItem(
      id: json['id'],
      itemCode: json['item_code'],
      serviceType: json['service_type'],
      serviceName: json['service_name'],
      serviceCharge: json['service_charge'],
      status: json['status'],
      diagnosisList: json['diagnosis_list'] != null
          ? List<String>.from(json['diagnosis_list'])
          : null,
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_code': itemCode,
      'service_type': serviceType,
      'service_name': serviceName,
      'service_charge': serviceCharge,
      'status': status,
      'diagnosis_list': diagnosisList,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
