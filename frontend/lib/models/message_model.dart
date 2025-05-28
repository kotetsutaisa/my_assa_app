import 'package:frontend/models/simple_user_model.dart';

class MessageModel {
  final String id;
  final String conversation_id;
  final SimpleUserModel sender;
  final String kind;
  final Map<String, dynamic> body;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversation_id,
    required this.sender,
    required this.kind,
    required this.body,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      conversation_id: json['conversation'],
      sender: SimpleUserModel.fromJson(json['sender']),
      kind: json['kind'],
      body: Map<String, dynamic>.from(json['body']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation': conversation_id,
    'sender': sender.toJson(),
    'kind': kind,
    'body': body,
    'created_at': createdAt.toIso8601String(),
  };
}