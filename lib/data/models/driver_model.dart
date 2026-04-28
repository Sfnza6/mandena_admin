class DriverModel {
  final int id;
  final String name;
  final String phone;
  final String password;
  final DateTime? createdAt;
  final int? branchId;
  final String? branchName;

  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.password,
    this.createdAt,
    this.branchId,
    this.branchName,
  });

  factory DriverModel.fromJson(Map<String, dynamic> j) {
    int i(v) => int.tryParse('${v ?? 0}') ?? 0;
    String s(v) => (v ?? '').toString();

    int? branchIdFrom(dynamic v) {
      if (v == null) return null;
      final t = '$v'.trim();
      if (t.isEmpty || t == '0') return null;
      return int.tryParse(t);
    }

    String? branchNameFrom(dynamic v) {
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    final bid = branchIdFrom(j['branch_id'] ?? j['branchId']);

    return DriverModel(
      id: i(j['id']),
      name: s(j['name']),
      phone: s(j['phone']),
      password: s(j['password']),
      createdAt: j['created_at'] != null && '${j['created_at']}'.isNotEmpty
          ? DateTime.tryParse('${j['created_at']}')
          : null,
      branchId: bid,
      branchName: branchNameFrom(j['branch_name'] ?? j['branchName']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'password': password,
    'created_at': createdAt?.toIso8601String(),
    if (branchId != null) 'branch_id': branchId,
    if (branchName != null) 'branch_name': branchName,
  };

  DriverModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? password,
    DateTime? createdAt,
    int? branchId,
    String? branchName,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
    );
  }
}
