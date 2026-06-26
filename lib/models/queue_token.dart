enum TokenStatus { waiting, called, serving, completed, cancelled, skipped, noShow }

class QueueToken {
  final String id;
  final String userId;
  final String serviceId;
  final String branchId;
  final String tokenNumber;
  final int position;
  final TokenStatus status;
  final DateTime createdAt;
  final DateTime? calledAt;
  final DateTime? completedAt;
  final String? serviceName;
  final String? branchName;
  final int? estimatedWaitMinutes;
  final String qrCode;
  final String? userName;

  const QueueToken({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.branchId,
    required this.tokenNumber,
    required this.position,
    this.status = TokenStatus.waiting,
    required this.createdAt,
    this.calledAt,
    this.completedAt,
    this.serviceName,
    this.branchName,
    this.estimatedWaitMinutes,
    required this.qrCode,
    this.userName,
  });

  factory QueueToken.fromJson(Map<String, dynamic> json) {
    return QueueToken(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      serviceId: json['service_id'] as String,
      branchId: json['branch_id'] as String,
      tokenNumber: json['token_number'] as String? ?? '',
      position: json['position'] as int? ?? 0,
      status: _parseStatus(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      calledAt: json['called_at'] != null
          ? DateTime.parse(json['called_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      serviceName: json['service_name'] as String? ??
          (json['services'] is Map ? json['services']['name'] as String? : null),
      branchName: json['branch_name'] as String? ??
          (json['branches'] is Map ? json['branches']['name'] as String? : null),
      estimatedWaitMinutes: json['estimated_wait_minutes'] as int?,
      qrCode: json['qr_code'] as String? ?? json['id'] as String,
      userName: json['user_name'] as String? ??
          (json['profiles'] is Map ? json['profiles']['full_name'] as String? : null),
    );
  }

  static TokenStatus _parseStatus(String? status) {
    switch (status) {
      case 'waiting':
        return TokenStatus.waiting;
      case 'called':
        return TokenStatus.called;
      case 'serving':
        return TokenStatus.serving;
      case 'completed':
        return TokenStatus.completed;
      case 'cancelled':
        return TokenStatus.cancelled;
      case 'skipped':
        return TokenStatus.skipped;
      case 'no_show':
        return TokenStatus.noShow;
      default:
        return TokenStatus.waiting;
    }
  }

  String get statusString {
    switch (status) {
      case TokenStatus.waiting:
        return 'waiting';
      case TokenStatus.called:
        return 'called';
      case TokenStatus.serving:
        return 'serving';
      case TokenStatus.completed:
        return 'completed';
      case TokenStatus.cancelled:
        return 'cancelled';
      case TokenStatus.skipped:
        return 'skipped';
      case TokenStatus.noShow:
        return 'no_show';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'service_id': serviceId,
      'branch_id': branchId,
      'token_number': tokenNumber,
      'position': position,
      'status': statusString,
      'created_at': createdAt.toIso8601String(),
      'qr_code': qrCode,
      if (calledAt != null) 'called_at': calledAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
    };
  }

  QueueToken copyWith({
    int? position,
    TokenStatus? status,
    DateTime? calledAt,
    DateTime? completedAt,
    String? serviceName,
    String? branchName,
    int? estimatedWaitMinutes,
    String? qrCode,
    String? userName,
  }) {
    return QueueToken(
      id: id,
      userId: userId,
      serviceId: serviceId,
      branchId: branchId,
      tokenNumber: tokenNumber,
      position: position ?? this.position,
      status: status ?? this.status,
      createdAt: createdAt,
      calledAt: calledAt ?? this.calledAt,
      completedAt: completedAt ?? this.completedAt,
      serviceName: serviceName ?? this.serviceName,
      branchName: branchName ?? this.branchName,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      qrCode: qrCode ?? this.qrCode,
      userName: userName ?? this.userName,
    );
  }

  bool get isActive =>
      status == TokenStatus.waiting ||
      status == TokenStatus.called ||
      status == TokenStatus.serving;

  String get statusLabel {
    switch (status) {
      case TokenStatus.waiting:
        return 'Waiting';
      case TokenStatus.called:
        return 'Your Turn!';
      case TokenStatus.serving:
        return 'Being Served';
      case TokenStatus.completed:
        return 'Completed';
      case TokenStatus.cancelled:
        return 'Cancelled';
      case TokenStatus.skipped:
        return 'Skipped';
      case TokenStatus.noShow:
        return 'No Show';
    }
  }
}
