class DriverModel {
  final int id;
  final String name;
  final String phone;
  final String password;
  final DateTime? createdAt;

  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.password,
    this.createdAt,
  });

  factory DriverModel.fromJson(Map<String, dynamic> j) {
    int i(v) => int.tryParse('${v ?? 0}') ?? 0;
    String s(v) => (v ?? '').toString();

    return DriverModel(
      id: i(j['id']),
      name: s(j['name']),
      phone: s(j['phone']),
      password: s(j['password']),
      createdAt: j['created_at'] != null && '${j['created_at']}'.isNotEmpty
          ? DateTime.tryParse('${j['created_at']}')
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'password': password,
    'created_at': createdAt?.toIso8601String(),
  };

  DriverModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? password,
    DateTime? createdAt,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
