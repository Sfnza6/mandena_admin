class DashboardStats {
  final int items;
  final int orders;
  final int customers;
  final int drivers;

  DashboardStats({
    required this.items,
    required this.orders,
    required this.customers,
    required this.drivers,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    int i(v) => int.tryParse('$v') ?? 0;
    return DashboardStats(
      items: i(json['items']),
      orders: i(json['orders']),
      customers: i(json['customers']),
      drivers: i(json['drivers']),
    );
  }

  // ===============================
  // 🔹 الدالة المطلوبة للكاش toJson()
  // ===============================
  Map<String, dynamic> toJson() {
    return {
      'items': items,
      'orders': orders,
      'customers': customers,
      'drivers': drivers,
    };
  }
}
