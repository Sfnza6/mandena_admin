// lib/controllers/admin_order_details_controller.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';

import '../core/services/api_service.dart';
import '../core/config/env.dart';

/* ============================================================
   Extra Model
   ============================================================ */
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

/* ============================================================
   Component Model
   ============================================================ */
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

/* ============================================================
   Item Model
   ============================================================ */
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
        if (src.containsKey(k) && src[k] != null) {
          final v = src[k];
          final lst = asList(v);
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

    final extrasList = (j['extras'] is List)
        ? (j['extras'] as List)
            .map(
              (e) =>
                  AdminOrderExtraModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList()
        : const <AdminOrderExtraModel>[];

    final rawAdd = pickList(j, const [
      'components_add',
      'componentsAdd',
    ]).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final rawRem = pickList(j, const [
      'components_rem',
      'componentsRem',
      'components_removed',
    ]).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final compsAdd = rawAdd
        .where(belongsToThisItem)
        .map(AdminOrderComponentModel.fromJson)
        .toList();

    final compsRem = rawRem
        .where(belongsToThisItem)
        .map(AdminOrderComponentModel.fromJson)
        .toList();

    final lineTotalVal = (j['line_total'] is num)
        ? (j['line_total'] as num).toDouble()
        : (double.tryParse('${j['line_total']}') ?? 0.0);

    final extrasSum =
        extrasList.fold<double>(0.0, (s, x) => s + (x.price * x.quantity));
    final compsAddSum =
        compsAdd.fold<double>(0.0, (s, x) => s + (x.price * x.quantity));
    final fallbackWithExtras = lineTotalVal + extrasSum + compsAddSum;

    final ltw = (j['line_total_with_extras'] is num)
        ? (j['line_total_with_extras'] as num).toDouble()
        : (double.tryParse('${j['line_total_with_extras']}') ?? 0.0);

    return AdminOrderItemModel(
      orderItemId: orderItemId,
      itemId: itemId,
      name: (j['name'] ?? j['title'] ?? '').toString(),
      quantity: int.tryParse('${j['quantity'] ?? 0}') ?? 0,
      price: (j['price'] is num)
          ? (j['price'] as num).toDouble()
          : (double.tryParse('${j['price']}') ?? 0.0),
      lineTotal: lineTotalVal,
      lineTotalWithExtras: (ltw > 0) ? ltw : fallbackWithExtras,
      extras: extrasList,
      componentsAdd: compsAdd,
      componentsRem: compsRem,
    );
  }
}

/* ============================================================
   Header Model
   ============================================================ */
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
        paymentMethod:
            int.tryParse('${j['payment_method'] ?? 0}') ?? 0,
        gateway: (j['gateway'] ?? '').toString(),
      );
}

/* ============================================================
   Controller + الكــــاش
   ============================================================ */
class AdminOrderDetailsController extends GetxController {
  final _api = ApiService();

  final loading = false.obs;
  final header = Rxn<AdminOrderHeaderModel>();
  final items = <AdminOrderItemModel>[].obs;
  final driver = Rxn<Map<String, dynamic>>();

  late int orderId;
  int? userId;

  /* ===========================
     ⏳ كــــــاش (In-Memory)
     =========================== */

  static final Map<int, AdminOrderHeaderModel> _headerCache = {};
  static final Map<int, List<AdminOrderItemModel>> _itemsCache = {};
  static final Map<int, DateTime> _cacheTime = {};

  static const Duration _ttl = Duration(seconds: 30);

  bool _isFresh(DateTime? t) {
    if (t == null) return false;
    return DateTime.now().difference(t) < _ttl;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    orderId = int.tryParse(
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

  /* ============================================================
     fetch() — مع إضافة الكــــاش فقط
     ============================================================ */
  Future<void> fetch() async {
    if (orderId <= 0) {
      Get.snackbar('تنبيه', 'رقم الطلب غير صحيح.');
      return;
    }

    // 1) إن وُجد كاش حديث → استخدمه بالكامل دون ريكوست
    if (_headerCache.containsKey(orderId) &&
        _itemsCache.containsKey(orderId) &&
        _isFresh(_cacheTime[orderId])) {
      header.value = _headerCache[orderId];
      items.assignAll(_itemsCache[orderId]!);
      return;
    }

    // 2) لو لا يوجد كاش → اعمل ريكوست عادي (بدون تغيير منطقك)
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
        _failClean();
        Get.snackbar('تعذّر التحميل', 'رد غير متوقّع من الخادم.');
        return;
      }

      Map<String, dynamic>? data;
      if (root['data'] is Map) {
        data = Map<String, dynamic>.from(root['data']);
      } else if (root['order'] != null || root['items'] != null) {
        data = Map<String, dynamic>.from(root);
      }

      if (data == null) {
        _failClean();
        Get.snackbar('تعذّر التحميل', 'لم نتمكّن من تحميل تفاصيل الطلب.');
        return;
      }

      header.value = AdminOrderHeaderModel.fromJson(
        Map<String, dynamic>.from(data['order'] ?? const {}),
      );

      final list = (data['items'] ?? []) as List;
      final parsedItems = list
          .map(
            (e) => AdminOrderItemModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();

      items.assignAll(parsedItems);

      driver.value = (data['driver'] == null)
          ? null
          : Map<String, dynamic>.from(data['driver']);

      // 3) تخزين في الكاش
      _headerCache[orderId] = header.value!;
      _itemsCache[orderId] = parsedItems;
      _cacheTime[orderId] = DateTime.now();
    } catch (e) {
      _failClean();
      Get.snackbar('خطأ', _friendlyError(e));
    } finally {
      loading(false);
    }
  }

  /* ============================================================
     Helpers
     ============================================================ */
  void _failClean() {
    header.value = null;
    items.clear();
    driver.value = null;
  }

  double get itemsTotal {
    if (items.isEmpty) return 0.0;
    return items.fold<double>(
      0.0,
      (sum, it) =>
          sum +
          (it.lineTotalWithExtras > 0 ? it.lineTotalWithExtras : it.lineTotal),
    );
  }

  double get computedGrandTotal {
    final h = header.value;
    if (h == null) return 0.0;
    if (h.grandTotal > 0) return h.grandTotal;
    return itemsTotal + h.deliveryFee;
  }

  String deliveryTypeArabic(String key) {
    switch (key.toLowerCase()) {
      case 'pickup':
        return 'استلام';
      case 'delivery':
        return 'توصيل';
      default:
        return key;
    }
  }

  String _friendlyError(Object e) {
    final t = e.toString().toLowerCase();

    if (e is TimeoutException || t.contains('timeout')) {
      return 'انتهت مهلة الاتصال.';
    }
    if (_looksOffline(t) || e is SocketException) {
      return 'لا يوجد اتصال بالإنترنت.';
    }
    if (t.contains('format exception') || t.contains('json')) {
      return 'خطأ في قراءة البيانات.';
    }
    return 'حدث خلل غير متوقّع.';
  }

  bool _looksOffline(String t) {
    return t.contains('failed host lookup') ||
        t.contains('socketexception') ||
        t.contains('network is unreachable') ||
        t.contains('connection refused') ||
        t.contains('dns');
  }
}
