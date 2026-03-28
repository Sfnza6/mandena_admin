// lib/controllers/item_components_controller.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../core/services/api_service.dart';
import '../core/config/env.dart'; // مهم: لاستخدام مسارات Env

class SimpleRef {
  final int id;
  final String name;
  const SimpleRef(this.id, this.name);

  factory SimpleRef.fromJson(Map<String, dynamic> j) => SimpleRef(
    int.tryParse('${j['id'] ?? 0}') ?? 0,
    (j['name'] ?? j['name_c'] ?? '').toString(),
  );
}

class ComponentRow {
  final int id;
  final String name;
  final RxBool selected; // مفعّل للصنف؟
  final RxDouble price; // سعر الإضافة (لـ additions فقط)

  ComponentRow({
    required this.id,
    required this.name,
    bool selected = false,
    double price = 0.0,
  }) : selected = RxBool(selected),
       price = RxDouble(price);
}

class ItemComponentsController extends GetxController {
  final _api = ApiService();

  // =================== 🔹 Cache في الذاكرة (RAM) 🔹 ===================

  /// كاش للأصناف (اللي في الـ dropdown / شاشة البحث)
  static List<SimpleRef>? _cacheItems;
  static DateTime? _cacheItemsAt;

  /// كاش لكل المكوّنات المتاحة (بنخزنها كـ Map بسيط {id,name,price})
  static List<Map<String, dynamic>>? _cacheComponents;
  static DateTime? _cacheComponentsAt;

  /// كاش لربط كل صنف بمكوّناته:
  /// item_id -> { additions: [ {id,price} ], removals: [ {id} ] }
  static final Map<int, Map<String, dynamic>> _cacheBinding = {};
  static final Map<int, DateTime> _cacheBindingAt = {};

  /// مدة صلاحية الكاش (للكل)
  static const Duration _cacheTTL = Duration(seconds: 60);

  bool _isFresh(DateTime? t) {
    if (t == null) return false;
    return DateTime.now().difference(t) <= _cacheTTL;
  }

  // =================== 🔹 Cache دائم (GetStorage) 🔹 ===================

  static const String _boxName = 'admin_cache';

  static const String _kItemsKey = 'item_components_items';
  static const String _kItemsTimeKey = 'item_components_items_time';

  static const String _kCompsKey = 'item_components_all';
  static const String _kCompsTimeKey = 'item_components_all_time';

  static const String _kBindingsKey = 'item_components_bindings';
  static const String _kBindingsTimeKey = 'item_components_bindings_time';

  final GetStorage _box = GetStorage(_boxName);

  // =================== حالة عامّة ===================

  final isBusy = false.obs;
  final isSaving = false.obs;

  // الأصناف
  final items = <SimpleRef>[].obs;
  final selectedItem = Rxn<SimpleRef>();

  // 🔍 بحث عن صنف (منتج) عند الاختيار
  final itemSearch = ''.obs;

  List<SimpleRef> get filteredItems {
    final q = itemSearch.value.trim();
    if (q.isEmpty) return items;
    return items
        .where((e) => e.name.contains(q) || e.id.toString() == q)
        .toList();
  }

  // المكوّنات
  final additions = <ComponentRow>[].obs; // إضافات مدفوعة
  final removals = <ComponentRow>[].obs; // مكوّنات قابلة للحذف

  // بحث داخل المكوّنات
  final searchAdd = ''.obs;
  final searchRem = ''.obs;

  @override
  void onInit() {
    super.onInit();

    // 1️⃣ حمّل أي كاش محفوظ من GetStorage (عرض فوري)
    _loadFromPersistentCache();

    // 2️⃣ بعدها حمّل من السيرفر مع استخدام كاش RAM
    loadItemsAndComponents();
  }

  /* =================== 🔹 تحميل الكاش من GetStorage 🔹 =================== */

  void _loadFromPersistentCache() {
    try {
      // ----- الأصناف -----
      final itemsJson = _box.read(_kItemsKey);
      final itemsTimeRaw = _box.read(_kItemsTimeKey);

      if (itemsJson != null && itemsTimeRaw != null) {
        DateTime? t;
        if (itemsTimeRaw is int) {
          t = DateTime.fromMillisecondsSinceEpoch(itemsTimeRaw);
        } else if (itemsTimeRaw is String) {
          t = DateTime.tryParse(itemsTimeRaw);
        }

        final List listRaw = itemsJson is String
            ? (jsonDecode(itemsJson) as List)
            : (itemsJson as List);

        final list = listRaw
            .map((e) => SimpleRef.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        if (list.isNotEmpty) {
          _cacheItems = List<SimpleRef>.from(list);
          _cacheItemsAt = t;
          if (items.isEmpty) {
            items.assignAll(list);
          }
        }
      }

      // ----- كل المكوّنات -----
      final compsJson = _box.read(_kCompsKey);
      final compsTimeRaw = _box.read(_kCompsTimeKey);

      if (compsJson != null && compsTimeRaw != null) {
        DateTime? t;
        if (compsTimeRaw is int) {
          t = DateTime.fromMillisecondsSinceEpoch(compsTimeRaw);
        } else if (compsTimeRaw is String) {
          t = DateTime.tryParse(compsTimeRaw);
        }

        final List listRaw = compsJson is String
            ? (jsonDecode(compsJson) as List)
            : (compsJson as List);

        final comps = listRaw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        if (comps.isNotEmpty) {
          _cacheComponents = List<Map<String, dynamic>>.from(comps);
          _cacheComponentsAt = t;

          if (additions.isEmpty && removals.isEmpty) {
            final base = <ComponentRow>[];
            for (final m in comps) {
              final id = int.tryParse('${m['id'] ?? 0}') ?? 0;
              final name = (m['name'] ?? '').toString();
              final price = (m['price'] is num)
                  ? (m['price'] as num).toDouble()
                  : 0.0;
              base.add(ComponentRow(id: id, name: name, price: price));
            }

            additions.assignAll(
              base
                  .map(
                    (e) => ComponentRow(
                      id: e.id,
                      name: e.name,
                      selected: false,
                      price: e.price.value,
                    ),
                  )
                  .toList(),
            );

            removals.assignAll(
              base
                  .map(
                    (e) => ComponentRow(
                      id: e.id,
                      name: e.name,
                      selected: false,
                      price: 0.0,
                    ),
                  )
                  .toList(),
            );
          }
        }
      }

      // ----- كاش ربط الأصناف بالمكوّنات -----
      final bindsJson = _box.read(_kBindingsKey);
      final bindsTimeJson = _box.read(_kBindingsTimeKey);

      if (bindsJson is Map && bindsTimeJson is Map) {
        final Map<String, dynamic> bMap = Map<String, dynamic>.from(bindsJson);
        final Map<String, dynamic> tMap = Map<String, dynamic>.from(
          bindsTimeJson,
        );

        _cacheBinding.clear();
        _cacheBindingAt.clear();

        bMap.forEach((key, val) {
          final id = int.tryParse(key) ?? 0;
          if (id <= 0) return;
          if (val is Map) {
            final data = Map<String, dynamic>.from(val);
            _cacheBinding[id] = data;

            final traw = tMap[key];
            DateTime? t;
            if (traw is int) {
              t = DateTime.fromMillisecondsSinceEpoch(traw);
            } else if (traw is String) {
              t = DateTime.tryParse(traw);
            }
            if (t != null) {
              _cacheBindingAt[id] = t;
            }
          }
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('loadFromPersistentCache error: $e');
    }
  }

  /* =================== 🔹 حفظ الكاش في GetStorage 🔹 =================== */

  void _saveToPersistentCache() {
    try {
      // الأصناف
      if (_cacheItems != null && _cacheItems!.isNotEmpty) {
        final list = _cacheItems!
            .map((e) => {'id': e.id, 'name': e.name})
            .toList();
        _box.write(_kItemsKey, list);
        _box.write(
          _kItemsTimeKey,
          (_cacheItemsAt ?? DateTime.now()).millisecondsSinceEpoch,
        );
      }

      // المكوّنات
      if (_cacheComponents != null && _cacheComponents!.isNotEmpty) {
        _box.write(_kCompsKey, _cacheComponents);
        _box.write(
          _kCompsTimeKey,
          (_cacheComponentsAt ?? DateTime.now()).millisecondsSinceEpoch,
        );
      }

      // الربط لكل صنف
      if (_cacheBinding.isNotEmpty) {
        final out = <String, dynamic>{};
        final outTime = <String, dynamic>{};

        _cacheBinding.forEach((id, data) {
          out['$id'] = data;
        });
        _cacheBindingAt.forEach((id, t) {
          outTime['$id'] = t.millisecondsSinceEpoch;
        });

        _box.write(_kBindingsKey, out);
        _box.write(_kBindingsTimeKey, outTime);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('saveToPersistentCache error: $e');
    }
  }

  /* =================== تحميل الأصناف + المكوّنات =================== */

  Future<void> loadItemsAndComponents() async {
    isBusy.value = true;
    try {
      // 1️⃣ جرّب كاش RAM أولاً لو موجود وحديث
      final now = DateTime.now();
      final itemsFresh = _cacheItems != null && _isFresh(_cacheItemsAt);
      final compsFresh =
          _cacheComponents != null && _isFresh(_cacheComponentsAt);

      if (itemsFresh && compsFresh) {
        // الأصناف
        items.assignAll(_cacheItems!);

        // المكوّنات
        final base = <ComponentRow>[];
        for (final m in _cacheComponents!) {
          final id = int.tryParse('${m['id'] ?? 0}') ?? 0;
          final name = (m['name'] ?? '').toString();
          final price = (m['price'] is num)
              ? (m['price'] as num).toDouble()
              : 0.0;
          base.add(ComponentRow(id: id, name: name, price: price));
        }

        additions.assignAll(
          base
              .map(
                (e) => ComponentRow(
                  id: e.id,
                  name: e.name,
                  selected: false,
                  price: e.price.value,
                ),
              )
              .toList(),
        );

        removals.assignAll(
          base
              .map(
                (e) => ComponentRow(
                  id: e.id,
                  name: e.name,
                  selected: false,
                  price: 0.0,
                ),
              )
              .toList(),
        );

        // لا داعي للـ API
        return;
      }

      // 2️⃣ لو الكاش قديم/مش موجود → حمل من السيرفر
      // الأصناف
      final rItems = await _api.get(Env.itemsSimpleList);
      if (rItems is Map && rItems['ok'] == true) {
        final list = (rItems['items'] as List? ?? const [])
            .map((e) => SimpleRef.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        items.assignAll(list);

        _cacheItems = List<SimpleRef>.from(list);
        _cacheItemsAt = now;
      }

      // المكوّنات
      final rComps = await _api.get(Env.componentsList);
      final base = <ComponentRow>[];
      final rawList = <Map<String, dynamic>>[];

      if (rComps is Map && rComps['ok'] == true) {
        final comps = (rComps['components'] as List? ?? const []);
        for (final raw in comps) {
          final m = Map<String, dynamic>.from(raw as Map);
          final id = int.tryParse('${m['id'] ?? 0}') ?? 0;
          final name = (m['name'] ?? m['name_c'] ?? '').toString();
          final price =
              double.tryParse('${m['price'] ?? m['pri'] ?? 0}') ?? 0.0;

          base.add(ComponentRow(id: id, name: name, price: price));

          rawList.add({'id': id, 'name': name, 'price': price});
        }
      }

      additions.assignAll(
        base
            .map(
              (e) => ComponentRow(
                id: e.id,
                name: e.name,
                selected: false,
                price: e.price.value,
              ),
            )
            .toList(),
      );

      removals.assignAll(
        base
            .map(
              (e) => ComponentRow(
                id: e.id,
                name: e.name,
                selected: false,
                price: 0.0,
              ),
            )
            .toList(),
      );

      _cacheComponents = rawList;
      _cacheComponentsAt = now;

      // 3️⃣ بعد التحديث من السيرفر → خزّن في GetStorage
      _saveToPersistentCache();
    } catch (e) {
      if (kDebugMode) debugPrint('loadItemsAndComponents error: $e');
      Get.snackbar('خطأ', 'تعذّر تحميل البيانات');
    } finally {
      isBusy.value = false;
    }
  }

  /// عند تغيير الصنف: إعادة تحميل الربط الحالي له
  Future<void> loadItemBinding(SimpleRef item, {bool force = false}) async {
    selectedItem.value = item;

    // إعادة الضبط
    for (final a in additions) {
      a.selected.value = false;
    }
    for (final r in removals) {
      r.selected.value = false;
    }

    if (item.id == 0) return;

    // 1️⃣ جرّب كاش الربط أولاً
    if (!force &&
        _cacheBinding.containsKey(item.id) &&
        _isFresh(_cacheBindingAt[item.id])) {
      final data = _cacheBinding[item.id]!;
      final adds = (data['additions'] as List? ?? const []);
      final rems = (data['removals'] as List? ?? const []);

      // عيّن الإضافات + السعر
      for (final a in additions) {
        Map<String, dynamic>? found;
        for (final raw in adds) {
          final m = Map<String, dynamic>.from(raw as Map);
          final id = int.tryParse('${m['id'] ?? 0}') ?? 0;
          if (id == a.id) {
            found = m;
            break;
          }
        }
        if (found != null) {
          a.selected.value = true;
          final p =
              double.tryParse(
                '${found['price'] ?? found['pri'] ?? found['pri_override'] ?? a.price.value}',
              ) ??
              a.price.value;
          a.price.value = p;
        }
      }

      // عيّن المحذوفات
      for (final rr in removals) {
        final exists = rems.any((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          final id = int.tryParse('${m['id'] ?? 0}') ?? 0;
          return id == rr.id;
        });
        rr.selected.value = exists;
      }

      return;
    }

    // 2️⃣ لو مافيش كاش أو قديم → جيب من السيرفر وحدث الكاش
    isBusy.value = true;
    try {
      Map<String, dynamic>? r;

      // نحاول GET مع query
      final g = await _api.get(
        Env.itemComponentsGet,
        query: {'item_id': '${item.id}'},
      );
      if (g is Map<String, dynamic>) r = g;

      // إن فشل GET نجرب POST فورم (توافقًا مع سيرفرات لا تدعم query)
      if (r == null || r['ok'] != true) {
        final p = await _api.post(
          Env.itemComponentsGet,
          body: {'item_id': '${item.id}'},
        );
        if (p is Map<String, dynamic>) r = p;
      }

      if (r != null && r['ok'] == true) {
        final adds = (r['additions'] as List? ?? const []);
        final rems = (r['removals'] as List? ?? const []);

        // عيّن الإضافات + السعر
        for (final a in additions) {
          Map<String, dynamic>? found;
          for (final raw in adds) {
            final m = Map<String, dynamic>.from(raw as Map);
            final id = int.tryParse('${m['id'] ?? 0}') ?? 0;
            if (id == a.id) {
              found = m;
              break;
            }
          }
          if (found != null) {
            a.selected.value = true;
            // pri أو price أو pri_override (لدعم سكربت قديم)
            final p =
                double.tryParse(
                  '${found['price'] ?? found['pri'] ?? found['pri_override'] ?? a.price.value}',
                ) ??
                a.price.value;
            a.price.value = p;
          }
        }

        // عيّن المحذوفات
        for (final rr in removals) {
          final exists = rems.any((raw) {
            final m = Map<String, dynamic>.from(raw as Map);
            final id = int.tryParse('${m['id'] ?? 0}') ?? 0;
            return id == rr.id;
          });
          rr.selected.value = exists;
        }

        // 🔹 حدّث كاش الربط لهذا الصنف + خزّنه
        _cacheBinding[item.id] = {
          'additions': adds
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
          'removals': rems
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        };
        _cacheBindingAt[item.id] = DateTime.now();
        _saveToPersistentCache();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('loadItemBinding error: $e');
      Get.snackbar('خطأ', 'تعذّر تحميل ربط هذا الصنف');
    } finally {
      isBusy.value = false;
    }
  }

  List<ComponentRow> get filteredAdditions {
    final q = searchAdd.value.trim();
    if (q.isEmpty) return additions;
    return additions.where((e) => e.name.contains(q)).toList();
  }

  List<ComponentRow> get filteredRemovals {
    final q = searchRem.value.trim();
    if (q.isEmpty) return removals;
    return removals.where((e) => e.name.contains(q)).toList();
  }

  /// حفظ ربط الصنف بالمكوّنات
  Future<void> save() async {
    final sel = selectedItem.value;
    if (sel == null) {
      Get.snackbar('تنبيه', 'اختر صنفًا أولاً');
      return;
    }
    isSaving.value = true;
    try {
      final adds = additions
          .where((e) => e.selected.value)
          .map((e) => {'id': e.id, 'price': e.price.value})
          .toList();

      final rems = removals
          .where((e) => e.selected.value)
          .map((e) => {'id': e.id})
          .toList();

      final res = await _api.post(
        Env.itemComponentsSave,
        body: {
          'item_id': '${sel.id}',
          'additions': jsonEncode(adds),
          'removals': jsonEncode(rems),
        },
      );

      if (res is Map && res['ok'] == true) {
        // 🔹 حدّث كاش الربط للصنف الحالي
        _cacheBinding[sel.id] = {
          'additions': adds.map((e) => Map<String, dynamic>.from(e)).toList(),
          'removals': rems.map((e) => Map<String, dynamic>.from(e)).toList(),
        };
        _cacheBindingAt[sel.id] = DateTime.now();
        _saveToPersistentCache();

        Get.snackbar('تم', 'تم حفظ الربط بنجاح');
      } else {
        Get.snackbar(
          'خطأ',
          (res is Map && res['message'] != null)
              ? '${res['message']}'
              : 'تعذّر الحفظ',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('save error: $e');
      Get.snackbar('خطأ', 'فشل الاتصال بالسيرفر');
    } finally {
      isSaving.value = false;
    }
  }

  /// إضافة مكوّن جديد (زر "مكوّن جديد +")
  Future<bool> addNewComponent({
    required String name,
    required double price,
  }) async {
    try {
      final res = await _api.post(
        Env.componentAdd,
        body: {
          'name': name,
          'price': price.toString(), // كـ String متوافق مع POST form
        },
      );

      if (res is Map && res['ok'] == true) {
        final id = int.tryParse('${res['id'] ?? 0}') ?? 0;

        // أضفه محليًا للقائمتين
        final row = ComponentRow(id: id, name: name, price: price);
        additions.add(row);
        removals.add(ComponentRow(id: id, name: name, price: 0.0));

        // 🔹 حدّث كاش المكوّنات + التخزين الدائم
        final m = {'id': id, 'name': name, 'price': price};
        _cacheComponents ??= <Map<String, dynamic>>[];
        _cacheComponents!.add(m);
        _cacheComponentsAt = DateTime.now();
        _saveToPersistentCache();

        return true;
      }

      // في حال رجع خطأ برسالة من السيرفر
      if (res is Map && res['message'] != null) {
        Get.snackbar('خطأ', '${res['message']}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('addNewComponent error: $e');
      Get.snackbar('خطأ', 'تعذّرت إضافة المكوّن');
      return false;
    }
  }
}
