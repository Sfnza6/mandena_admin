import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import '../core/services/api_service.dart';
import '../core/config/env.dart';
import '../data/models/order_model.dart';

class OrdersController extends GetxController {
  final _api = ApiService();

  final loading = false.obs;
  final orders = <OrderModel>[].obs;

  /// 0 الكل - 1 pending - 2 processing - 3 assigned - 4 cancelled - 5 success/delivered
  final filterIndex = 0.obs;

  /// نص البحث
  final search = ''.obs;

  Timer? _pollTimer;
  Worker? _filterWorker;
  Worker? _searchWorker;

  // ==========================================================
  //                    📌 الكــــــــــــاش
  // ==========================================================

  /// كاش حسب الفلتر: 0..5
  static final Map<int, List<OrderModel>> _cache = {};

  /// وقت تخزين كل فلتر
  static final Map<int, DateTime> _cacheAt = {};

  /// عمر الكاش
  static const Duration _ttl = Duration(seconds: 8);

  bool _fresh(DateTime? t) {
    if (t == null) return false;
    return DateTime.now().difference(t) < _ttl;
  }

  // ==========================================================

  @override
  void onInit() {
    super.onInit();

    fetch();

    _filterWorker = ever<int>(filterIndex, (_) => fetch());

    _searchWorker = debounce<String>(
      search,
      (_) => orders.refresh(),
      time: const Duration(milliseconds: 350),
    );

    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => fetch(silent: true),
    );
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    _filterWorker?.dispose();
    _searchWorker?.dispose();
    super.onClose();
  }

  String? _statusByIndex(int i) {
    return switch (i) {
      0 => 'all',
      1 => 'pending',
      2 => 'processing',
      3 => 'assigned',
      4 => 'cancelled',
      5 => 'success,delivered',
      _ => null,
    };
  }

  // ==========================================================
  //                📌 FETCH with Cache + FORCE
  // ==========================================================

  Future<void> fetch({bool silent = false, bool force = false}) async {
    final idx = filterIndex.value;

    // ——— الكاش قبل الريكويست ———
    if (!force && _cache[idx] != null && _fresh(_cacheAt[idx])) {
      orders.assignAll(_cache[idx]!);

      if (!silent) loading(false);
      return;
    }

    try {
      if (!silent) loading(true);

      final status = _statusByIndex(idx);

      final res = await _api.get(
        Env.ordersList,
        query: {
          if (status != null) 'status': status,
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      List data;
      if (res is List) {
        data = res;
      } else if (res is Map && res['orders'] is List) {
        data = res['orders'] as List;
      } else if (res is Map && res['data'] is List) {
        data = res['data'] as List;
      } else if (res is String) {
        final obj = jsonDecode(res);
        if (obj is Map && obj['orders'] is List) {
          data = obj['orders'] as List;
        } else {
          data = const [];
        }
      } else {
        data = const [];
      }

      final parsed = data
          .map<OrderModel>(
            (e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      orders.assignAll(parsed);

      // ——— تخزين الكاش ———
      _cache[idx] = parsed;
      _cacheAt[idx] = DateTime.now();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذّر جلب الطلبات: $e',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      if (!silent) loading(false);
    }
  }

  // ==========================================================
  //               📌 تنظيف الكاش عند تغيير حالة الطلب
  // ==========================================================

  // ignore: unused_element
  void _invalidateCache() {
    _cache.remove(filterIndex.value);
    _cacheAt.remove(filterIndex.value);
  }

  // 📌 مثال (لو عندك approveOrder / rejectOrder / assignDriver)
  /*
  Future<void> approveOrder(int id) async {
    await _api.postForm(...);

    _invalidateCache();
    fetch(force: true);
  }
  */

  // ==========================================================

  void setFilter(int i) {
    if (i == filterIndex.value) return;
    filterIndex.value = i;
  }

  void setSearch(String q) {
    search.value = q;
  }

  // ==========================================================
  //              📌 الفلترة + البحث محلياً (بدون ريكويست)
  // ==========================================================

  List<OrderModel> get filtered {
    final q = search.value.trim();
    final idx = filterIndex.value;
    final stRaw = _statusByIndex(idx);

    Set<String>? allowedStatuses;
    if (idx == 0 || stRaw == null || stRaw == 'all') {
      allowedStatuses = null;
    } else {
      allowedStatuses = stRaw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
    }

    return orders.where((o) {
      final okStatus = (allowedStatuses == null)
          ? true
          : allowedStatuses.contains(o.status);

      final idStr = '${o.id}';
      final userIdStr = '${o.userId}';
      final userName = (o.userName ?? '');
      final userPhone = (o.userPhone ?? '');
      final addr = o.address;
      final drvName = (o.driverName ?? '');
      final drvPhone = (o.driverPhone ?? '');

      final okSearch =
          q.isEmpty ||
          idStr.contains(q) ||
          userIdStr.contains(q) ||
          userName.contains(q) ||
          userPhone.contains(q) ||
          addr.contains(q) ||
          drvName.contains(q) ||
          drvPhone.contains(q);

      return okStatus && okSearch;
    }).toList();
  }
}
