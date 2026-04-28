import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../core/config/env.dart';
import '../core/services/api_service.dart';
import '../data/models/category_model.dart';
import '../data/models/item_model.dart';
import 'admin_branch_scope_controller.dart';
import 'AuthController.dart';
import 'categories_controller.dart';

class ItemsController extends GetxController {
  final _api = ApiService();
  final _branchScope = Get.find<AdminBranchScopeController>();
  Worker? _branchWorker;
  int? _lastBranchId;

  static final Map<int, List<ItemModel>> _cacheItemsByBranch = {};
  static final Map<int, DateTime> _cacheItemsTimeByBranch = {};
  static const Duration _itemsCacheDuration = Duration(minutes: 2);

  static final Map<int, List<CategoryModel>> _cacheCategoriesByBranch = {};
  static final Map<int, DateTime> _cacheCategoriesTimeByBranch = {};
  static const Duration _catsCacheDuration = Duration(minutes: 5);

  final loading = false.obs;
  final saving = false.obs;

  final items = <ItemModel>[].obs;
  final filtered = <ItemModel>[].obs;

  final searchCtrl = TextEditingController();

  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final discountCtrl = TextEditingController();

  final categories = <CategoryModel>[].obs;
  final selectedCategoryId = Rxn<int>();

  final _picker = ImagePicker();
  File? imageFile;
  final imagePath = ''.obs;
  final currentImageUrl = ''.obs;

  int? get _branchId => _branchScope.effectiveBranchId;

  static Map<String, dynamic>? _safeDecode(dynamic res) {
    try {
      if (res == null) return null;
      if (res is Map<String, dynamic>) return res;

      try {
        final dynamic maybeBody = (res as dynamic).body;
        if (maybeBody is String) {
          res = maybeBody;
        }
      } catch (_) {}

      String s = res is String ? res : res.toString();
      s = s.trim();

      if (s.isNotEmpty && s.codeUnitAt(0) == 0xFEFF) {
        s = s.substring(1);
      }

      final start = s.indexOf('{');
      final end = s.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        s = s.substring(start, end + 1);
      }

      dynamic obj = jsonDecode(s);
      if (obj is String) {
        obj = jsonDecode(obj);
      }

      if (obj is Map<String, dynamic>) {
        return Map<String, dynamic>.from(obj);
      }
    } catch (_) {}
    return null;
  }

  bool _okFromMap(Map<String, dynamic> m) =>
      m['ok'] == true || m['status']?.toString() == 'success';

  bool _isSuccess(dynamic res) {
    final m = _safeDecode(res);
    if (m == null) return false;
    return _okFromMap(m);
  }

  // ignore: unused_element
  Map<String, dynamic>? _dataMap(dynamic res) {
    final m = _safeDecode(res);
    if (m == null) return null;

    if (m['data'] is Map) {
      return Map<String, dynamic>.from(m['data'] as Map);
    }
    if (m['item'] is Map) {
      return Map<String, dynamic>.from(m['item'] as Map);
    }
    return null;
  }

  String _err(dynamic res, String fallback) {
    final m = _safeDecode(res);
    if (m != null && m['message'] != null) {
      return m['message'].toString();
    }
    return fallback;
  }

  void invalidateCategoriesCache({bool clearSelection = false}) {
    final branchId = _branchId;
    if (branchId != null) {
      _cacheCategoriesByBranch.remove(branchId);
      _cacheCategoriesTimeByBranch.remove(branchId);
    }
    categories.clear();
    if (clearSelection) {
      selectedCategoryId.value = null;
    }
  }

  Future<void> refreshCategoriesAfterCategoryChange() async {
    invalidateCategoriesCache();
    await fetchCategories(force: true, silentIfNoBranch: true);
  }

  @override
  void onInit() {
    super.onInit();

    _branchWorker = ever<int?>(_branchScope.selectedBranchId, (branchId) async {
      if (branchId == null || branchId <= 0) return;
      if (_lastBranchId == branchId) return;
      _lastBranchId = branchId;
      _clearCurrentBranchUi();
      await fetchCategories(silentIfNoBranch: true);
      await fetchItems(silentIfNoBranch: true);
    });

    ever<List<ItemModel>>(items, (_) => _applyFilter());
    searchCtrl.addListener(_applyFilter);

    Future.microtask(() async {
      await fetchCategories(silentIfNoBranch: true);
      await fetchItems(silentIfNoBranch: true);
    });
  }

  @override
  void onClose() {
    _branchWorker?.dispose();
    searchCtrl.dispose();
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    discountCtrl.dispose();
    super.onClose();
  }

  Future<void> refreshLive({bool refreshCategoriesToo = false}) async {
    final branchId = _branchId;
    if (branchId != null) {
      _cacheItemsByBranch.remove(branchId);
      _cacheItemsTimeByBranch.remove(branchId);
      if (refreshCategoriesToo) {
        _cacheCategoriesByBranch.remove(branchId);
        _cacheCategoriesTimeByBranch.remove(branchId);
      }
    }
    await fetchItems(force: true, silentIfNoBranch: true);
    if (refreshCategoriesToo) {
      await fetchCategories(force: true, silentIfNoBranch: true);
    }
    items.refresh();
    filtered.refresh();

    if (Get.isRegistered<CategoriesController>()) {
      try {
        await Get.find<CategoriesController>().refreshLive();
      } catch (_) {}
    }
  }

  void _clearCurrentBranchUi() {
    items.clear();
    filtered.clear();
    categories.clear();
    selectedCategoryId.value = null;
    searchCtrl.clear();
    imageFile = null;
    imagePath.value = '';
    currentImageUrl.value = '';
  }

  bool _ensureBranchSelected() {
    if (_branchId != null && _branchId! > 0) return true;
    Get.snackbar(
      'تنبيه',
      'اختر الفرع أولاً',
      snackPosition: SnackPosition.BOTTOM,
    );
    return false;
  }

  Future<void> fetchCategories({
    bool force = false,
    bool silentIfNoBranch = false,
  }) async {
    final branchId = _branchId;
    if (branchId == null || branchId <= 0) {
      categories.clear();
      if (!silentIfNoBranch) {
        Get.snackbar(
          'تنبيه',
          'اختر الفرع أولاً',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }

    final cached = _cacheCategoriesByBranch[branchId];
    final cachedTime = _cacheCategoriesTimeByBranch[branchId];

    if (!force &&
        cached != null &&
        cachedTime != null &&
        DateTime.now().difference(cachedTime) <= _catsCacheDuration) {
      categories.assignAll(cached);
      return;
    }

    try {
      final res = await _api.get(
        Env.categoriesList,
        query: {'t': DateTime.now().millisecondsSinceEpoch.toString()},
      );

      List raw;
      if (res is Map && res['data'] is List) {
        raw = res['data'] as List;
      } else if (res is List) {
        raw = res;
      } else if (res is String) {
        final j = jsonDecode(res);
        raw = (j is Map && j['data'] is List)
            ? j['data']
            : (j is List ? j : []);
      } else {
        raw = const [];
      }

      final list = raw
          .map(
            (e) => CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      categories.assignAll(list);
      _cacheCategoriesByBranch[branchId] = List<CategoryModel>.from(list);
      _cacheCategoriesTimeByBranch[branchId] = DateTime.now();
    } catch (e) {
      categories.clear();
      Get.snackbar(
        'خطأ',
        'تعذر جلب الأقسام: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> fetchItems({
    bool force = false,
    bool silentIfNoBranch = false,
  }) async {
    final branchId = _branchId;
    if (branchId == null || branchId <= 0) {
      items.clear();
      filtered.clear();
      if (!silentIfNoBranch) {
        Get.snackbar(
          'تنبيه',
          'اختر الفرع أولاً',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }

    final cached = _cacheItemsByBranch[branchId];
    final cachedTime = _cacheItemsTimeByBranch[branchId];

    if (!force &&
        cached != null &&
        cachedTime != null &&
        DateTime.now().difference(cachedTime) <= _itemsCacheDuration) {
      items.assignAll(cached);
      filtered.assignAll(cached);
      return;
    }

    try {
      loading(true);

      final res = await _api.get(
        Env.itemsSimpleList,
        query: {'t': DateTime.now().millisecondsSinceEpoch.toString()},
      );

      List raw;
      if (res is List) {
        raw = res;
      } else if (res is Map && res['items'] is List) {
        raw = res['items'] as List;
      } else if (res is Map && res['data'] is List) {
        raw = res['data'] as List;
      } else if (res is String) {
        final j = jsonDecode(res);
        if (j is List) {
          raw = j;
        } else if (j is Map && j['items'] is List) {
          raw = j['items'] as List;
        } else if (j is Map && j['data'] is List) {
          raw = j['data'] as List;
        } else {
          raw = const [];
        }
      } else {
        raw = const [];
      }

      final parsed = raw
          .map((e) => ItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((e) => e.branchId != null && e.branchId == branchId)
          .toList();

      items.assignAll(parsed);
      filtered.assignAll(parsed);

      _cacheItemsByBranch[branchId] = List<ItemModel>.from(parsed);
      _cacheItemsTimeByBranch[branchId] = DateTime.now();
    } catch (e) {
      items.clear();
      filtered.clear();
      Get.snackbar(
        'خطأ',
        'تعذر جلب الأصناف: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      loading(false);
    }
  }

  void _applyFilter() {
    final q = searchCtrl.text.trim();
    if (q.isEmpty) {
      filtered.assignAll(items);
      return;
    }

    filtered.assignAll(
      items.where((it) => it.name.contains(q) || it.description.contains(q)),
    );
  }

  void onSearchChanged(String _) => _applyFilter();

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

  Future<bool> saveNewItem() async {
    if (!_ensureBranchSelected()) return false;

    if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'تنبيه',
        'أدخل الاسم والسعر',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (selectedCategoryId.value == null) {
      Get.snackbar('تنبيه', 'اختر قسمًا', snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    try {
      saving(true);

      final fields = <String, String>{
        'name': nameCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'price': priceCtrl.text.trim(),
        'discount': discountCtrl.text.trim(),
        'category_id': selectedCategoryId.value.toString(),
      };

      dynamic res;
      if (imageFile != null) {
        res = await _postMultipart(
          url: Env.itemAdd,
          fields: fields,
          image: imageFile!,
        );
      } else {
        res = await _api.postForm(Env.itemAdd, fields);
      }

      final decoded = _safeDecode(res) ?? <String, dynamic>{};

      if (_okFromMap(decoded)) {
        await refreshLive(refreshCategoriesToo: true);
        resetForm();
        return true;
      }

      Get.snackbar(
        'خطأ',
        _err(decoded, 'فشل الحفظ'),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل الاتصال: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      saving(false);
    }
  }

  Future<bool> updateItem(int id) async {
    if (!_ensureBranchSelected()) return false;

    if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'تنبيه',
        'أدخل الاسم والسعر',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      saving(true);

      final fields = <String, String>{
        'id': id.toString(),
        'name': nameCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'price': priceCtrl.text.trim(),
        'discount': discountCtrl.text.trim(),
        'category_id': selectedCategoryId.value?.toString() ?? '',
        if (imageFile == null && currentImageUrl.value.isNotEmpty)
          'image_url': currentImageUrl.value,
      };

      dynamic res;
      if (imageFile != null) {
        res = await _postMultipart(
          url: Env.itemUpdate,
          fields: fields,
          image: imageFile!,
        );
      } else {
        res = await _api.postForm(Env.itemUpdate, fields);
      }

      final decoded = _safeDecode(res) ?? <String, dynamic>{};

      if (_okFromMap(decoded)) {
        await refreshLive(refreshCategoriesToo: true);
        resetForm();
        return true;
      }

      Get.snackbar(
        'خطأ',
        _err(decoded, 'فشل التعديل'),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل الاتصال: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      saving(false);
    }
  }

  Future<void> deleteItem(ItemModel it) async {
    if (!_ensureBranchSelected()) return;

    try {
      final res = await _api.postForm(Env.itemDelete, {'id': it.id.toString()});

      if (_isSuccess(res)) {
        await refreshLive(refreshCategoriesToo: true);
        Get.snackbar(
          'تم',
          'تم حذف ${it.name}',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'خطأ',
          _err(res, 'فشل الحذف'),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر الاتصال: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void confirmDelete(ItemModel it) {
    Get.defaultDialog(
      title: 'تأكيد الحذف',
      middleText: 'هل تريد حذف "${it.name}" ؟',
      textConfirm: 'حذف',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        await deleteItem(it);
      },
    );
  }

  Future<Map<String, dynamic>> _postMultipart({
    required String url,
    required Map<String, String> fields,
    required File image,
  }) async {
    final branchId = _branchId;
    final uri = Uri.parse(url);
    final req = http.MultipartRequest('POST', uri);

    final cleanFields = <String, String>{...fields};
    cleanFields.removeWhere((k, v) => v.trim().isEmpty);
    req.fields.addAll(cleanFields);

    if (branchId != null && branchId > 0) {
      req.fields['branch_id'] = branchId.toString();
      req.headers['X-Branch-Id'] = branchId.toString();
    }

    try {
      if (Get.isRegistered<AuthController>()) {
        final token = Get.find<AuthController>().token;
        if (token != null && token.isNotEmpty) {
          req.headers['Authorization'] = 'Bearer $token';
          req.fields['token'] = token;
        }
      }
    } catch (_) {}

    req.headers['Accept'] = 'application/json';
    req.files.add(await http.MultipartFile.fromPath('image', image.path));

    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final resp = await http.Response.fromStream(streamed);

    final m = _safeDecode(resp.body);
    if (m != null) return m;
    return {
      'ok': false,
      'status': 'error',
      'code': resp.statusCode,
      'message': resp.body,
    };
  }

  void prepareEdit(ItemModel it) {
    nameCtrl.text = it.name;
    descCtrl.text = it.description;
    priceCtrl.text = it.price.toString();
    discountCtrl.clear();
    selectedCategoryId.value = it.categoryId;
    imageFile = null;
    imagePath.value = '';
    currentImageUrl.value = it.imageUrl;
  }

  void resetForm() {
    nameCtrl.clear();
    descCtrl.clear();
    priceCtrl.clear();
    discountCtrl.clear();
    selectedCategoryId.value = null;
    imageFile = null;
    imagePath.value = '';
    currentImageUrl.value = '';
  }

  void viewItem(ItemModel it) {
    Get.snackbar('معاينة', it.name, snackPosition: SnackPosition.BOTTOM);
  }
}
