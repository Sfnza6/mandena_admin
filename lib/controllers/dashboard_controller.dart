import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mandena_admin/data/models/dashboard_stats.dart';
import '../core/services/api_service.dart';
import '../core/config/env.dart';

class DashboardController extends GetxController {
  final _api = ApiService();

  // =================== 🔹 Cache ثابت للداشبورد (RAM) 🔹 ===================

  // كاش للإحصائيات العامة
  static DashboardStats? _cacheStats;
  static DateTime? _cacheStatsTime;
  static const Duration _statsCacheDuration = Duration(seconds: 60);

  // كاش للأكثر طلباً حسب الفترة (key = period: day/week/month/all)
  static final Map<String, List<(int, String, String, String, String)>>
  _cacheMostOrdered = {};
  static final Map<String, DateTime> _cacheMostOrderedTime = {};
  static const Duration _mostCacheDuration = Duration(seconds: 60);

  // كاش للتقييمات
  static List<(String, String, String)>? _cacheReviews;
  static DateTime? _cacheReviewsTime;
  static const Duration _reviewsCacheDuration = Duration(seconds: 60);

  // =================== 🔹 Cache دائم (GetStorage) 🔹 ===================

  static const String _boxName = 'admin_cache';
  static const String _kStatsKey = 'dashboard_stats';
  static const String _kStatsTimeKey = 'dashboard_stats_time';
  static const String _kMostKey = 'dashboard_most_ordered';
  static const String _kMostTimeKey = 'dashboard_most_ordered_time';
  static const String _kReviewsKey = 'dashboard_reviews';
  static const String _kReviewsTimeKey = 'dashboard_reviews_time';

  final GetStorage _box = GetStorage(_boxName);

  // =================== =================== ===================

  // 0=يوم, 1=أسبوع, 2=شهر, 3=الكل
  final period = 3.obs;

  final Rxn<DashboardStats> stats = Rxn<DashboardStats>();
  final loadingStats = false.obs;

  // (الترتيب, الاسم, العدد, التاريخ, الصورة)
  RxList<(int, String, String, String, String)> mostOrdered =
      <(int, String, String, String, String)>[].obs;

  RxList<(String, String, String)> reviews = <(String, String, String)>[].obs;

  Timer? _autoRefreshTimer;

  @override
  void onInit() {
    super.onInit();

    // 1️⃣ حمّل من الكاش الدائم في البداية (عرض فوري لو فيه بيانات محفوظة)
    _loadFromPersistentCache();

    // 2️⃣ ثمّ حدّث من الخادم + كاش RAM
    refreshAll();

    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      refreshAll();
    });
    ever<int>(period, (_) => fetchMostOrdered());
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  /* =================== 🔹 تحميل الكاش من GetStorage 🔹 =================== */

  void _loadFromPersistentCache() {
    try {
      // ----- الإحصائيات -----
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

      // ----- الأكثر طلباً -----
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

        // لو الفترة الحالية لها كاش، عرّضها فوراً
        final per = _periodParam(period.value);
        final cachedList = _cacheMostOrdered[per];
        if (cachedList != null) {
          mostOrdered.assignAll(cachedList);
        }
      }

      // ----- التقييمات -----
      final reviewsJson = _box.read(_kReviewsKey);
      final reviewsTimeRaw = _box.read(_kReviewsTimeKey);

      if (reviewsJson != null && reviewsTimeRaw != null) {
        List<(String, String, String)> list = [];

        if (reviewsJson is List) {
          for (final e in reviewsJson) {
            if (e is Map) {
              final m = Map<String, dynamic>.from(e);
              list.add((
                (m['name'] ?? '').toString(),
                (m['time'] ?? '').toString(),
                (m['text'] ?? '').toString(),
              ));
            }
          }
        } else if (reviewsJson is String) {
          final arr = jsonDecode(reviewsJson) as List;
          for (final e in arr) {
            if (e is Map) {
              final m = Map<String, dynamic>.from(e);
              list.add((
                (m['name'] ?? '').toString(),
                (m['time'] ?? '').toString(),
                (m['text'] ?? '').toString(),
              ));
            }
          }
        }

        DateTime? t;
        if (reviewsTimeRaw is int) {
          t = DateTime.fromMillisecondsSinceEpoch(reviewsTimeRaw);
        } else if (reviewsTimeRaw is String) {
          t = DateTime.tryParse(reviewsTimeRaw);
        }

        if (list.isNotEmpty) {
          reviews.assignAll(list);
          _cacheReviews = List<(String, String, String)>.from(list);
          _cacheReviewsTime = t;
        }
      }
    } catch (_) {
      // لو صار أي خطأ في الكاش، نتجاهله بهدوء
    }
  }

  /* =================== 🔹 حفظ الكاش في GetStorage 🔹 =================== */

  void _saveStatsToStorage() {
    try {
      if (_cacheStats == null || _cacheStatsTime == null) return;
      // نفترض DashboardStats عنده toJson()
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

  void _saveReviewsToStorage() {
    try {
      if (_cacheReviews == null || _cacheReviewsTime == null) return;
      final list = _cacheReviews!
          .map((t) => {'name': t.$1, 'time': t.$2, 'text': t.$3})
          .toList();
      _box.write(_kReviewsKey, list);
      _box.write(_kReviewsTimeKey, _cacheReviewsTime!.millisecondsSinceEpoch);
    } catch (_) {}
  }

  /* =================== =================== =================== */

  Future<void> refreshAll() async {
    await Future.wait([fetchStats(), fetchMostOrdered(), fetchReviews()]);
  }

  Future<void> fetchStats() async {
    // 🔹 جرّب الكاش أولاً لو ما عندناش بيانات في الـ stats
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
      final data = await _api.get(Env.stats);
      stats.value = DashboardStats.fromJson(
        data is Map ? Map<String, dynamic>.from(data) : {},
      );

      // 🔹 حدّث الكاش بعد النجاح
      _cacheStats = stats.value;
      _cacheStatsTime = DateTime.now();
      _saveStatsToStorage();
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

  /// ✅ يقرأ most_ordered.php مع دعم period
  Future<void> fetchMostOrdered() async {
    try {
      final per = _periodParam(period.value);

      // 🔹 جرّب الكاش أولاً لو القائمة فاضية
      try {
        final now = DateTime.now();
        final cached = _cacheMostOrdered[per];
        final t = _cacheMostOrderedTime[per];
        if (mostOrdered.isEmpty &&
            cached != null &&
            t != null &&
            now.difference(t) <= _mostCacheDuration) {
          mostOrdered.assignAll(cached);
          return;
        }
      } catch (_) {}

      final data = await _api.get(
        Env.mostOrdered,
        query: {
          'limit': '10',
          'period': per,
          // 'include_inactive': '1', // إذا حابب تُظهر غير المفعّل
        },
      );

      final list = (data is List)
          ? data.map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];

      final out = <(int, String, String, String, String)>[];

      for (var i = 0; i < list.length; i++) {
        final m = list[i];
        final rank = i + 1;
        final name = (m['name'] ?? '').toString();

        // نأخذ العدد ضمن الفترة أولاً، وإلا التراكمي كبديل
        final countNum = (m['order_count_period'] is num)
            ? (m['order_count_period'] as num).toInt()
            : (int.tryParse(
                    '${m['order_count_period'] ?? m['order_count'] ?? 0}',
                  ) ??
                  0);
        final countStr = '$countNum';

        // التاريخ: آخر طلب ضمن الفترة وإلا updated/created
        final date =
            (m['last_order_at'] ??
                    m['updated_at'] ??
                    m['item_updated_at'] ??
                    m['created_at'] ??
                    m['item_created_at'] ??
                    '')
                .toString();

        // الصورة
        final image = (m['image_url'] ?? m['image'] ?? '').toString();

        out.add((rank, name, countStr, date, image));
      }

      mostOrdered.assignAll(out);

      // 🔹 حدّث كاش الـ most ordered لهذه الفترة
      _cacheMostOrdered[per] = List<(int, String, String, String, String)>.from(
        out,
      );
      _cacheMostOrderedTime[per] = DateTime.now();
      _saveMostOrderedToStorage();
    } catch (_) {
      // تجاهل الخطأ حتى لا تتعطّل الواجهة
    }
  }

  Future<void> fetchReviews() async {
    // 🔹 جرّب الكاش لو القائمة فاضية
    try {
      final now = DateTime.now();
      if (reviews.isEmpty &&
          _cacheReviews != null &&
          _cacheReviewsTime != null &&
          now.difference(_cacheReviewsTime!) <= _reviewsCacheDuration) {
        reviews.assignAll(_cacheReviews!);
        return;
      }
    } catch (_) {}

    try {
      final data = await _api.get(Env.reviews);
      final list = (data as List)
          .map(
            (e) => (
              (e['name'] ?? '').toString(),
              (e['time'] ?? '').toString(),
              (e['text'] ?? '').toString(),
            ),
          )
          .toList();

      reviews.assignAll(list);

      // 🔹 حدّث كاش التقييمات
      _cacheReviews = List<(String, String, String)>.from(list);
      _cacheReviewsTime = DateTime.now();
      _saveReviewsToStorage();
    } catch (_) {}
  }
}
