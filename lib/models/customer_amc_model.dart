import 'amc_plan_model.dart';

class CustomerAmcListResponse {
  final List<CustomerAmc> amcs;

  const CustomerAmcListResponse({required this.amcs});

  factory CustomerAmcListResponse.fromJson(Map<String, dynamic> json) {
    final dynamic dataRoot = json['data'];
    dynamic listNode;

    if (dataRoot is List) {
      listNode = dataRoot;
    } else if (dataRoot is Map<String, dynamic>) {
      listNode =
          dataRoot['customer_amcs'] ??
          dataRoot['customer_amc_list'] ??
          dataRoot['amcs'] ??
          dataRoot['items'] ??
          dataRoot['data'];
    } else if (dataRoot is Map) {
      final map = Map<String, dynamic>.from(dataRoot);
      listNode =
          map['customer_amcs'] ??
          map['customer_amc_list'] ??
          map['amcs'] ??
          map['items'] ??
          map['data'];
    }

    listNode ??=
        json['customer_amcs'] ?? json['customer_amc_list'] ?? json['amcs'];

    if (listNode is Map) {
      listNode = [listNode];
    }

    return CustomerAmcListResponse(
      amcs: listNode is List
          ? listNode
                .whereType<Map>()
                .map((item) => CustomerAmc.fromJson(Map<String, dynamic>.from(item)))
                .toList()
          : <CustomerAmc>[],
    );
  }
}

class CustomerAmcDetailResponse {
  final CustomerAmc? amc;

  const CustomerAmcDetailResponse({required this.amc});

  factory CustomerAmcDetailResponse.fromJson(Map<String, dynamic> json) {
    final dynamic dataRoot = json['data'];
    final Map<String, dynamic> payload = dataRoot is Map<String, dynamic>
        ? Map<String, dynamic>.from(dataRoot)
        : dataRoot is Map
        ? Map<String, dynamic>.from(dataRoot)
        : Map<String, dynamic>.from(json);

    final dynamic detailNode =
        payload['customer_amc'] ??
        payload['customer_amc_detail'] ??
        payload['amc'] ??
        payload['detail'] ??
        payload['data'] ??
        payload;

    final Map<String, dynamic>? detail = detailNode is Map<String, dynamic>
        ? Map<String, dynamic>.from(detailNode)
        : detailNode is Map
        ? Map<String, dynamic>.from(detailNode)
        : null;

    if (detail != null) {
      if (!detail.containsKey('amc_schedule_meetings') &&
          payload['amc_schedule_meetings'] is List) {
        detail['amc_schedule_meetings'] = payload['amc_schedule_meetings'];
      }

      if (!detail.containsKey('schedule_meetings') &&
          payload['schedule_meetings'] is List) {
        detail['schedule_meetings'] = payload['schedule_meetings'];
      }
    }

    return CustomerAmcDetailResponse(
      amc: detail == null ? null : CustomerAmc.fromJson(detail),
    );
  }
}

class CustomerAmc {
  final int? id;
  final String? requestId;
  final String? amcType;
  final String? requestDate;
  final String? amcNumber;
  final String? planName;
  final String? planCode;
  final String? description;
  final String? status;
  final int? scheduleMeetingsCount;
  final String? supportType;
  final String? duration;
  final String? totalVisits;
  final String? planCost;
  final String? startDate;
  final String? endDate;
  final String? priorityLevel;
  final String? totalAmount;
  final String? payTerms;
  final String? additionalNotes;
  final String? createdAt;
  final String? updatedAt;
  final AmcPlan? amcPlan;
  final List<AmcScheduleMeeting> scheduleMeetings;
  final List<CoveredItem> coveredItems;

  const CustomerAmc({
    required this.id,
    required this.requestId,
    required this.amcType,
    required this.requestDate,
    required this.amcNumber,
    required this.planName,
    required this.planCode,
    required this.description,
    required this.status,
    required this.scheduleMeetingsCount,
    required this.supportType,
    required this.duration,
    required this.totalVisits,
    required this.planCost,
    required this.startDate,
    required this.endDate,
    required this.priorityLevel,
    required this.totalAmount,
    required this.payTerms,
    required this.additionalNotes,
    required this.createdAt,
    required this.updatedAt,
    required this.amcPlan,
    required this.scheduleMeetings,
    required this.coveredItems,
  });

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  static String? _toText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static Map<String, dynamic>? _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<CoveredItem> _toCoveredItems(dynamic value) {
    if (value is! List) return const <CoveredItem>[];
    return value
        .whereType<Map>()
        .map((item) => CoveredItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static List<AmcScheduleMeeting> _toScheduleMeetings(dynamic value) {
    if (value is! List) return const <AmcScheduleMeeting>[];
    return value
        .whereType<Map>()
        .map((item) => AmcScheduleMeeting.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static String? _pickText(List<dynamic> values) {
    for (final value in values) {
      final text = _toText(value);
      if (text != null) {
        return text;
      }
    }
    return null;
  }

  factory CustomerAmc.fromJson(Map<String, dynamic> json) {
    final planSource =
        _toMap(json['amc_plan']) ??
        _toMap(json['plan']) ??
        _toMap(json['amc_data']) ??
        _toMap(json['plan_details']) ??
        _toMap(json['plan_detail']);
    final AmcPlan? plan =
        planSource == null ? null : AmcPlan.fromJson(planSource);
    final List<CoveredItem> coveredItems = _toCoveredItems(
      json['covered_items'] ??
          json['covered_services'] ??
          json['services'] ??
          planSource?['covered_items'] ??
          planSource?['covered_services'] ??
          planSource?['services'],
    );
    final List<AmcScheduleMeeting> scheduleMeetings = _toScheduleMeetings(
      json['amc_schedule_meetings'] ??
          json['schedule_meetings'] ??
          json['amcScheduleMeetings'],
    );

    return CustomerAmc(
      id: _toInt(
        json['id'] ??
            json['customer_amc_id'] ??
            json['customerAmcId'] ??
            json['amc_id'] ??
            json['amcId'],
      ),
      requestId: _pickText([
        json['request_id'],
        json['requestId'],
        json['amc_request_id'],
        json['amcRequestId'],
      ]),
      amcType: _pickText([
        json['amc_type'],
        json['amcType'],
        json['support_type'],
        json['supportType'],
        plan?.supportType,
      ]),
      requestDate: _pickText([
        json['request_date'],
        json['requestDate'],
        json['created_at'],
        json['createdAt'],
      ]),
      amcNumber: _pickText([
        json['amc_number'],
        json['amc_no'],
        json['amcNo'],
        json['reference_no'],
        json['referenceNo'],
        json['number'],
        json['request_id'],
      ]),
      planName: _pickText([
        json['plan_name'],
        json['planName'],
        json['amc_name'],
        json['amcName'],
        plan?.planName,
      ]),
      planCode: _pickText([
        json['plan_code'],
        json['planCode'],
        plan?.planCode,
      ]),
      description: _pickText([
        json['description'],
        json['remarks'],
        json['notes'],
        plan?.description,
      ]),
      status: _pickText([
        json['status'],
        json['amc_status'],
        json['amcStatus'],
        plan?.status,
      ]),
      scheduleMeetingsCount: _toInt(
        json['amc_schedule_meetings_count'] ??
            json['schedule_meetings_count'] ??
            json['amcScheduleMeetingsCount'] ??
            json['scheduleMeetingsCount'],
      ),
      supportType: _pickText([
        json['support_type'],
        json['supportType'],
        plan?.supportType,
      ]),
      duration: _pickText([
        json['duration'],
        json['plan_duration'],
        json['planDuration'],
        plan?.duration,
      ]),
      totalVisits: _pickText([
        json['total_visits'],
        json['totalVisits'],
        json['visits'],
        plan?.totalVisits,
      ]),
      planCost: _pickText([
        json['plan_cost'],
        json['planCost'],
        plan?.planCost,
      ]),
      startDate: _pickText([
        json['plan_start_date'],
        json['start_date'],
        json['startDate'],
        json['amc_start_date'],
        json['amcStartDate'],
      ]),
      endDate: _pickText([
        json['plan_end_date'],
        json['end_date'],
        json['endDate'],
        json['amc_end_date'],
        json['amcEndDate'],
      ]),
      priorityLevel: _pickText([
        json['priority_level'],
        json['priorityLevel'],
      ]),
      totalAmount: _pickText([
        json['total_amount'],
        json['totalAmount'],
        json['amc_total_amount'],
        json['amcTotalAmount'],
        plan?.totalCost,
      ]),
      payTerms: _pickText([
        json['pay_terms'],
        json['payTerms'],
        plan?.payTerms,
      ]),
      additionalNotes: _pickText([
        json['additional_notes'],
        json['additionalNotes'],
        json['notes'],
        json['remarks'],
      ]),
      createdAt: _pickText([json['created_at'], json['createdAt']]),
      updatedAt: _pickText([json['updated_at'], json['updatedAt']]),
      amcPlan: plan,
      scheduleMeetings: scheduleMeetings,
      coveredItems: coveredItems,
    );
  }

  String get displayTitle =>
      _pickText([planName, amcPlan?.planName, 'AMC Service']) ?? 'AMC Service';

  String get displayCode => _pickText([amcNumber, planCode, amcPlan?.planCode]) ?? '';

  String get displayDescription =>
      _pickText([description, amcPlan?.description]) ?? '';

  String get displayRequestId => _pickText([requestId, amcNumber]) ?? '-';

  String get displayAmcType =>
      _pickText([amcType, supportType, amcPlan?.supportType]) ?? '-';

  String get displayRequestDate =>
      _pickText([requestDate, startDate, createdAt]) ?? '';

  String get displayStatus => _pickText([status, amcPlan?.status, 'pending']) ?? 'pending';

  String get displayScheduledMeetingsCount =>
      scheduleMeetingsCount?.toString() ?? '-';

  String get displaySupportType =>
      _pickText([supportType, amcPlan?.supportType]) ?? '-';

  String get displayDuration =>
      _pickText([duration, amcPlan?.duration, '0']) ?? '0';

  String get displayTotalVisits =>
      _pickText([totalVisits, amcPlan?.totalVisits, '0']) ?? '0';

  String get displayPlanCost =>
      _pickText([planCost, amcPlan?.planCost, totalAmount, amcPlan?.totalCost]) ??
      '0';

  String get displayTotalAmount =>
      _pickText([totalAmount, amcPlan?.totalCost, amcPlan?.planCost]) ?? '0';

  List<AmcScheduleMeeting> get completedScheduleMeetings =>
      scheduleMeetings
          .where((meeting) => meeting.isCompleted)
          .toList(growable: false);

  bool get hasCoveredItems => coveredItems.isNotEmpty;
}

class AmcScheduleMeeting {
  final int? id;
  final int? serviceRequestId;
  final int? amcId;
  final String? scheduledAt;
  final String? rescheduledAt;
  final String? completedAt;
  final String? remarks;
  final String? report;
  final int? visitsCount;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  const AmcScheduleMeeting({
    required this.id,
    required this.serviceRequestId,
    required this.amcId,
    required this.scheduledAt,
    required this.rescheduledAt,
    required this.completedAt,
    required this.remarks,
    required this.report,
    required this.visitsCount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  static String? _toText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  factory AmcScheduleMeeting.fromJson(Map<String, dynamic> json) {
    return AmcScheduleMeeting(
      id: _toInt(json['id']),
      serviceRequestId: _toInt(
        json['service_request_id'] ?? json['serviceRequestId'],
      ),
      amcId: _toInt(json['amc_id'] ?? json['amcId']),
      scheduledAt: _toText(json['scheduled_at'] ?? json['scheduledAt']),
      rescheduledAt: _toText(
        json['rescheduled_at'] ?? json['rescheduledAt'],
      ),
      completedAt: _toText(json['completed_at'] ?? json['completedAt']),
      remarks: _toText(json['remarks']),
      report: _toText(json['report']),
      visitsCount: _toInt(json['visits_count'] ?? json['visitsCount']),
      status: _toText(json['status']),
      createdAt: _toText(json['created_at'] ?? json['createdAt']),
      updatedAt: _toText(json['updated_at'] ?? json['updatedAt']),
    );
  }

  bool get isCompleted => (status ?? '').trim().toLowerCase() == 'completed';
}
