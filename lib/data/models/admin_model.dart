class AdminModel {
  final int id;
  final String name;
  final String phone;
  final String avatarUrl;
  final String role;

  const AdminModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatarUrl,
    required this.role,
  });

  factory AdminModel.fromJson(Map<String, dynamic> j) => AdminModel(
    id: int.tryParse('${j['id'] ?? 0}') ?? 0,
    name: (j['name'] ?? '').toString(),
    phone: (j['phone'] ?? '').toString(),
    avatarUrl: (j['avatar_url'] ?? '').toString(),
    role: (j['role'] ?? 'admin').toString(),
  );
}
