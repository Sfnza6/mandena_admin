class BranchModel {
  final int id;
  final String code;
  final String name;
  final String addressText;
  final String phone;
  final double? lat;
  final double? lng;
  final double pricePerKm;
  final double maxDeliveryKm;
  final bool supportsDelivery;
  final bool supportsPickup;
  final bool isActive;
  final bool isDefault;

  const BranchModel({
    required this.id,
    required this.code,
    required this.name,
    required this.addressText,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.pricePerKm,
    required this.maxDeliveryKm,
    required this.supportsDelivery,
    required this.supportsPickup,
    required this.isActive,
    required this.isDefault,
  });

  static double _toDouble(dynamic v, [double fallback = 0]) {
    if (v == null) return fallback;
    return double.tryParse('$v') ?? fallback;
  }

  static bool _toBool(dynamic v) {
    final s = '${v ?? 0}'.toLowerCase().trim();
    return s == '1' || s == 'true';
  }

  factory BranchModel.fromJson(Map<String, dynamic> j) {
    double? nullableDouble(dynamic v) {
      if (v == null) return null;
      final s = '$v'.trim();
      if (s.isEmpty || s.toLowerCase() == 'null') return null;
      return double.tryParse(s);
    }

    return BranchModel(
      id: int.tryParse('${j['id'] ?? 0}') ?? 0,
      code: (j['code'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      addressText: (j['address_text'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString(),
      lat: nullableDouble(j['lat']),
      lng: nullableDouble(j['lng']),
      pricePerKm: _toDouble(j['price_per_km']),
      maxDeliveryKm: _toDouble(j['max_delivery_km']),
      supportsDelivery: _toBool(j['supports_delivery']),
      supportsPickup: _toBool(j['supports_pickup']),
      isActive: _toBool(j['is_active']),
      isDefault: _toBool(j['is_default']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'address_text': addressText,
    'phone': phone,
    'lat': lat,
    'lng': lng,
    'price_per_km': pricePerKm,
    'max_delivery_km': maxDeliveryKm,
    'supports_delivery': supportsDelivery ? 1 : 0,
    'supports_pickup': supportsPickup ? 1 : 0,
    'is_active': isActive ? 1 : 0,
    'is_default': isDefault ? 1 : 0,
  };

  BranchModel copyWith({
    int? id,
    String? code,
    String? name,
    String? addressText,
    String? phone,
    double? lat,
    double? lng,
    double? pricePerKm,
    double? maxDeliveryKm,
    bool? supportsDelivery,
    bool? supportsPickup,
    bool? isActive,
    bool? isDefault,
  }) {
    return BranchModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      addressText: addressText ?? this.addressText,
      phone: phone ?? this.phone,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      pricePerKm: pricePerKm ?? this.pricePerKm,
      maxDeliveryKm: maxDeliveryKm ?? this.maxDeliveryKm,
      supportsDelivery: supportsDelivery ?? this.supportsDelivery,
      supportsPickup: supportsPickup ?? this.supportsPickup,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
