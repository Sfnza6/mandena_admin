import 'dart:convert';

class OfferModel {
  final int id;
  final int? branchId;
  final String title;
  final String imageUrl;
  final double? price;
  final String? description;
  final bool isActive;

  const OfferModel({
    required this.id,
    this.branchId,
    required this.title,
    required this.imageUrl,
    this.price,
    this.description,
    this.isActive = true,
  });

  static int _toInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  static double? _toNullableDouble(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return double.tryParse(s);
  }

  static String? _toNullableString(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return s;
  }

  static bool _toBool(dynamic v, [bool fallback = true]) {
    if (v == null) return fallback;
    final s = '$v'.toLowerCase().trim();
    return s == '1' || s == 'true' || s == 'yes';
  }

  factory OfferModel.fromJson(Map<String, dynamic> j) {
    return OfferModel(
      id: _toInt(j['id']),
      branchId: _toInt(j['branch_id'] ?? j['branchId'], -1) < 0
          ? null
          : _toInt(j['branch_id'] ?? j['branchId']),
      title: (j['title'] ?? j['name'] ?? j['caption'] ?? '').toString(),
      imageUrl: (j['image_url'] ?? j['image'] ?? j['photo'] ?? '').toString(),
      price: _toNullableDouble(j['price']),
      description: _toNullableString(j['description'] ?? j['desc']),
      isActive: _toBool(j['is_active'] ?? j['active'] ?? j['status'], true),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (branchId != null) 'branch_id': branchId,
    'title': title,
    'image_url': imageUrl,
    if (price != null) 'price': price,
    if (description != null) 'description': description,
    'is_active': isActive ? 1 : 0,
  };

  OfferModel copyWith({
    int? id,
    int? branchId,
    String? title,
    String? imageUrl,
    double? price,
    String? description,
    bool? isActive,
  }) {
    return OfferModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is OfferModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
