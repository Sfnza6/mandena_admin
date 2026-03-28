import 'dart:convert';
import 'package:get/get.dart';
import '../core/services/api_service.dart';
import '../core/config/env.dart';
import '../core/utils/snack_utils.dart';
import '../data/models/item_model.dart';

class ReceiverItemsController extends GetxController {
  final _api = ApiService();

  final loading = false.obs;
  final items = <ItemModel>[].obs;

  /// أسماء الأقسام (يُملأ من جلب الفئات إن وُجد)
  final categoryNames = <int, String>{}.obs;

  /// تجميع الأصناف حسب القسم: categoryId -> قائمة الأصناف
  Map<int, List<ItemModel>> get itemsByCategory {
    final map = <int, List<ItemModel>>{};
    for (final it in items) {
      map.putIfAbsent(it.categoryId, () => []).add(it);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    final keys = map.keys.toList()..sort();
    return Map.fromEntries(keys.map((k) => MapEntry(k, map[k]!)));
  }

  /* ===========================
      🟢 كــاش الأصــنــاف
     =========================== */

  static List<ItemModel>? _cacheItems;       // قائمة الكاش
  static DateTime? _cacheAt;                 // وقت التحديث
  static const Duration _ttl = Duration(seconds: 30); // مدة الصلاحية

  bool _isFresh(DateTime? t) {
    if (t == null) return false;
    return DateTime.now().difference(t) < _ttl;
  }

  @override
  void onInit() {
    super.onInit();
    fetchItems();
  }

  /* ===========================
      🟢 جلب الأصناف + كاش
     =========================== */
  Future<void> fetchItems({bool force = false}) async {
    // 1) لو الكاش حديث → استعمله وارجع
    if (!force && _cacheItems != null && _isFresh(_cacheAt)) {
      items.assignAll(_cacheItems!);
      return;
    }

    loading(true);
    try {
      dynamic res = await _api.get(Env.receiverGetItems);

      // 🔍 لو الرد String نجرب نفكّه JSON
      if (res is String) {
        try {
          res = jsonDecode(res);
        } catch (_) {}
      }

      final list = (res is Map && res['items'] is List)
          ? (res['items'] as List)
          : (res is List ? res : const []);

      final parsed = list
          .map((e) => ItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      items.assignAll(parsed);

      // 🟢 خزّن في الكاش
      _cacheItems = parsed;
      _cacheAt = DateTime.now();

      // جلب أسماء الأقسام (إن وُجدت)
      _fetchCategoryNames();
    } finally {
      loading(false);
    }
  }

  Future<void> _fetchCategoryNames() async {
    try {
      final res = await _api.get(Env.categoriesList);
      dynamic data = res;
      if (res is String) {
        try {
          data = jsonDecode(res);
        } catch (_) {}
      }
      final raw = data is Map
          ? (data['data'] ?? data['categories'] ?? data['items'])
          : (data is List ? data : null);
      final listSafe = raw is List ? raw : const [];
      final names = <int, String>{};
      for (final e in listSafe) {
        final m = Map<String, dynamic>.from(e as Map);
        final id = int.tryParse('${m['id'] ?? 0}') ?? 0;
        final name = (m['name'] ?? '').toString().trim();
        if (id > 0 && name.isNotEmpty) names[id] = name;
      }
      categoryNames.assignAll(names);
    } catch (_) {}
  }

  /* ===========================
      🟢 تشغيل/إيقاف صنف
     =========================== */
  Future<void> toggleItem(ItemModel it, bool value) async {
    try {
      final res = await _api.postForm(Env.receiverToggleItem, {
        'item_id': '${it.id}',
        'is_active': value ? '1' : '0',
      });

      // نتحقق من الرد لو فيه status=error
      dynamic obj = res;
      if (res is String) {
        try {
          obj = jsonDecode(res);
        } catch (_) {}
      }
      if (obj is Map && obj['status'] == 'error') {
        AppSnack.error('تعذّر تحديث حالة الصنف');
        return;
      }

      final i = items.indexWhere((x) => x.id == it.id);
      if (i != -1) {
        items[i] = items[i].copyWith(isActive: value);

        // 🔄 تحدّيث الكاش مباشرة
        _cacheItems = items.toList();
        _cacheAt = DateTime.now();
      }
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذّر تحديث حالة الصنف'));
    }
  }

  /* ===========================
      🟢 تعديل الكمية اليومية
     =========================== */
  Future<void> setDailyQuota(ItemModel it, int? quota) async {
    try {
      final res = await _api.postForm(Env.receiverSetQuota, {
        'item_id': '${it.id}',
        // لو null معناها إزالة الحد اليومي (حسب منطق الـ PHP عندك)
        'daily_quota': quota == null ? 'null' : '$quota',
      });

      // نفك الرد ونتأكد من status
      dynamic obj = res;
      if (res is String) {
        try {
          obj = jsonDecode(res);
        } catch (_) {}
      }

      if (obj is Map && obj['status'] != null && obj['status'] != 'success') {
        AppSnack.error('تعذّر حفظ الحد اليومي');
        return;
      }

      // ✅ نحدّث العنصر محلياً (حتى يظهر فوراً)
      final i = items.indexWhere((x) => x.id == it.id);
      if (i != -1) {
        items[i] = items[i].copyWith(
          dailyQuota: quota,
          quotaUsed: 0,
          remaining: quota,
          // لو فيه حد يومي جديد نخلي الصنف فعّال تلقائياً
          isActive: (quota == null) ? items[i].isActive : true,
        );

        // تحديث الكاش من النسخة الجديدة
        _cacheItems = items.toList();
      }

      // ❗ مهم: نلغي صلاحية الكاش ونعيد الجلب من السيرفر
      _cacheAt = null;
      await fetchItems(force: true);

      AppSnack.success(
        quota == null ? 'تم إلغاء الحد اليومي' : 'تم تعيين الحد اليومي بنجاح',
      );
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذّر حفظ الحد اليومي'));
    }
  }

  /* ===========================
      🟢 إغلاق/فتح قسم كامل بأصنافه
     =========================== */
  Future<void> toggleCategory(int categoryId, bool value) async {
    final list = items.where((it) => it.categoryId == categoryId).toList();
    if (list.isEmpty) return;
    final toggled = <ItemModel>[];
    for (final it in list) {
      if (it.isActive != value) {
        await toggleItem(it, value);
        toggled.add(it);
      }
    }
    if (toggled.isEmpty) return;
    final names = toggled.map((it) => it.name).join('\n• ');
    AppSnack.successWithDetails(
      value ? 'تم فتح الأصناف' : 'تم إغلاق الأصناف',
      '• $names',
      duration: const Duration(seconds: 4),
    );
  }

  /* ===========================
      🟢 إغلاق جميع الأصناف
     =========================== */
  Future<void> closeAllItems() async {
    if (items.isEmpty) {
      AppSnack.warning('لا توجد أصناف لإغلاقها');
      return;
    }

    if (loading.value) return;

    loading(true);
    try {
      final currentItems = items.toList();

      for (final it in currentItems) {
        if (it.isActive) {
          await toggleItem(it, false);
        }
      }

      AppSnack.success('تم إغلاق جميع الأصناف لليوم');
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذّر إغلاق الأصناف'));
    } finally {
      loading(false);

      // 🟢 تحديث الكاش
      _cacheItems = items.toList();
      _cacheAt = DateTime.now();
    }
  }
}
