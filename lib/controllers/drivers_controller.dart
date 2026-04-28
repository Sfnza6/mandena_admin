// lib/controllers/drivers_controller.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/api_service.dart';
import '../core/config/env.dart';
import '../data/models/branch_model.dart';
import '../data/models/driver_model.dart';
import '../data/models/order_model.dart';
import 'admin_branch_scope_controller.dart';
import 'AuthController.dart';

class DriversController extends GetxController {
  final _api = ApiService();
  final _branchScope = Get.find<AdminBranchScopeController>();

  /* ===================== سائقون ===================== */

  final loading = false.obs;
  final saving = false.obs;

  final drivers = <DriverModel>[].obs;
  final filtered = <DriverModel>[].obs;

  final searchCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  /// فروع نموذج إضافة السائق + فلتر الفروع للمالك
  final formBranches = <BranchModel>[].obs;
  final formBranchesLoading = false.obs;
  final selectedBranchId = Rxn<int>();

  /* ===================== فلترة الفروع ===================== */

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

  /// القيمة المختارة في شريط الفروع:
  /// 0 = كل الفروع
  /// غير ذلك = رقم الفرع
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

    final b = formBranches.firstWhereOrNull((e) => e.id == id);
    if (b != null && b.name.trim().isNotEmpty) return b.name;

    return 'فرع #$id';
  }

  void setBranchFilter(int value) {
    final newValue = value <= 0 ? null : value;

    if (_branchScope.selectedBranchId.value == newValue) return;

    _branchScope.selectedBranchId.value = newValue;

    _clearDriversCache();
    fetchDrivers(force: true);
  }

  /* ===================== كاش السائقين ===================== */

  static final Map<String, List<DriverModel>> _driversCache = {};
  static final Map<String, DateTime> _driversCacheAt = {};

  static const Duration _driversCacheTTL = Duration(seconds: 60);

  static final Map<String, List<OrderModel>> _assignedCache = {};
  static final Map<String, DateTime> _assignedCacheAt = {};

  static const Duration _assignedCacheTTL = Duration(seconds: 20);

  static const String _driversDiskKey = 'drivers_cache_raw';
  static const String _driversDiskAtKey = 'drivers_cache_at';

  static const Duration _driversDiskTTL = Duration(minutes: 5);
  static bool _diskLoadedOnce = false;

  Worker? _branchWorker;

  bool _isFresh(DateTime? t, Duration ttl) {
    if (t == null) return false;
    return DateTime.now().difference(t) < ttl;
  }

  bool _isDiskFresh(DateTime? t) {
    if (t == null) return false;
    return DateTime.now().difference(t) < _driversDiskTTL;
  }

  String get _driversCacheKey {
    final branchId = _effectiveBranchId;
    return branchId == null ? 'drivers_all' : 'drivers_branch_$branchId';
  }

  String get _driversDiskRawKey {
    return '${_driversDiskKey}_$_driversCacheKey';
  }

  String get _driversDiskAtKeyScoped {
    return '${_driversDiskAtKey}_$_driversCacheKey';
  }

  String _assignedKey(int? driverId) {
    final branchId = _effectiveBranchId;
    final branchPart = branchId == null ? 'all_branches' : 'branch_$branchId';
    final driverPart = driverId?.toString() ?? 'all';

    return '$branchPart:$driverPart';
  }

  void _clearDriversCache() {
    _driversCache.clear();
    _driversCacheAt.clear();
    _diskLoadedOnce = false;
  }

  Future<void> _saveDriversRawToDisk(List<dynamic> rawList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(rawList);

      await prefs.setString(_driversDiskRawKey, jsonStr);
      await prefs.setString(
        _driversDiskAtKeyScoped,
        DateTime.now().toIso8601String(),
      );
    } catch (_) {}
  }

  Future<bool> _loadDriversFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_driversDiskRawKey);
      final atStr = prefs.getString(_driversDiskAtKeyScoped);

      if (raw == null || atStr == null) return false;

      final at = DateTime.tryParse(atStr);
      if (!_isDiskFresh(at)) return false;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return false;

      final branchId = _effectiveBranchId;

      var list = decoded
          .map((e) => DriverModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (branchId != null && branchId > 0) {
        list = list.where((d) => d.branchId == branchId).toList();
      }

      _driversCache[_driversCacheKey] = list;
      _driversCacheAt[_driversCacheKey] = at ?? DateTime.now();

      drivers.assignAll(list);
      _applySearch();

      return true;
    } catch (_) {
      return false;
    }
  }

  /* ===================== جلب السائقين ===================== */

  Future<void> fetchDrivers({bool force = false}) async {
    final branchId = _effectiveBranchId;
    final cacheKey = _driversCacheKey;

    if (!force && !_diskLoadedOnce && !_driversCache.containsKey(cacheKey)) {
      _diskLoadedOnce = true;
      final ok = await _loadDriversFromDisk();
      if (ok) {
        // ignore: discarded_futures
        fetchDrivers(force: true);
        return;
      }
    }

    if (!force &&
        _driversCache.containsKey(cacheKey) &&
        _isFresh(_driversCacheAt[cacheKey], _driversCacheTTL)) {
      drivers.assignAll(_driversCache[cacheKey]!);
      _applySearch();
      return;
    }

    try {
      loading(true);

      final res = await _api.get(
        Env.driversList,
        query: {
          if (branchId != null && branchId > 0) 'branch_id': '$branchId',
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final listRaw = (res is Map && res['data'] is List)
          ? res['data'] as List
          : (res is Map && res['drivers'] is List)
          ? res['drivers'] as List
          : (res is List ? res : const <dynamic>[]);

      var list = listRaw
          .map((e) => DriverModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      /// حماية إضافية لو السيرفر لا يفلتر branch_id
      if (branchId != null && branchId > 0) {
        list = list.where((d) => d.branchId == branchId).toList();
      }

      drivers.assignAll(list);
      _applySearch();

      _driversCache[cacheKey] = list;
      _driversCacheAt[cacheKey] = DateTime.now();

      _saveDriversRawToDisk(listRaw);
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر تحميل السائقين: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      drivers.clear();
      filtered.clear();
    } finally {
      loading(false);
    }
  }

  void _applySearch() {
    onSearchChanged(searchCtrl.text);
  }

  void onSearchChanged(String q) {
    q = q.trim();

    if (q.isEmpty) {
      filtered.assignAll(drivers);
      return;
    }

    filtered.assignAll(
      drivers.where(
        (d) =>
            d.name.contains(q) ||
            d.phone.contains(q) ||
            d.id.toString().contains(q) ||
            (d.branchName != null && d.branchName!.contains(q)),
      ),
    );
  }

  /* ===================== الفروع ===================== */

  Future<void> loadBranchesForForm({bool force = false}) async {
    if (formBranchesLoading.value) return;
    if (!force && formBranches.isNotEmpty) return;

    try {
      formBranchesLoading(true);

      final res = await _api.get(Env.branchesList);

      final raw = (res is Map && res['data'] is List)
          ? (res['data'] as List)
          : (res is List ? res : const <dynamic>[]);

      final list = raw
          .map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e)))
          .where((b) => b.id > 0)
          .toList();

      formBranches.assignAll(list);

      final sel = selectedBranchId.value;
      if (sel != null && !list.any((b) => b.id == sel)) {
        selectedBranchId.value = null;
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر تحميل الفروع: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      formBranches.clear();
    } finally {
      formBranchesLoading(false);
    }
  }

  /* ===================== إضافة / حذف ===================== */

  void resetForm() {
    nameCtrl.clear();
    phoneCtrl.clear();
    passCtrl.clear();

    if (canFilterBranches) {
      selectedBranchId.value = _branchScope.selectedBranchId.value;
    } else {
      selectedBranchId.value = _effectiveBranchId;
    }
  }

  Future<bool> addDriver() async {
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final pass = passCtrl.text.trim();

    final branchId = selectedBranchId.value ?? _effectiveBranchId;

    if (name.isEmpty || phone.isEmpty || pass.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'املأ الاسم/الهاتف/الرقم السري',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (branchId == null || branchId <= 0) {
      Get.snackbar(
        'تنبيه',
        'اختر الفرع المرتبط بالسائق',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      saving(true);

      final res = await _api.postForm(Env.addDriver, {
        'name': name,
        'phone': phone,
        'password': pass,
        'branch_id': '$branchId',
      });

      final ok =
          (res is Map && (res['status'] == 'success' || res['ok'] == true));

      if (!ok) {
        final msg =
            (res is Map ? (res['message'] ?? res['error']) : res)?.toString() ??
            'فشل الإضافة';
        Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
        return false;
      }

      _clearDriversCache();
      await fetchDrivers(force: true);
      resetForm();

      return true;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر الاتصال: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      saving(false);
    }
  }

  Future<bool> deleteDriver(DriverModel d) async {
    try {
      final res = await _api.postForm(Env.deleteDriver, {
        'id': d.id.toString(),
      });

      final ok =
          (res is Map && (res['status'] == 'success' || res['ok'] == true));

      if (ok) {
        drivers.removeWhere((e) => e.id == d.id);
        filtered.removeWhere((e) => e.id == d.id);

        _clearDriversCache();
        await fetchDrivers(force: true);

        return true;
      } else {
        final msg =
            (res is Map ? (res['message'] ?? res['error']) : res)?.toString() ??
            'تعذر الحذف';
        Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر الاتصال: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /* ===================== الطلبات المكلّفة ===================== */

  final assignedLoading = false.obs;
  final assignedOrders = <OrderModel>[].obs;

  Future<void> fetchAssignedOrders({int? driverId, bool force = false}) async {
    final key = _assignedKey(driverId);
    final branchId = _effectiveBranchId;

    if (!force &&
        _assignedCache.containsKey(key) &&
        _isFresh(_assignedCacheAt[key], _assignedCacheTTL)) {
      assignedOrders.assignAll(_assignedCache[key]!);
      return;
    }

    assignedLoading(true);

    try {
      final params = <String, String>{
        if (driverId != null) 'driver_id': '$driverId',
        if (branchId != null && branchId > 0) 'branch_id': '$branchId',
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final res = await _api.get(Env.assignedOrders, query: params);

      final listRaw = (res is Map && res['orders'] is List)
          ? (res['orders'] as List)
          : (res is List ? res : const <dynamic>[]);

      var list = listRaw
          .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (branchId != null && branchId > 0) {
        list = list.where((o) => o.branchId == branchId).toList();
      }

      assignedOrders.assignAll(list);

      _assignedCache[key] = list;
      _assignedCacheAt[key] = DateTime.now();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر تحميل الطلبات المكلّفة: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      assignedOrders.clear();
    } finally {
      assignedLoading(false);
    }
  }

  Future<bool> assignOrderToDriver({
    required int orderId,
    required int driverId,
  }) async {
    try {
      final res = await _api.postForm(Env.assignDriver, {
        'order_id': '$orderId',
        'driver_id': '$driverId',
      });

      final ok =
          (res is Map && (res['status'] == 'success' || res['ok'] == true));

      if (!ok) {
        final msg =
            (res is Map ? (res['message'] ?? res['error']) : res)?.toString() ??
            'تعذر التكليف';
        Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
        return false;
      }

      await fetchAssignedOrders(force: true);

      return true;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر الاتصال: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /* ===================== لوحة مالية لسائق معيّن ===================== */

  final driverFinanceLoading = false.obs;
  final driverFinanceRange = 'all'.obs;

  final driverFinanceSummary = <String, dynamic>{}.obs;
  final driverFinanceToday = <String, dynamic>{}.obs;

  final driverFinanceDriverClosures = <Map<String, dynamic>>[].obs;
  final driverFinanceRestaurantClosures = <Map<String, dynamic>>[].obs;

  Future<void> loadDriverFinance(int driverId, {String? range}) async {
    final branchId = _effectiveBranchId;

    if (range != null) {
      driverFinanceRange.value = range;
    }

    driverFinanceLoading(true);

    try {
      final dash = await _api.get(
        Env.driverDashboard,
        query: {
          'driver_id': '$driverId',
          'range': driverFinanceRange.value,
          if (branchId != null && branchId > 0) 'branch_id': '$branchId',
        },
      );

      if (dash is Map) {
        final m = Map<String, dynamic>.from(dash);

        driverFinanceSummary.assignAll({
          'delivered': m['delivered'] ?? 0,
          'rejected': m['rejected'] ?? 0,
          'profit_all': double.tryParse('${m['profit_all'] ?? 0}') ?? 0.0,
          'dues_today': double.tryParse('${m['dues_today'] ?? 0}') ?? 0.0,
          'debt_today': double.tryParse('${m['debt_today'] ?? 0}') ?? 0.0,
        });

        if (m['today'] is Map) {
          driverFinanceToday.assignAll(
            Map<String, dynamic>.from(m['today'] as Map),
          );
        }
      }

      final clos = await _api.get(
        Env.driverClosuresList,
        query: {
          'driver_id': '$driverId',
          if (branchId != null && branchId > 0) 'branch_id': '$branchId',
        },
      );

      if (clos is Map) {
        final mm = Map<String, dynamic>.from(clos);

        final dList = (mm['driver'] ?? []) as List;
        driverFinanceDriverClosures.assignAll(
          dList.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );

        final rList = (mm['restaurant'] ?? []) as List;
        driverFinanceRestaurantClosures.assignAll(
          rList.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );

        if (mm['today'] is Map) {
          driverFinanceToday.assignAll(
            Map<String, dynamic>.from(mm['today'] as Map),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر تحميل البيانات المالية للسائق: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      driverFinanceLoading(false);
    }
  }

  /* ===================== دورة الحياة ===================== */

  @override
  void onInit() {
    super.onInit();

    searchCtrl.addListener(() {
      onSearchChanged(searchCtrl.text);
    });

    if (canFilterBranches) {
      loadBranchesForForm();
    }

    _branchWorker = ever<int?>(_branchScope.selectedBranchId, (_) {
      _clearDriversCache();
      fetchDrivers(force: true);
    });

    fetchDrivers();
  }

  @override
  void onClose() {
    _branchWorker?.dispose();

    searchCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    passCtrl.dispose();

    super.onClose();
  }
}
