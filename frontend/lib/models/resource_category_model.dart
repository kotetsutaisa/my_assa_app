// lib/models/resource_category_model.dart
class ResourceCategoryModel {
  final int    id;            // サーバーは int PK
  final String name;

  const ResourceCategoryModel({
    required this.id,
    required this.name,
  });

  factory ResourceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ResourceCategoryModel(
      id        : json['id']        as int,
      name      : json['name']      as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id'     : id,
        'name'   : name,
      };
}
