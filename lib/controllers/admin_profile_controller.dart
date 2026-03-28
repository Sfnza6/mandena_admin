import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/api_service.dart';
import '../core/config/env.dart';
import '../core/utils/snack_utils.dart';
import '../data/models/staff_model.dart';

class AdminProfileController extends GetxController {
  final _api = ApiService();

  final loading = false.obs;
  final saving = false.obs;
  final admin = Rxn<StaffModel>();

  // فورم تغيير كلمة السر
  final curPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  // ==========================================================
  //                        📌 الكــــــاش
  // ==========================================================

  /// نخزّن بيانات الأدمن حسب الـ ID
  static final Map<int, StaffModel> _cache = {};
  static final Map<int, DateTime> _cacheAt = {};
  static const Duration _ttl = Duration(seconds: 20);

  bool _fresh(DateTime? t) {
    if (t == null) return false;
    return DateTime.now().difference(t) < _ttl;
  }

  void _setCache(int id, StaffModel m) {
    _cache[id] = m;
    _cacheAt[id] = DateTime.now();
  }

  void invalidate(int id) {
    _cache.remove(id);
    _cacheAt.remove(id);
  }

  // ==========================================================

  Future<void> fetchAdminById(int id, {bool force = false}) async {
    // ✔ الكاش موجود وحديث → رجّع البيانات فوراً
    if (!force && _cache[id] != null && _fresh(_cacheAt[id])) {
      admin.value = _cache[id]!;
      return;
    }

    try {
      loading(true);

      final res =
          await _api.get('${Env.base}/get_staff_by_id.php?id=$id');

      Map<String, dynamic>? raw;

      if (res is Map && res['status'] == 'success') {
        if (res['data'] is Map) {
          raw = Map<String, dynamic>.from(res['data']);
        } else if (res['data'] is List && (res['data'] as List).isNotEmpty) {
          raw = Map<String, dynamic>.from((res['data'] as List).first);
        }
      }

      if (raw != null) {
        final model = StaffModel.fromJson(raw);

        admin.value = model;

        // ✔ حفظ في الكاش
        _setCache(id, model);
      }
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذّر تحميل البيانات'));
    } finally {
      loading(false);
    }
  }

  // ==========================================================
  //                     تغيير كلمة السر
  // ==========================================================

  Future<bool> changePassword() async {
    final cur = curPassCtrl.text.trim();
    final np = newPassCtrl.text.trim();
    final cp = confirmPassCtrl.text.trim();

    if (np.length < 6) {
      AppSnack.error('كلمة السر الجديدة يجب أن تكون 6 أحرف على الأقل');
      return false;
    }
    if (np != cp) {
      AppSnack.error('تأكيد كلمة السر غير مطابق');
      return false;
    }

    final adm = admin.value;
    if (adm == null) {
      AppSnack.error('بيانات غير متوفرة');
      return false;
    }
    if (cur.isEmpty) {
      AppSnack.error('أدخل كلمة السر الحالية للتحقق');
      return false;
    }

    try {
      saving(true);

      final res = await _api.postForm(Env.adminChangePassword, {
        'id': '${adm.id}',
        'current_password': cur,
        'new_password': np,
      });

      if (res is Map &&
          (res['status'] == 'success' || res['ok'] == true)) {
        AppSnack.success('تم تغيير كلمة السر بنجاح');

        // تنظيف الحقول
        curPassCtrl.clear();
        newPassCtrl.clear();
        confirmPassCtrl.clear();

        // ⚠ مهم: تنظيف كاش الأدمن
        invalidate(adm.id);

        return true;
      } else {
        AppSnack.error(AppSnack.passwordChangeError(res));
        return false;
      }
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذّر تغيير كلمة السر'));
      return false;
    } finally {
      saving(false);
    }
  }
}
