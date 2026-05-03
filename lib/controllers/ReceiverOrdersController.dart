import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../core/services/api_service.dart';
import '../core/config/env.dart';
import '../core/utils/snack_utils.dart';
import 'AuthController.dart';

class ReceiverOrder {
  final int id;
  final int userId;
  final String address;
  final int paymentMethod;
  final double total;
  final double deliveryFee;
  String status;
  final String statusOrder;
  final String createdAt;

  ReceiverOrder({
    required this.id,
    required this.userId,
    required this.address,
    required this.paymentMethod,
    required this.total,
    required this.deliveryFee,
    required this.status,
    required this.statusOrder,
    required this.createdAt,
  });

  factory ReceiverOrder.fromJson(Map<String, dynamic> j) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('${v ?? 0}'.replaceAll(',', '').trim()) ?? 0.0;
    }

    return ReceiverOrder(
      id: int.tryParse('${j['id']}') ?? 0,
      userId: int.tryParse('${j['user_id']}') ?? 0,
      address: (j['address'] ?? j['address_text'] ?? '').toString(),
      paymentMethod: int.tryParse('${j['payment_method'] ?? 0}') ?? 0,
      total: toDouble(j['total']),
      deliveryFee: toDouble(
        j['delivery_fee'] ??
            j['deliveryFee'] ??
            j['delivery_price'] ??
            j['shipping_fee'],
      ),
      status: (j['status'] ?? j['normalized_status'] ?? '').toString(),
      statusOrder: (j['status_order'] ?? '').toString(),
      createdAt: (j['created_at'] ?? '').toString(),
    );
  }

  bool get isPickupOrder =>
      statusOrder == 'pickup' || statusOrder == 'internal_pickup';

  bool get isInternalPickup => statusOrder == 'internal_pickup';

  String get orderTypeLabel {
    if (statusOrder == 'internal_pickup') return 'استلام داخلي';
    if (statusOrder == 'pickup') return 'استلام خارجي';
    return 'توصيل';
  }
}

class ReceiverOrderItem {
  final int orderItemId;
  final int itemId;
  final String title;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String imageUrl;

  final List<Map<String, dynamic>> extras;
  final List<Map<String, dynamic>> componentsAdd;
  final List<Map<String, dynamic>> componentsRem;

  ReceiverOrderItem({
    required this.orderItemId,
    required this.itemId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.imageUrl,
    this.extras = const [],
    this.componentsAdd = const [],
    this.componentsRem = const [],
  });

  factory ReceiverOrderItem.fromJson(Map<String, dynamic> j) {
    final title = (j['title'] ?? j['name'] ?? 'صنف').toString();
    final unit = (j['unit_price'] is num)
        ? (j['unit_price'] as num).toDouble()
        : (j['price'] is num)
        ? (j['price'] as num).toDouble()
        : (double.tryParse('${j['unit_price'] ?? j['price'] ?? 0}') ?? 0.0);
    final line = (j['line_total'] is num)
        ? (j['line_total'] as num).toDouble()
        : (double.tryParse('${j['line_total'] ?? 0}') ?? 0.0);

    List<Map<String, dynamic>> asList(dynamic v) {
      if (v is List) {
        return v.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return const [];
    }

    return ReceiverOrderItem(
      orderItemId: int.tryParse('${j['order_item_id'] ?? j['id'] ?? 0}') ?? 0,
      itemId: int.tryParse('${j['item_id'] ?? 0}') ?? 0,
      title: title,
      quantity: int.tryParse('${j['quantity'] ?? 1}') ?? 1,
      unitPrice: unit,
      lineTotal: line,
      imageUrl: (j['image_url'] ?? '').toString(),
      extras: asList(j['extras']),
      componentsAdd: asList(j['components_add']),
      componentsRem: asList(
        j['components_rem'] ?? j['componentsRem'] ?? j['components_removed'],
      ),
    );
  }
}

class ReceiverOrdersController extends GetxController
    with WidgetsBindingObserver {
  final _api = ApiService();

  final loading = false.obs;
  final orders = <ReceiverOrder>[].obs;

  /// فلتر العرض في صفحة الطلبات الواردة فقط.
  /// لا يوجد تبويب الكل، وطلبات التوصيل التي خرجت للتوصيل أو فشل تعيينها تظهر في صفحة التتبع.
  final orderFilter = 'pending'.obs;

  void setOrderFilter(String value) {
    if (value == 'pending' ||
        value == 'processing' ||
        value == 'ready_pickup') {
      orderFilter.value = value;
    }
  }

  List<ReceiverOrder> get filteredOrders {
    return orders.where((o) => o.status == orderFilter.value).toList();
  }

  /// cache: order_id -> items
  final Map<int, List<ReceiverOrderItem>> itemsCache = {};
  final Map<int, int> itemsVersion = {};

  String get _sessionCacheKey {
    try {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        final userId = auth.admin.value?.id ?? 0;
        final branchId = auth.currentBranchId ?? 0;
        return 'receiver:user=$userId:branch=$branchId';
      }
    } catch (_) {}
    return 'receiver:user=0:branch=0';
  }

  void _ensureSessionCache() {
    final key = _sessionCacheKey;
    if (_ordersCacheOwnerKey == key) return;

    _ordersCacheOwnerKey = key;
    _ordersCache = null;
    _ordersCacheAt = null;
    _lastVersion = -1;

    itemsCache.clear();
    itemsVersion.clear();
    expandedIds.clear();
    _stickyUntil.clear();
    orders.clear();
  }

  static void clearGlobalCache() {
    _ordersCacheOwnerKey = null;
    _ordersCache = null;
    _ordersCacheAt = null;
  }

  // =========================
  //   📌 كــــــــــــــاش الطلبات
  // =========================
  static List<ReceiverOrder>? _ordersCache;
  static DateTime? _ordersCacheAt;
  static String? _ordersCacheOwnerKey;

  /// TTL للكاش (30 ثانية)
  static const Duration _ordersTTL = Duration(seconds: 30);

  bool _cacheFresh(DateTime? t) {
    if (t == null) return false;
    return DateTime.now().difference(t) < _ordersTTL;
  }

  final expandedIds = <int>{}.obs;
  bool isExpanded(int id) => expandedIds.contains(id);
  void setExpanded(int id, bool v) {
    if (v) {
      expandedIds.add(id);
    } else {
      expandedIds.remove(id);
    }
  }

  Timer? _poll;
  Timer? _liveTimer;

  /// ⏱️ polling كامل للاحتياط كل 60 ثانية
  final int pollSeconds = 60;

  int _lastVersion = -1;

  /// آخر مرة نجح فيها fetch حقيقي
  DateTime? _lastFetchAt;

  static const Set<String> _visibleStatuses = {
    'pending',
    'processing',
    'ready_pickup',
  };

  static const Set<String> _processingAliases = {
    'approved',
    'accepted',
    'preparing',
    'in_prep',
    'readying',
  };

  String _normalizeStatus(String s) {
    final x = s.toLowerCase().trim();

    if (_processingAliases.contains(x)) return 'processing';

    // حالات الاستلام بعد التجهيز تبقى في صفحة الطلبات الواردة حتى يضغط الأدمن تم التسليم.
    if (const [
      'ready_pickup',
      'pickup_ready',
      'ready_for_pickup',
      'prepared_pickup',
    ].contains(x)) {
      return 'ready_pickup';
    }

    // هذه الحالات تخص طلبات التوصيل قبل خروج الطلب فعلياً مع السائق.
    // نعرضها في الطلبات الواردة كـ "جاري التحضير" فقط بدون زر جهز للتوصيل.
    if (const [
      'ready_for_driver',
      'searching_driver',
      'driver_offered',
      'assigned',
      'driver_to_pickup',
    ].contains(x)) {
      return 'processing';
    }

    // حالات التوصيل الفعلية أو فشل التعيين لا تظهر هنا؛ مكانها صفحة التتبع.
    if (const [
      'on_the_way',
      'out_for_delivery',
      'delivering',
      'handover',
      'assignment_failed',
      'no_driver',
      'driver_rejected_after_accept',
      'delivered',
      'success',
      'completed',
      'complete',
    ].contains(x)) {
      return x;
    }

    return x;
  }

  final Map<int, DateTime> _stickyUntil = {};
  final Duration _stickyDuration = const Duration(minutes: 15);

  bool _isSticky(int id) {
    final t = _stickyUntil[id];
    if (t == null) return false;
    if (DateTime.now().isAfter(t)) {
      _stickyUntil.remove(id);
      return false;
    }
    return true;
  }

  /// هل التطبيق في الواجهة؟
  bool _isForeground = true;

  @override
  void onReady() {
    super.onReady();
    WidgetsBinding.instance.addObserver(this);
    _ensureSessionCache();
    fetch();
    _startLiveWatcher();

    _poll = Timer.periodic(Duration(seconds: pollSeconds), (_) async {
      if (!_isForeground) return;

      // لو صار fetch ناجح آخر 5 دقائق، ما فيش داعي
      if (_lastFetchAt != null &&
          DateTime.now().difference(_lastFetchAt!) <
              const Duration(minutes: 5)) {
        return;
      }

      await fetch(silent: true, force: true);
    });
  }

  @override
  void onClose() {
    _poll?.cancel();
    _liveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = (state == AppLifecycleState.resumed);

    if (_isForeground) {
      fetch(silent: true, force: true);
    }
  }

  void _startLiveWatcher() {
    _liveTimer?.cancel();

    /// تحديث لحظي: يجلب الطلبات تلقائياً بدون الحاجة لزر التحديث.
    /// استخدمنا force لتجاوز الكاش حتى تظهر الطلبات الجديدة فوراً.
    _liveTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetch(silent: true, force: true),
    );
  }

  Future<void> _checkVersion() async {
    if (!_isForeground) return;
    _ensureSessionCache();

    try {
      final res = await _api.get(
        Env.ordersVersion,
        query: {'t': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      final obj = (res is String) ? jsonDecode(res) : res;
      final v = (obj is Map && obj['v'] != null)
          ? int.tryParse('${obj['v']}')
          : null;
      if (v == null) return;
      if (_lastVersion == -1) {
        _lastVersion = v;
        return;
      }
      if (v != _lastVersion) {
        _lastVersion = v;
        await fetch(silent: true, force: true);
      }
    } catch (_) {}
  }

  List<ReceiverOrder> _parseAndFilterAndCache(dynamic res) {
    final list = <ReceiverOrder>[];
    List data = const [];

    if (res is Map && res['orders'] is List) {
      data = res['orders'] as List;
    } else if (res is List) {
      data = res;
    }

    for (final e in data) {
      final m = Map<String, dynamic>.from(e as Map);

      final assignmentStatus = '${m['driver_assignment_status'] ?? ''}'
          .toLowerCase()
          .trim();
      final offerStatus = '${m['offer_status'] ?? ''}'.toLowerCase().trim();

      // فشل تعيين السائق أو انسحاب السائق بعد القبول مكانه صفحة التتبع، وليس الطلبات الواردة.
      if (const {
            'assignment_failed',
            'no_driver',
            'failed',
            'driver_rejected_after_accept',
          }.contains(assignmentStatus) ||
          offerStatus == 'driver_rejected_after_accept') {
        continue;
      }

      final o = ReceiverOrder.fromJson(m);
      o.status = _normalizeStatus(o.status);

      final rawItems = (m['items'] is List) ? (m['items'] as List) : null;
      if (rawItems != null) {
        final items = rawItems
            .map(
              (x) => ReceiverOrderItem.fromJson(
                Map<String, dynamic>.from(x as Map),
              ),
            )
            .toList();

        if (items.isNotEmpty) {
          itemsCache[o.id] = items;
        } else {
          itemsCache.remove(o.id);
        }
        itemsVersion[o.id] = (itemsVersion[o.id] ?? 0) + 1;
      }

      if (_visibleStatuses.contains(o.status)) list.add(o);
    }
    return list;
  }

  Future<void> fetch({bool silent = false, bool force = false}) async {
    try {
      _ensureSessionCache();
      if (!silent) loading(true);

      // استخدام الكاش لو صالح
      if (!force && _ordersCache != null && _cacheFresh(_ordersCacheAt)) {
        orders.assignAll(_ordersCache!);
        if (!silent) loading(false);
        return;
      }

      dynamic res;
      try {
        res = await _api.get(
          Env.ordersList,
          query: {
            'status':
                'pending,processing,approved,accepted,preparing,ready_pickup,ready_for_driver,searching_driver,driver_offered,assigned,driver_to_pickup,on_the_way,out_for_delivery,delivering,assignment_failed,no_driver,delivered',
            't': '${DateTime.now().millisecondsSinceEpoch}',
          },
        );
      } catch (_) {
        res = await _api.get(
          Env.ordersList,
          query: {'t': '${DateTime.now().millisecondsSinceEpoch}'},
        );
      }

      final fresh = _parseAndFilterAndCache(res);

      // مهم جداً: لا نحتفظ بأي طلب قديم محلياً إذا لم يعد راجعاً من السيرفر.
      // هذا يمنع بقاء طلب التوصيل كـ "جاري التحضير" بعد أن يصبح "جاري التوصيل" أو "فشل تعيين سائق".
      final seen = <int>{};
      final unique = <ReceiverOrder>[];
      for (final o in fresh) {
        if (seen.add(o.id)) unique.add(o);
      }

      unique.sort((a, b) => b.id.compareTo(a.id));
      orders.assignAll(unique);

      _ordersCacheOwnerKey = _sessionCacheKey;
      _ordersCache = unique;
      _ordersCacheAt = DateTime.now();
      _lastFetchAt = DateTime.now();
    } catch (e) {
      if (!silent) {
        AppSnack.error(
          AppSnack.friendlyError(e, fallback: 'تعذّر جلب الطلبات'),
        );
      }
    } finally {
      if (!silent) loading(false);
    }
  }

  Future<List<ReceiverOrderItem>> loadItems(
    int orderId, {
    bool force = false,
  }) async {
    if (!force && itemsCache.containsKey(orderId)) {
      return itemsCache[orderId]!;
    }

    try {
      final res = await _api.get(
        Env.orderItems,
        query: {
          'order_id': '$orderId',
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      try {
        final obj = res is String ? jsonDecode(res) : res;
        final pretty = const JsonEncoder.withIndent('  ').convert(obj);
        Get.log('get_order_items/details($orderId): $pretty');
      } catch (_) {}

      dynamic root = res;
      if (res is String) {
        try {
          root = jsonDecode(res);
        } catch (_) {}
      }

      List raw = const [];

      if (root is Map) {
        if (root['items'] is List) {
          raw = root['items'] as List;
        } else if (root['data'] is List) {
          raw = root['data'] as List;
        } else if (root['data'] is Map && (root['data']['items'] is List)) {
          raw = root['data']['items'] as List;
        }
      } else if (root is List) {
        raw = root;
      }

      final out = raw
          .map(
            (e) =>
                ReceiverOrderItem.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      if (out.isNotEmpty) {
        itemsCache[orderId] = out;
      } else {
        itemsCache.remove(orderId);
      }

      itemsVersion[orderId] = (itemsVersion[orderId] ?? 0) + 1;
      return out;
    } catch (e) {
      itemsCache.remove(orderId);
      itemsVersion[orderId] = (itemsVersion[orderId] ?? 0) + 1;
      return [];
    }
  }

  Future<void> approve(int orderId) async {
    try {
      final res = await _api.postForm(Env.orderUpdate, {
        'order_id': '$orderId',
        'action': 'approve',
      });

      String? newStatus;
      final obj = (res is String) ? jsonDecode(res) : res;
      if (obj is Map) {
        newStatus = (obj['status'] ?? obj['new_status'])?.toString();
      }

      final idx = orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        final normalized = _normalizeStatus(newStatus ?? 'processing');
        orders[idx].status = normalized;
        orders.refresh();
      } else {
        orders.insert(
          0,
          ReceiverOrder(
            id: orderId,
            userId: 0,
            address: '',
            paymentMethod: 0,
            total: 0,
            deliveryFee: 0,
            status: 'processing',
            statusOrder: '',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }

      _stickyUntil[orderId] = DateTime.now().add(_stickyDuration);

      itemsCache.remove(orderId);
      itemsVersion[orderId] = (itemsVersion[orderId] ?? 0) + 1;

      _ordersCacheAt = null;

      ReceiverOrder? approvedOrder;
      for (final o in orders) {
        if (o.id == orderId) {
          approvedOrder = o;
          break;
        }
      }
      final isPickupOrder = approvedOrder?.isPickupOrder ?? false;

      AppSnack.success(
        isPickupOrder
            ? 'تمت الموافقة والطلب الآن جاري التحضير'
            : 'تمت الموافقة وبدأ البحث عن أقرب سائق',
      );

      // طلبات الاستلام الخارجي/الداخلي لا تدخل في منظومة السائق.
      // التوصيل فقط يبدأ البحث عن أقرب سائق بعد الموافقة.
      if (!isPickupOrder) {
        await _autoTriggerDriverSearch(orderId);
      }

      await fetch(silent: true, force: true);
      _checkVersion();
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذّر الموافقة'));
    }
  }

  /// ✅ بحث تلقائي عن أقرب سائق متاح وتعيينه
  /// يعمل في الخلفية بدون حظر الواجهة — لو فشل لا يُظهر خطأ
  Future<void> _autoTriggerDriverSearch(int orderId) async {
    try {
      // 1️⃣ أولاً: نخبر السيرفر أن الطلب جاهز للسائق (يبدأ بحث تلقائي)
      final res = await _api.postForm(Env.orderUpdate, {
        'order_id': '$orderId',
        'action': 'ready',
      });

      // لا نحذف الطلب من القائمة — يبقى مرئياً حتى يتم التعيين
      debugPrint('🚗 Auto driver search triggered for order #$orderId');

      try {
        final obj = (res is String) ? jsonDecode(res) : res;
        if (obj is Map && obj['ok'] == true) {
          debugPrint(
            '✅ Server started searching for driver for order #$orderId',
          );
        }
      } catch (_) {}
    } catch (e) {
      // صامت: لو فشل البحث، الطلب يبقى processing
      // ويمكن للمستقبل لاحقاً الضغط على "تم التجهيز" يدوياً
      debugPrint('⚠️ Auto driver search failed for order #$orderId: $e');
    }
  }

  Future<void> reject(int orderId) async {
    try {
      await _api.postForm(Env.orderUpdate, {
        'order_id': '$orderId',
        'action': 'reject',
      });
    } finally {
      orders.removeWhere((o) => o.id == orderId);
      itemsCache.remove(orderId);
      itemsVersion.remove(orderId);
      _stickyUntil.remove(orderId);

      _ordersCacheAt = null;

      _checkVersion();
    }
  }

  Future<void> assignDriver(int orderId, int driverId) async {
    try {
      await _api.postForm(Env.assignDriver, {
        'order_id': '$orderId',
        'driver_id': '$driverId',
      });
    } finally {
      orders.removeWhere((o) => o.id == orderId);
      itemsCache.remove(orderId);
      itemsVersion.remove(orderId);
      _stickyUntil.remove(orderId);

      _ordersCacheAt = null;

      _checkVersion();
    }
  }

  Future<void> markReadyPickup(int orderId) async {
    try {
      final res = await _api.postForm(Env.orderUpdate, {
        'order_id': '$orderId',
        'action': 'ready_pickup',
      });

      try {
        final obj = (res is String) ? jsonDecode(res) : res;
        if (obj is Map && obj['ok'] == false) {
          AppSnack.error(
            (obj['message'] ?? 'تعذر تحديث الطلب إلى تم التجهيز').toString(),
          );
          return;
        }
      } catch (_) {}

      final idx = orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        orders[idx].status = 'ready_pickup';
        orders.refresh();
      }

      _stickyUntil[orderId] = DateTime.now().add(_stickyDuration);
      _ordersCacheAt = null;

      AppSnack.success('تم تجهيز طلب الاستلام');
      await fetch(silent: true, force: true);
    } catch (e) {
      AppSnack.error(
        AppSnack.friendlyError(e, fallback: 'تعذر تحديث الطلب إلى تم التجهيز'),
      );
    }
  }

  Future<void> markReadyForDriver(int orderId) async {
    try {
      final res = await _api.postForm(Env.orderUpdate, {
        'order_id': '$orderId',
        'action': 'ready',
      });

      try {
        final obj = (res is String) ? jsonDecode(res) : res;
        if (obj is Map && obj['ok'] == false) {
          AppSnack.error(
            (obj['message'] ?? 'تعذر تجهيز الطلب للتوصيل').toString(),
          );
          return;
        }
      } catch (_) {}

      orders.removeWhere((o) => o.id == orderId);
      itemsCache.remove(orderId);
      itemsVersion.remove(orderId);
      _stickyUntil.remove(orderId);
      _ordersCacheAt = null;

      AppSnack.success('تم تجهيز الطلب وبدء البحث عن أقرب سائق');
      _checkVersion();
    } catch (e) {
      AppSnack.error(
        AppSnack.friendlyError(e, fallback: 'تعذر تجهيز الطلب للتوصيل'),
      );
    }
  }

  Future<void> markDelivered(int orderId) async {
    try {
      final res = await _api.postForm(Env.orderUpdate, {
        'order_id': '$orderId',
        'action': 'delivered',
      });

      try {
        final obj = (res is String) ? jsonDecode(res) : res;
        if (obj is Map && obj['ok'] == false) {
          AppSnack.error('تعذّر تحديث حالة الطلب');
          return;
        }
      } catch (_) {}

      orders.removeWhere((o) => o.id == orderId);
      itemsCache.remove(orderId);
      itemsVersion.remove(orderId);
      _stickyUntil.remove(orderId);

      _ordersCacheAt = null;

      AppSnack.success('تم تسجيل الطلب كمسلَّم');
      _checkVersion();
    } catch (e) {
      AppSnack.error(
        AppSnack.friendlyError(e, fallback: 'تعذّر تحديث حالة الطلب'),
      );
    }
  }

  /// 🟢 دالة لاستعمالها من الخارج لما يتم تكليف سائق من مكان آخر
  void onOrderAssignedExternally(int orderId) {
    orders.removeWhere((o) => o.id == orderId);
    itemsCache.remove(orderId);
    itemsVersion.remove(orderId);
    _stickyUntil.remove(orderId);

    if (_ordersCache != null) {
      _ordersCache = _ordersCache!.where((o) => o.id != orderId).toList();
    }

    _ordersCacheAt = null;
    orders.refresh();
  }
}
