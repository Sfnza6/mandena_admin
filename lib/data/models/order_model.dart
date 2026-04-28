class OrderModel {
  final int id;
  final int userId;
  final String? userName;
  final String? userPhone;
  final String address;
  final double total;
  final String status;
  final String statusOrder;
  final int? driverI;
  final String? driverName;
  final String? driverPhone;
  final String createdAt;

  /// ✅ مهم لفلترة سجل الطلبات حسب الفرع
  final int? branchId;
  final String? branchName;

  OrderModel({
    required this.id,
    required this.userId,
    required this.address,
    required this.total,
    required this.status,
    required this.statusOrder,
    required this.createdAt,
    this.userName,
    this.userPhone,
    this.driverI,
    this.driverName,
    this.driverPhone,
    this.branchId,
    this.branchName,
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0.0;
    }

    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('${v ?? 0}') ?? 0;
    }

    int? toNullableInt(dynamic v) {
      if (v == null) return null;
      final text = '$v'.trim();
      if (text.isEmpty || text == 'null') return null;
      return int.tryParse(text);
    }

    String? toNullableString(dynamic v) {
      if (v == null) return null;
      final text = '$v'.trim();
      if (text.isEmpty || text == 'null') return null;
      return text;
    }

    return OrderModel(
      id: toInt(j['id']),
      userId: toInt(j['user_id'] ?? j['userId']),
      userName: toNullableString(
        j['user_name'] ?? j['username'] ?? j['name'] ?? j['userName'],
      ),
      userPhone: toNullableString(
        j['user_phone'] ?? j['phone'] ?? j['userPhone'],
      ),
      address: (j['address'] ?? j['address_name'] ?? '').toString(),
      total: toDouble(j['total'] ?? j['total_price'] ?? j['orders_total']),
      status: (j['normalized_status'] ?? j['status'] ?? '').toString(),
      statusOrder: (j['status_order'] ?? j['statusOrder'] ?? '').toString(),
      driverI: toNullableInt(j['driver_id'] ?? j['driverId']),
      driverName: toNullableString(j['driver_name'] ?? j['driverName']),
      driverPhone: toNullableString(j['driver_phone'] ?? j['driverPhone']),
      createdAt: (j['created_at'] ?? j['createdAt'] ?? '').toString(),

      /// ✅ دعم أكثر من اسم محتمل من PHP / JSON
      branchId: toNullableInt(j['branch_id'] ?? j['branchId']),
      branchName: toNullableString(j['branch_name'] ?? j['branchName']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'userId': userId,
      'user_name': userName,
      'userName': userName,
      'user_phone': userPhone,
      'userPhone': userPhone,
      'address': address,
      'total': total,
      'status': status,

      // نكرر المفتاحين ليتوافق مع أي شكل للـ fromJson
      'status_order': statusOrder,
      'statusOrder': statusOrder,

      'driver_id': driverI,
      'driverId': driverI,
      'driver_name': driverName,
      'driverName': driverName,
      'driver_phone': driverPhone,
      'driverPhone': driverPhone,
      'created_at': createdAt,
      'createdAt': createdAt,

      /// ✅ مهم لفلترة الفروع والكاش
      'branch_id': branchId,
      'branchId': branchId,
      'branch_name': branchName,
      'branchName': branchName,
    };
  }

  OrderModel copyWith({
    int? id,
    int? userId,
    String? userName,
    String? userPhone,
    String? address,
    double? total,
    String? status,
    String? statusOrder,
    int? driverI,
    String? driverName,
    String? driverPhone,
    String? createdAt,
    int? branchId,
    String? branchName,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      address: address ?? this.address,
      total: total ?? this.total,
      status: status ?? this.status,
      statusOrder: statusOrder ?? this.statusOrder,
      createdAt: createdAt ?? this.createdAt,
      driverI: driverI ?? this.driverI,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
    );
  }
}
