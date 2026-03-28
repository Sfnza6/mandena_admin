import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/config/env.dart';
import '../core/services/api_service.dart';
import '../core/utils/snack_utils.dart';
import '../data/models/branch_model.dart';

class BranchesController extends GetxController {
  final _api = ApiService();

  final loading = false.obs;
  final saving = false.obs;
  final branches = <BranchModel>[].obs;

  final codeCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();
  final pricePerKmCtrl = TextEditingController();
  final maxDeliveryKmCtrl = TextEditingController();

  final supportsDelivery = true.obs;
  final supportsPickup = true.obs;
  final isActive = true.obs;
  final isDefault = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBranches();
  }

  @override
  void onClose() {
    codeCtrl.dispose();
    nameCtrl.dispose();
    addressCtrl.dispose();
    phoneCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    pricePerKmCtrl.dispose();
    maxDeliveryKmCtrl.dispose();
    super.onClose();
  }

  void resetForm() {
    codeCtrl.clear();
    nameCtrl.clear();
    addressCtrl.clear();
    phoneCtrl.clear();
    latCtrl.clear();
    lngCtrl.clear();
    pricePerKmCtrl.clear();
    maxDeliveryKmCtrl.clear();

    supportsDelivery.value = true;
    supportsPickup.value = true;
    isActive.value = true;
    isDefault.value = false;
  }

  Future<void> fetchBranches() async {
    try {
      loading(true);

      final res = await _api.get(Env.branchesList);

      final raw = (res is Map && res['data'] is List)
          ? (res['data'] as List)
          : (res is List ? res : const <dynamic>[]);

      branches.assignAll(
        raw.map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e))),
      );
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذر تحميل الفروع'));
    } finally {
      loading(false);
    }
  }

  double? _nullableDouble(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    return double.tryParse(v);
  }

  double _doubleOrZero(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  Future<bool> addBranch() async {
    final code = codeCtrl.text.trim();
    final name = nameCtrl.text.trim();
    final address = addressCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    if (code.isEmpty || name.isEmpty) {
      AppSnack.warning('أدخل رمز الفرع واسم الفرع');
      return false;
    }

    final lat = _nullableDouble(latCtrl.text);
    final lng = _nullableDouble(lngCtrl.text);
    final pricePerKm = _doubleOrZero(pricePerKmCtrl.text);
    final maxDeliveryKm = _doubleOrZero(maxDeliveryKmCtrl.text);

    if (latCtrl.text.trim().isNotEmpty && lat == null) {
      AppSnack.warning('قيمة lat غير صحيحة');
      return false;
    }

    if (lngCtrl.text.trim().isNotEmpty && lng == null) {
      AppSnack.warning('قيمة lng غير صحيحة');
      return false;
    }

    try {
      saving(true);

      final res = await _api.postForm(Env.branchAdd, {
        'code': code,
        'name': name,
        'address_text': address,
        'phone': phone,
        'lat': lat?.toString() ?? '',
        'lng': lng?.toString() ?? '',
        'price_per_km': pricePerKm.toString(),
        'max_delivery_km': maxDeliveryKm.toString(),
        'supports_delivery': supportsDelivery.value ? '1' : '0',
        'supports_pickup': supportsPickup.value ? '1' : '0',
        'is_active': isActive.value ? '1' : '0',
        'is_default': isDefault.value ? '1' : '0',
      });

      final ok =
          (res is Map && (res['status'] == 'success' || res['ok'] == true));

      if (!ok) {
        final msg = res is Map
            ? (res['message'] ?? 'تعذر إضافة الفرع')
            : 'تعذر إضافة الفرع';
        AppSnack.error('$msg');
        return false;
      }

      await fetchBranches();
      resetForm();
      return true;
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذر إضافة الفرع'));
      return false;
    } finally {
      saving(false);
    }
  }

  Future<bool> updateBranch(
    BranchModel b, {
    required String code,
    required String name,
    required String addressText,
    required String phone,
    required String latText,
    required String lngText,
    required String pricePerKmText,
    required String maxDeliveryKmText,
    required bool supportsDeliveryValue,
    required bool supportsPickupValue,
    required bool isActiveValue,
    required bool isDefaultValue,
  }) async {
    if (code.trim().isEmpty || name.trim().isEmpty) {
      AppSnack.warning('رمز الفرع واسم الفرع مطلوبان');
      return false;
    }

    final lat = _nullableDouble(latText);
    final lng = _nullableDouble(lngText);

    if (latText.trim().isNotEmpty && lat == null) {
      AppSnack.warning('قيمة lat غير صحيحة');
      return false;
    }

    if (lngText.trim().isNotEmpty && lng == null) {
      AppSnack.warning('قيمة lng غير صحيحة');
      return false;
    }

    final pricePerKm = _doubleOrZero(pricePerKmText);
    final maxDeliveryKm = _doubleOrZero(maxDeliveryKmText);

    try {
      final res = await _api.postForm(Env.branchUpdate, {
        'id': '${b.id}',
        'code': code.trim(),
        'name': name.trim(),
        'address_text': addressText.trim(),
        'phone': phone.trim(),
        'lat': lat?.toString() ?? '',
        'lng': lng?.toString() ?? '',
        'price_per_km': pricePerKm.toString(),
        'max_delivery_km': maxDeliveryKm.toString(),
        'supports_delivery': supportsDeliveryValue ? '1' : '0',
        'supports_pickup': supportsPickupValue ? '1' : '0',
        'is_active': isActiveValue ? '1' : '0',
        'is_default': isDefaultValue ? '1' : '0',
      });

      final ok =
          (res is Map && (res['status'] == 'success' || res['ok'] == true));

      if (!ok) {
        final msg = res is Map
            ? (res['message'] ?? 'تعذر تحديث الفرع')
            : 'تعذر تحديث الفرع';
        AppSnack.error('$msg');
        return false;
      }

      final idx = branches.indexWhere((e) => e.id == b.id);
      if (idx != -1) {
        branches[idx] = b.copyWith(
          code: code.trim(),
          name: name.trim(),
          addressText: addressText.trim(),
          phone: phone.trim(),
          lat: lat,
          lng: lng,
          pricePerKm: pricePerKm,
          maxDeliveryKm: maxDeliveryKm,
          supportsDelivery: supportsDeliveryValue,
          supportsPickup: supportsPickupValue,
          isActive: isActiveValue,
          isDefault: isDefaultValue,
        );
        branches.refresh();
      }

      return true;
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذر تحديث الفرع'));
      return false;
    }
  }

  Future<bool> deleteBranch(BranchModel b) async {
    try {
      final res = await _api.postForm(Env.branchDelete, {'id': '${b.id}'});

      final ok =
          (res is Map && (res['status'] == 'success' || res['ok'] == true));

      if (!ok) {
        final msg = res is Map
            ? (res['message'] ?? 'تعذر حذف الفرع')
            : 'تعذر حذف الفرع';
        AppSnack.error('$msg');
        return false;
      }

      branches.removeWhere((e) => e.id == b.id);
      return true;
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذر حذف الفرع'));
      return false;
    }
  }
}
