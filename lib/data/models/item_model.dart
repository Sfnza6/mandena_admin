class ItemModel {
  final int id;
  final int? branchId;
  final String name;
  final String description;
  final double price;
  final String? discount;
  final String imageUrl;
  final int categoryId;
  final double rating;
  final int orderCount;
  final bool isActive;
  final int? dailyQuota;
  final String? quotaDate;
  final int quotaUsed;
  final int? remaining;

  ItemModel({
    required this.id,
    this.branchId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    this.discount,
    this.rating = 0,
    this.orderCount = 0,
    this.isActive = true,
    this.dailyQuota,
    this.quotaDate,
    this.quotaUsed = 0,
    this.remaining,
  });

  static int _toInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  static double _toDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse('$v') ?? fallback;
  }

  static int? _toNullableInt(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return int.tryParse(s);
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

  factory ItemModel.fromJson(Map<String, dynamic> j) {
    final img =
        (j['image_url'] ?? j['imageUrl'] ?? j['image'] ?? j['photo'] ?? '')
            .toString();

    return ItemModel(
      id: _toInt(j['id']),
      branchId: _toNullableInt(j['branch_id'] ?? j['branchId']),
      name: (j['name'] ?? '').toString(),
      description: (j['description'] ?? j['desc'] ?? '').toString(),
      price: _toDouble(j['price']),
      discount: _toNullableString(j['discount']),
      imageUrl: img,
      categoryId: _toInt(j['category_id'] ?? j['categoryId']),
      rating: _toDouble(j['rating'] ?? j['avg_rating'] ?? 0),
      orderCount: _toInt(j['order_count'] ?? j['orders_count'] ?? 0),
      isActive: _toBool(
        j['is_active'] ?? j['active'] ?? j['available'] ?? 1,
        true,
      ),
      dailyQuota: _toNullableInt(j['daily_quota']),
      quotaDate: _toNullableString(j['quota_date']),
      quotaUsed: _toInt(j['quota_used'] ?? 0),
      remaining: _toNullableInt(j['remaining']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (branchId != null) 'branch_id': branchId,
    'name': name,
    'description': description,
    'price': price,
    'discount': discount,
    'image_url': imageUrl,
    'category_id': categoryId,
    'rating': rating,
    'order_count': orderCount,
    'is_active': isActive ? 1 : 0,
    'daily_quota': dailyQuota,
    'quota_date': quotaDate,
    'quota_used': quotaUsed,
    'remaining': remaining,
  };

  ItemModel copyWith({
    int? id,
    int? branchId,
    String? name,
    String? description,
    double? price,
    String? discount,
    String? imageUrl,
    int? categoryId,
    double? rating,
    int? orderCount,
    bool? isActive,
    int? dailyQuota,
    String? quotaDate,
    int? quotaUsed,
    int? remaining,
  }) {
    return ItemModel(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      rating: rating ?? this.rating,
      orderCount: orderCount ?? this.orderCount,
      isActive: isActive ?? this.isActive,
      dailyQuota: dailyQuota ?? this.dailyQuota,
      quotaDate: quotaDate ?? this.quotaDate,
      quotaUsed: quotaUsed ?? this.quotaUsed,
      remaining: remaining ?? this.remaining,
    );
  }
}
