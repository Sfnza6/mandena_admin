import 'dart:convert';

class CategoryModel {
  final int id;
  final int? branchId;
  final String name;
  final String image;
  final bool active;

  const CategoryModel({
    required this.id,
    this.branchId,
    required this.name,
    required this.image,
    required this.active,
  });

  static int _toInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  static int? _toNullableInt(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return int.tryParse(s);
  }

  static bool _toBool(dynamic v, [bool fallback = true]) {
    if (v == null) return fallback;
    final s = '$v'.toLowerCase().trim();
    return s == '1' || s == 'true' || s == 'yes';
  }

  static String _toStringValue(dynamic v) => (v ?? '').toString();

  CategoryModel copyWith({
    int? id,
    int? branchId,
    String? name,
    String? image,
    bool? active,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      image: image ?? this.image,
      active: active ?? this.active,
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> j) {
    return CategoryModel(
      id: _toInt(j['id']),
      branchId: _toNullableInt(j['branch_id'] ?? j['branchId']),
      name: _toStringValue(j['name'] ?? j['title']),
      image: _toStringValue(j['image_url'] ?? j['image'] ?? j['photo']),
      active: _toBool(j['active'] ?? j['is_active'] ?? j['status'], true),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (branchId != null) 'branch_id': branchId,
    'name': name,
    'image_url': image,
    'active': active ? 1 : 0,
  };

  @override
  String toString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CategoryModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
