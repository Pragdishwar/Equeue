class ServiceModel {
  final String id;
  final String branchId;
  final String name;
  final String description;
  final int avgServiceTime; // minutes
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ServiceModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.description,
    this.avgServiceTime = 10,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      branchId: json['branch_id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      avgServiceTime: json['avg_service_time'] as int? ?? 10,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_id': branchId,
      'name': name,
      'description': description,
      'avg_service_time': avgServiceTime,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ServiceModel copyWith({
    String? name,
    String? description,
    int? avgServiceTime,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id,
      branchId: branchId,
      name: name ?? this.name,
      description: description ?? this.description,
      avgServiceTime: avgServiceTime ?? this.avgServiceTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
