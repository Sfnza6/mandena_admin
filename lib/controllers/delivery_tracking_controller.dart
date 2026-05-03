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
  final forceDriversLoading = false.obs;
  final forceDrivers = <Map<String, dynamic>>[].obs;
  final forceAssigningOrderId = 0.obs;

  /// فلاتر صفحة تتبع التوصيل
  /// الترتيب المطلوب من اليمين لليسار:
  /// تم تعيين سائق - فشل تعيين سائق - جاري التوصيل
  final status = 'assigned'.obs;

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
    MapEntry('assigned', 'تم تعيين سائق'),
    MapEntry('assignment_failed', 'فشل تعيين سائق'),
    MapEntry('on_the_way', 'جاري التوصيل'),
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

    return list.where((row) {
      if (selected == 'assigned') return isAssigned(row);
      if (selected == 'assignment_failed') return isAssignmentFailed(row);
      if (selected == 'on_the_way') return isDelivering(row);
      return false;
    }).toList();
  }

  bool isAssigned(Map<String, dynamic> row) {
    if (isAssignmentFailed(row)) return false;

    final orderStatus = _norm(row['status']);
    final assignmentStatus = _norm(row['driver_assignment_status']);
    final offerStatus = _norm(row['offer_status']);

    // تم تعيين السائق يعني السائق قبل الطلب، لكن لم يدخل بعد مرحلة التوصيل.
    // لا نعتبر on_the_way هنا حتى لا تتكرر الطلبية في تبويبين.
    return orderStatus == 'assigned' ||
        (assignmentStatus == 'assigned' &&
            orderStatus != 'on_the_way' &&
            orderStatus != 'delivering' &&
            orderStatus != 'out_for_delivery' &&
            orderStatus != 'delivered' &&
            orderStatus != 'success') ||
        (offerStatus == 'accepted' &&
            orderStatus != 'on_the_way' &&
            orderStatus != 'delivering' &&
            orderStatus != 'out_for_delivery' &&
            orderStatus != 'delivered' &&
            orderStatus != 'success');
  }

  bool isAssignmentFailed(Map<String, dynamic> row) {
    final orderStatus = _norm(row['status']);
    final assignmentStatus = _norm(row['driver_assignment_status']);
    final offerStatus = _norm(row['offer_status']);

    if (isDelivered(row) || isDelivering(row)) return false;

    return assignmentStatus == 'assignment_failed' ||
        assignmentStatus == 'no_driver' ||
        assignmentStatus == 'failed' ||
        orderStatus == 'assignment_failed' ||
        orderStatus == 'no_driver' ||
        orderStatus == 'driver_rejected_after_accept' ||
        offerStatus == 'driver_rejected_after_accept' ||
        (orderStatus == 'ready_for_driver' && assignmentStatus == 'no_driver');
  }

  bool isSearchingDriver(Map<String, dynamic> row) {
    if (isAssignmentFailed(row)) return false;

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

    // جاري التوصيل يعرض فقط الطلبات التي خرجت فعلياً للتوصيل.
    return orderStatus == 'on_the_way' ||
        orderStatus == 'delivering' ||
        orderStatus == 'out_for_delivery';
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
    if (isAssignmentFailed(row)) return 'فشل تعيين سائق';
    if (isAssigned(row)) return 'تم تعيين سائق';
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

  Future<void> fetchForceDrivers({bool force = false}) async {
    forceDriversLoading(true);
    try {
      final res = await _api.get(
        Env.adminDriversLive,
        query: {
          if (_branchId != null) 'branch_id': '${_branchId!}',
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final raw = (res is Map && res['data'] is List)
          ? res['data'] as List
          : (res is List ? res : const <dynamic>[]);

      forceDrivers.assignAll(
        raw.map((e) => Map<String, dynamic>.from(e as Map)).where((row) {
          return '${row['is_active'] ?? 0}' == '1';
        }).toList(),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر تحميل السائقين: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      forceDriversLoading(false);
    }
  }

  Future<bool> forceAssignDriver({
    required int orderId,
    required int driverId,
  }) async {
    if (orderId <= 0 || driverId <= 0) return false;

    forceAssigningOrderId.value = orderId;
    try {
      final res = await _api.postForm(Env.forceAssignDriver, {
        'order_id': '$orderId',
        'driver_id': '$driverId',
      });

      final ok =
          res is Map && (res['ok'] == true || res['status'] == 'assigned');
      if (!ok) {
        final msg = res is Map
            ? (res['message'] ?? res['error'] ?? 'فشل التكليف الإجباري')
                  .toString()
            : 'فشل التكليف الإجباري';
        Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
        return false;
      }

      Get.snackbar(
        'تم',
        'تم تكليف السائق إجبارياً',
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetch(silent: true, force: true);
      return true;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر التكليف الإجباري: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      forceAssigningOrderId.value = 0;
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
        return 'جاهز للتوصيل';
      case 'driver_offered':
        return 'جاري البحث عن السائق';
      case 'assigned':
        return 'تم تعيين سائق';
      case 'on_the_way':
      case 'delivering':
      case 'out_for_delivery':
        return 'جاري التوصيل';
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
