import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENUM
// ─────────────────────────────────────────────────────────────────────────────

enum NotificationType {
  queueUpdate('queue_update'),
  turnReminder('turn_reminder'),
  delay('delay'),
  completion('completion');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.queueUpdate,
    );
  }

  String get label {
    switch (this) {
      case NotificationType.queueUpdate:
        return 'Queue Update';
      case NotificationType.turnReminder:
        return 'Turn Reminder';
      case NotificationType.delay:
        return 'Delay';
      case NotificationType.completion:
        return 'Completion';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  // ── JSON ──────────────────────────────────────────────────────────────

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String? ?? 'queue_update'),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type.value,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ── COPY WITH ─────────────────────────────────────────────────────────

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ── EQUALITY ──────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.message == message &&
        other.type == type &&
        other.isRead == isRead &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        title,
        message,
        type,
        isRead,
        createdAt,
      );

  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, type: ${type.label}, '
        'isRead: $isRead, createdAt: $createdAt)';
  }
}
