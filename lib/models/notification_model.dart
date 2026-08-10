import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  NotificationModel({
    this.id,
    this.userId,
    this.title,
    this.body,
    this.type,
    this.data,
    this.actionUrl,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? parsedData;
    final raw = map['data'];
    if (raw is Map) {
      parsedData = Map<String, dynamic>.from(
        raw.map((k, v) => MapEntry(k.toString(), v)),
      );
    } else if (raw is String && raw.isNotEmpty) {
      parsedData = {'raw': raw};
    }

    return NotificationModel(
      id: map['id']?.toString(),
      userId: map['userId']?.toString(),
      title: map['title']?.toString(),
      body: map['body']?.toString(),
      type: map['type']?.toString(),
      data: parsedData,
      actionUrl: map['actionUrl']?.toString(),
      isRead: map['isRead'] == true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is DateTime ? map['createdAt'] as DateTime : null),
    );
  }

  final String? id;
  final String? userId;
  final String? title;
  final String? body;
  final String? type;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final bool? isRead;
  final DateTime? createdAt;

  String? get jobId => data?['jobId']?.toString();
  String? get hireId => data?['hireId']?.toString();
  String? get quoteId => data?['quoteId']?.toString();
  String? get chatId => data?['chatId']?.toString();

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'actionUrl': actionUrl,
        'isRead': isRead,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    String? actionUrl,
    bool? isRead,
    DateTime? createdAt,
  }) =>
      NotificationModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        body: body ?? this.body,
        type: type ?? this.type,
        data: data ?? this.data,
        actionUrl: actionUrl ?? this.actionUrl,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
      );
}
