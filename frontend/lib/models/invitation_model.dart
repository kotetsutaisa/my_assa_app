class InvitationModel {
  final String id;
  final String conversationId;
  final String invitedBy;
  final String title;
  final DateTime invitedAt;

  InvitationModel({
    required this.id,
    required this.conversationId,
    required this.invitedBy,
    required this.title,
    required this.invitedAt,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'],
      conversationId: json['conversation'],
      invitedBy: json['invited_by'],
      title: json['title'],
      invitedAt: DateTime.parse(json['invited_at']),
    );
  }
}
