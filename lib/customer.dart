class Customer {
  int? id;
  int area = 0;
  String userGroup = '';
  String companyName = '';
  int customerRate = 0;
  String username = '';
  String addressLine1 = '';
  String addressLine2 = '';
  String contactNumber = '';
  String email = '';

  Customer({
    this.id,
    this.area = 0,
    this.userGroup = '',
    this.companyName = '',
    this.customerRate = 0,
    this.username = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.contactNumber = '',
    this.email = '',
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      area: map['area'] ?? 0,
      userGroup: map['user_group'] ?? '',
      companyName: map['company_name'] ?? '',
      customerRate: map['customer_rate'] ?? 0,
      username: map['username'] ?? '',
      addressLine1: map['address_line_1'] ?? '',
      addressLine2: map['address_line_2'] ?? '',
      contactNumber: map['contact_number'] ?? '',
      email: map['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'area': area,
      'user_group': userGroup,
      'company_name': companyName,
      'customer_rate': customerRate,
      'username': username,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'contact_number': contactNumber,
      'email': email,
    };
  }
}
