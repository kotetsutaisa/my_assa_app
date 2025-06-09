import 'dart:convert';

import 'package:frontend/models/simple_user_model.dart';

class MessageModel {
  final String id;
  final String conversation_id;
  final SimpleUserModel sender;
  final String kind;
  final Map<String, dynamic> body;
  final DateTime createdAt;
  final bool isRead;
  final List<int> readUsers;

  MessageModel({
    required this.id,
    required this.conversation_id,
    required this.sender,
    required this.kind,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.readUsers,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawBody = json['body'];
    print(json['read_users']);


    return MessageModel(
      id: json['id'],
      conversation_id: json['conversation'],
      sender: SimpleUserModel.fromJson(json['sender']),
      kind: json['kind'],
      body: rawBody is String
        ? Map<String, dynamic>.from(jsonDecode(rawBody))
        : Map<String, dynamic>.from(rawBody),
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      readUsers: List<int>.from(json['read_users'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation': conversation_id,
    'sender': sender.toJson(),
    'kind': kind,
    'body': body,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
    'read_users': readUsers,
  };

  MessageModel copyWith({
    String? id,
    String? conversation_id,
    SimpleUserModel? sender,
    String? kind,
    Map<String, dynamic>? body,
    DateTime? createdAt,
    bool? isRead,
    List<int>? readUsers,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversation_id: conversation_id ?? this.conversation_id,
      sender: sender ?? this.sender,
      kind: kind ?? this.kind,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readUsers: readUsers ?? this.readUsers,
    );
  }
}