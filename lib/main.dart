import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:mandena_admin/controllers/AuthController.dart';
import 'package:mandena_admin/controllers/admin_branch_scope_controller.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

/* ============================================================
                      كـــاش عـــام (RAM)
   ============================================================ */

/// كاش عام للتطبيق بالكامل (يستخدمه أي Controller)
/// محصول داخل الذاكرة فقط — يختفي عند إعادة تشغيل التطبيق
class GlobalCache {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _time = {};

  /// زمن صلاحية الكاش الافتراضي
  static const Duration ttl = Duration(seconds: 30);

  /// حفظ بيانات في الكاش
  static void set(String key, dynamic value, {Duration? expire}) {
    _cache[key] = value;
    _time[key] = DateTime.now().add(expire ?? ttl);
  }

  /// جلب من الكاش
  static dynamic get(String key) {
    if (!_cache.containsKey(key)) return null;
    final exp = _time[key];
    if (exp == null || DateTime.now().isAfter(exp)) {
      _cache.remove(key);
      _time.remove(key);
      return null;
    }
    return _cache[key];
  }

  /// حذف مفتاح
  static void remove(String key) {
    _cache.remove(key);
    _time.remove(key);
  }

  /// مسح كامل الكاش
  static void clear() {
    _cache.clear();
    _time.clear();
  }
}

/// كاش سريع مخزن في GetStorage — يبقى بعد إعادة تشغيل التطبيق
class PersistentCache {
  static final _box = GetStorage('admin_cache');

  static dynamic get(String key) => _box.read(key);

  static void set(String key, dynamic value) => _box.write(key, value);

  static void remove(String key) => _box.remove(key);

  static void clear() => _box.erase();
}

/* ============================================================
                      نقطة البدء
   ============================================================ */

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 صناديق التخزين
  await GetStorage.init('auth'); // للجلسة
  await GetStorage.init('admin_cache'); // للكاش الدائم

  // ✅ صناديق الكاش الجديدة التي استخدمناها في الكنترولرات
  await GetStorage.init('delivery_settings_box'); // إعدادات التوصيل
  await GetStorage.init('item_comments_box'); // كاش تعليقات الأصناف

  /* ------------------------------------------------------------
       🔥  تهيئة الكاش قبل تشغيل التطبيق
       - تحميل بيانات محفوظة مسبقاً لتسريع الإقلاع
       - يمكن استخدامه لاحقاً لـ Dashboard أو counters
     ------------------------------------------------------------ */

  // مثال: تحميل آخر Dashboard Cache (لو موجود)
  final cachedDashboard = PersistentCache.get('dashboard_data');
  if (cachedDashboard != null) {
    GlobalCache.set('dashboard_data', cachedDashboard);
  }

  // 🔹 AuthController متاح لكل التطبيق
  if (!Get.isRegistered<AuthController>()) {
    Get.put(AuthController(), permanent: true);
  }
  Get.put(AdminBranchScopeController(), permanent: true);
  if (!Get.isRegistered<AdminBranchScopeController>()) {
    Get.put(AdminBranchScopeController(), permanent: true);
  }

  runApp(const Mandena_admin(initialRoute: ''));
}

/* ============================================================
                      واجهة التطبيق
   ============================================================ */

class Mandena_admin extends StatelessWidget {
  const Mandena_admin({super.key, required String initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Iforenta Admin',
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.decide, // بوابة التوجيه حسب الجلسة/الدور
      getPages: AppPages.pages,
      theme: AppTheme.lightTheme,
      locale: const Locale('ar'),
    );
  }
}
