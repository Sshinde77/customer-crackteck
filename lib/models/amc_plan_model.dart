class AmcPlanResponse {
  final List<AmcPlanItem>? amcPlans;

  AmcPlanResponse({this.amcPlans});

  factory AmcPlanResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rootData = json['data'];
    dynamic plansNode = json['amc_plans'];
    if (plansNode == null && rootData is Map<String, dynamic>) {
      plansNode = rootData['amc_plans'] ?? rootData['plans'];
    }
    if (plansNode == null && rootData is List) {
      plansNode = rootData;
    }
    if (plansNode == null && json['plans'] is List) {
      plansNode = json['plans'];
    }

    return AmcPlanResponse(
      amcPlans: plansNode is List
          ? plansNode
                .whereType<Map>()
                .map((i) => AmcPlanItem.fromJson(Map<String, dynamic>.from(i)))
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
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final rawPlan = data['amc_plan'] ?? data['plan'];
    final rawCoveredItems =
        data['covered_items'] ?? data['covered_services'] ?? data['services'];

    return AmcPlanDetailResponse(
      amcPlan: rawPlan is Map
          ? AmcPlan.fromJson(Map<String, dynamic>.from(rawPlan))
          : null,
      coveredItems: rawCoveredItems is List
          ? rawCoveredItems
                .whereType<Map>()
                .map((i) => CoveredItem.fromJson(Map<String, dynamic>.from(i)))
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
    final dynamic rawPlan = json['plan'] ?? json['amc_plan'];
    final dynamic rawCoveredItems = json['covered_items'];

    return AmcPlanItem(
      plan: rawPlan is Map
          ? AmcPlan.fromJson(Map<String, dynamic>.from(rawPlan))
          : AmcPlan.fromJson(json),
      coveredItems: rawCoveredItems is List
          ? rawCoveredItems
                .whereType<Map>()
                .map((i) => CoveredItem.fromJson(Map<String, dynamic>.from(i)))
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

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _toStringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return null;
  }

  static List<int>? _toIntList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final out = <int>[];
      for (final item in value) {
        if (item is Map) {
          final int? id = _toInt(item['id']);
          if (id != null) out.add(id);
          continue;
        }
        final int? parsed = _toInt(item);
        if (parsed != null) out.add(parsed);
      }
      return out;
    }
    return null;
  }

  factory AmcPlan.fromJson(Map<String, dynamic> json) {
    return AmcPlan(
      id: _toInt(json['id']),
      planName: _toStringValue(
        json['plan_name'] ?? json['planName'] ?? json['name'],
      ),
      planCode: _toStringValue(
        json['plan_code'] ?? json['planCode'] ?? json['code'],
      ),
      description: _toStringValue(json['description']),
      duration: _toInt(json['duration']),
      totalVisits: _toInt(json['total_visits'] ?? json['totalVisits']),
      planCost: _toStringValue(json['plan_cost'] ?? json['planCost']),
      tax: _toStringValue(json['tax']),
      totalCost: _toStringValue(json['total_cost'] ?? json['totalCost']),
      payTerms: _toStringValue(json['pay_terms'] ?? json['payTerms']),
      supportType: _toStringValue(json['support_type'] ?? json['supportType']),
      coveredItems: _toIntList(json['covered_items'] ?? json['coveredItems']),
      brochure: _toStringValue(json['brochure']),
      tandc: _toStringValue(json['tandc']),
      replacementPolicy: _toStringValue(
        json['replacement_policy'] ?? json['replacementPolicy'],
      ),
      status: _toStringValue(json['status']),
      deletedAt: _toStringValue(json['deleted_at']),
      createdAt: _toStringValue(json['created_at']),
      updatedAt: _toStringValue(json['updated_at']),
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

  bool matchesSupportFilter(String filter) {
    final normalizedFilter = filter.trim().toLowerCase();
    if (normalizedFilter.isEmpty) {
      return true;
    }

    final haystack = <String?>[
      supportType,
      planName,
      planCode,
      description,
      payTerms,
      replacementPolicy,
    ].whereType<String>().map((value) => value.toLowerCase()).join(' ');

    if (normalizedFilter == 'offline') {
      return haystack.contains('offline') ||
          haystack.contains('off line') ||
          haystack.contains('onsite') ||
          haystack.contains('on site') ||
          haystack.contains('site visit') ||
          haystack.contains('visit');
    }

    if (normalizedFilter == 'online') {
      return haystack.contains('online') ||
          haystack.contains('on line') ||
          haystack.contains('remote') ||
          haystack.contains('virtual');
    }

    return haystack.contains(normalizedFilter);
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

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _toStringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return null;
  }

  static List<String>? _toStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value];
    }
    return null;
  }

  factory CoveredItem.fromJson(Map<String, dynamic> json) {
    return CoveredItem(
      id: _toInt(json['id']),
      itemCode: _toStringValue(json['item_code'] ?? json['itemCode']),
      serviceType: _toStringValue(json['service_type'] ?? json['serviceType']),
      serviceName: _toStringValue(json['service_name'] ?? json['serviceName']),
      serviceCharge: _toStringValue(
        json['service_charge'] ?? json['serviceCharge'],
      ),
      status: _toStringValue(json['status']),
      diagnosisList: _toStringList(
        json['diagnosis_list'] ?? json['diagnosisList'],
      ),
      deletedAt: _toStringValue(json['deleted_at']),
      createdAt: _toStringValue(json['created_at']),
      updatedAt: _toStringValue(json['updated_at']),
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
