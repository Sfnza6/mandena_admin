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
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0.0;
    }

    return OrderModel(
      id: int.tryParse('${j['id'] ?? 0}') ?? 0,
      userId: int.tryParse('${j['user_id'] ?? 0}') ?? 0,
      userName: (j['user_name'] ?? '').toString(),
      userPhone: (j['user_phone'] ?? '').toString(),
      address: (j['address'] ?? '').toString(),
      total: toDouble(j['total']),
      status: (j['normalized_status'] ?? j['status'] ?? '').toString(),
      statusOrder: (j['status_order'] ?? '').toString(),
      driverI: (j['driver_id'] != null)
          ? int.tryParse('${j['driver_id']}') ?? 0
          : null,
      driverName: (j['driver_name'] ?? '').toString(),
      driverPhone: (j['driver_phone'] ?? '').toString(),
      createdAt: (j['created_at'] ?? '').toString(),
    );
  }

    Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'total': total,
      'status': status,
      // نكرر المفتاحين ليتوافق مع أي شكل للـ fromJson
      'status_order': statusOrder,
      'statusOrder': statusOrder,
      'driver_name': driverName,
      'driverName': driverName,
    };
  }

}
