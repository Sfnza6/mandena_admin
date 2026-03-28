import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../core/config/env.dart';
import '../data/models/branch_model.dart';
import 'AuthController.dart';

class AdminBranchScopeController extends GetxController {
  static const _kSelectedBranchId = 'selected_manage_branch_id';

  final _auth = Get.find<AuthController>();
  final _box = GetStorage('admin_cache');
  final _client = http.Client();

  final branches = <BranchModel>[].obs;
  final loading = false.obs;
  final selectedBranchId = Rxn<int>();

  bool get isOwner => _auth.isOwner;
  bool get canChooseBranch => _auth.isOwner;
  int? get fixedBranchId => _auth.scopedBranchId;
  int? get effectiveBranchId => fixedBranchId ?? selectedBranchId.value;

  String get currentBranchLabel {
    final id = effectiveBranchId;
    if (id == null) return 'اختر الفرع';
    try {
      return branches.firstWhere((e) => e.id == id).name;
    } catch (_) {
      if (fixedBranchId != null) return 'الفرع #$id';
      return 'اختر الفرع';
    }
  }

  @override
  void onInit() {
    super.onInit();
    _syncFromAuth();
    ever(_auth.admin, (_) => _syncFromAuth());
  }

  Future<void> _syncFromAuth() async {
    if (!_auth.isLoggedIn) {
      branches.clear();
      selectedBranchId.value = null;
      return;
    }

    if (fixedBranchId != null) {
      selectedBranchId.value = fixedBranchId;
      await fetchBranches(silent: true);
      return;
    }

    await fetchBranches(silent: true);

    if (selectedBranchId.value != null &&
        branches.any((e) => e.id == selectedBranchId.value)) {
      return;
    }

    final saved = _box.read(_kSelectedBranchId);
    final savedId = saved is int ? saved : int.tryParse('${saved ?? ''}');
    if (savedId != null && branches.any((e) => e.id == savedId)) {
      selectedBranchId.value = savedId;
      return;
    }

    try {
      final fallback = branches.firstWhere((e) => e.isDefault);
      selectedBranchId.value = fallback.id;
    } catch (_) {
      if (branches.isNotEmpty) {
        selectedBranchId.value = branches.first.id;
      }
    }

    if (selectedBranchId.value != null) {
      await _box.write(_kSelectedBranchId, selectedBranchId.value);
    }
  }

  Future<void> fetchBranches({bool silent = false}) async {
    try {
      if (!silent) loading(true);
      final uri = Uri.parse(Env.url(Env.branchesList));
      final res = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final j = jsonDecode(res.body);
      List raw = const [];
      if (j is List) {
        raw = j;
      } else if (j is Map && j['data'] is List) {
        raw = j['data'] as List;
      }
      branches.assignAll(
        raw
            .map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.isActive)
            .toList(),
      );
    } catch (e) {
      debugPrint('fetchBranches(scope) error: $e');
    } finally {
      if (!silent) loading(false);
    }
  }

  Future<void> selectBranch(int? id) async {
    if (fixedBranchId != null || id == null || id <= 0) return;
    if (selectedBranchId.value == id) return;
    selectedBranchId.value = id;
    await _box.write(_kSelectedBranchId, id);
  }
}
