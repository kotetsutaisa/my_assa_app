class Company {
  final int id;
  final String name;
  final String address;
  final String phone;
  final bool isApproved;

  Company({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.isApproved,
  });

  /// JSON → モデル
  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      isApproved: json['is_approved'],
    );
  }

  /// モデル → JSON（あとで PUT/PATCH に使える）
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
      };
}

