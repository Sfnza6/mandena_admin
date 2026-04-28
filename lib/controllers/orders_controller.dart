import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import '../core/services/api_service.dart';
import '../core/config/env.dart';
import '../data/models/branch_model.dart';
import '../data/models/order_model.dart';
import 'admin_branch_scope_controller.dart';
import 'AuthController.dart';

class OrdersController extends GetxController {
  final _api = ApiService();
  final _branchScope = Get.find<AdminBranchScopeController>();

  final loading = false.obs;
  final orders = <OrderModel>[].obs;

  /// 0 الكل - 1 pending - 2 processing - 3 assigned - 4 cancelled - 5 success/delivered
  final filterIndex = 0.obs;

  final search = ''.obs;

  final branches = <BranchModel>[].obs;
  final branchesLoading = false.obs;

  Timer? _pollTimer;
  Worker? _filterWorker;
  Worker? _searchWorker;
  Worker? _branchWorker;

  static final Map<String, List<OrderModel>> _cache = {};
  static final Map<String, DateTime> _cacheAt = {};

  static const Duration _ttl = Duration(seconds: 8);

  bool _fresh(DateTime? t) {
    if (t == null) return false;
    return DateTime.now().difference(t) < _ttl;
  }

  bool get canFilterBranches {
    try {
      final dynamic auth = Get.find<AuthController>();

      final dynamic roleRaw = auth.role;
      final role = roleRaw is Rx ? '${roleRaw.value}' : '$roleRaw';
      if (role.toLowerCase().trim() == 'owner') return true;
    } catch (_) {}

    try {
      final dynamic auth = Get.find<AuthController>();

      final dynamic userRaw = auth.user;
      final dynamic user = userRaw is Rx ? userRaw.value : userRaw;

      if (user is Map) {
        final role = '${user['role'] ?? ''}'.toLowerCase().trim();
        if (role == 'owner') return true;
      }
    } catch (_) {}

    return false;
  }

  int get branchFilterValue => _branchScope.selectedBranchId.value ?? 0;

  int? get _effectiveBranchId {
    final selected = _branchScope.selectedBranchId.value;

    if (canFilterBranches) {
      if (selected != null && selected > 0) return selected;

      /// المالك مع اختيار "كل الفروع"
      return null;
    }

    final branchId = _branchScope.effectiveBranchId;
    if (branchId != null && branchId > 0) return branchId;

    return null;
  }

  String get selectedBranchTitle {
    final id = _effectiveBranchId;

    if (canFilterBranches && id == null) return 'كل الفروع';

    if (id == null || id <= 0) return 'فرع غير محدد';

    final b = branches.firstWhereOrNull((e) => e.id == id);
    if (b != null && b.name.trim().isNotEmpty) return b.name;

    return 'فرع #$id';
  }

  void setBranchFilter(int value) {
    final newValue = value <= 0 ? null : value;

    if (_branchScope.selectedBranchId.value == newValue) return;

    _branchScope.selectedBranchId.value = newValue;

    _cache.clear();
    _cacheAt.clear();

    fetch(force: true);
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

  String _cacheKey(int idx) {
    final branchId = _effectiveBranchId;
    final branchPart = branchId == null ? 'all_branches' : 'branch_$branchId';
    return '$branchPart:filter_$idx';
  }

  Future<void> loadBranches({bool force = false}) async {
    if (!canFilterBranches) return;
    if (branchesLoading.value) return;
    if (!force && branches.isNotEmpty) return;

    try {
      branchesLoading(true);

      final res = await _api.get(Env.branchesList);

      final raw = (res is Map && res['data'] is List)
          ? (res['data'] as List)
          : (res is List ? res : const <dynamic>[]);

      final list = raw
          .map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e)))
          .where((b) => b.id > 0)
          .toList();

      branches.assignAll(list);
    } catch (_) {
      branches.clear();
    } finally {
      branchesLoading(false);
    }
  }

  @override
  void onInit() {
    super.onInit();

    if (canFilterBranches) {
      loadBranches();
    }

    fetch();

    _filterWorker = ever<int>(filterIndex, (_) => fetch());

    _searchWorker = debounce<String>(
      search,
      (_) => orders.refresh(),
      time: const Duration(milliseconds: 350),
    );

    _pollTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => fetch(silent: true),
    );

    _branchWorker = ever<int?>(_branchScope.selectedBranchId, (_) {
      _cache.clear();
      _cacheAt.clear();
      fetch(force: true);
    });
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    _filterWorker?.dispose();
    _searchWorker?.dispose();
    _branchWorker?.dispose();
    super.onClose();
  }

  Future<void> fetch({bool silent = false, bool force = false}) async {
    final auth = Get.find<AuthController>();
    final branchId = _effectiveBranchId;

    if (!auth.isLoggedIn) {
      orders.clear();
      if (!silent) loading(false);
      return;
    }

    if (!canFilterBranches && (branchId == null || branchId <= 0)) {
      orders.clear();
      if (!silent) loading(false);
      return;
    }

    final idx = filterIndex.value;
    final key = _cacheKey(idx);

    if (!force && _cache[key] != null && _fresh(_cacheAt[key])) {
      orders.assignAll(_cache[key]!);

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
          if (branchId != null && branchId > 0) 'branch_id': '$branchId',
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
        } else if (obj is Map && obj['data'] is List) {
          data = obj['data'] as List;
        } else {
          data = const [];
        }
      } else {
        data = const [];
      }

      var parsed = data
          .map<OrderModel>(
            (e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      /// حماية إضافية لو السيرفر لا يطبق branch_id
      if (branchId != null && branchId > 0) {
        parsed = parsed.where((o) => o.branchId == branchId).toList();
      }

      orders.assignAll(parsed);

      _cache[key] = parsed;
      _cacheAt[key] = DateTime.now();
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

  // ignore: unused_element
  void _invalidateCache() {
    _cache.clear();
    _cacheAt.clear();
  }

  void setFilter(int i) {
    if (i == filterIndex.value) return;
    filterIndex.value = i;
  }

  void setSearch(String q) {
    search.value = q;
  }

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
