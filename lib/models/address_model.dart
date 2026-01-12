class AddressModel {
  final int? id;
  final String? branchName;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final bool isDefault;

  AddressModel({
    this.id,
    this.branchName,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      branchName: json['branch_name'],
      addressLine1: json['address1'] ?? json['address_line1'] ?? '',
      addressLine2: json['address2'] ?? json['address_line2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      pincode: json['pincode'] ?? '',
      isDefault: json['is_primary'] == 'yes' || json['is_default'] == 1 || json['is_default'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'branch_name': branchName,
      'address1': addressLine1,
      'address2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'is_primary': isDefault ? 'yes' : 'no',
    };
  }
}
