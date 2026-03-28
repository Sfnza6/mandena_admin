import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart'; // ✅ للكاش الدائم

import '../core/services/api_service.dart';
import '../core/config/env.dart';
import '../data/models/category_model.dart';
import '../data/models/item_model.dart';
import 'items_controller.dart'; // ✅ استخدمناه كـ fallback لقراءة الأصناف
import 'admin_branch_scope_controller.dart';

class CategoriesController extends GetxController {
  final _api = ApiService();
  final _branchScope = Get.find<AdminBranchScopeController>();
  Worker? _branchWorker;

  // =================== 🔹 Cache ثابت في الذاكرة (RAM) 🔹 ===================
  static final Map<int, List<CategoryModel>> _cacheCategoriesByBranch = {};
  static final Map<int, Map<int, int>> _cacheItemCountByBranch = {};
  static final Map<int, DateTime> _cacheTimeByBranch = {};
  static const Duration _cacheDuration = Duration(seconds: 60);

  // =================== 🔹 Cache دائم في التخزين المحلي (GetStorage) 🔹 ===================
  static const String _boxName = 'admin_cache';
  static const String _kCatsKey = 'categories_list';
  static const String _kCountKey = 'categories_items_count';
  static const String _kTimeKey = 'categories_cache_at';

  int? get _branchId => _branchScope.effectiveBranchId;
  String get _catsKey => '${_kCatsKey}_${_branchId ?? 0}';
  String get _countKey => '${_kCountKey}_${_branchId ?? 0}';
  String get _timeKey => '${_kTimeKey}_${_branchId ?? 0}';

  final GetStorage _box = GetStorage(_boxName);
  List<CategoryModel>? get _cacheCategories =>
      _branchId == null ? null : _cacheCategoriesByBranch[_branchId!];
  set _cacheCategories(List<CategoryModel>? v) {
    final bid = _branchId;
    if (bid == null) return;
    if (v == null) {
      _cacheCategoriesByBranch.remove(bid);
    } else {
      _cacheCategoriesByBranch[bid] = v;
    }
  }

  Map<int, int>? get _cacheItemCount =>
      _branchId == null ? null : _cacheItemCountByBranch[_branchId!];
  set _cacheItemCount(Map<int, int>? v) {
    final bid = _branchId;
    if (bid == null) return;
    if (v == null) {
      _cacheItemCountByBranch.remove(bid);
    } else {
      _cacheItemCountByBranch[bid] = v;
    }
  }

  DateTime? get _cacheTime =>
      _branchId == null ? null : _cacheTimeByBranch[_branchId!];
  set _cacheTime(DateTime? v) {
    final bid = _branchId;
    if (bid == null) return;
    if (v == null) {
      _cacheTimeByBranch.remove(bid);
    } else {
      _cacheTimeByBranch[bid] = v;
    }
  }

  // حالة التحميل والحفظ والبحث
  final loading = false.obs;
  final saving = false.obs;
  final searchCtrl = TextEditingController();

  // البيانات
  final categories = <CategoryModel>[].obs;
  final filtered = <CategoryModel>[].obs;

  // عدّاد الأصناف لكل قسم
  final itemCountByCatId = <int, int>{}.obs;

  // نموذج (اسم وصورة)
  final nameCtrl = TextEditingController();
  final imagePath = ''.obs;

  // معاينة محلية
  File? imageFile;
  final currentImageUrl = ''.obs; // رابط الشبكة (للتعديل)

  // لالتقاط الصور
  final _picker = ImagePicker();

  // قاعدة روابط للإنتاج
  static const String kBaseUrl = 'https://evoranta.ly';

  // =================== Utilities ===================
  /// فك JSON بشكل آمن حتى لو كان مزدوج الترميز أو فيه نص زائد أو رجع Response
  static Map<String, dynamic>? _safeDecode(dynamic res) {
    try {
      if (res == null) return null;
      if (res is Map<String, dynamic>) return res;

      // حاول التقاط body إن كان كائن Response
      try {
        final dynamic maybeBody = (res as dynamic).body;
        if (maybeBody is String) {
          res = maybeBody;
        }
      } catch (_) {
        // تجاهل إن لم يكن به body
      }

      String s = (res is String) ? res : res.toString();
      s = s.trim();

      // إزالة BOM إن وجدت
      if (s.isNotEmpty && s.codeUnitAt(0) == 0xFEFF) {
        s = s.substring(1);
      }

      // اقتناص أول { وآخر } لو فيه زيادات حول JSON
      final start = s.indexOf('{');
      final end = s.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        s = s.substring(start, end + 1);
      }

      dynamic first = jsonDecode(s);

      // في حال السيرفر أرجع JSON كنص داخل JSON
      if (first is String) {
        first = jsonDecode(first);
      }

      if (first is Map<String, dynamic>) {
        return Map<String, dynamic>.from(first);
      }
    } catch (_) {
      // لا ترمِ الاستثناء، فقط أعد null
    }
    return null;
  }

  static String normalizeImageUrl(String? raw) {
    var u = (raw ?? '').trim();
    if (u.isEmpty) return '';

    u = u.replaceAll(
      RegExp(
        r'^https?://(localhost|127\.0\.0\.1)(:\d+)?',
        caseSensitive: false,
      ),
      kBaseUrl,
    );

    if (u.startsWith('/')) return '$kBaseUrl$u'.replaceAll(' ', '%20');

    final isFilename = !u.startsWith('http') && !u.startsWith('/');

    if (isFilename) {
      if (!u.toLowerCase().contains('uploads/')) {
        return '$kBaseUrl/uploads/$u'.replaceAll(' ', '%20');
      }
      return '$kBaseUrl/$u'.replaceAll(' ', '%20');
    }
    return u.replaceAll(' ', '%20');
  }

  static String _fixUrl(String u) {
    var x = u.trim();
    if (x.isEmpty) return '';

    x = x.replaceAll(
      RegExp(
        r'^https?://(localhost|127\.0\.0\.1)(:\d+)?',
        caseSensitive: false,
      ),
      Env.base.isNotEmpty ? Env.base : kBaseUrl,
    );

    if (x.startsWith('/')) {
      final base = Env.base.isNotEmpty ? Env.base : kBaseUrl;
      x = '$base${x.replaceFirst(RegExp(r"^/+"), "")}';
    }

    final isRelative = !x.startsWith('http://') && !x.startsWith('https://');

    if (isRelative) {
      final base = Env.base.isNotEmpty ? Env.base : kBaseUrl;
      x = '$base/${x.replaceFirst(RegExp(r"^/+"), "")}';
    }

    x = x.replaceAll(' ', '%20');
    return x;
  }

  // =================== Lifecycle ===================
  @override
  void onInit() {
    super.onInit();

    // 1️⃣ حمّل من الكاش الدائم (GetStorage) أولاً – عرض فوري
    _loadFromPersistentCache();

    // 2️⃣ بعد ذلك: جلب من السيرفر مع كاش RAM
    fetchAll();

    _branchWorker = ever<int?>(_branchScope.selectedBranchId, (_) {
      _clearBranchCache();
      // لا نمسح كاش الفروع الأخرى، فقط نفرغ المعروض الحالي
      fetchAll();
    });

    searchCtrl.addListener(_reapplyFilter);
    ever<List<CategoryModel>>(categories, (_) => _reapplyFilter());
  }

  @override
  void onClose() {
    _branchWorker?.dispose();
    searchCtrl.dispose();
    nameCtrl.dispose();
    super.onClose();
  }

  // ignore: unused_element
  void _clearBranchCache() {
    final bid = _branchId;
    if (bid != null) {
      _cacheCategoriesByBranch.remove(bid);
      _cacheItemCountByBranch.remove(bid);
      _cacheTimeByBranch.remove(bid);
    }
    categories.clear();
    filtered.clear();
    itemCountByCatId.clear();
  }

  bool _ensureBranchSelected() {
    if (_branchScope.effectiveBranchId != null) return true;
    Get.snackbar(
      'تنبيه',
      'اختر الفرع أولاً',
      snackPosition: SnackPosition.BOTTOM,
    );
    return false;
  }

  /* =================== 🔹 تحميل الكاش من التخزين المحلي 🔹 =================== */
  void _loadFromPersistentCache() {
    try {
      if (!_ensureBranchSelected()) return;
      final catsJson = _box.read(_catsKey);
      final countJson = _box.read(_countKey);
      final timeJson = _box.read(_timeKey);

      if (catsJson == null || countJson == null || timeJson == null) {
        return;
      }

      // استرجاع وقت الكاش
      DateTime? cachedAt;
      if (timeJson is int) {
        cachedAt = DateTime.fromMillisecondsSinceEpoch(timeJson);
      } else if (timeJson is String) {
        cachedAt = DateTime.tryParse(timeJson);
      }

      // نفترض أن الكاش القديم صالح (حتى لو أقدم من _cacheDuration)
      // لأننا سنعمل Refresh من السيرفر بعده مباشرة
      final List catsList = (catsJson is String)
          ? (jsonDecode(catsJson) as List)
          : (catsJson as List);

      final List<CategoryModel> listCats = catsList
          .map(
            (e) => CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      final Map<String, dynamic> countMapRaw = (countJson is String)
          ? Map<String, dynamic>.from(jsonDecode(countJson))
          : Map<String, dynamic>.from(countJson as Map);

      final mapCount = <int, int>{};
      countMapRaw.forEach((k, v) {
        final id = int.tryParse(k) ?? 0;
        final val = (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
        if (id > 0) mapCount[id] = val;
      });

      // تعبئة الـ Rx
      categories.assignAll(listCats);
      itemCountByCatId.assignAll(mapCount);
      _reapplyFilter();

      // تحديث كاش الذاكرة أيضاً
      _cacheCategories = List<CategoryModel>.from(listCats);
      _cacheItemCount = Map<int, int>.from(mapCount);
      _cacheTime = cachedAt;
    } catch (e) {
      // لو فشل الكاش، نتجاهله بهدوء
      debugPrint('loadFromPersistentCache error: $e');
    }
  }

  /* =================== 🔹 حفظ الكاش في التخزين المحلي 🔹 =================== */
  void _saveToPersistentCache() {
    try {
      final catsList = _cacheCategories?.map((e) => e.toJson()).toList() ?? [];
      final mapCount = <String, int>{};
      (_cacheItemCount ?? {}).forEach((k, v) {
        mapCount['$k'] = v;
      });

      _box.write(_kCatsKey, catsList);
      _box.write(_kCountKey, mapCount);
      _box.write(
        _kTimeKey,
        _cacheTime?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('saveToPersistentCache error: $e');
    }
  }

  /* =================== جلب الأقسام + الأصناف (للعدّادات) =================== */
  Future<void> fetchAll() async {
    // 🔹 1) جرّب كاش RAM أولاً لو القائمة فاضية
    try {
      final now = DateTime.now();
      if (categories.isEmpty &&
          _cacheCategories != null &&
          _cacheTime != null &&
          now.difference(_cacheTime!) <= _cacheDuration) {
        categories.assignAll(_cacheCategories!);
        itemCountByCatId.assignAll(_cacheItemCount ?? {});
        _reapplyFilter();
        return; // لا داعي للـ Request
      }
    } catch (_) {
      /* لو صار خطأ في الكاش تجاهله */
    }

    try {
      loading(true);

      /* ---------- 1) جلب الأقسام ---------- */
      final resCatsRaw = await _api.get(Env.categoriesList);
      final jCats = _safeDecode(resCatsRaw);

      List<CategoryModel> listCats = [];

      if (jCats != null) {
        if (jCats['status'] == 'success') {
          final data =
              (jCats['data'] ?? jCats['categories'] ?? jCats['items'] ?? [])
                  as List;
          listCats = data
              .map(
                (e) =>
                    CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
        } else if (jCats['ok'] == true) {
          final data =
              (jCats['data'] ?? jCats['categories'] ?? jCats['items'] ?? [])
                  as List;
          listCats = data
              .map(
                (e) =>
                    CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
        }
      } else if (resCatsRaw is Map && resCatsRaw['status'] == 'success') {
        listCats = (resCatsRaw['data'] as List)
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (resCatsRaw is List) {
        listCats = resCatsRaw
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      categories.assignAll(listCats);

      /* ---------- 2) جلب الأصناف لحساب عدد كل قسم ---------- */
      final resItemsRaw = await _api.get(Env.itemsList);
      final jItems = _safeDecode(resItemsRaw);

      List<ItemModel> listItems = [];

      if (jItems != null) {
        if (jItems['status'] == 'success') {
          final data =
              (jItems['data'] ?? jItems['items'] ?? jItems['list'] ?? [])
                  as List;
          listItems = data
              .map(
                (e) => ItemModel.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
        } else if (jItems['ok'] == true) {
          final data =
              (jItems['items'] ?? jItems['data'] ?? jItems['list'] ?? [])
                  as List;
          listItems = data
              .map(
                (e) => ItemModel.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
        }
      } else if (resItemsRaw is Map && resItemsRaw['status'] == 'success') {
        listItems = (resItemsRaw['data'] as List)
            .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (resItemsRaw is List) {
        listItems = resItemsRaw
            .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // ✅ Fallback: لو فشلنا في قراءة الأصناف من الـ API نستخدم ItemsController
      if (listItems.isEmpty && Get.isRegistered<ItemsController>()) {
        final ic = Get.find<ItemsController>();
        if (ic.items.isEmpty && ic.loading.isFalse) {
          await ic.fetchItems();
        }
        if (ic.items.isNotEmpty) {
          listItems = List<ItemModel>.from(ic.items);
        }
      }

      // بناء خريطة: category_id -> count
      final map = <int, int>{};
      for (final it in listItems) {
        final cid = it.categoryId;
        if (cid <= 0) continue;
        map[cid] = (map[cid] ?? 0) + 1;
      }
      itemCountByCatId.assignAll(map);

      // 🔹 3) حدّث كاش RAM بعد النجاح
      _cacheCategories = List<CategoryModel>.from(listCats);
      _cacheItemCount = Map<int, int>.from(map);
      _cacheTime = DateTime.now();

      // 🔹 4) خزّن نسخة في GetStorage (كاش دائم)
      _saveToPersistentCache();

      _reapplyFilter();
    } catch (e) {
      categories.clear();
      filtered.clear();
      itemCountByCatId.clear();
      Get.snackbar(
        'خطأ',
        'تعذر جلب الأقسام/الأصناف.',
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint('fetchAll error: $e');
    } finally {
      loading(false);
    }
  }

  /* =================== فلترة =================== */
  void _reapplyFilter() {
    final q = searchCtrl.text.trim();
    if (q.isEmpty) {
      filtered.assignAll(categories);
    } else {
      filtered.assignAll(categories.where((c) => c.name.contains(q)));
    }
  }

  /* =================== عدد أصناف القسم =================== */
  int countItemsInCategory(int categoryId) => itemCountByCatId[categoryId] ?? 0;

  /* =================== اختيار صورة =================== */
  Future<void> pickImageFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null) {
      imageFile = File(picked.path);
      imagePath.value = picked.path;
    }
  }

  /* =================== رفع صورة (إن وجدت) =================== */
  Future<String?> _uploadImageIfNeeded() async {
    if (imageFile == null) {
      return currentImageUrl.value.isNotEmpty
          ? _fixUrl(currentImageUrl.value)
          : null;
    }
    try {
      final res = await _api.uploadFile(
        Env.uploadImage, // upload_image.php
        filePath: imageFile!.path,
        fieldName: 'image',
      );

      final j = _safeDecode(res);
      if (j == null) {
        Get.snackbar(
          'خطأ',
          'الرد من السيرفر غير صالح (رفع الصورة).',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      final bool ok =
          (j['ok'] == true) || (j['status'] == 'success') || (j['code'] == 200);

      final dynamic url =
          j['url'] ??
          j['image_url'] ??
          (j['data'] is Map
              ? (j['data']['url'] ??
                    j['data']['image_url'] ??
                    j['data']['path'])
              : null) ??
          j['path'];

      if (ok && url != null && url.toString().trim().isNotEmpty) {
        return _fixUrl(url.toString());
      }

      Get.snackbar(
        'خطأ',
        j['message']?.toString() ?? 'فشل رفع الصورة',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل رفع الصورة.',
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint('upload error: $e');
      return null;
    }
  }

  /* =================== إضافة قسم =================== */
  Future<bool> saveNewCategory() async {
    if (!_ensureBranchSelected()) return false;
    if (nameCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'تنبيه',
        'أدخل اسم القسم',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    try {
      saving(true);
      final name = nameCtrl.text.trim();
      dynamic res;

      if (imageFile != null) {
        res = await _api.postMultipart(
          Env.categoryAdd,
          fields: {'name': name},
          filePath: imageFile!.path,
          fieldName: 'image',
        );
      } else {
        res = await _api.postForm(Env.categoryAdd, {'name': name});
      }

      // أولاً: حاول فك JSON
      final j = _safeDecode(res);

      // ثانياً: كشبكة أمان، إن تعذّر فك JSON لكن النص يوحي بالنجاح، اعتبرها نجحت
      final String raw = (res is String) ? res : res.toString();
      final bool looksSuccess =
          raw.contains('"status":"success"') ||
          raw.contains('"ok":true') ||
          raw.contains('"code":200');

      if (j != null && ((j['status'] == 'success') || (j['ok'] == true))) {
        if (j['data'] is Map<String, dynamic>) {
          final newCat = CategoryModel.fromJson(
            j['data'] as Map<String, dynamic>,
          );
          categories.insert(0, newCat);
        } else {
          await fetchAll();
        }

        // 🔹 حدّث كاش RAM + التخزين الدائم بعد إضافة قسم جديد
        _cacheCategories = List<CategoryModel>.from(categories);
        _cacheItemCount = Map<int, int>.from(itemCountByCatId);
        _cacheTime = DateTime.now();
        _saveToPersistentCache();

        resetForm();
        return true;
      } else if (j == null && looksSuccess) {
        // نجاح بدون JSON صالح: نحدّث القائمة من الخادم
        await fetchAll();
        resetForm();
        return true;
      }

      final msg = j?['message']?.toString() ?? 'تعذر معالجة رد الخادم';
      Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (e) {
      // لا نرمي رسالة مضلّلة: نتحقق إن كانت العملية نجحت رغم الاستثناء
      try {
        final msg = e.toString();
        if (msg.contains('status') && msg.contains('success')) {
          await fetchAll();
          resetForm();
          return true;
        }
      } catch (_) {}
      Get.snackbar(
        'خطأ',
        'فشل الاتصال بالخادم.',
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint('saveNewCategory error: $e');
      return false;
    } finally {
      saving(false);
    }
  }

  /* =================== تعديل قسم =================== */
  void editCategory(CategoryModel c) {
    nameCtrl.text = c.name;
    imagePath.value = '';
    imageFile = null;
    currentImageUrl.value = _fixUrl(c.image);

    showCategorySheet(title: 'تعديل قسم', onSubmit: () => updateCategory(c.id));
  }

  Future<bool> updateCategory(int id) async {
    if (!_ensureBranchSelected()) return false;
    if (nameCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'تنبيه',
        'أدخل اسم القسم',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    try {
      saving(true);

      String imgUrl = currentImageUrl.value;
      final uploaded = await _uploadImageIfNeeded();
      if (uploaded != null && uploaded.isNotEmpty) imgUrl = uploaded;

      final body = <String, String>{
        'id': '$id',
        'name': nameCtrl.text.trim(),
        if (imgUrl.isNotEmpty) 'image_url': imgUrl,
      };

      final res = await _api.postForm(Env.categoryUpdate, body);
      final j = _safeDecode(res);

      if (j != null && ((j['status'] == 'success') || (j['ok'] == true))) {
        if (j['data'] is Map<String, dynamic>) {
          final updated = CategoryModel.fromJson(
            j['data'] as Map<String, dynamic>,
          );
          final idx = categories.indexWhere((e) => e.id == updated.id);
          if (idx != -1) {
            categories[idx] = updated;
            categories.refresh();
          } else {
            await fetchAll();
          }
        } else {
          await fetchAll();
        }

        // 🔹 تحديث كاش RAM + التخزين الدائم بعد التعديل
        _cacheCategories = List<CategoryModel>.from(categories);
        _cacheItemCount = Map<int, int>.from(itemCountByCatId);
        _cacheTime = DateTime.now();
        _saveToPersistentCache();

        resetForm();
        return true;
      } else {
        final msg = j?['message']?.toString() ?? 'فشل التعديل';
        Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل الاتصال بالخادم.',
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint('updateCategory error: $e');
      return false;
    } finally {
      saving(false);
    }
  }

  /* =================== حذف قسم =================== */
  void confirmDeleteCategory(CategoryModel c) {
    Get.defaultDialog(
      title: 'تأكيد الحذف',
      middleText: 'هل تريد حذف "${c.name}" ؟',
      textConfirm: 'حذف',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        await _deleteCategory(c);
      },
    );
  }

  Future<void> _deleteCategory(CategoryModel c) async {
    try {
      if (!_ensureBranchSelected()) return;
      final res = await _api.postForm(Env.categoryDelete, {
        'id': c.id.toString(),
      });
      final j = _safeDecode(res);
      final ok =
          (j != null && ((j['status'] == 'success') || (j['ok'] == true))) ||
          (res is String && res.contains('"status":"success"'));

      if (ok) {
        categories.removeWhere((e) => e.id == c.id);
        filtered.removeWhere((e) => e.id == c.id);

        // 🔹 تحديث الكاش بعد الحذف
        _cacheCategories = List<CategoryModel>.from(categories);
        _cacheItemCount = Map<int, int>.from(itemCountByCatId);
        _cacheTime = DateTime.now();
        _saveToPersistentCache();

        Get.snackbar(
          'تم',
          'تم حذف ${c.name}',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        final msg =
            j?['message']?.toString() ?? (res?.toString() ?? 'فشل الحذف');
        Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر الاتصال بالخادم.',
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint('deleteCategory error: $e');
    }
  }

  /* =================== شيت الإضافة/التعديل =================== */
  void showAddCategorySheet() {
    resetForm();
    showCategorySheet(title: 'إضافة قسم جديد', onSubmit: saveNewCategory);
  }

  void showCategorySheet({
    required String title,
    required Future<bool> Function() onSubmit,
  }) {
    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F3F17),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: _fieldDecoration('اسم القسم'),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: pickImageFromGallery,
                  child: Obx(() {
                    Widget child;
                    if (imagePath.value.isNotEmpty && imageFile != null) {
                      child = Image.file(
                        imageFile!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    } else if (currentImageUrl.value.isNotEmpty) {
                      child = Image.network(
                        currentImageUrl.value,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    } else {
                      child = Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 36,
                            color: Color(0xFFB88969),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'اختر صورة من المعرض',
                            style: TextStyle(color: Color(0xFFB88969)),
                          ),
                        ],
                      );
                    }
                    return Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EFEA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      clipBehavior: Clip.antiAlias,
                      child: child,
                    );
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Obx(
                    () => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6F3F17),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: saving.value
                          ? null
                          : () async {
                              final ok = await onSubmit();
                              if (ok && Get.isOverlaysOpen) {
                                Get.back();
                              }
                            },
                      child: saving.value
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'حفظ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  /* =================== تنظيف =================== */
  void resetForm() {
    nameCtrl.clear();
    imagePath.value = '';
    imageFile = null;
    currentImageUrl.value = '';
  }
}

/* أدوات الحقول */
InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF2EFEA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(14),
    ),
  );
}
