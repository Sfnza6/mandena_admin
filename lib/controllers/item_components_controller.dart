import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../core/services/api_service.dart';
import '../core/config/env.dart';
import 'admin_branch_scope_controller.dart';

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
  final RxString name;
  final RxBool selected;
  final RxDouble price;

  ComponentRow({
    required this.id,
    required String name,
    bool selected = false,
    double price = 0.0,
  }) : name = RxString(name),
       selected = RxBool(selected),
       price = RxDouble(price);
}

class ItemComponentsController extends GetxController {
  final _api = ApiService();
  final _box = GetStorage('admin_cache');

  final isBusy = false.obs;
  final isSaving = false.obs;
  final isWorkingOnComponent = false.obs;

  final items = <SimpleRef>[].obs;
  final selectedItem = Rxn<SimpleRef>();

  final itemSearch = ''.obs;
  final additions = <ComponentRow>[].obs;
  final removals = <ComponentRow>[].obs;
  final searchAdd = ''.obs;
  final searchRem = ''.obs;

  AdminBranchScopeController? get _scope =>
      Get.isRegistered<AdminBranchScopeController>()
      ? Get.find<AdminBranchScopeController>()
      : null;

  int get _branchId => _scope?.effectiveBranchId ?? 0;

  String get _itemsKey => 'item_components_items_branch_$_branchId';
  String get _itemsTimeKey => 'item_components_items_time_branch_$_branchId';
  String get _compsKey => 'item_components_components_branch_$_branchId';
  String get _compsTimeKey =>
      'item_components_components_time_branch_$_branchId';
  String get _bindingsKey => 'item_components_bindings_branch_$_branchId';
  String get _bindingsTimeKey =>
      'item_components_bindings_time_branch_$_branchId';

  @override
  void onInit() {
    super.onInit();
    _loadFromCache();
    loadItemsAndComponents(force: true);
    if (_scope != null) {
      ever<int?>(_scope!.selectedBranchId, (_) {
        selectedItem.value = null;
        itemSearch.value = '';
        searchAdd.value = '';
        searchRem.value = '';
        _loadFromCache();
        loadItemsAndComponents(force: true);
      });
    }
  }

  List<SimpleRef> get filteredItems {
    final q = itemSearch.value.trim();
    if (q.isEmpty) return items;
    return items
        .where((e) => e.name.contains(q) || e.id.toString() == q)
        .toList();
  }

  List<ComponentRow> get filteredAdditions {
    final q = searchAdd.value.trim();
    if (q.isEmpty) return additions;
    return additions.where((e) => e.name.value.contains(q)).toList();
  }

  List<ComponentRow> get filteredRemovals {
    final q = searchRem.value.trim();
    if (q.isEmpty) return removals;
    return removals.where((e) => e.name.value.contains(q)).toList();
  }

  void _resetSelections() {
    for (final a in additions) {
      a.selected.value = false;
    }
    for (final r in removals) {
      r.selected.value = false;
    }
  }

  void _buildComponentsFromRaw(List<Map<String, dynamic>> raw) {
    additions.assignAll(
      raw
          .map(
            (m) => ComponentRow(
              id: int.tryParse('${m['id'] ?? 0}') ?? 0,
              name: (m['name'] ?? '').toString(),
              price: double.tryParse('${m['price'] ?? 0}') ?? 0.0,
            ),
          )
          .toList(),
    );

    removals.assignAll(
      raw
          .map(
            (m) => ComponentRow(
              id: int.tryParse('${m['id'] ?? 0}') ?? 0,
              name: (m['name'] ?? '').toString(),
              price: double.tryParse('${m['price'] ?? 0}') ?? 0.0,
            ),
          )
          .toList(),
    );
  }

  void _loadFromCache() {
    try {
      final itemsRaw = _box.read(_itemsKey);
      if (itemsRaw is List) {
        items.assignAll(
          itemsRaw
              .map(
                (e) => SimpleRef.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList(),
        );
      } else {
        items.clear();
      }

      final compsRaw = _box.read(_compsKey);
      if (compsRaw is List) {
        final raw = compsRaw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _buildComponentsFromRaw(raw);
      } else {
        additions.clear();
        removals.clear();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('item comps cache load error: $e');
    }
  }

  void _saveItemsCache(List<SimpleRef> list) {
    _box.write(
      _itemsKey,
      list.map((e) => {'id': e.id, 'name': e.name}).toList(),
    );
    _box.write(_itemsTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  void _saveComponentsCache(List<Map<String, dynamic>> list) {
    _box.write(_compsKey, list);
    _box.write(_compsTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  void _refreshComponentsCacheFromMemory() {
    _saveComponentsCache([
      ...additions.map(
        (e) => {'id': e.id, 'name': e.name.value, 'price': e.price.value},
      ),
    ]);
  }

  Map<String, dynamic> _readBindingsCache() {
    final raw = _box.read(_bindingsKey);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  void _writeBindingCache(int itemId, List adds, List rems) {
    final map = _readBindingsCache();
    map['$itemId'] = {'additions': adds, 'removals': rems};
    _box.write(_bindingsKey, map);

    final timeMapRaw = _box.read(_bindingsTimeKey);
    final timeMap = timeMapRaw is Map
        ? Map<String, dynamic>.from(timeMapRaw)
        : <String, dynamic>{};
    timeMap['$itemId'] = DateTime.now().millisecondsSinceEpoch;
    _box.write(_bindingsTimeKey, timeMap);
  }

  Map<String, dynamic>? _getBindingCache(int itemId) {
    final map = _readBindingsCache();
    final data = map['$itemId'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  Map<String, dynamic>? _findById(List list, int id) {
    for (final e in list) {
      final m = Map<String, dynamic>.from(e as Map);
      final mid = int.tryParse('${m['id'] ?? 0}') ?? 0;
      if (mid == id) return m;
    }
    return null;
  }

  bool _containsId(List list, int id) {
    for (final e in list) {
      final m = Map<String, dynamic>.from(e as Map);
      final mid = int.tryParse('${m['id'] ?? 0}') ?? 0;
      if (mid == id) return true;
    }
    return false;
  }

  void _scrubDeletedComponentFromBindingCache(int componentId) {
    final map = _readBindingsCache();
    final patched = <String, dynamic>{};

    map.forEach((key, value) {
      if (value is! Map) return;
      final itemMap = Map<String, dynamic>.from(value);
      final adds = (itemMap['additions'] as List? ?? const []).where((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return (int.tryParse('${m['id'] ?? 0}') ?? 0) != componentId;
      }).toList();
      final rems = (itemMap['removals'] as List? ?? const []).where((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return (int.tryParse('${m['id'] ?? 0}') ?? 0) != componentId;
      }).toList();
      patched[key] = {'additions': adds, 'removals': rems};
    });

    _box.write(_bindingsKey, patched);
  }

  Future<void> loadItemsAndComponents({bool force = false}) async {
    if (_branchId <= 0) {
      items.clear();
      additions.clear();
      removals.clear();
      return;
    }

    isBusy.value = true;
    try {
      final rItems = await _api.get(Env.itemsSimpleList);
      if (rItems is Map && rItems['ok'] == true) {
        final list = (rItems['items'] as List? ?? const [])
            .map((e) => SimpleRef.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        items.assignAll(list);
        _saveItemsCache(list);
      }

      final rComps = await _api.get(Env.componentsList);
      final raw = <Map<String, dynamic>>[];
      if (rComps is Map && rComps['ok'] == true) {
        for (final e in (rComps['components'] as List? ?? const [])) {
          final m = Map<String, dynamic>.from(e as Map);
          raw.add({
            'id': int.tryParse('${m['id'] ?? 0}') ?? 0,
            'name': (m['name'] ?? m['name_c'] ?? '').toString(),
            'price': double.tryParse('${m['price'] ?? m['pri'] ?? 0}') ?? 0.0,
          });
        }
      }
      _buildComponentsFromRaw(raw);
      _saveComponentsCache(raw);
    } catch (e) {
      if (kDebugMode) debugPrint('loadItemsAndComponents error: $e');
      Get.snackbar('خطأ', 'تعذّر تحميل الأصناف والمكوّنات');
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> loadItemBinding(SimpleRef item, {bool force = false}) async {
    selectedItem.value = item;
    _resetSelections();
    if (item.id <= 0 || _branchId <= 0) return;

    if (!force) {
      final cached = _getBindingCache(item.id);
      if (cached != null) {
        _applyBinding(
          cached['additions'] as List? ?? const [],
          cached['removals'] as List? ?? const [],
        );
        return;
      }
    }

    isBusy.value = true;
    try {
      dynamic r = await _api.get(
        Env.itemComponentsGet,
        query: {'item_id': '${item.id}'},
      );
      if (r is! Map || r['ok'] != true) {
        r = await _api.post(
          Env.itemComponentsGet,
          body: {'item_id': '${item.id}'},
        );
      }
      if (r is Map && r['ok'] == true) {
        final adds = (r['additions'] as List? ?? const []);
        final rems = (r['removals'] as List? ?? const []);
        _applyBinding(adds, rems);
        _writeBindingCache(item.id, adds, rems);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('loadItemBinding error: $e');
      Get.snackbar('خطأ', 'تعذّر تحميل مكونات هذا الصنف');
    } finally {
      isBusy.value = false;
    }
  }

  void _applyBinding(List adds, List rems) {
    for (final a in additions) {
      final found = _findById(adds, a.id);
      if (found != null) {
        a.selected.value = true;
        a.price.value =
            double.tryParse(
              '${found['price'] ?? found['pri'] ?? a.price.value}',
            ) ??
            a.price.value;
      } else {
        a.selected.value = false;
      }
    }

    for (final r in removals) {
      r.selected.value = _containsId(rems, r.id);
    }
  }

  Future<void> save() async {
    final sel = selectedItem.value;
    if (sel == null || _branchId <= 0) {
      Get.snackbar('تنبيه', 'اختر الفرع والصنف أولاً');
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
        _writeBindingCache(sel.id, adds, rems);
        Get.snackbar('تم', 'تم حفظ الإضافات والإزالات للصنف');
      } else {
        Get.snackbar(
          'خطأ',
          (res is Map && res['message'] != null)
              ? '${res['message']}'
              : 'تعذّر الحفظ',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('save item components error: $e');
      Get.snackbar('خطأ', 'فشل الاتصال بالسيرفر');
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> addNewComponent({
    required String name,
    required double price,
  }) async {
    if (_branchId <= 0) {
      Get.snackbar('تنبيه', 'اختر الفرع أولاً');
      return false;
    }
    isWorkingOnComponent.value = true;
    try {
      final res = await _api.post(
        Env.componentAdd,
        body: {'name': name, 'price': price.toString()},
      );

      if (res is Map && res['ok'] == true) {
        final id = int.tryParse('${res['id'] ?? 0}') ?? 0;
        final actualName = (res['name'] ?? name).toString();
        final actualPrice =
            double.tryParse('${res['price'] ?? price}') ?? price;

        final existingAdd = additions.where((e) => e.id == id).toList();
        if (existingAdd.isEmpty) {
          additions.add(
            ComponentRow(id: id, name: actualName, price: actualPrice),
          );
        }

        final existingRem = removals.where((e) => e.id == id).toList();
        if (existingRem.isEmpty) {
          removals.add(
            ComponentRow(id: id, name: actualName, price: actualPrice),
          );
        }

        _refreshComponentsCacheFromMemory();
        return true;
      }

      if (res is Map && res['message'] != null) {
        Get.snackbar('خطأ', '${res['message']}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('addNewComponent error: $e');
      Get.snackbar('خطأ', 'تعذّرت إضافة المكوّن');
      return false;
    } finally {
      isWorkingOnComponent.value = false;
    }
  }

  Future<bool> updateComponent({
    required int id,
    required String name,
    required double price,
  }) async {
    if (_branchId <= 0 || id <= 0) {
      Get.snackbar('تنبيه', 'اختر الفرع والمكوّن أولاً');
      return false;
    }

    isWorkingOnComponent.value = true;
    try {
      final res = await _api.post(
        Env.componentUpdate,
        body: {'id': '$id', 'name': name.trim(), 'price': price.toString()},
      );

      if (res is Map && res['ok'] == true) {
        final newName = (res['name'] ?? name).toString();
        final newPrice = double.tryParse('${res['price'] ?? price}') ?? price;

        for (final row in additions.where((e) => e.id == id)) {
          row.name.value = newName;
          row.price.value = newPrice;
        }
        for (final row in removals.where((e) => e.id == id)) {
          row.name.value = newName;
          row.price.value = newPrice;
        }

        _refreshComponentsCacheFromMemory();
        return true;
      }

      Get.snackbar(
        'خطأ',
        (res is Map && res['message'] != null)
            ? '${res['message']}'
            : 'تعذر تعديل المكوّن',
      );
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('updateComponent error: $e');
      Get.snackbar('خطأ', 'تعذّر تعديل المكوّن');
      return false;
    } finally {
      isWorkingOnComponent.value = false;
    }
  }

  Future<bool> deleteComponent(int id) async {
    if (_branchId <= 0 || id <= 0) {
      Get.snackbar('تنبيه', 'اختر الفرع والمكوّن أولاً');
      return false;
    }

    isWorkingOnComponent.value = true;
    try {
      final res = await _api.post(Env.componentDelete, body: {'id': '$id'});

      if (res is Map && res['ok'] == true) {
        additions.removeWhere((e) => e.id == id);
        removals.removeWhere((e) => e.id == id);
        _scrubDeletedComponentFromBindingCache(id);
        _refreshComponentsCacheFromMemory();
        return true;
      }

      Get.snackbar(
        'خطأ',
        (res is Map && res['message'] != null)
            ? '${res['message']}'
            : 'تعذر حذف المكوّن',
      );
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('deleteComponent error: $e');
      Get.snackbar('خطأ', 'تعذّر حذف المكوّن');
      return false;
    } finally {
      isWorkingOnComponent.value = false;
    }
  }
}
