class WorkCategoryModel {
  final int? id;
  final String name;

  WorkCategoryModel({required this.id, required this.name});

  factory WorkCategoryModel.fromJson(Map<String, dynamic> json) {
    return WorkCategoryModel(
      id: json['id'],
      name: json['name'],
    );
  }
}
