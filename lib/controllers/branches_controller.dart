import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/config/env.dart';
import '../core/routes/app_routes.dart';
import '../core/services/api_service.dart';
import '../core/utils/snack_utils.dart';
import '../data/models/branch_model.dart';

class BranchesController extends GetxController {
  final _api = ApiService();

  final loading = false.obs;
  final saving = false.obs;
  final branches = <BranchModel>[].obs;

  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();

  final isActive = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBranches();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    super.onClose();
  }

  void resetForm() {
    nameCtrl.clear();
    addressCtrl.clear();
    latCtrl.clear();
    lngCtrl.clear();
    isActive.value = true;
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

  Future<void> pickLocation({
    TextEditingController? latController,
    TextEditingController? lngController,
    TextEditingController? addressController,
  }) async {
    final latC = latController ?? latCtrl;
    final lngC = lngController ?? lngCtrl;
    final addressC = addressController ?? addressCtrl;

    final result = await Get.toNamed(
      Routes.branchMapPicker,
      arguments: {
        if (_nullableDouble(latC.text) != null)
          'lat': _nullableDouble(latC.text),
        if (_nullableDouble(lngC.text) != null)
          'lng': _nullableDouble(lngC.text),
        'address_text': addressC.text.trim(),
      },
    );

    if (result is Map) {
      final lat = result['lat'];
      final lng = result['lng'];
      final address = (result['address_text'] ?? '').toString();

      if (lat != null) latC.text = lat.toString();
      if (lng != null) lngC.text = lng.toString();
      if (address.isNotEmpty) addressC.text = address;
    }
  }

  Future<bool> addBranch() async {
    final name = nameCtrl.text.trim();
    final address = addressCtrl.text.trim();
    final lat = _nullableDouble(latCtrl.text);
    final lng = _nullableDouble(lngCtrl.text);

    if (name.isEmpty) {
      AppSnack.warning('أدخل اسم الفرع');
      return false;
    }

    if (lat == null || lng == null) {
      AppSnack.warning('اختر موقع الفرع من الخريطة');
      return false;
    }

    try {
      saving(true);

      final res = await _api.postForm(Env.branchAdd, {
        'name': name,
        'address_text': address,
        'lat': lat.toString(),
        'lng': lng.toString(),
        'is_active': isActive.value ? '1' : '0',
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
    required String name,
    required String addressText,
    required String latText,
    required String lngText,
    required bool isActiveValue,
  }) async {
    if (name.trim().isEmpty) {
      AppSnack.warning('اسم الفرع مطلوب');
      return false;
    }

    final lat = _nullableDouble(latText);
    final lng = _nullableDouble(lngText);

    if (lat == null || lng == null) {
      AppSnack.warning('اختر موقع الفرع من الخريطة');
      return false;
    }

    try {
      final res = await _api.postForm(Env.branchUpdate, {
        'id': '${b.id}',
        'name': name.trim(),
        'address_text': addressText.trim(),
        'lat': lat.toString(),
        'lng': lng.toString(),
        'is_active': isActiveValue ? '1' : '0',
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
          name: name.trim(),
          addressText: addressText.trim(),
          lat: lat,
          lng: lng,
          isActive: isActiveValue,
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
    if (b.isDefault) {
      AppSnack.warning('لا يمكنك حذف الفرع الرئيسي أو الافتراضي');
      return false;
    }

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
      AppSnack.success('تم حذف الفرع');
      return true;
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذر حذف الفرع'));
      return false;
    }
  }
}
