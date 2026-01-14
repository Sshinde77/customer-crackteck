class CompanyDetailsResponse {
  final CompanyDetails? companyDetails;

  CompanyDetailsResponse({this.companyDetails});

  factory CompanyDetailsResponse.fromJson(Map<String, dynamic> json) {
    return CompanyDetailsResponse(
      companyDetails: json['company_details'] != null 
          ? CompanyDetails.fromJson(json['company_details']) 
          : null,
    );
  }
}

class CompanyDetails {
  final int? id;
  final int? customerId;
  final String? companyName;
  final String? compAddress1;
  final String? compAddress2;
  final String? compCity;
  final String? compState;
  final String? compCountry;
  final String? compPincode;
  final String? gstNo;
  final String? createdAt;
  final String? updatedAt;

  CompanyDetails({
    this.id,
    this.customerId,
    this.companyName,
    this.compAddress1,
    this.compAddress2,
    this.compCity,
    this.compState,
    this.compCountry,
    this.compPincode,
    this.gstNo,
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyDetails.fromJson(Map<String, dynamic> json) {
    return CompanyDetails(
      id: json['id'],
      customerId: json['customer_id'] is String ? int.tryParse(json['customer_id']) : json['customer_id'],
      companyName: json['company_name'],
      compAddress1: json['comp_address1'],
      compAddress2: json['comp_address2'],
      compCity: json['comp_city'],
      compState: json['comp_state'],
      compCountry: json['comp_country'],
      compPincode: json['comp_pincode'],
      gstNo: json['gst_no'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'company_name': companyName,
      'comp_address1': compAddress1,
      'comp_address2': compAddress2,
      'comp_city': compCity,
      'comp_state': compState,
      'comp_country': compCountry,
      'comp_pincode': compPincode,
      'gst_no': gstNo,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
