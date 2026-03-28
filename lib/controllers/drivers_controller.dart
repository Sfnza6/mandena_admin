// lib/controllers/drivers_controller.dart
import 'dart:convert'; // ✅ للكاش على الجهاز
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ للكاش المحلي

import '../core/services/api_service.dart';
import '../core/config/env.dart';
import '../data/models/driver_model.dart';
import '../data/models/order_model.dart';

class DriversController extends GetxController {
  final _api = ApiService();

  /* ===================== سائقون ===================== */

  // حالة التحميل والحفظ
  final loading = false.obs;
  final saving = false.obs;

  // البيانات
  final drivers = <DriverModel>[].obs;
  final filtered = <DriverModel>[].obs;

  // حقول البحث/الإضافة
  final searchCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  /* ===================== كـــاش للسائقين (في الذاكرة) ===================== */

  static List<DriverModel>? _driversCache;
  static DateTime? _driversCacheAt;

  // ⏱ TTL للسائقين في الذاكرة (أفضل من 30 ثانية)
  static const Duration _driversCacheTTL = Duration(seconds: 60);

  // كاش للطلبات المكلّفة (حسب السائق أو all) في الذاكرة
  static final Map<String, List<OrderModel>> _assignedCache = {};
  static final Map<String, DateTime> _assignedCacheAt = {};

  // ⏱ TTL للطلبات المكلّفة
  static const Duration _assignedCacheTTL = Duration(seconds: 20);

  bool _isFresh(DateTime? t, Duration ttl) {
    if (t == null) return false;
    return DateTime.now().difference(t) < ttl;
  }

  String _assignedKey(int? driverId) => driverId?.toString() ?? 'all';

  /* ===================== كـــاش للسائقين (على الجهاز) ===================== */

  static const String _driversDiskKey = 'drivers_cache_raw';
  static const String _driversDiskAtKey = 'drivers_cache_at';

  // TTL للكاش على الجهاز (مثلاً 5 دقائق)
  static const Duration _driversDiskTTL = Duration(minutes: 5);
  static bool _diskLoadedOnce = false;

  bool _isDiskFresh(DateTime? t) {
    if (t == null) return false;
    return DateTime.now().difference(t) < _driversDiskTTL;
  }

  /// حفظ الـ JSON الخام الذي جاء من الـ API في SharedPreferences
  Future<void> _saveDriversRawToDisk(List<dynamic> rawList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(rawList);
      await prefs.setString(_driversDiskKey, jsonStr);
      await prefs.setString(
        _driversDiskAtKey,
        DateTime.now().toIso8601String(),
      );
    } catch (_) {
      // تجاهل أي خطأ في التخزين بدون كسر المنطق
    }
  }

  /// محاولة تحميل السائقين من الكاش على الجهاز → وتعبئة _driversCache + drivers + filtered
  Future<bool> _loadDriversFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_driversDiskKey);
      final atStr = prefs.getString(_driversDiskAtKey);
      if (raw == null || atStr == null) return false;

      final at = DateTime.tryParse(atStr);
      if (!_isDiskFresh(at)) return false;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return false;

      final listRaw = decoded;

      final list = listRaw
          .map((e) => DriverModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (list.isEmpty) return false;

      _driversCache = list;
      _driversCacheAt = at;

      drivers.assignAll(list);
      filtered.assignAll(list);

      return true;
    } catch (_) {
      return false;
    }
  }

  // جلب السائقين
  Future<void> fetchDrivers({bool force = false}) async {
    // 🔹 أول فتح: نحاول نقرأ من الكاش على الجهاز مرة واحدة فقط
    if (!force && !_diskLoadedOnce && _driversCache == null) {
      _diskLoadedOnce = true;
      final ok = await _loadDriversFromDisk();
      if (ok) {
        // ✅ عرض سريع من الكاش، ثم تحديث من السيرفر في الخلفية
        // ignore: discarded_futures
        fetchDrivers(force: true);
        return;
      }
    }

    // 1) لو عندي كاش في الذاكرة حديث → رجّعه بدل ريكوست جديد
    if (!force &&
        _isFresh(_driversCacheAt, _driversCacheTTL) &&
        _driversCache != null) {
      drivers.assignAll(_driversCache!);
      filtered.assignAll(_driversCache!);

      // لو فيه نص بحث قديم نرجّع الفلترة عليه
      final q = searchCtrl.text.trim();
      if (q.isNotEmpty) {
        onSearchChanged(q);
      }
      return;
    }

    try {
      loading(true);
      final res = await _api.get(
        Env.driversList,
        query: {
          // t لكسر كاش البروكسي فقط
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      // يدعم شكلين للـ API: {status, data} أو {drivers: []} أو List مباشرة
      final listRaw = (res is Map && res['data'] is List)
          ? res['data'] as List
          : (res is Map && res['drivers'] is List)
              ? res['drivers'] as List
              : (res is List ? res : const <dynamic>[]);

      final list = listRaw
          .map((e) => DriverModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      drivers.assignAll(list);
      filtered.assignAll(list);

      // ✅ حفظ في الكاش (الذاكرة)
      _driversCache = list;
      _driversCacheAt = DateTime.now();

      // ✅ حفظ الخام في الكاش على الجهاز أيضاً
      _saveDriversRawToDisk(listRaw);

      // لو فيه نص بحث مكتوب حالياً نعيد الفلترة عليه بعد التحديث من السيرفر
      final q = searchCtrl.text.trim();
      if (q.isNotEmpty) {
        onSearchChanged(q);
      }
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

  // تصفية/بحث
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
            d.id.toString().contains(q),
      ),
    );
  }

  // مسح حقول الإضافة
  void resetForm() {
    nameCtrl.clear();
    phoneCtrl.clear();
    passCtrl.clear();
  }

  // إضافة سائق جديد
  Future<bool> addDriver() async {
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || pass.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'املأ الاسم/الهاتف/الرقم السري',
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

      // بعد الإضافة نعيد تحميل القائمة ونحدّث الكاش تلقائياً
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

  // حذف سائق (يمكنك استدعاؤها من الواجهة بعد تأكيد المستخدم)
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

        // حدّث الكاش بعد الحذف
        _driversCache = drivers.toList();
        _driversCacheAt = DateTime.now();

        // تحديث الكاش على الجهاز أيضاً
        _saveDriversRawToDisk(
          drivers
              .map((e) => e.toJson()) // يفترض أن DriverModel فيه toJson
              .toList(),
        );

        // لو فيه نص بحث نرجّع الفلترة
        final q = searchCtrl.text.trim();
        if (q.isNotEmpty) {
          onSearchChanged(q);
        }

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
        snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  /* ===================== الطلبات المكلّفة ===================== */

  final assignedLoading = false.obs;
  final assignedOrders = <OrderModel>[].obs;

  // جلب الطلبات المكلّفة (اختياري: حسب سائق معيّن) + كاش
  Future<void> fetchAssignedOrders({int? driverId, bool force = false}) async {
    final key = _assignedKey(driverId);

    // 1) استخدم الكاش في الذاكرة لو حديث
    if (!force &&
        _assignedCache.containsKey(key) &&
        _isFresh(_assignedCacheAt[key], _assignedCacheTTL)) {
      assignedOrders.assignAll(_assignedCache[key]!);
      return;
    }

    assignedLoading(true);
    try {
      final params = driverId == null
          ? {
              't': DateTime.now().millisecondsSinceEpoch.toString(),
            }
          : <String, String>{
              'driver_id': '$driverId',
              't': DateTime.now().millisecondsSinceEpoch.toString(),
            };

      final res = await _api.get(Env.assignedOrders, query: params);

      final listRaw = (res is Map && res['orders'] is List)
          ? (res['orders'] as List)
          : (res is List ? res : const <dynamic>[]);

      final list = listRaw
          .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      assignedOrders.assignAll(list);

      // ✅ خزّن في الكاش حسب key (سائق معيّن أو all)
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

  // تكليف طلب لسائق (ترجع زي ما كانت)
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

      // بعد التكليف نحدّث قائمة الطلبات المكلّفة
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

  /* ===================== لوحة مالية لسائق معيّن (للأدمن) ===================== */

  final driverFinanceLoading = false.obs;
  final driverFinanceRange = 'all'.obs; // today|week|month|all

  final driverFinanceSummary = <String, dynamic>{}.obs; // delivered/rejected/...
  final driverFinanceToday = <String, dynamic>{}.obs;   // dues_today/debt_today/profit_today

  final driverFinanceDriverClosures = <Map<String, dynamic>>[].obs;
  final driverFinanceRestaurantClosures = <Map<String, dynamic>>[].obs;

  Future<void> loadDriverFinance(int driverId, {String? range}) async {
    if (range != null) {
      driverFinanceRange.value = range;
    }

    driverFinanceLoading(true);
    try {
      // 1) ملخّص من dashboard.php (مسار السائق الصحيح)
      final dash = await _api.get(
        Env.driverDashboard, // 🔴 مهم: /api/driver/dashboard.php
        query: {
          'driver_id': '$driverId',
          'range': driverFinanceRange.value,
        },
      );

      if (dash is Map) {
        final m = Map<String, dynamic>.from(dash);

        driverFinanceSummary.assignAll({
          'delivered': m['delivered'] ?? 0,
          'rejected': m['rejected'] ?? 0,
          'profit_all':
              double.tryParse('${m['profit_all'] ?? 0}') ?? 0.0,
          'dues_today':
              double.tryParse('${m['dues_today'] ?? 0}') ?? 0.0,
          'debt_today':
              double.tryParse('${m['debt_today'] ?? 0}') ?? 0.0,
        });

        if (m['today'] is Map) {
          driverFinanceToday.assignAll(
            Map<String, dynamic>.from(m['today'] as Map),
          );
        }
      }

      // 2) تفاصيل الإغلاقات من closures_list.php (مسار السائق الصحيح)
      final clos = await _api.get(
        Env.driverClosuresList, // 🔴 مهم: /api/driver/closures_list.php
        query: {'driver_id': '$driverId'},
      );

      if (clos is Map) {
        final mm = Map<String, dynamic>.from(clos);

        final dList = (mm['driver'] ?? []) as List;
        driverFinanceDriverClosures.assignAll(
          dList
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );

        final rList = (mm['restaurant'] ?? []) as List;
        driverFinanceRestaurantClosures.assignAll(
          rList
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
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

    // ✅ ربط حقل البحث بالفلترة مباشرة
    searchCtrl.addListener(() {
      onSearchChanged(searchCtrl.text);
    });

    fetchDrivers();
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    passCtrl.dispose();
    super.onClose();
  }
}
