// lib/controllers/users_controller.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/services/api_service.dart';
import '../core/config/env.dart';
import '../data/models/user_model.dart';

class UsersController extends GetxController with WidgetsBindingObserver {
  final _api = ApiService();

  final loading = false.obs;
  final users = <UserModel>[].obs;
  final lastError = ''.obs;

  /// نص البحث (اسم / رقم الهاتف / رقم المستخدم)
  final searchQuery = ''.obs;

  Timer? _auto;
  final _interval = const Duration(seconds: 15);

  /* ===================== كـــاش (RAM) ===================== */

  static List<UserModel>? _cacheUsers;
  static DateTime? _cacheAt;

  static const Duration _cacheTTL = Duration(seconds: 25);

  bool get _hasFreshCache {
    if (_cacheUsers == null || _cacheAt == null) return false;
    return DateTime.now().difference(_cacheAt!) < _cacheTTL;
  }

  void _writeCache(List<UserModel> list) {
    _cacheUsers = List<UserModel>.from(list);
    _cacheAt = DateTime.now();
  }

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  @override
  void onReady() {
    super.onReady();

    fetchUsers(silent: true);

    WidgetsBinding.instance.addObserver(this);

    _auto?.cancel();
    _auto = Timer.periodic(_interval, (_) {
      fetchUsers(silent: true);
    });
  }

  @override
  void onClose() {
    _auto?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  // تحديث عند العودة من الخلفية
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchUsers(silent: true);
    }
  }

  /// Pull-to-Refresh
  Future<void> refreshUsers() => fetchUsers(force: true, silent: true);

  /* ===================== ضبط نص البحث ===================== */

  void setSearch(String value) {
    searchQuery.value = value;
  }

  /* ===================== جلب قائمة المستخدمين ===================== */

  Future<void> fetchUsers({bool silent = false, bool force = false}) async {
    try {
      // 1) استخدم الكاش
      if (!force && _hasFreshCache) {
        users.assignAll(_cacheUsers!);
        return;
      }

      if (!silent) loading(true);
      lastError.value = '';

      final res = await _api.get(
        Env.usersList,
        query: {
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      dynamic root = res;
      if (res is String) {
        try {
          root = jsonDecode(res);
        } catch (_) {}
      }

      final List rawList =
          (root is List)
              ? root
              : (root is Map && root['data'] is List)
                  ? root['data']
                  : (root is Map && root['users'] is List)
                      ? root['users']
                      : <dynamic>[];

      final list = rawList
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      users.assignAll(list);

      // 2) تحديث الكاش
      _writeCache(list);
    } catch (e) {
      lastError.value = e.toString();

      if (!silent) {
        Get.snackbar(
          'خطأ',
          'تعذّر تحميل المستخدمين',
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      // 3) fallback للكاش القديم حتى لو منتهي
      if (_cacheUsers != null) {
        users.assignAll(_cacheUsers!);
      }
    } finally {
      if (!silent) loading(false);
    }
  }

  /* ===================== تحديث عنصر واحد محليًا ===================== */

  void _localUpsert({
    required int userId,
    bool? isBanned,
    String? bannedReason,
  }) {
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx == -1) return;

    final u = users[idx];
    final updated = u.copyWith(
      isBanned: isBanned ?? u.isBanned,
      bannedReason: bannedReason ?? u.bannedReason,
    );

    users[idx] = updated;
    users.refresh();

    // تحديث الكاش
    if (_cacheUsers != null) {
      final cIdx = _cacheUsers!.indexWhere((e) => e.id == userId);
      if (cIdx != -1) {
        _cacheUsers![cIdx] = updated;
      }
      _cacheAt = DateTime.now();
    }
  }

  /* ===================== تقييد / إلغاء تقييد المستخدم ===================== */

  Future<void> toggleBan({
    required int userId,
    required bool ban,
    String reason = '',
  }) async {
    try {
      await _api.postForm(Env.updateuserban, {
        'user_id': '$userId',
        'is_banned': ban ? '1' : '0',
        'banned_reason': reason,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      // تحديث محلي فوري (Optimistic Update)
      _localUpsert(
        userId: userId,
        isBanned: ban,
        bannedReason: ban ? reason : '',
      );

      // تحديث من السيرفر
      await Future.delayed(const Duration(milliseconds: 250));
      await fetchUsers(silent: true, force: true);

      Get.snackbar(
        'تم',
        ban ? 'تم تقييد المستخدم' : 'تم إلغاء التقييد',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذّر تعديل حالة المستخدم: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
