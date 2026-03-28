import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/api_service.dart';
import '../core/config/env.dart';
import '../data/models/offer_model.dart';
import 'admin_branch_scope_controller.dart';

class OffersController extends GetxController {
  final _api = ApiService();
  final _branchScope = Get.find<AdminBranchScopeController>();
  Worker? _branchWorker;

  // الحالة والبيانات
  final offers = <OfferModel>[].obs;
  final loading = false.obs;

  // ========= كاش داخل الذاكرة (Static Shared Cache) =========
  static final Map<int, List<OfferModel>> _cacheOffersByBranch = {};
  static final Map<int, DateTime> _cacheAtByBranch = {};
  static const Duration _cacheTtl = Duration(seconds: 20);

  // ========= كاش دائم SharedPreferences =========
  static const String _storageKey = 'cache_offers';
  static const String _storageTime = 'cache_offers_time';

  int? get _branchId => _branchScope.effectiveBranchId;
  String get _storageKeyScoped => '${_storageKey}_${_branchId ?? 0}';
  String get _storageTimeScoped => '${_storageTime}_${_branchId ?? 0}';

  void _clearBranchCache() {
    final bid = _branchId;
    if (bid != null) {
      _cacheOffersByBranch.remove(bid);
      _cacheAtByBranch.remove(bid);
    }
    offers.clear();
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

  bool get _hasValidCache {
    final bid = _branchId;
    if (bid == null) return false;
    final offers = _cacheOffersByBranch[bid];
    final at = _cacheAtByBranch[bid];
    if (offers == null || at == null) return false;
    final diff = DateTime.now().difference(at);
    return diff < _cacheTtl;
  }

  void _updateCacheFromList(List<OfferModel> list) async {
    if (!_ensureBranchSelected()) return;
    final bid = _branchId!;
    _cacheOffersByBranch[bid] = List<OfferModel>.from(list);
    _cacheAtByBranch[bid] = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
      _storageKeyScoped,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    prefs.setString(
      _storageTimeScoped,
      _cacheAtByBranch[bid]!.toIso8601String(),
    );
  }

  Future<void> _loadCacheFromStorage() async {
    if (!_ensureBranchSelected()) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKeyScoped);
    final timeStr = prefs.getString(_storageTimeScoped);

    if (raw == null || timeStr == null) return;

    if (!_ensureBranchSelected()) return;
    try {
      final t = DateTime.tryParse(timeStr);
      if (t == null) return;

      final diff = DateTime.now().difference(t);
      if (diff > _cacheTtl) return;

      final list = jsonDecode(raw) as List;
      final parsed = list
          .map((e) => OfferModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final bid = _branchId!;
      _cacheOffersByBranch[bid] = parsed;
      _cacheAtByBranch[bid] = t;

      offers.assignAll(parsed);
    } catch (_) {}
  }

  @override
  void onInit() {
    super.onInit();
    _loadCacheFromStorage().then((_) {
      fetchOffers();
    });
    _branchWorker = ever<int?>(_branchScope.selectedBranchId, (_) {
      _clearBranchCache();
      fetchOffers(force: true);
    });
  }

  @override
  void onClose() {
    _branchWorker?.dispose();
    super.onClose();
  }

  /* =================== Utils =================== */

  Map<String, dynamic>? _safeDecode(dynamic res) {
    try {
      if (res == null) return null;

      if (res is Map<String, dynamic>) return res;
      if (res is Map) return Map<String, dynamic>.from(res);

      try {
        final dynamic body = (res as dynamic).body;
        if (body is String) res = body;
      } catch (_) {}

      String s = res.toString().trim();
      if (s.isNotEmpty && s.codeUnitAt(0) == 0xFEFF) {
        s = s.substring(1);
      }

      final i = s.indexOf('{');
      final j = s.lastIndexOf('}');
      if (i != -1 && j != -1) s = s.substring(i, j + 1);

      dynamic obj = jsonDecode(s);
      if (obj is String) obj = jsonDecode(obj);

      if (obj is Map<String, dynamic>) return obj;
      if (obj is Map) return Map<String, dynamic>.from(obj);
    } catch (_) {}

    return null;
  }

  bool _looksSuccess(dynamic raw) {
    final s = raw?.toString() ?? '';
    return s.contains('"status":"success"') ||
        s.contains('"ok":true') ||
        s.contains('"code":200');
  }

  /* =================== جلب العروض =================== */
  Future<void> fetchOffers({bool force = false}) async {
    try {
      if (!force && _hasValidCache) {
        offers.assignAll(_cacheOffersByBranch[_branchId!]!);
        return;
      }

      loading(true);

      final data = await _api.get(
        Env.offersList,
        query: {'t': DateTime.now().millisecondsSinceEpoch.toString()},
      );

      List<OfferModel> list;
      if (data is List) {
        list = data
            .map(
              (e) => OfferModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      } else if (data is Map && data['data'] is List) {
        list = (data['data'] as List)
            .map(
              (e) => OfferModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      } else if (data is String) {
        final j = jsonDecode(data);
        if (j is List) {
          list = j
              .map(
                (e) => OfferModel.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
        } else if (j is Map && j['data'] is List) {
          list = (j['data'] as List)
              .map(
                (e) => OfferModel.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
        } else {
          list = <OfferModel>[];
        }
      } else {
        list = <OfferModel>[];
      }

      offers.assignAll(list);
      _updateCacheFromList(list);
    } catch (e) {
      offers.clear();
      Get.snackbar(
        'خطأ',
        'تعذر جلب العروض',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      loading(false);
    }
  }

  Future<void> refreshOffers() => fetchOffers(force: true);

  /* =================== إضافة/تعديل/حذف =================== */

  Future<void> addOffer({
    required String title,
    double? price,
    String? imagePath,
    String? imageUrl,
    String? description,
  }) async {
    if (!_ensureBranchSelected()) return;
    try {
      dynamic res;
      if ((imagePath ?? '').isNotEmpty) {
        res = await _api.postMultipart(
          Env.offerAdd,
          fields: {
            'title': title,
            if (price != null) 'price': '$price',
            if ((description ?? '').isNotEmpty) 'description': description!,
          },
          filePath: imagePath!,
          fieldName: 'image',
        );
      } else {
        res = await _api.postForm(Env.offerAdd, {
          'title': title,
          if (price != null) 'price': '$price',
          if ((imageUrl ?? '').isNotEmpty) 'image_url': imageUrl!,
          if ((description ?? '').isNotEmpty) 'description': description!,
        });
      }

      final j = _safeDecode(res);
      if ((j != null && ((j['ok'] == true) || (j['status'] == 'success'))) ||
          (j == null && _looksSuccess(res))) {
        await fetchOffers(force: true);
        Get.back();
        return;
      }

      final msg = j?['message']?.toString() ?? 'تعذر إضافة العرض';
      Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر إضافة العرض',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> updateOffer(OfferModel m, {String? imagePath}) async {
    if (!_ensureBranchSelected()) return;
    try {
      dynamic res;
      if ((imagePath ?? '').isNotEmpty) {
        res = await _api.postMultipart(
          Env.offerUpdate,
          fields: {
            'id': '${m.id}',
            'title': m.title,
            if (m.price != null) 'price': '${m.price}',
          },
          filePath: imagePath!,
          fieldName: 'image',
        );
      } else {
        res = await _api.postForm(Env.offerUpdate, {
          'id': '${m.id}',
          'title': m.title,
          'image_url': m.imageUrl,
          if (m.price != null) 'price': '${m.price}',
        });
      }

      final j = _safeDecode(res);
      if ((j != null && ((j['ok'] == true) || (j['status'] == 'success'))) ||
          (j == null && _looksSuccess(res))) {
        await fetchOffers(force: true);
        Get.back();
      } else {
        final msg = j?['message']?.toString() ?? 'تعذر تعديل العرض';
        Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر تعديل العرض',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteOffer(int id) async {
    if (!_ensureBranchSelected()) return;
    try {
      final res = await _api.postForm(Env.offerDelete, {'id': '$id'});
      final j = _safeDecode(res);

      final ok =
          (j != null && ((j['ok'] == true) || (j['status'] == 'success'))) ||
          _looksSuccess(res);

      if (ok) {
        offers.removeWhere((o) => o.id == id);

        final bid = _branchId;
        if (bid != null && _cacheOffersByBranch[bid] != null) {
          _cacheOffersByBranch[bid] = _cacheOffersByBranch[bid]!
              .where((o) => o.id != id)
              .toList(growable: false);
          _cacheAtByBranch[bid] = DateTime.now();
        }
      } else {
        final msg = j?['message']?.toString() ?? 'تعذر حذف العرض';
        Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر حذف العرض',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
