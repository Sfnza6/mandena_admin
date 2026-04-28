import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mandena_admin/data/models/dashboard_stats.dart';
import '../core/services/api_service.dart';
import '../core/config/env.dart';
import 'admin_branch_scope_controller.dart';

class DashboardController extends GetxController {
  final _api = ApiService();
  final _branchScope = Get.find<AdminBranchScopeController>();
  Worker? _branchWorker;

  // =================== 🔹 Cache ثابت للداشبورد (RAM) 🔹 ===================

  static final Map<int, DashboardStats> _cacheStatsByBranch = {};
  static final Map<int, DateTime> _cacheStatsTimeByBranch = {};
  static const Duration _statsCacheDuration = Duration(seconds: 60);

  static final Map<String, List<(int, String, String, String, String)>>
  _cacheMostOrdered = {};
  static final Map<String, DateTime> _cacheMostOrderedTime = {};
  static const Duration _mostCacheDuration = Duration(seconds: 60);

  // =================== 🔹 Cache دائم (GetStorage) 🔹 ===================

  static const String _boxName = 'admin_cache';
  static const String _kStatsKey = 'dashboard_stats';
  static const String _kStatsTimeKey = 'dashboard_stats_time';
  static const String _kMostKey = 'dashboard_most_ordered';
  static const String _kMostTimeKey = 'dashboard_most_ordered_time';

  final GetStorage _box = GetStorage(_boxName);

  int get _branchCacheId => _branchScope.effectiveBranchId ?? 0;

  int? get _branchId {
    final id = _branchScope.effectiveBranchId;
    if (id != null && id > 0) return id;
    return null;
  }

  DashboardStats? get _cacheStats => _cacheStatsByBranch[_branchCacheId];
  set _cacheStats(DashboardStats? v) {
    if (v == null) {
      _cacheStatsByBranch.remove(_branchCacheId);
    } else {
      _cacheStatsByBranch[_branchCacheId] = v;
    }
  }

  DateTime? get _cacheStatsTime => _cacheStatsTimeByBranch[_branchCacheId];
  set _cacheStatsTime(DateTime? v) {
    if (v == null) {
      _cacheStatsTimeByBranch.remove(_branchCacheId);
    } else {
      _cacheStatsTimeByBranch[_branchCacheId] = v;
    }
  }

  String get _mostCacheKey => '${_branchCacheId}:${_periodParam(period.value)}';

  // =================== =================== ===================

  // 0=يوم, 1=أسبوع, 2=شهر, 3=الكل
  final period = 3.obs;

  final Rxn<DashboardStats> stats = Rxn<DashboardStats>();
  final loadingStats = false.obs;

  // (الترتيب, الاسم, العدد, التاريخ, الصورة)
  RxList<(int, String, String, String, String)> mostOrdered =
      <(int, String, String, String, String)>[].obs;

  Timer? _autoRefreshTimer;
  int? _lastBranchId;

  @override
  void onInit() {
    super.onInit();

    _loadFromPersistentCache();

    final current = _branchId;
    if (current != null && current > 0) {
      _lastBranchId = current;
      Future.microtask(refreshAll);
    }

    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 90), (_) {
      if (_branchId != null && _branchId! > 0) {
        refreshAll();
      }
    });

    ever<int>(period, (_) {
      if (_branchId != null && _branchId! > 0) {
        fetchMostOrdered();
      }
    });

    _branchWorker = ever<int?>(_branchScope.selectedBranchId, (branchId) async {
      if (branchId == null || branchId <= 0) return;
      if (_lastBranchId == branchId) return;

      _lastBranchId = branchId;
      stats.value = null;
      mostOrdered.clear();

      await refreshAll();
    });
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    _branchWorker?.dispose();
    super.onClose();
  }

  /* =================== 🔹 تحميل الكاش من GetStorage 🔹 =================== */

  void _loadFromPersistentCache() {
    try {
      final statsJson = _box.read(_kStatsKey);
      final statsTimeRaw = _box.read(_kStatsTimeKey);

      if (statsJson != null && statsTimeRaw != null) {
        DashboardStats? d;
        if (statsJson is Map<String, dynamic>) {
          d = DashboardStats.fromJson(statsJson);
        } else if (statsJson is String) {
          final m = jsonDecode(statsJson) as Map<String, dynamic>;
          d = DashboardStats.fromJson(m);
        }

        DateTime? t;
        if (statsTimeRaw is int) {
          t = DateTime.fromMillisecondsSinceEpoch(statsTimeRaw);
        } else if (statsTimeRaw is String) {
          t = DateTime.tryParse(statsTimeRaw);
        }

        if (d != null) {
          stats.value = d;
          _cacheStats = d;
          _cacheStatsTime = t;
        }
      }

      final mostJson = _box.read(_kMostKey);
      final mostTimeJson = _box.read(_kMostTimeKey);

      if (mostJson is Map && mostTimeJson is Map) {
        final Map<String, dynamic> mostMap = Map<String, dynamic>.from(
          mostJson,
        );
        final Map<String, dynamic> timeMap = Map<String, dynamic>.from(
          mostTimeJson,
        );

        _cacheMostOrdered.clear();
        _cacheMostOrderedTime.clear();

        mostMap.forEach((key, val) {
          if (val is List) {
            final list = <(int, String, String, String, String)>[];
            for (final e in val) {
              if (e is Map) {
                final m = Map<String, dynamic>.from(e);
                final rank = (m['rank'] is num)
                    ? (m['rank'] as num).toInt()
                    : int.tryParse('${m['rank'] ?? 0}') ?? 0;
                final name = (m['name'] ?? '').toString();
                final count = (m['count'] ?? '').toString();
                final date = (m['date'] ?? '').toString();
                final image = (m['image'] ?? '').toString();
                list.add((rank, name, count, date, image));
              }
            }
            if (list.isNotEmpty) {
              _cacheMostOrdered[key] = list;
            }
          }
        });

        timeMap.forEach((key, val) {
          DateTime? t;
          if (val is int) {
            t = DateTime.fromMillisecondsSinceEpoch(val);
          } else if (val is String) {
            t = DateTime.tryParse(val);
          }
          if (t != null) {
            _cacheMostOrderedTime[key] = t;
          }
        });

        final cachedList = _cacheMostOrdered[_mostCacheKey];
        if (cachedList != null) {
          mostOrdered.assignAll(cachedList);
        }
      }
    } catch (_) {}
  }

  /* =================== 🔹 حفظ الكاش في GetStorage 🔹 =================== */

  void _saveStatsToStorage() {
    try {
      if (_cacheStats == null || _cacheStatsTime == null) return;
      final jsonStats = _cacheStats!.toJson();
      _box.write(_kStatsKey, jsonStats);
      _box.write(_kStatsTimeKey, _cacheStatsTime!.millisecondsSinceEpoch);
    } catch (_) {}
  }

  void _saveMostOrderedToStorage() {
    try {
      final out = <String, dynamic>{};
      final timeOut = <String, dynamic>{};

      _cacheMostOrdered.forEach((per, list) {
        out[per] = list
            .map(
              (t) => {
                'rank': t.$1,
                'name': t.$2,
                'count': t.$3,
                'date': t.$4,
                'image': t.$5,
              },
            )
            .toList();
      });

      _cacheMostOrderedTime.forEach((per, t) {
        timeOut[per] = t.millisecondsSinceEpoch;
      });

      _box.write(_kMostKey, out);
      _box.write(_kMostTimeKey, timeOut);
    } catch (_) {}
  }

  /* =================== =================== =================== */

  Future<void> refreshAll() async {
    final branchId = _branchId;
    if (branchId == null || branchId <= 0) {
      return;
    }

    await Future.wait([fetchStats(), fetchMostOrdered()]);
  }

  Future<void> fetchStats() async {
    final branchId = _branchId;
    if (branchId == null || branchId <= 0) {
      debugPrint('fetchStats skipped: branch_id is null');
      return;
    }

    try {
      final now = DateTime.now();
      if (stats.value == null &&
          _cacheStats != null &&
          _cacheStatsTime != null &&
          now.difference(_cacheStatsTime!) <= _statsCacheDuration) {
        stats.value = _cacheStats;
        return;
      }
    } catch (_) {}

    try {
      loadingStats(true);

      final data = await _api.get(Env.stats, query: {'branch_id': '$branchId'});

      stats.value = DashboardStats.fromJson(
        data is Map ? Map<String, dynamic>.from(data) : {},
      );

      _cacheStats = stats.value;
      _cacheStatsTime = DateTime.now();
      _saveStatsToStorage();
    } catch (e) {
      debugPrint('fetchStats error: $e');
    } finally {
      loadingStats(false);
    }
  }

  String _periodParam(int v) {
    switch (v) {
      case 0:
        return 'day';
      case 1:
        return 'week';
      case 2:
        return 'month';
      case 3:
      default:
        return 'all';
    }
  }

  Future<void> fetchMostOrdered() async {
    final branchId = _branchId;
    if (branchId == null || branchId <= 0) {
      debugPrint('fetchMostOrdered skipped: branch_id is null');
      return;
    }

    try {
      final now = DateTime.now();
      final cached = _cacheMostOrdered[_mostCacheKey];
      final t = _cacheMostOrderedTime[_mostCacheKey];
      if (mostOrdered.isEmpty &&
          cached != null &&
          t != null &&
          now.difference(t) <= _mostCacheDuration) {
        mostOrdered.assignAll(cached);
        return;
      }
    } catch (_) {}

    try {
      final per = _periodParam(period.value);

      final data = await _api.get(
        Env.mostOrdered,
        query: {'limit': '10', 'period': per, 'branch_id': '$branchId'},
      );

      final list = (data is List)
          ? data.map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];

      final out = <(int, String, String, String, String)>[];

      for (var i = 0; i < list.length; i++) {
        final m = list[i];
        final rank = i + 1;
        final name = (m['name'] ?? '').toString();

        final countNum = (m['order_count_period'] is num)
            ? (m['order_count_period'] as num).toInt()
            : (int.tryParse(
                    '${m['order_count_period'] ?? m['order_count'] ?? 0}',
                  ) ??
                  0);
        final countStr = '$countNum';

        final date =
            (m['last_order_at'] ??
                    m['updated_at'] ??
                    m['item_updated_at'] ??
                    m['created_at'] ??
                    m['item_created_at'] ??
                    '')
                .toString();

        final image = (m['image_url'] ?? m['image'] ?? '').toString();

        out.add((rank, name, countStr, date, image));
      }

      mostOrdered.assignAll(out);

      _cacheMostOrdered[_mostCacheKey] =
          List<(int, String, String, String, String)>.from(out);
      _cacheMostOrderedTime[_mostCacheKey] = DateTime.now();
      _saveMostOrderedToStorage();
    } catch (e) {
      debugPrint('fetchMostOrdered error: $e');
    }
  }
}
