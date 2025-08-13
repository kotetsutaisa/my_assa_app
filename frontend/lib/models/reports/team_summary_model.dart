class TeamSummaryModel {
  final String id;    // uuid
  final String name;

  const TeamSummaryModel({required this.id, required this.name});

  factory TeamSummaryModel.fromJson(Map<String, dynamic> json) {
    return TeamSummaryModel(
      id  : json['id'] as String,
      name: json['name'] as String,
    );
  }
}
