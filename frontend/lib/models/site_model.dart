

class SiteModel {
  final String id;
  final int? companyId;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? generalContractorName;
  final String? managerName;
  final String? managerPhone;
  final String? memo;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  SiteModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.generalContractorName,
    this.managerName,
    this.managerPhone,
    this.memo,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id'],
      companyId: json['company'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      generalContractorName: json['general_contractor_name'],
      managerName: json['manager_name'],
      managerPhone: json['manager_phone'],
      memo: json['memo'],
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company': companyId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'general_contractor_name': generalContractorName,
      'manager_name': managerName,
      'manager_phone': managerPhone,
      'memo': memo,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}