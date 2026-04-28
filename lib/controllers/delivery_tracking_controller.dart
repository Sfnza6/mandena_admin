import 'dart:async';

import 'package:get/get.dart';

import '../core/config/env.dart';
import '../core/services/api_service.dart';
import 'admin_branch_scope_controller.dart';

class DeliveryTrackingController extends GetxController {
  final _api = ApiService();

  final loading = false.obs;
  final error = ''.obs;
  final search = ''.obs;

  /// فلاتر صفحة تتبع التوصيل
  /// الترتيب المطلوب:
  /// جاري البحث عن السائق - جاري التوصيل - تم التسليم - الكل
  final status = 'searching_driver'.obs;

  final orders = <Map<String, dynamic>>[].obs;
  Timer? _timer;
  Worker? _branchWorker;
  Timer? _debounce;

  int? get _branchId {
    try {
      if (Get.isRegistered<AdminBranchScopeController>()) {
        final id = Get.find<AdminBranchScopeController>().effectiveBranchId;
        if (id != null && id > 0) return id;
      }
    } catch (_) {}
    return null;
  }

  List<MapEntry<String, String>> get filters => const [
    MapEntry('searching_driver', 'جاري البحث عن السائق'),
    MapEntry('on_the_way', 'جاري التوصيل'),
    MapEntry('delivered', 'تم التسليم'),
    MapEntry('all', 'الكل'),
  ];

  @override
  void onInit() {
    super.onInit();
    fetch();
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => fetch(silent: true),
    );
    if (Get.isRegistered<AdminBranchScopeController>()) {
      _branchWorker = ever<int?>(
        Get.find<AdminBranchScopeController>().selectedBranchId,
        (_) => fetch(force: true),
      );
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    _branchWorker?.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  void setSearch(String value) {
    search.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      fetch(silent: true, force: true);
    });
  }

  void setStatus(String value) {
    if (status.value == value) return;
    status.value = value;
  }

  Future<void> fetch({bool silent = false, bool force = false}) async {
    if (!silent) loading(true);
    error.value = '';

    try {
      final res = await _api.get(
        Env.adminDriverTracking,
        query: {
          // نجيب كل الحالات ثم نفلتر محلياً لأن فلتر "جاري البحث عن السائق"
          // يعتمد على status من الطلب + driver_assignment_status + offer_status.
          'status': 'all',
          'limit': '300',
          if (_branchId != null) 'branch_id': '${_branchId!}',
          if (search.value.trim().isNotEmpty) 'q': search.value.trim(),
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final raw = (res is Map && res['data'] is List)
          ? res['data'] as List
          : (res is List ? res : const <dynamic>[]);

      orders.assignAll(
        raw.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );
    } catch (e) {
      error.value = e.toString();
      if (!silent) {
        Get.snackbar(
          'خطأ',
          'تعذر تحميل تتبع التوصيل: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (!silent) loading(false);
    }
  }

  List<Map<String, dynamic>> get filteredOrders {
    final selected = status.value;
    final list = orders.map((e) => Map<String, dynamic>.from(e)).toList();

    if (selected == 'all') return list;

    return list.where((row) {
      if (selected == 'searching_driver') return isSearchingDriver(row);
      if (selected == 'on_the_way') return isDelivering(row);
      if (selected == 'delivered') return isDelivered(row);
      return true;
    }).toList();
  }

  bool isSearchingDriver(Map<String, dynamic> row) {
    final orderStatus = _norm(row['status']);
    final assignmentStatus = _norm(row['driver_assignment_status']);
    final offerStatus = _norm(row['offer_status']);

    return orderStatus == 'ready_for_driver' ||
        orderStatus == 'driver_offered' ||
        assignmentStatus == 'searching' ||
        assignmentStatus == 'offered' ||
        assignmentStatus == 'pending' ||
        offerStatus == 'pending' ||
        offerStatus == 'offered';
  }

  bool isDelivering(Map<String, dynamic> row) {
    final orderStatus = _norm(row['status']);

    // مهم:
    // تبويب "جاري التوصيل" يعرض فقط الطلبات التي حالتها الفعلية في جدول الطلبات on_the_way.
    // لا نعتمد هنا على driver_assignment_status أو offer_status حتى لا تظهر طلبات ليست في مرحلة التوصيل فعلياً.
    return orderStatus == 'on_the_way';
  }

  bool isDelivered(Map<String, dynamic> row) {
    final orderStatus = _norm(row['status']);
    final assignmentStatus = _norm(row['driver_assignment_status']);

    return orderStatus == 'delivered' ||
        orderStatus == 'success' ||
        assignmentStatus == 'delivered';
  }

  String displayStatus(Map<String, dynamic> row) {
    if (isDelivered(row)) return 'تم التسليم';
    if (isDelivering(row)) return 'جاري التوصيل';
    if (isSearchingDriver(row)) return 'جاري البحث عن السائق';

    final statusRaw = '${row['status'] ?? ''}';
    if (_hasValue(row['status_ar'])) return '${row['status_ar']}';
    return statusArabic(statusRaw);
  }

  Future<void> markReady(int orderId) async {
    try {
      final res = await _api.postForm(Env.orderUpdate, {
        'order_id': '$orderId',
        'action': 'ready',
      });

      final ok =
          res is Map && (res['ok'] == true || res['status'] == 'success');
      if (!ok) {
        final msg = res is Map
            ? (res['message'] ?? res['error'] ?? 'فشل تجهيز الطلب').toString()
            : 'فشل تجهيز الطلب';
        Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
        return;
      }

      Get.snackbar(
        'تم',
        'تم تجهيز الطلب وبدأ البحث عن أقرب سائق',
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetch(silent: true, force: true);
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر تجهيز الطلب: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String statusArabic(String value) {
    switch (value.toLowerCase().trim()) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
      case 'preparing':
      case 'approved':
      case 'accepted':
        return 'جاري التحضير';
      case 'ready_for_driver':
      case 'driver_offered':
        return 'جاري البحث عن السائق';
      case 'on_the_way':
        return 'جاري التوصيل';
      case 'assigned':
      case 'delivering':
      case 'out_for_delivery':
        return 'تم قبولها من السائق';
      case 'delivered':
      case 'success':
        return 'تم التسليم';
      case 'cancelled':
      case 'rejected':
        return 'ملغي';
      default:
        return value.isEmpty ? 'غير معروف' : value;
    }
  }

  String offerArabic(dynamic value) {
    final v = '$value'.toLowerCase().trim();
    switch (v) {
      case 'pending':
        return 'ينتظر رد السائق';
      case 'offered':
        return 'معروض على السائق';
      case 'accepted':
        return 'قبله السائق';
      case 'rejected':
        return 'رفضه السائق';
      case 'timeout':
        return 'انتهت المهلة';
      case 'cancelled':
        return 'ملغي';
      case 'delivered':
        return 'تم التسليم';
      default:
        return v.isEmpty || v == 'null' ? '-' : '$value';
    }
  }

  String _norm(dynamic value) => '$value'.toLowerCase().trim();

  bool _hasValue(dynamic v) {
    final s = '$v'.trim();
    return s.isNotEmpty && s != 'null';
  }
}
