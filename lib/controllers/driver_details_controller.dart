import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // ✅ للكاش الدائم

import '../core/services/api_service.dart';
import '../core/config/env.dart';
import '../data/models/order_model.dart';

class DriverDetailsController extends GetxController {
  DriverDetailsController(this.driverId, {this.initialName, this.initialPhone});

  final int driverId;
  final String? initialName;
  final String? initialPhone;

  final _api = ApiService();

  // ===================== 🔹 GetStorage للكاش الدائم 🔹 =====================

  static const String _boxName = 'admin_cache';
  static const String _kDriverPrefix = 'driver_';
  static const String _kDriverAtPrefix = 'driver_at_';
  static const String _kOrdersPrefix = 'driver_orders_';
  static const String _kOrdersAtPrefix = 'driver_orders_at_';

  final GetStorage _box = GetStorage(_boxName);

  // بيانات السائق
  final name = ''.obs;
  final phone = ''.obs;
  final createdAt = ''.obs;

  // الطلبات المكلّفة
  final loading = false.obs;
  final orders = <OrderModel>[].obs;

  int get ordersCount => orders.length;

  /* ===================== كـــاش في الذاكرة (RAM) ===================== */

  // كاش لبيانات السائق: driver_id -> Map<String,dynamic>
  static final Map<int, Map<String, dynamic>> _driverCache = {};
  static final Map<int, DateTime> _driverCacheAt = {};

  // كاش للطلبات المكلّفة: driver_id -> List<OrderModel>
  static final Map<int, List<OrderModel>> _assignedCache = {};
  static final Map<int, DateTime> _assignedCacheAt = {};

  // مدة صلاحية الكاش في الذاكرة
  static const Duration _cacheTTL = Duration(seconds: 30);

  bool _isFresh(DateTime? t) {
    if (t == null) return false;
    return DateTime.now().difference(t) < _cacheTTL;
  }

  @override
  void onInit() {
    super.onInit();
    name.value = initialName ?? '';
    phone.value = initialPhone ?? '';

    // 1️⃣ جرّب تحميل بيانات السائق + الطلبات من الكاش الدائم (GetStorage)
    _restoreFromStorage();

    // 2️⃣ بعد ذلك حدّث من السيرفر (مع كاش الـ RAM)
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([
      fetchDriver(), // يستخدم الكاش داخلياً
      fetchAssignedOrders(), // يستخدم الكاش داخلياً
    ]);
  }

  /* ===================== استرجاع من الكاش الدائم ===================== */

  void _restoreFromStorage() {
    try {
      // ----- بيانات السائق -----
      final dKey = '$_kDriverPrefix$driverId';
      final dAtKey = '$_kDriverAtPrefix$driverId';

      final rawDriver = _box.read(dKey);
      final rawDriverAt = _box.read(dAtKey);

      if (rawDriver is Map && rawDriverAt != null) {
        DateTime? t;
        if (rawDriverAt is int) {
          t = DateTime.fromMillisecondsSinceEpoch(rawDriverAt);
        } else if (rawDriverAt is String) {
          t = DateTime.tryParse(rawDriverAt);
        }

        final map = Map<String, dynamic>.from(rawDriver);
        name.value = (map['name'] ?? '').toString();
        phone.value = (map['phone'] ?? '').toString();
        createdAt.value = (map['created_at'] ?? '').toString();

        _driverCache[driverId] = map;
        _driverCacheAt[driverId] = t!;
      }

      // ----- الطلبات -----
      final oKey = '$_kOrdersPrefix$driverId';
      final oAtKey = '$_kOrdersAtPrefix$driverId';

      final rawOrders = _box.read(oKey);
      final rawOrdersAt = _box.read(oAtKey);

      if (rawOrders is List && rawOrdersAt != null) {
        DateTime? t;
        if (rawOrdersAt is int) {
          t = DateTime.fromMillisecondsSinceEpoch(rawOrdersAt);
        } else if (rawOrdersAt is String) {
          t = DateTime.tryParse(rawOrdersAt);
        }

        final list = rawOrders
            .map(
              (e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();

        orders.assignAll(list);
        _assignedCache[driverId] = list;
        _assignedCacheAt[driverId] = t!;
      }
    } catch (_) {
      // لو صار خطأ في الكاش نتجاهله
    }
  }

  /* ===================== حفظ في الكاش الدائم ===================== */

  void _saveDriverToStorage(Map<String, dynamic> map) {
    try {
      final dKey = '$_kDriverPrefix$driverId';
      final dAtKey = '$_kDriverAtPrefix$driverId';

      _box.write(dKey, map);
      _box.write(dAtKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  void _saveOrdersToStorage(List<OrderModel> list) {
    try {
      final oKey = '$_kOrdersPrefix$driverId';
      final oAtKey = '$_kOrdersAtPrefix$driverId';

      final out = list.map((e) => e.toJson()).toList();
      _box.write(oKey, out);
      _box.write(oAtKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// جلب بيانات السائق + كاش
  Future<void> fetchDriver({bool force = false}) async {
    // 1) حاول تستخدم الكاش في الذاكرة إن كان حديثًا
    if (!force &&
        _driverCache.containsKey(driverId) &&
        _isFresh(_driverCacheAt[driverId])) {
      final data = _driverCache[driverId]!;
      name.value = (data['name'] ?? '').toString();
      phone.value = (data['phone'] ?? '').toString();
      createdAt.value = (data['created_at'] ?? '').toString();
      return;
    }

    // 2) لو مافيش كاش أو قديم → جيب من السيرفر وحدث الكاش + التخزين
    try {
      final res = await _api.get(
        Env.driverById,
        query: {
          'driver_id': '$driverId',
          // t لكسر كاش البروكسي فقط، الكاش "الحقيقي" عندنا
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      // يدعم {status:data:{...}} أو {driver:{...}}
      final data = res is Map && res['data'] is Map
          ? res['data'] as Map
          : (res is Map && res['driver'] is Map)
          ? res['driver'] as Map
          : null;

      if (data != null) {
        final map = Map<String, dynamic>.from(data);

        // تحديث القيم المعروضة
        name.value = (map['name'] ?? '').toString();
        phone.value = (map['phone'] ?? '').toString();
        createdAt.value = (map['created_at'] ?? '').toString();

        // تخزين في الكاش (RAM)
        _driverCache[driverId] = map;
        _driverCacheAt[driverId] = DateTime.now();

        // تخزين في الكاش الدائم (GetStorage)
        _saveDriverToStorage(map);
      }
    } catch (_) {
      // تجاهل الخطأ بهدوء كما في كودك الأصلي
    }
  }

  /// جلب الطلبات المكلّفة للسائق + كاش
  Future<void> fetchAssignedOrders({bool force = false}) async {
    // 1) الكاش في الذاكرة
    if (!force &&
        _assignedCache.containsKey(driverId) &&
        _isFresh(_assignedCacheAt[driverId])) {
      orders.assignAll(_assignedCache[driverId]!);
      return;
    }

    // 2) الشبكة + تحديث الكاش
    loading(true);
    try {
      final res = await _api.get(
        Env.assignedOrders,
        query: {
          'driver_id': '$driverId',
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final listRaw = (res is Map && res['orders'] is List)
          ? (res['orders'] as List)
          : (res is List ? res : const <dynamic>[]);

      final list = listRaw
          .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      orders.assignAll(list);

      // تخزين في الكاش (RAM)
      _assignedCache[driverId] = list;
      _assignedCacheAt[driverId] = DateTime.now();

      // تخزين في الكاش الدائم (GetStorage)
      _saveOrdersToStorage(list);
    } finally {
      loading(false);
    }
  }
}
