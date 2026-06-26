import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.contact,
    required this.isActive,
    required this.createdAt,
    this.servicesCount,
  });

  final String id;
  final String name;
  final String address;
  final String contact;
  final bool isActive;
  final DateTime createdAt;
  final int? servicesCount;

  // ── JSON ──────────────────────────────────────────────────────────────

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      servicesCount: json['services_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'contact': contact,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      if (servicesCount != null) 'services_count': servicesCount,
    };
  }

  // ── COPY WITH ─────────────────────────────────────────────────────────

  Branch copyWith({
    String? id,
    String? name,
    String? address,
    String? contact,
    bool? isActive,
    DateTime? createdAt,
    int? servicesCount,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      servicesCount: servicesCount ?? this.servicesCount,
    );
  }

  // ── EQUALITY ──────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Branch &&
        other.id == id &&
        other.name == name &&
        other.address == address &&
        other.contact == contact &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.servicesCount == servicesCount;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        address,
        contact,
        isActive,
        createdAt,
        servicesCount,
      );

  @override
  String toString() {
    return 'Branch(id: $id, name: $name, address: $address, '
        'contact: $contact, isActive: $isActive, '
        'servicesCount: $servicesCount, createdAt: $createdAt)';
  }
}
