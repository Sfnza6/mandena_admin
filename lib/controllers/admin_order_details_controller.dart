import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';

import '../core/config/env.dart';
import '../core/services/api_service.dart';

class AdminOrderExtraModel {
  final String name;
  final int quantity;
  final double price;
  final double lineTotal;

  AdminOrderExtraModel({
    required this.name,
    required this.quantity,
    required this.price,
    required this.lineTotal,
  });

  factory AdminOrderExtraModel.fromJson(Map<String, dynamic> j) =>
      AdminOrderExtraModel(
        name: (j['name'] ?? '').toString(),
        quantity: int.tryParse('${j['quantity'] ?? 1}') ?? 1,
        price: (j['price'] is num)
            ? (j['price'] as num).toDouble()
            : (double.tryParse('${j['price']}') ?? 0.0),
        lineTotal: (j['line_total'] is num)
            ? (j['line_total'] as num).toDouble()
            : (double.tryParse('${j['line_total']}') ?? 0.0),
      );
}

class AdminOrderComponentModel {
  final int id;
  final String name;
  final int quantity;
  final double price;

  AdminOrderComponentModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory AdminOrderComponentModel.fromJson(Map<String, dynamic> j) =>
      AdminOrderComponentModel(
        id: int.tryParse('${j['id'] ?? j['com_id'] ?? 0}') ?? 0,
        name: (j['name'] ?? j['title'] ?? '').toString(),
        quantity: int.tryParse('${j['quantity'] ?? j['qty'] ?? 1}') ?? 1,
        price: (j['price'] is num)
            ? (j['price'] as num).toDouble()
            : (double.tryParse('${j['price']}') ?? 0.0),
      );
}

class AdminOrderItemModel {
  final int orderItemId;
  final int itemId;
  final String name;
  final int quantity;
  final double price;
  final double lineTotal;
  final double lineTotalWithExtras;
  final List<AdminOrderExtraModel> extras;
  final List<AdminOrderComponentModel> componentsAdd;
  final List<AdminOrderComponentModel> componentsRem;

  AdminOrderItemModel({
    required this.orderItemId,
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.lineTotal,
    required this.lineTotalWithExtras,
    required this.extras,
    required this.componentsAdd,
    required this.componentsRem,
  });

  factory AdminOrderItemModel.fromJson(Map<String, dynamic> j) {
    final orderItemId = int.tryParse('${j['order_item_id']}') ?? 0;
    final itemId = int.tryParse('${j['item_id']}') ?? 0;

    List asList(v) {
      if (v is List) return v;
      if (v is String && v.trim().startsWith('[')) {
        try {
          return jsonDecode(v) as List;
        } catch (_) {}
      }
      return const [];
    }

    List pickList(Map<String, dynamic> src, List<String> keys) {
      for (final k in keys) {
        if (src[k] != null) {
          final lst = asList(src[k]);
          if (lst.isNotEmpty) return lst;
        }
      }
      return const [];
    }

    bool belongsToThisItem(Map<String, dynamic> m) {
      final oi =
          int.tryParse('${m['order_item_id'] ?? m['oi_id'] ?? ''}') ?? -1;
      final ii = int.tryParse('${m['item_id'] ?? m['itemId'] ?? ''}') ?? -1;
      if (oi > 0) return oi == orderItemId;
      if (ii > 0) return ii == itemId;
      return true;
    }

    final extrasList = pickList(j, const ['extras'])
        .map((e) => AdminOrderExtraModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final addList = pickList(j, const ['components_add', 'componentsAdd'])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where(belongsToThisItem)
        .map(AdminOrderComponentModel.fromJson)
        .toList();

    final remList =
        pickList(j, const [
              'components_rem',
              'componentsRem',
              'components_removed',
            ])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where(belongsToThisItem)
            .map(AdminOrderComponentModel.fromJson)
            .toList();

    final lineTotal = (j['line_total'] is num)
        ? (j['line_total'] as num).toDouble()
        : (double.tryParse('${j['line_total']}') ?? 0.0);

    final extrasSum = extrasList.fold<double>(
      0.0,
      (s, x) => s + (x.price * x.quantity),
    );
    final addSum = addList.fold<double>(
      0.0,
      (s, x) => s + (x.price * x.quantity),
    );

    final withExtras = (j['line_total_with_extras'] is num)
        ? (j['line_total_with_extras'] as num).toDouble()
        : (double.tryParse('${j['line_total_with_extras']}') ??
              (lineTotal + extrasSum + addSum));

    return AdminOrderItemModel(
      orderItemId: orderItemId,
      itemId: itemId,
      name: (j['name'] ?? j['title'] ?? '').toString(),
      quantity: int.tryParse('${j['quantity'] ?? 0}') ?? 0,
      price: (j['price'] is num)
          ? (j['price'] as num).toDouble()
          : (double.tryParse('${j['price']}') ?? 0.0),
      lineTotal: lineTotal,
      lineTotalWithExtras: withExtras,
      extras: extrasList,
      componentsAdd: addList,
      componentsRem: remList,
    );
  }
}

class AdminOrderHeaderModel {
  final int id;
  final int userId;
  final int driverId;
  final String status;
  final String statusOrder;
  final double total;
  final String address;
  final String createdAt;
  final double deliveryFee;
  final double grandTotal;
  final int paymentMethod;
  final String gateway;
  final int branchId;

  AdminOrderHeaderModel({
    required this.id,
    required this.userId,
    required this.driverId,
    required this.status,
    required this.statusOrder,
    required this.total,
    required this.address,
    required this.createdAt,
    required this.deliveryFee,
    required this.grandTotal,
    required this.paymentMethod,
    required this.gateway,
    required this.branchId,
  });

  factory AdminOrderHeaderModel.fromJson(Map<String, dynamic> j) =>
      AdminOrderHeaderModel(
        id: int.tryParse('${j['id']}') ?? 0,
        userId: int.tryParse('${j['user_id']}') ?? 0,
        driverId: int.tryParse('${j['driver_id']}') ?? 0,
        status: (j['status'] ?? '').toString(),
        statusOrder: (j['status_order'] ?? '').toString(),
        total: (j['total'] is num)
            ? (j['total'] as num).toDouble()
            : (double.tryParse('${j['total']}') ?? 0.0),
        address: (j['address'] ?? '').toString(),
        createdAt: (j['created_at'] ?? '').toString(),
        deliveryFee: (j['delivery_fee'] is num)
            ? (j['delivery_fee'] as num).toDouble()
            : (double.tryParse('${j['delivery_fee']}') ?? 0.0),
        grandTotal: (j['grand_total'] is num)
            ? (j['grand_total'] as num).toDouble()
            : (double.tryParse('${j['grand_total']}') ?? 0.0),
        paymentMethod: int.tryParse('${j['payment_method'] ?? 0}') ?? 0,
        gateway: (j['gateway'] ?? '').toString(),
        branchId: int.tryParse('${j['branch_id'] ?? 0}') ?? 0,
      );
}

class AdminOrderCustomerModel {
  final int id;
  final String name;
  final String phone;
  final String address;

  const AdminOrderCustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory AdminOrderCustomerModel.fromJson(Map<String, dynamic> j) =>
      AdminOrderCustomerModel(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        name: (j['name'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        address: (j['address'] ?? '').toString(),
      );
}

class AdminOrderBranchModel {
  final int id;
  final String name;
  final String address;
  final String phone;

  const AdminOrderBranchModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
  });

  factory AdminOrderBranchModel.fromJson(Map<String, dynamic> j) =>
      AdminOrderBranchModel(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        name: (j['name'] ?? '').toString(),
        address: (j['address'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
      );
}

class _OrderDetailsCacheEntry {
  final AdminOrderHeaderModel header;
  final List<AdminOrderItemModel> items;
  final Map<String, dynamic>? driver;
  final AdminOrderCustomerModel? customer;
  final AdminOrderBranchModel? branch;
  final DateTime at;

  const _OrderDetailsCacheEntry({
    required this.header,
    required this.items,
    required this.driver,
    required this.customer,
    required this.branch,
    required this.at,
  });
}

class AdminOrderDetailsController extends GetxController {
  final _api = ApiService();

  final loading = false.obs;
  final header = Rxn<AdminOrderHeaderModel>();
  final items = <AdminOrderItemModel>[].obs;
  final driver = Rxn<Map<String, dynamic>>();
  final customer = Rxn<AdminOrderCustomerModel>();
  final branch = Rxn<AdminOrderBranchModel>();

  late int orderId;
  int? userId;

  static final Map<int, _OrderDetailsCacheEntry> _cache = {};
  static const Duration _ttl = Duration(seconds: 30);

  bool _fresh(DateTime? t) {
    if (t == null) return false;
    return DateTime.now().difference(t) < _ttl;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    orderId =
        int.tryParse(
          '${args?['orderId'] ?? args?['order_id'] ?? args?['id'] ?? 0}',
        ) ??
        0;
    userId = int.tryParse('${args?['userId'] ?? args?['user_id'] ?? ''}');
  }

  @override
  void onReady() {
    super.onReady();
    fetch();
  }

  Future<void> fetch() async {
    if (orderId <= 0) {
      Get.snackbar('تنبيه', 'رقم الطلب غير صحيح');
      return;
    }

    final cached = _cache[orderId];
    if (cached != null && _fresh(cached.at)) {
      header.value = cached.header;
      items.assignAll(cached.items);
      driver.value = cached.driver;
      customer.value = cached.customer;
      branch.value = cached.branch;
      return;
    }

    try {
      loading(true);
      final res = await _api.get(
        Env.orderDetails,
        query: {
          'order_id': '$orderId',
          if (userId != null) 'user_id': '$userId',
          't': '${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      final root = res is String ? jsonDecode(res) : res;
      if (root is! Map) {
        _clear();
        Get.snackbar('خطأ', 'رد غير متوقع من الخادم');
        return;
      }

      final data = (root['data'] is Map)
          ? Map<String, dynamic>.from(root['data'])
          : Map<String, dynamic>.from(root);

      final hdr = AdminOrderHeaderModel.fromJson(
        Map<String, dynamic>.from(data['order'] ?? const {}),
      );
      final parsedItems = ((data['items'] ?? const []) as List)
          .map(
            (e) => AdminOrderItemModel.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();

      final parsedDriver = (data['driver'] is Map)
          ? Map<String, dynamic>.from(data['driver'])
          : null;
      final parsedCustomer = (data['customer'] is Map)
          ? AdminOrderCustomerModel.fromJson(
              Map<String, dynamic>.from(data['customer']),
            )
          : null;
      final parsedBranch = (data['branch'] is Map)
          ? AdminOrderBranchModel.fromJson(
              Map<String, dynamic>.from(data['branch']),
            )
          : null;

      header.value = hdr;
      items.assignAll(parsedItems);
      driver.value = parsedDriver;
      customer.value = parsedCustomer;
      branch.value = parsedBranch;

      _cache[orderId] = _OrderDetailsCacheEntry(
        header: hdr,
        items: parsedItems,
        driver: parsedDriver,
        customer: parsedCustomer,
        branch: parsedBranch,
        at: DateTime.now(),
      );
    } catch (e) {
      _clear();
      Get.snackbar('خطأ', _friendlyError(e));
    } finally {
      loading(false);
    }
  }

  void _clear() {
    header.value = null;
    items.clear();
    driver.value = null;
    customer.value = null;
    branch.value = null;
  }

  double get itemsBaseTotal {
    return items.fold<double>(0.0, (s, it) => s + it.lineTotal);
  }

  double get extrasAndAddsTotal {
    return items.fold<double>(
      0.0,
      (sum, it) =>
          sum +
          it.extras.fold<double>(0.0, (a, e) => a + (e.price * e.quantity)) +
          it.componentsAdd.fold<double>(
            0.0,
            (a, c) => a + (c.price * c.quantity),
          ),
    );
  }

  double get itemsTotal {
    return items.fold<double>(0.0, (s, it) => s + it.lineTotalWithExtras);
  }

  double get computedGrandTotal {
    final h = header.value;
    if (h == null) return 0.0;
    if (h.grandTotal > 0) return h.grandTotal;
    return itemsTotal + h.deliveryFee;
  }

  String orderTypeArabic(String key) {
    switch (key.toLowerCase().trim()) {
      case 'pickup':
      case 'takeaway':
        return 'استلام';
      case 'delivery':
        return 'توصيل';
      default:
        return key;
    }
  }

  String statusArabic(String key) {
    switch (key.toLowerCase().trim()) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'قيد التجهيز';
      case 'assigned':
        return 'تم إسناده للسائق';
      case 'accepted':
        return 'مقبول';
      case 'cancelled':
        return 'ملغي';
      case 'success':
      case 'delivered':
        return 'مكتمل';
      case 'on_way':
      case 'on the way':
        return 'في الطريق';
      default:
        return key;
    }
  }

  String paymentMethodArabic(AdminOrderHeaderModel h) {
    final isOnline =
        h.paymentMethod == 1 ||
        (h.gateway.isNotEmpty && h.gateway.toLowerCase() != 'cash');
    return isOnline ? 'دفع أونلاين' : 'دفع عند الاستلام';
  }

  String gatewayArabic(String gateway) {
    switch (gateway.toLowerCase().trim()) {
      case 'yusor':
      case 'yesser':
        return 'يسر / مصرف الجمهورية';
      case 'sahari':
        return 'الصحاري';
      case 'aman':
        return 'الأمان';
      case 'tadawul':
        return 'تداول';
      case 'cash':
      case '':
        return '—';
      default:
        return gateway;
    }
  }

  String _friendlyError(Object e) {
    final t = e.toString().toLowerCase();
    if (e is TimeoutException || t.contains('timeout')) {
      return 'انتهت مهلة الاتصال';
    }
    if (e is SocketException || t.contains('socket')) {
      return 'تعذر الاتصال بالخادم';
    }
    if (t.contains('404')) return 'الملف المطلوب غير موجود على السيرفر';
    if (t.contains('500')) return 'حصل خطأ داخلي في السيرفر';
    return 'تعذر تحميل تفاصيل الطلب';
  }
}
