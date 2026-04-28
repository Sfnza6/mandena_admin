import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../core/services/api_service.dart';
import '../core/config/env.dart';
import 'dashboard_controller.dart';
import 'orders_controller.dart';
import 'categories_controller.dart';
import 'items_controller.dart';
import 'offers_controller.dart';
import 'branches_controller.dart';
import 'staff_controller.dart';
import 'users_controller.dart';
import 'drivers_controller.dart';
import '../modules/delivery/delivery_settings_controller.dart';
import 'receiver_items_controller.dart';
import 'ReceiverOrdersController.dart';

class AdminUser {
  final int id;
  final String name;
  final String phone;
  final String role; // owner | admin | receiver
  final String avatarUrl;
  final int? branchId;
  final String branchName;

  const AdminUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.avatarUrl,
    this.branchId,
    this.branchName = '',
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) {
    int i(v) => int.tryParse('${v ?? 0}') ?? 0;
    String s(v) => (v ?? '').toString();

    int? ni(v) {
      if (v == null) return null;
      final t = '$v'.trim();
      if (t.isEmpty || t.toLowerCase() == 'null') return null;
      return int.tryParse(t);
    }

    return AdminUser(
      id: i(j['id']),
      name: s(j['name']),
      phone: s(j['phone']),
      role: s(j['role']).toLowerCase().trim(),
      avatarUrl: s(j['avatar_url'] ?? j['image_url'] ?? j['photo']),
      branchId: ni(j['branch_id'] ?? j['branchId']),
      branchName: (() {
        final b = j['branch'];
        if (b is Map && b['name'] != null) return s(b['name']);
        return s(
          j['branch_name'] ??
              j['branchName'] ??
              j['branch_title'] ??
              j['branchTitle'],
        );
      })(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'role': role,
    'avatar_url': avatarUrl,
    'branch_id': branchId,
    'branch_name': branchName,
  };
}

class AuthController extends GetxController {
  final _api = ApiService();
  final _box = GetStorage('auth');

  final Rxn<AdminUser> admin = Rxn<AdminUser>();
  final isBusy = false.obs;

  static const _kToken = 'token';
  static const _kUser = 'user';
  static const _kCacheAt = 'user_cache_at';

  static const Duration _ttl = Duration(minutes: 10);

  bool _didRestore = false;
  bool _isRefreshing = false;

  String? get token => _box.read<String?>(_kToken);
  bool get isLoggedIn => admin.value != null;

  String get currentRole => (admin.value?.role ?? '').toLowerCase().trim();
  int? get currentBranchId => admin.value?.branchId;
  String get currentBranchName => (admin.value?.branchName ?? '').trim();

  bool get isOwner => currentRole == 'owner';
  bool get isAdmin => currentRole == 'admin';
  bool get isReceiver => currentRole == 'receiver';

  int? get scopedBranchId => isOwner ? null : currentBranchId;

  @override
  void onInit() {
    super.onInit();
    if (_didRestore) return;
    _didRestore = true;
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final t = _box.read<String?>(_kToken);
    final u = _box.read<String?>(_kUser);
    final ts = _box.read<int?>(_kCacheAt);

    if (t == null || u == null) return;

    try {
      final user = AdminUser.fromJson(jsonDecode(u));
      admin.value = user;

      if (ts != null) {
        final savedAt = DateTime.fromMillisecondsSinceEpoch(ts, isUtc: false);
        final age = DateTime.now().difference(savedAt);

        if (age > _ttl) {
          await _refreshUserData();
        }
      }
    } catch (_) {
      await logout();
    }
  }

  Future<void> _refreshUserData() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final res = await _api.get(Env.me);
      Map<String, dynamic>? raw;

      if (res is Map && res['status'] == 'success' && res['data'] is Map) {
        raw = Map<String, dynamic>.from(res['data']);
      } else if (res is Map && res['data'] is Map) {
        raw = Map<String, dynamic>.from(res['data']);
      } else if (res is Map && res.containsKey('id')) {
        raw = Map<String, dynamic>.from(res);
      }

      if (raw == null) return;

      final refreshed = AdminUser.fromJson(raw);
      admin.value = refreshed;

      await _box.write(_kUser, jsonEncode(refreshed.toJson()));
      await _box.write(_kCacheAt, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // تجاهل الخطأ هنا حتى لا ندخل في حلقة
    } finally {
      _isRefreshing = false;
    }
  }

  Map<String, dynamic>? _extractUserMap(dynamic res) {
    if (res is Map) {
      if (res['admin'] is Map) return Map<String, dynamic>.from(res['admin']);
      if (res['user'] is Map) return Map<String, dynamic>.from(res['user']);
      if (res['data'] is Map) return Map<String, dynamic>.from(res['data']);
      if (res.containsKey('id')) return Map<String, dynamic>.from(res);
    }
    return null;
  }

  String? _extractToken(dynamic res) {
    if (res is Map) {
      final t = res['token'] ?? res['access_token'];
      if (t != null) return t.toString();
    }
    return null;
  }

  Future<bool> login({required String phone, required String password}) async {
    try {
      isBusy(true);

      final res = await _api.postForm(Env.loginAdmin, {
        'phone': phone,
        'password': password,
      });

      if (res is Map && (res['status'] == 'success' || res['ok'] == true)) {
        final userMap = _extractUserMap(res);
        final t = _extractToken(res);

        if (userMap == null) {
          Get.snackbar('خطأ', 'استجابة غير متوقعة من الخادم');
          return false;
        }

        final user = AdminUser.fromJson(userMap);

        // مهم: عند تبديل مستخدم/مستقبل طلبات نمسح كاش الطلبات القديم
        // حتى لا تظهر طلبات فرع أو مستخدم سابق بعد تسجيل الخروج والدخول من جديد.
        ReceiverOrdersController.clearGlobalCache();

        admin.value = user;

        if (t != null) await _box.write(_kToken, t);
        await _box.write(_kUser, jsonEncode(user.toJson()));
        await _box.write(_kCacheAt, DateTime.now().millisecondsSinceEpoch);

        return true;
      }

      Get.snackbar(
        'خطأ',
        (res is Map
                ? (res['message'] ?? 'بيانات الدخول غير صحيحة')
                : 'بيانات الدخول غير صحيحة')
            .toString(),
      );
      return false;
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر الاتصال: $e');
      return false;
    } finally {
      isBusy(false);
    }
  }

  Future<void> logout() async {
    ReceiverOrdersController.clearGlobalCache();
    await _box.remove(_kToken);
    await _box.remove(_kUser);
    await _box.remove(_kCacheAt);

    admin.value = null;

    if (Get.isRegistered<DashboardController>()) {
      Get.delete<DashboardController>(force: true);
    }
    if (Get.isRegistered<OrdersController>()) {
      Get.delete<OrdersController>(force: true);
    }
    if (Get.isRegistered<CategoriesController>()) {
      Get.delete<CategoriesController>(force: true);
    }
    if (Get.isRegistered<ItemsController>()) {
      Get.delete<ItemsController>(force: true);
    }
    if (Get.isRegistered<OffersController>()) {
      Get.delete<OffersController>(force: true);
    }
    if (Get.isRegistered<BranchesController>()) {
      Get.delete<BranchesController>(force: true);
    }
    if (Get.isRegistered<StaffController>()) {
      Get.delete<StaffController>(force: true);
    }
    if (Get.isRegistered<UsersController>()) {
      Get.delete<UsersController>(force: true);
    }
    if (Get.isRegistered<DriversController>()) {
      Get.delete<DriversController>(force: true);
    }
    if (Get.isRegistered<DeliverySettingsController>()) {
      Get.delete<DeliverySettingsController>(force: true);
    }
    if (Get.isRegistered<ReceiverItemsController>()) {
      Get.delete<ReceiverItemsController>(force: true);
    }
    if (Get.isRegistered<ReceiverOrdersController>()) {
      Get.delete<ReceiverOrdersController>(force: true);
    }
  }
}
