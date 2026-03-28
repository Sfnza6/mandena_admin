import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../core/services/api_service.dart';
import '../core/config/env.dart';

class AdminUser {
  final int id;
  final String name;
  final String phone;
  final String role; // owner | admin | receiver
  final String avatarUrl;
  final int? branchId;

  const AdminUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.avatarUrl,
    this.branchId,
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
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'role': role,
    'avatar_url': avatarUrl,
    'branch_id': branchId,
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
      final uid = admin.value?.id;
      if (uid == null) return;

      final res = await _api.get('${Env.base}/get_staff_by_id.php?id=$uid');

      Map<String, dynamic>? raw;

      if (res is Map && res['status'] == 'success') {
        if (res['data'] is Map) {
          raw = Map<String, dynamic>.from(res['data']);
        } else if (res['data'] is List && (res['data'] as List).isNotEmpty) {
          raw = Map<String, dynamic>.from((res['data'] as List).first);
        }
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
    await _box.remove(_kToken);
    await _box.remove(_kUser);
    await _box.remove(_kCacheAt);
    admin.value = null;
  }
}
