// lib/controllers/user_details_controller.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/services/api_service.dart';
import '../core/config/env.dart';
import '../data/models/order_model.dart';
import 'users_controller.dart'; // لتحديث قائمة المستخدمين بعد التقييد/الإلغاء

class UserDetailsController extends GetxController with WidgetsBindingObserver {
  UserDetailsController(this.userId, {this.initialName, this.initialPhone});

  // ===== params =====
  final int userId;
  final String? initialName;
  final String? initialPhone;

  // ===== services =====
  final _api = ApiService();

  // ===== user fields =====
  final name = ''.obs;
  final phone = ''.obs;
  final isBanned = false.obs;
  final bannedReason = ''.obs;

  // ===== orders =====
  final loading = false.obs;
  final orders = <OrderModel>[].obs;

  int get ordersCount => orders.length;

  // مانع سباق بسيط بعد التقييد/الإلغاء
  DateTime? _holdBanUntil;

  /* ===================== كـــاش (RAM) ===================== */

  // بيانات المستخدم: user_id -> Map
  static final Map<int, Map<String, dynamic>> _userCache = {};
  static final Map<int, DateTime> _userCacheAt = {};

  // الطلبات: user_id -> List<OrderModel>
  static final Map<int, List<OrderModel>> _ordersCache = {};
  static final Map<int, DateTime> _ordersCacheAt = {};

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
  }

  @override
  void onReady() {
    super.onReady();
    // راقب دورة حياة التطبيق لتحديث البيانات عند العودة من الخلفية
    WidgetsBinding.instance.addObserver(this);
    loadAll();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    // عند الخروج من الصفحة حدّث قائمة المستخدمين إن كانت مفتوحة
    if (Get.isRegistered<UsersController>()) {
      Get.find<UsersController>().refreshUsers();
    }
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // لما ترجع من الخلفية، حمّل من جديد (باستخدام الكاش لو مازال صالح)
      loadAll();
    }
  }

  Future<void> loadAll() async {
    await fetchUser();
    await fetchUserOrders(silent: true);
  }

  /* ===================== جلب المستخدم ===================== */

  /// يجلب بيانات المستخدم (يدعم أكثر من شكل للـ API) مع كاش + كسر كاش اختياري
  Future<void> fetchUser({bool force = false}) async {
    // 1) جرّب الكاش أولاً
    if (!force &&
        _userCache.containsKey(userId) &&
        _isFresh(_userCacheAt[userId])) {
      final data = _userCache[userId]!;
      _applyUserDataFromMap(data, fromCache: true);
      return;
    }

    // 2) من السيرفر
    try {
      final res = await _api.get(
        Env.userById,
        query: {
          'user_id': '$userId',
          // t لكسر كاش البروكسي/السيرفر، بينما الكاش "الحقيقي" عندنا
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final obj = (res is String) ? jsonDecode(res) : res;

      Map<String, dynamic>? data;
      if (obj is Map) {
        if (obj['data'] is Map) {
          data = Map<String, dynamic>.from(obj['data']);
        } else if (obj['user'] is Map) {
          data = Map<String, dynamic>.from(obj['user']);
        } else {
          final cand = <String>['id', 'username', 'name', 'phone', 'is_banned'];
          if (cand.any(obj.containsKey)) {
            data = Map<String, dynamic>.from(obj);
          }
        }
      }

      if (data != null) {
        // طبّق القيم على الـ Rx
        _applyUserDataFromMap(data, fromCache: false);

        // خزن في الكاش
        _userCache[userId] = Map<String, dynamic>.from(data);
        _userCacheAt[userId] = DateTime.now();

        // لو فيه طلبات راجعة من نفس الـ endpoint، خزنها في كاش الطلبات أيضاً
        final rawOrders = (data['orders'] is List)
            ? (data['orders'] as List)
            : (obj is Map && obj['orders'] is List
                ? obj['orders'] as List
                : null);
        if (rawOrders != null) {
          final list = rawOrders
              .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          orders.assignAll(list);
          _ordersCache[userId] = list;
          _ordersCacheAt[userId] = DateTime.now();
        }
      }
    } catch (_) {
      // تجاهل بهدوء
    }
  }

  void _applyUserDataFromMap(Map<String, dynamic> data,
      {required bool fromCache}) {
    name.value =
        (data['username'] ?? data['name'] ?? name.value).toString();
    phone.value = (data['phone'] ?? phone.value).toString();

    // === لا نغيّر isBanned إلا إذا فيه حقل فعلاً في الـ Map ===
    final rawBan = (data.containsKey('is_banned')
        ? data['is_banned']
        : (data.containsKey('banned')
            ? data['banned']
            : (data.containsKey('blocked') ? data['blocked'] : null)));

    if (rawBan != null) {
      final s = (rawBan is bool)
          ? (rawBan ? '1' : '0')
          : rawBan.toString().toLowerCase().trim();
      final serverBan = (s == '1' || s == 'true');

      // احترم قفل السباق _holdBanUntil حتى لو البيانات من الكاش
      final now = DateTime.now();
      if (_holdBanUntil == null || now.isAfter(_holdBanUntil!)) {
        isBanned.value = serverBan;
      }
    }

    // سبب الحظر (لو موجود)
    if (data.containsKey('banned_reason') ||
        data.containsKey('ban_reason')) {
      bannedReason.value =
          (data['banned_reason'] ?? data['ban_reason'] ?? '').toString();
    }
  }

  /* ===================== جلب الطلبات ===================== */

  /// يجلب طلبات المستخدم مع كاش + كسر كاش اختياري
  Future<void> fetchUserOrders({bool silent = false, bool force = false}) async {
    // 1) استخدام كاش الطلبات إن وُجد وكان حديثًا
    if (!force &&
        _ordersCache.containsKey(userId) &&
        _isFresh(_ordersCacheAt[userId])) {
      orders.assignAll(_ordersCache[userId]!);
      return;
    }

    if (!silent) loading(true);
    try {
      final res = await _api.get(
        Env.userOrders,
        query: {
          'user_id': '$userId',
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      dynamic root = res;
      if (res is String) {
        try {
          root = jsonDecode(res);
        } catch (_) {}
      }

      final listRaw = (root is Map && root['data'] is List)
          ? root['data'] as List
          : (root is Map && root['orders'] is List)
              ? root['orders'] as List
              : (root is List ? root : const <dynamic>[]);

      final list = listRaw
          .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      orders.assignAll(list);

      // خزن في الكاش
      _ordersCache[userId] = list;
      _ordersCacheAt[userId] = DateTime.now();
    } finally {
      if (!silent) loading(false);
    }
  }

  /* ===================== أدوات مساعدة ===================== */

  /// ترجمة حالة الطلب للعربي
  String statusArabic(String? s) {
    final x = (s ?? '').toLowerCase().trim();
    switch (x) {
      case 'pending':
        return 'معلّق';
      case 'accepted':
      case 'processing':
      case 'preparing':
        return 'جاري التحضير';
      case 'assigned':
      case 'onway':
      case 'delivering':
        return 'جاري التوصيل';
      case 'delivered':
        return 'تم التسليم';
      case 'rejected':
      case 'cancelled':
        return 'أُلغي';
      default:
        return s ?? '-';
    }
  }

  /// تقييد/إلغاء تقييد المستخدم ثم إعادة الجلب وتحديث قائمة المستخدمين
  Future<void> toggleBan({String reason = ''}) async {
    final next = !isBanned.value;
    try {
      final res = await _api.postForm(Env.updateuserban, {
        'user_id': '$userId',
        'is_banned': next ? '1' : '0',
        if (reason.isNotEmpty) 'banned_reason': reason,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      final obj = (res is String) ? jsonDecode(res) : res;
      final ok =
          (obj is Map) &&
          ((obj['ok'] == true) ||
              (obj['status']?.toString().toLowerCase() == 'success') ||
              (obj['status']?.toString() == '1'));

      if (!ok) throw 'تعذّر تحديث حالة التقييد';

      // عدّل الحالة محليًا مباشرة
      isBanned.value = next;
      bannedReason.value = next ? reason : '';

      // قفل منع تحديث عكسي لمدة قصيرة تحسّبًا لسباق طلبات
      _holdBanUntil = DateTime.now().add(const Duration(seconds: 2));

      // نحدّث الكاش المحلي لهذا المستخدم كذلك (لو موجود)
      if (_userCache.containsKey(userId)) {
        final m = Map<String, dynamic>.from(_userCache[userId]!);
        m['is_banned'] = next ? 1 : 0;
        m['banned_reason'] = next ? reason : '';
        _userCache[userId] = m;
        _userCacheAt[userId] = DateTime.now();
      }

      // انتظر لحظة لضمان كتابة الـ DB، ثم أعد الجلب من السيرفر (مع force)
      await Future.delayed(const Duration(milliseconds: 250));
      await fetchUser(force: true);

      // حدّث شاشة القائمة فورًا (إن كانت موجودة)
      if (Get.isRegistered<UsersController>()) {
        await Get.find<UsersController>().refreshUsers();
      }

      Get.snackbar(
        'تم',
        next ? 'تم تقييد المستخدم' : 'تم إلغاء التقييد',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('خطأ', '$e', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
