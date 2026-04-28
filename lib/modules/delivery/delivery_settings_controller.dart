import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/services/api_service.dart';
import '../../core/config/env.dart';
import '../../controllers/admin_branch_scope_controller.dart';
import '../../data/models/branch_model.dart';

class DeliverySettingsController extends GetxController {
  final _api = ApiService();
  final _branchScope = Get.find<AdminBranchScopeController>();
  final _box = GetStorage('delivery_settings_box');

  final priceCtrl = TextEditingController();
  final maxDistanceCtrl = TextEditingController();

  final freeMode = false.obs;
  final loading = false.obs;
  final saving = false.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;

  Worker? _branchWorker;

  List<BranchModel> get branches => _branchScope.branches;
  bool get canChooseBranch => _branchScope.canChooseBranch;
  int? get selectedBranchId => _branchScope.effectiveBranchId;
  String get selectedBranchName => _branchScope.currentBranchLabel;

  int? get _branchId {
    final id = _branchScope.effectiveBranchId;
    if (id != null && id > 0) return id;
    return null;
  }

  String get _cacheKey => 'delivery_config_branch_${_branchId ?? 0}';

  @override
  void onInit() {
    super.onInit();

    _loadFromCache();

    final current = _branchId;
    if (current != null && current > 0) {
      Future.microtask(_loadConfig);
    }

    _branchWorker = ever<int?>(_branchScope.selectedBranchId, (branchId) async {
      if (branchId == null || branchId <= 0) return;
      errorMessage.value = '';
      successMessage.value = '';
      _loadFromCache();
      await _loadConfig();
      update();
    });
  }

  @override
  void onClose() {
    _branchWorker?.dispose();
    priceCtrl.dispose();
    maxDistanceCtrl.dispose();
    super.onClose();
  }

  Future<void> changeBranch(int? branchId) async {
    if (branchId == null || branchId <= 0) return;
    await _branchScope.selectBranch(branchId);
    update();
  }

  void _loadFromCache() {
    try {
      final cached = _box.read(_cacheKey);
      if (cached is Map) {
        final price = (cached['price_per_km'] ?? 1.5).toString();
        final maxDistance = (cached['max_delivery_km'] ?? 30.0).toString();
        final free = cached['free_mode'] == true || cached['free_mode'] == 1;

        priceCtrl.text = price;
        maxDistanceCtrl.text = maxDistance;
        freeMode.value = free;
      }
    } catch (_) {}
  }

  void _saveToCache({
    required double pricePerKm,
    required double maxDeliveryKm,
    required bool free,
  }) {
    _box.write(_cacheKey, {
      'price_per_km': pricePerKm,
      'max_delivery_km': maxDeliveryKm,
      'free_mode': free ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _loadConfig() async {
    final branchId = _branchId;
    if (branchId == null || branchId <= 0) {
      errorMessage.value = 'اختر الفرع أولاً';
      return;
    }

    loading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    update();

    try {
      final res = await _api.get(
        '${Env.base}/admin/delivery/get_config.php',
        query: {'branch_id': '$branchId'},
      );

      final data = (res is String) ? jsonDecode(res) : res;

      if (data is Map && data['ok'] == true) {
        final priceVal = data['price_per_km'] ?? 1.5;
        final maxVal = data['max_delivery_km'] ?? 30.0;
        final free = (data['free_mode'] == 1 || data['free_mode'] == true);

        priceCtrl.text = '$priceVal';
        maxDistanceCtrl.text = '$maxVal';
        freeMode.value = free;

        _saveToCache(
          pricePerKm: priceVal is num
              ? priceVal.toDouble()
              : (double.tryParse('$priceVal') ?? 1.5),
          maxDeliveryKm: maxVal is num
              ? maxVal.toDouble()
              : (double.tryParse('$maxVal') ?? 30.0),
          free: free,
        );
      } else {
        errorMessage.value = data is Map
            ? data['message']?.toString() ?? 'فشل في جلب الإعدادات'
            : 'فشل في جلب الإعدادات';
      }
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء جلب الإعدادات: $e';
    } finally {
      loading.value = false;
      update();
    }
  }

  Future<void> save() async {
    final branchId = _branchId;
    if (branchId == null || branchId <= 0) {
      Get.snackbar(
        'تنبيه',
        'اختر الفرع أولاً',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final priceTxt = priceCtrl.text.trim().replaceAll(',', '.');
    final maxTxt = maxDistanceCtrl.text.trim().replaceAll(',', '.');

    if (priceTxt.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى إدخال سعر الكيلومتر',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (maxTxt.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى إدخال أقصى مسافة للتوصيل',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final price = double.tryParse(priceTxt) ?? -1;
    final maxDistance = double.tryParse(maxTxt) ?? -1;

    if (price < 0) {
      Get.snackbar(
        'تنبيه',
        'قيمة سعر الكيلومتر غير صحيحة',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (maxDistance < 0) {
      Get.snackbar(
        'تنبيه',
        'قيمة أقصى مسافة غير صحيحة',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    saving.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    update();

    try {
      final res = await _api.post(
        '${Env.base}/admin/delivery/save_config.php',
        body: {
          'branch_id': '$branchId',
          'price_per_km': price.toString(),
          'max_delivery_km': maxDistance.toString(),
          'free_mode': freeMode.value ? '1' : '0',
        },
      );

      final data = (res is String) ? jsonDecode(res) : res;

      if (data is Map && data['ok'] == true) {
        successMessage.value =
            data['message']?.toString() ?? 'تم حفظ إعدادات التوصيل بنجاح';
        _saveToCache(
          pricePerKm: price,
          maxDeliveryKm: maxDistance,
          free: freeMode.value,
        );
        Get.snackbar(
          'تم الحفظ',
          successMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
        );
      } else {
        final msg = data is Map
            ? data['message']?.toString() ?? 'تعذّر حفظ الإعدادات'
            : 'تعذّر حفظ الإعدادات';
        errorMessage.value = msg;
        Get.snackbar(
          'خطأ',
          msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء الحفظ: $e';
      Get.snackbar(
        'خطأ',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      saving.value = false;
      update();
    }
  }

  Future<void> reload() => _loadConfig();
}
