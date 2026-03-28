import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../core/services/api_service.dart';
import '../core/config/env.dart';
import '../core/utils/snack_utils.dart';
import '../data/models/staff_model.dart';
import '../data/models/branch_model.dart';

class StaffController extends GetxController {
  final _api = ApiService();

  final loading = false.obs;
  final saving = false.obs;
  final loadingBranches = false.obs;

  final list = <StaffModel>[].obs;
  final filtered = <StaffModel>[].obs;

  final branches = <BranchModel>[].obs;

  final searchCtrl = TextEditingController();

  final nameCtrl = TextEditingController();
  final phoneTextCtrl = TextEditingController();
  final passTextCtrl = TextEditingController();

  final selectedRole = 'admin'.obs;
  final selectedBranchId = Rxn<int>();
  final active = true.obs;

  static List<StaffModel>? _cacheList;
  static DateTime? _cacheTime;
  static const Duration _ttl = Duration(seconds: 60);

  bool _isFresh(DateTime? t) =>
      t != null && DateTime.now().difference(t) < _ttl;

  static const String _boxName = 'admin_cache';
  static const String _keyStaff = 'staff_list';
  static const String _keyTime = 'staff_list_time';

  final GetStorage _box = GetStorage(_boxName);

  static const Map<String, List<String>> rolePermissions = {
    'owner': [
      'لوحة التحكم الكاملة',
      'إدارة جميع الفروع',
      'إدارة الطاقم والصلاحيات',
      'إدارة الأصناف والأقسام والعروض لكل الفروع',
      'إدارة الطلبات والمستخدمين والسائقين',
      'إعدادات النظام العامة',
    ],
    'admin': [
      'لوحة التحكم',
      'إدارة الأصناف/الأقسام/العروض',
      'إدارة الطلبات',
      'إدارة المستخدمين والسائقين',
      'إدارة الطاقم',
    ],
    'receiver': ['استقبال الطلبات', 'عرض وتتبع الطلبات', 'تحديث حالة الطلب'],
  };

  bool get roleNeedsBranch => selectedRole.value != 'owner';

  @override
  void onInit() {
    super.onInit();
    _loadPersistentCache();
    fetchBranches();
    fetchStaff();
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    nameCtrl.dispose();
    phoneTextCtrl.dispose();
    passTextCtrl.dispose();
    super.onClose();
  }

  void _loadPersistentCache() {
    try {
      final rawList = _box.read(_keyStaff);
      final rawTime = _box.read(_keyTime);
      if (rawList == null || rawTime == null) return;

      List listJson;

      if (rawList is String) {
        listJson = (jsonDecode(rawList) as List);
      } else if (rawList is List) {
        listJson = rawList;
      } else {
        return;
      }

      final listOut = listJson
          .map((e) => StaffModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      DateTime? t;
      if (rawTime is int) {
        t = DateTime.fromMillisecondsSinceEpoch(rawTime);
      } else if (rawTime is String) {
        t = DateTime.tryParse(rawTime);
      }

      list.assignAll(listOut);
      filtered.assignAll(listOut);

      _cacheList = listOut;
      _cacheTime = t;
    } catch (_) {}
  }

  void _savePersistentCache() {
    try {
      final data = list.map((e) => e.toJson()).toList();

      _box.write(_keyStaff, data);
      _box.write(
        _keyTime,
        _cacheTime?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  void _clearStaffCache() {
    _cacheList = null;
    _cacheTime = null;
    _box.remove(_keyStaff);
    _box.remove(_keyTime);
  }

  Future<void> fetchBranches() async {
    try {
      loadingBranches(true);

      final res = await _api.get(Env.branchesList);

      final raw = (res is Map && res['data'] is List)
          ? (res['data'] as List)
          : (res is List ? res : const <dynamic>[]);

      final items = raw
          .map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e)))
          .where((b) => b.isActive)
          .toList();

      branches.assignAll(items);

      if (selectedBranchId.value != null) {
        final exists = items.any(
          (element) => element.id == selectedBranchId.value,
        );
        if (!exists) {
          selectedBranchId.value = null;
        }
      }
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذر تحميل الفروع'));
    } finally {
      loadingBranches(false);
    }
  }

  String branchNameById(int? id) {
    if (id == null) return '-';
    try {
      final b = branches.firstWhere((e) => e.id == id);
      return b.name;
    } catch (_) {
      return 'فرع #$id';
    }
  }

  Future<void> fetchStaff({bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheList != null && _isFresh(_cacheTime)) {
      list.assignAll(_cacheList!);
      filtered.assignAll(_cacheList!);
      return;
    }

    try {
      loading(true);

      final res = await _api.get(Env.staffList);

      final raw = (res is Map && res['data'] is List)
          ? (res['data'] as List)
          : (res is List ? res : const <dynamic>[]);

      final items = raw
          .map((e) => StaffModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      list.assignAll(items);
      filtered.assignAll(items);

      _cacheList = List<StaffModel>.from(items);
      _cacheTime = DateTime.now();
      _savePersistentCache();
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذّر تحميل الطاقم'));
    } finally {
      loading(false);
    }
  }

  void onSearchChanged(String q) {
    q = q.trim();
    if (q.isEmpty) {
      filtered.assignAll(list);
      return;
    }

    filtered.assignAll(
      list.where(
        (s) =>
            s.name.contains(q) ||
            s.phone.contains(q) ||
            s.role.contains(q) ||
            s.id.toString() == q ||
            (s.branchId?.toString() == q) ||
            branchNameById(s.branchId).contains(q),
      ),
    );
  }

  void onRoleChanged(String role) {
    selectedRole.value = role;
    if (role == 'owner') {
      selectedBranchId.value = null;
    }
  }

  void resetForm() {
    nameCtrl.clear();
    phoneTextCtrl.clear();
    passTextCtrl.clear();
    selectedRole.value = 'admin';
    selectedBranchId.value = null;
    active.value = true;
  }

  Future<bool> addStaff() async {
    final name = nameCtrl.text.trim();
    final phone = phoneTextCtrl.text.trim();
    final pass = passTextCtrl.text.trim();
    final role = selectedRole.value;
    final branchId = selectedBranchId.value;

    if (name.isEmpty || phone.isEmpty || pass.isEmpty) {
      AppSnack.warning('املأ الاسم والهاتف وكلمة المرور');
      return false;
    }

    if (role != 'owner' && branchId == null) {
      AppSnack.warning('اختر الفرع لهذا المستخدم');
      return false;
    }

    try {
      saving(true);

      final res = await _api.postForm(Env.staffAdd, {
        'name': name,
        'phone': phone,
        'password': pass,
        'role': role,
        'is_active': active.value ? '1' : '0',
        if (branchId != null) 'branch_id': '$branchId',
      });

      final ok =
          (res is Map && (res['status'] == 'success' || res['ok'] == true));

      if (!ok) {
        final msg = res is Map
            ? (res['message'] ?? 'تعذّر إضافة العضو')
            : 'تعذّر إضافة العضو';
        AppSnack.error('$msg');
        return false;
      }

      _clearStaffCache();
      await fetchStaff(forceRefresh: true);
      resetForm();
      return true;
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذّر إضافة العضو'));
      return false;
    } finally {
      saving(false);
    }
  }

  Future<bool> deleteStaff(StaffModel s) async {
    try {
      final res = await _api.postForm(Env.staffDelete, {'id': '${s.id}'});
      final ok =
          (res is Map && (res['status'] == 'success' || res['ok'] == true));

      if (ok) {
        _clearStaffCache();
        await fetchStaff(forceRefresh: true);
        return true;
      } else {
        final msg = res is Map
            ? (res['message'] ?? 'تعذّر حذف العضو')
            : 'تعذّر حذف العضو';
        AppSnack.error('$msg');
        return false;
      }
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذّر الحذف'));
      return false;
    }
  }

  Future<bool> updateRole(StaffModel s, String newRole, {int? branchId}) async {
    try {
      final effectiveBranchId = newRole == 'owner' ? null : branchId;

      if (newRole != 'owner' && effectiveBranchId == null) {
        AppSnack.warning('اختر الفرع لهذا المستخدم');
        return false;
      }

      final res = await _api.postForm(Env.staffUpdateRole, {
        'id': '${s.id}',
        'role': newRole,
        'branch_id': effectiveBranchId != null ? '$effectiveBranchId' : '',
      });

      final ok =
          (res is Map && (res['status'] == 'success' || res['ok'] == true));

      if (ok) {
        _clearStaffCache();
        await fetchStaff(forceRefresh: true);
        return true;
      } else {
        final msg = res is Map
            ? (res['message'] ?? 'تعذّر تحديث الدور')
            : 'تعذّر تحديث الدور';
        AppSnack.error('$msg');
        return false;
      }
    } catch (e) {
      AppSnack.error(AppSnack.friendlyError(e, fallback: 'تعذّر التحديث'));
      return false;
    }
  }
}
