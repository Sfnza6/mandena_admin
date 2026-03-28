// lib/controllers/most_ordered_controller.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../core/services/api_service.dart';
import '../core/config/env.dart';

typedef MostOrderedRecord = (int, String, String, String, String);

class MostOrderedController extends GetxController {
  final _api = ApiService();

  /// 0: شهر, 1: أسبوع, 2: يوم, 3: الكل
  final period = 3.obs;

  /// العناصر في الواجهة
  final items = <MostOrderedRecord>[].obs;

  /// حالة التحميل
  final loading = false.obs;

  bool includeInactive = false;

  /// حدود حسب الفترة
  int _limitFor(int p) {
    switch (p) {
      case 0:
        return 20;
      case 1:
        return 15;
      case 2:
        return 10;
      default:
        return 50;
    }
  }

  /* =======================================================
                     🔥 نظام الكــاش الكامل 🔥
    ======================================================= */

  /// كاش RAM: periodKey → List<Record>
  static final Map<String, List<MostOrderedRecord>> _cache = {};

  /// وقت آخر تحديث
  static final Map<String, DateTime> _cacheAt = {};

  /// TTL للكاش
  static const Duration _ttl = Duration(seconds: 60);

  bool _isFresh(DateTime? t) =>
      t != null && DateTime.now().difference(t) < _ttl;

  /* =======================================================
                   🔥 الكاش الدائم GetStorage 🔥
    ======================================================= */

  static const String _boxName = 'admin_cache';
  static const String _kMostKey = 'most_ordered_cache';
  static const String _kMostTimeKey = 'most_ordered_cache_time';

  final _box = GetStorage(_boxName);

  /// تحميل الكاش من التخزين
  void _loadPersistentCache() {
    try {
      final raw = _box.read(_kMostKey);
      final rawT = _box.read(_kMostTimeKey);

      if (raw is Map && rawT is Map) {
        final cacheMap = Map<String, dynamic>.from(raw);
        final timeMap = Map<String, dynamic>.from(rawT);

        cacheMap.forEach((key, val) {
          if (val is List) {
            final list = <MostOrderedRecord>[];
            for (final e in val) {
              if (e is Map<String, dynamic>) {
                final rank = int.tryParse('${e['rank'] ?? 0}') ?? 0;
                final name = (e['name'] ?? '').toString();
                final count = (e['count'] ?? '').toString();
                final date = (e['date'] ?? '').toString();
                final img = (e['image'] ?? '').toString();
                list.add((rank, name, count, date, img));
              }
            }
            if (list.isNotEmpty) {
              _cache[key] = list;
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
          if (t != null) _cacheAt[key] = t;
        });
      }

      // تحميل فوري إذا فيه كاش للفترة الحالية
      final key = _periodKey(period.value);
      if (_cache.containsKey(key)) {
        items.assignAll(_cache[key]!);
      }
    } catch (_) {}
  }

  /// حفظ الكاش الدائم
  void _savePersistentCache() {
    try {
      final out = <String, dynamic>{};
      final outTime = <String, dynamic>{};

      _cache.forEach((key, list) {
        out[key] = list
            .map((t) => {
                  'rank': t.$1,
                  'name': t.$2,
                  'count': t.$3,
                  'date': t.$4,
                  'image': t.$5,
                })
            .toList();
      });

      _cacheAt.forEach((key, t) {
        outTime[key] = t.millisecondsSinceEpoch;
      });

      _box.write(_kMostKey, out);
      _box.write(_kMostTimeKey, outTime);
    } catch (_) {}
  }

  /* =======================================================
                          🔥 Helpers 🔥
    ======================================================= */

  String _periodKey(int p) {
    switch (p) {
      case 0:
        return 'month';
      case 1:
        return 'week';
      case 2:
        return 'day';
      default:
        return 'all';
    }
  }

  /* =======================================================
                        ON READY
    ======================================================= */

  @override
  void onReady() {
    super.onReady();
    _loadPersistentCache(); // تحميل فوري من الكاش
    fetch(); // أول تحديث من السيرفر
  }

  /* =======================================================
                      تغيير الفترة
    ======================================================= */

  Future<void> changePeriod(int p) async {
    if (p == period.value) return;
    period.value = p;

    // لو فيه كاش جاهز → اعرضه فوراً
    final key = _periodKey(p);
    if (_cache.containsKey(key) && _isFresh(_cacheAt[key])) {
      items.assignAll(_cache[key]!);
      return;
    }

    await fetch();
  }

  /* =======================================================
                       جلب البيانات
    ======================================================= */

  Future<void> fetch() async {
    final key = _periodKey(period.value);
    final limit = _limitFor(period.value);

    // 1️⃣ جرّب الكاش أولاً
    if (_cache.containsKey(key) && _isFresh(_cacheAt[key])) {
      items.assignAll(_cache[key]!);
      return;
    }

    // 2️⃣ سيرفر
    try {
      loading(true);

      final endpoint = (Env.mostOrdered.isNotEmpty)
          ? Env.mostOrdered
          : '${Env.base}/most_ordered.php';

      final res = await _api.get(
        endpoint,
        query: {
          'limit': '$limit',
          'include_inactive': includeInactive ? '1' : '0',
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final dynamic json = (res is String) ? jsonDecode(res) : res;

      final List rawList = (json is List)
          ? json
          : (json is Map && json['data'] is List
              ? json['data']
              : const []);

      final list = <MostOrderedRecord>[];

      for (var i = 0; i < rawList.length; i++) {
        final row = Map<String, dynamic>.from(rawList[i]);

        final name = (row['name'] ?? '').toString();
        final count = '${row['order_count'] ?? 0}';
        final date =
            (row['updated_at'] ?? row['created_at'] ?? '').toString();
        final image = (row['image_url'] ?? '').toString();

        list.add((i + 1, name, count, date, image));
      }

      items.assignAll(list);

      // 3️⃣ خزّن في كاش RAM + التخزين الدائم
      _cache[key] = List<MostOrderedRecord>.from(list);
      _cacheAt[key] = DateTime.now();
      _savePersistentCache();
    } catch (e) {
      Get.log('most_ordered fetch error: $e');
    } finally {
      loading(false);
    }
  }
}
