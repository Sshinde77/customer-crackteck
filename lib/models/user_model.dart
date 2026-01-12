class UserModel {
  final int? id;
  final String? customerCode;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? dob;
  final String? gender;
  final String? customerType;
  final String? sourceType;
  final String? status;
  final String? updatedAt;

  UserModel({
    this.id,
    this.customerCode,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.dob,
    this.gender,
    this.customerType,
    this.sourceType,
    this.status,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? json;
    return UserModel(
      id: user['id'],
      customerCode: user['customer_code'],
      firstName: user['first_name'],
      lastName: user['last_name'],
      phone: user['phone'],
      email: user['email'],
      dob: user['dob'],
      gender: user['gender'],
      customerType: user['customer_type'],
      sourceType: user['source_type'],
      status: user['status'],
      updatedAt: user['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_code': customerCode,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'dob': dob,
      'gender': gender,
      'customer_type': customerType,
      'source_type': sourceType,
      'status': status,
      'updated_at': updatedAt,
    };
  }
}
