class StaffModel {
  final int id;
  final String name;
  final String phone;
  final String role;
  final String avatarUrl;
  final bool isActive;
  final int? branchId;

  StaffModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.avatarUrl = '',
    this.isActive = true,
    this.branchId,
  });

  factory StaffModel.fromJson(Map<String, dynamic> j) {
    int? toNullableInt(dynamic v) {
      if (v == null) return null;
      final s = '$v'.trim();
      if (s.isEmpty || s.toLowerCase() == 'null') return null;
      return int.tryParse(s);
    }

    return StaffModel(
      id: int.tryParse('${j['id']}') ?? 0,
      name: (j['name'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString(),
      role: (j['role'] ?? 'admin').toString().toLowerCase().trim(),
      avatarUrl: (j['avatar_url'] ?? j['avatarUrl'] ?? '').toString(),
      isActive: ['1', 1, true, 'true'].contains(j['is_active']),
      branchId: toNullableInt(j['branch_id'] ?? j['branchId']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'role': role,
    'avatar_url': avatarUrl,
    'is_active': isActive ? 1 : 0,
    'branch_id': branchId,
  };

  StaffModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? role,
    String? avatarUrl,
    bool? isActive,
    int? branchId,
  }) {
    return StaffModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      branchId: branchId ?? this.branchId,
    );
  }

  static StaffModel fromAdminUser(dynamic adminUser) {
    return StaffModel(
      id: int.tryParse('${adminUser.id}') ?? 0,
      name: (adminUser.name ?? '').toString(),
      phone: (adminUser.phone ?? '').toString(),
      role: (adminUser.role ?? 'admin').toString().toLowerCase().trim(),
      avatarUrl: (adminUser.avatarUrl ?? '').toString(),
      isActive: true,
      branchId: adminUser.branchId,
    );
  }
}
