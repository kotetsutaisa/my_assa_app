class LastMessage {
  final String? content;
  final DateTime? createdAt;

  LastMessage({this.content, this.createdAt});

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    print('🟨 LastMessage 受信: $json');
    return LastMessage(
      content: json['content'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'content': content,
    'created_at': createdAt?.toIso8601String(),
  };
  
}
