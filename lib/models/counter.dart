import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENUM
// ─────────────────────────────────────────────────────────────────────────────

enum CounterStatus {
  open('open'),
  closed('closed');

  const CounterStatus(this.value);
  final String value;

  static CounterStatus fromString(String value) {
    return CounterStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CounterStatus.closed,
    );
  }

  String get label {
    switch (this) {
      case CounterStatus.open:
        return 'Open';
      case CounterStatus.closed:
        return 'Closed';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class Counter {
  const Counter({
    required this.id,
    required this.branchId,
    required this.serviceId,
    required this.name,
    required this.status,
    this.currentTokenId,
  });

  final String id;
  final String branchId;
  final String serviceId;
  final String name;
  final CounterStatus status;
  final String? currentTokenId;

  // ── HELPERS ───────────────────────────────────────────────────────────

  bool get isOpen => status == CounterStatus.open;
  bool get isBusy => currentTokenId != null;

  // ── JSON ──────────────────────────────────────────────────────────────

  factory Counter.fromJson(Map<String, dynamic> json) {
    return Counter(
      id: json['id'] as String,
      branchId: json['branch_id'] as String,
      serviceId: json['service_id'] as String,
      name: json['name'] as String? ?? '',
      status: CounterStatus.fromString(json['status'] as String? ?? 'closed'),
      currentTokenId: json['current_token_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_id': branchId,
      'service_id': serviceId,
      'name': name,
      'status': status.value,
      'current_token_id': currentTokenId,
    };
  }

  // ── COPY WITH ─────────────────────────────────────────────────────────

  Counter copyWith({
    String? id,
    String? branchId,
    String? serviceId,
    String? name,
    CounterStatus? status,
    String? currentTokenId,
  }) {
    return Counter(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
      status: status ?? this.status,
      currentTokenId: currentTokenId ?? this.currentTokenId,
    );
  }

  // ── EQUALITY ──────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Counter &&
        other.id == id &&
        other.branchId == branchId &&
        other.serviceId == serviceId &&
        other.name == name &&
        other.status == status &&
        other.currentTokenId == currentTokenId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        branchId,
        serviceId,
        name,
        status,
        currentTokenId,
      );

  @override
  String toString() {
    return 'Counter(id: $id, name: $name, status: ${status.label}, '
        'currentTokenId: $currentTokenId)';
  }
}
