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
    return NotificationModel(
      id: map['id']?.toString(),
      userId: map['userId'],
      title: map['title'],
      body: map['body'],
      type: map['type'],
      data: map['data'],
      actionUrl: map['actionUrl'],
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt']?.toDate(),
    );
  }
  final String? id;
  final String? userId;
  final String? title;
  final String? body;
  final String? type; // 'job', 'message', 'payment', 'promotion', 'system'
  final String? data;
  final String? actionUrl;
  final bool? isRead;
  final DateTime? createdAt;

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
    String? data,
    String? actionUrl,
    bool? isRead,
    DateTime? createdAt,
  }) => NotificationModel(
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
