import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/item_components_controller.dart';

const _brand = Color.fromARGB(255, 112, 56, 30);
const _bg = Color(0xFFF8F8FA);
const _cardB = Color(0xFFE9ECF1);
const _textD = Color(0xFF2B2F36);
const _textM = Color(0xFF60636B);
const _textL = Color(0xFF9AA0A6);
const _danger = Color(0xFFC0392B);

class ItemComponentsView extends StatelessWidget {
  const ItemComponentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ItemComponentsController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Obx(
            () => Text(
              c.selectedItem.value == null
                  ? 'مكونات الأصناف'
                  : 'إدارة مكونات الصنف',
              style: const TextStyle(
                color: _textD,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          iconTheme: const IconThemeData(color: _textD),
          leading: Obx(() {
            if (c.selectedItem.value == null) {
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Get.back(),
              );
            }
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                c.selectedItem.value = null;
              },
            );
          }),
          actions: [
            Obx(() {
              if (c.selectedItem.value == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: TextButton.icon(
                  onPressed: c.isSaving.value ? null : c.save,
                  icon: const Icon(Icons.save_outlined, color: _brand),
                  label: const Text(
                    'حفظ',
                    style: TextStyle(
                      color: _brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        floatingActionButton: Obx(() {
          if (c.selectedItem.value == null) {
            return FloatingActionButton.extended(
              onPressed: c.isWorkingOnComponent.value
                  ? null
                  : () => _showAddComponentDialog(context, c),
              backgroundColor: _brand,
              foregroundColor: Colors.white,
              icon: c.isWorkingOnComponent.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: const Text('مكوّن جديد'),
            );
          }
          return const SizedBox.shrink();
        }),
        body: Obx(() {
          if (c.isBusy.value && c.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (c.selectedItem.value == null) {
            return _ItemsBrowser(controller: c);
          }

          return _ItemComponentsEditor(controller: c);
        }),
      ),
    );
  }

  static Future<void> _showAddComponentDialog(
    BuildContext context,
    ItemComponentsController c,
  ) async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('إضافة مكوّن جديد'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم المكوّن',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'السعر الابتدائي',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            ),
          ),
          Obx(
            () => ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _brand),
              onPressed: c.isWorkingOnComponent.value
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final price =
                          double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                      if (name.isEmpty) {
                        Get.snackbar('تنبيه', 'أدخل اسم المكوّن');
                        return;
                      }
                      final ok = await c.addNewComponent(
                        name: name,
                        price: price,
                      );
                      if (ok) {
                        Get.snackbar('تم', 'تمت إضافة المكوّن');
                        Navigator.pop(context);
                      }
                    },
              icon: c.isWorkingOnComponent.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.white),
              label: Text(
                c.isWorkingOnComponent.value ? 'جاري الحفظ...' : 'حفظ',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsBrowser extends StatelessWidget {
  const _ItemsBrowser({required this.controller});

  final ItemComponentsController controller;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.loadItemsAndComponents,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          const _TopIntroCard(),
          const SizedBox(height: 14),
          _CardWrap(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ابحث عن الصنف ثم افتحه لاختيار الإضافات والإزالات الخاصة به.',
                  style: TextStyle(color: _textM, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => controller.itemSearch.value = v.trim(),
                  decoration: const InputDecoration(
                    hintText: 'بحث بالاسم أو رقم الصنف...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Row(
                    children: [
                      _MiniStatChip(
                        label: 'الأصناف',
                        value: '${controller.items.length}',
                        icon: Icons.inventory_2_outlined,
                      ),
                      const SizedBox(width: 8),
                      _MiniStatChip(
                        label: 'المكوّنات',
                        value:
                            '${controller.additions.length > controller.removals.length ? controller.additions.length : controller.removals.length}',
                        icon: Icons.tune_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _SectionHeader(
            title: 'قائمة الأصناف',
            icon: Icons.restaurant_menu_outlined,
          ),
          const SizedBox(height: 10),
          Obx(() {
            final list = controller.filteredItems;
            if (list.isEmpty) {
              return const _EmptyCard(message: 'لا توجد أصناف مطابقة');
            }
            return Column(
              children: list.map((it) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ItemTile(
                    item: it,
                    onTap: () async {
                      await controller.loadItemBinding(it, force: true);
                    },
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _ItemComponentsEditor extends StatelessWidget {
  const _ItemComponentsEditor({required this.controller});

  final ItemComponentsController controller;

  @override
  Widget build(BuildContext context) {
    final item = controller.selectedItem.value!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardWrap(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _brand.withOpacity(.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.fastfood_rounded, color: _brand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _textD,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${item.id}',
                        style: const TextStyle(fontSize: 12, color: _textL),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await controller.loadItemBinding(item, force: true);
                  },
                  icon: const Icon(Icons.refresh_rounded, color: _brand),
                  label: const Text('تحديث', style: TextStyle(color: _brand)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionHeader(
            title: 'إدارة المكوّنات',
            icon: Icons.tune_rounded,
            trailing: Obx(
              () => controller.isWorkingOnComponent.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 10),
          _CardWrap(
            child: Row(
              children: [
                Expanded(
                  child: _SearchField(
                    hint: 'بحث في الإضافات (+)',
                    onChanged: (s) => controller.searchAdd.value = s.trim(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SearchField(
                    hint: 'بحث في الإزالات (-)',
                    onChanged: (s) => controller.searchRem.value = s.trim(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ComponentList(
            title: 'الإضافات',
            subtitle:
                'فعّل العناصر التي تريد إضافتها للصنف، ويمكنك تعديل الاسم والسعر أو حذف المكوّن.',
            rows: controller.filteredAdditions,
            showPrice: true,
            controller: controller,
          ),
          const SizedBox(height: 14),
          _ComponentList(
            title: 'الإزالات',
            subtitle:
                'فعّل العناصر التي يمكن للزبون إزالتها من الصنف، ويمكنك تعديل اسم المكوّن أو حذفه.',
            rows: controller.filteredRemovals,
            showPrice: false,
            controller: controller,
          ),
        ],
      ),
    );
  }
}

class _TopIntroCard extends StatelessWidget {
  const _TopIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _brand.withOpacity(.95),
            const Color.fromARGB(255, 145, 82, 45),
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مكونات الأصناف',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'الصفحة تعرض الأصناف أولاً، وبعد فتح أي صنف تستطيع تحديد الإضافات والإزالات الخاصة به بشكل واضح ومنظم.',
            style: TextStyle(
              color: Color(0xFFF9EDE8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.onTap});

  final SimpleRef item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardB),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${item.id}',
                  style: const TextStyle(
                    color: _textM,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textD,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'اضغط للدخول واختيار الإضافات والإزالات',
                      style: TextStyle(fontSize: 12, color: _textL),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _brand.withOpacity(.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _brand,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  const _MiniStatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardB),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _brand),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: _textL),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _textD,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _CardWrap(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(color: _textL, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _textM),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _textM,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CardWrap extends StatelessWidget {
  const _CardWrap({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardB),
      ),
      child: child,
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ComponentList extends StatelessWidget {
  const _ComponentList({
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.showPrice,
    required this.controller,
  });

  final String title;
  final String subtitle;
  final List<ComponentRow> rows;
  final bool showPrice;
  final ItemComponentsController controller;

  @override
  Widget build(BuildContext context) {
    return _CardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _textD,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: _textL),
                    ),
                  ],
                ),
              ),
              Obx(() {
                final active = rows.where((r) => r.selected.value).length;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active > 0
                        ? _brand.withOpacity(.08)
                        : const Color(0xFFF1F3F7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'المفعّل: $active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: active > 0 ? _brand : _textL,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text('لا توجد بيانات', style: TextStyle(color: _textL)),
              ),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final row = rows[i];
                return Obx(() {
                  final isOn = row.selected.value;
                  final price = row.price.value;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => row.selected.value = !isOn,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isOn
                              ? const Color(0xFFFFD9C8)
                              : const Color(0xFFE7EAF0),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x11000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isOn,
                            onChanged: (v) => row.selected.value = v ?? false,
                            activeColor: _brand,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.name.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _textD,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  showPrice
                                      ? '${price % 1 == 0 ? price.toInt() : price} د.ل'
                                      : 'السعر الحالي: ${price % 1 == 0 ? price.toInt() : price} د.ل',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOn ? _textM : _textL,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: controller.isWorkingOnComponent.value
                                ? null
                                : () => _showEditComponentSheet(
                                    context,
                                    controller,
                                    row,
                                  ),
                            icon: const Icon(Icons.edit_rounded, color: _brand),
                            tooltip: 'تعديل المكوّن',
                          ),
                          IconButton(
                            onPressed: controller.isWorkingOnComponent.value
                                ? null
                                : () =>
                                      _confirmDelete(context, controller, row),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: _danger,
                            ),
                            tooltip: 'حذف المكوّن',
                          ),
                        ],
                      ),
                    ),
                  );
                });
              },
            ),
        ],
      ),
    );
  }

  static Future<void> _showEditComponentSheet(
    BuildContext context,
    ItemComponentsController controller,
    ComponentRow row,
  ) async {
    final nameCtrl = TextEditingController(text: row.name.value);
    final priceCtrl = TextEditingController(
      text:
          (row.price.value % 1 == 0
                  ? row.price.value.toInt().toString()
                  : row.price.value.toString())
              .trim(),
    );

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E4EA),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'تعديل المكوّن',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم المكوّن',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'السعر',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: _brand),
                    onPressed: controller.isWorkingOnComponent.value
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final price =
                                double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                            if (name.isEmpty) {
                              Get.snackbar('تنبيه', 'أدخل اسم المكوّن');
                              return;
                            }
                            final ok = await controller.updateComponent(
                              id: row.id,
                              name: name,
                              price: price,
                            );
                            if (ok) {
                              Get.snackbar('تم', 'تم تعديل المكوّن');
                              Navigator.pop(ctx);
                            }
                          },
                    icon: controller.isWorkingOnComponent.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, color: Colors.white),
                    label: Text(
                      controller.isWorkingOnComponent.value
                          ? 'جاري الحفظ...'
                          : 'حفظ التعديل',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    ItemComponentsController controller,
    ComponentRow row,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المكوّن'),
        content: Text('هل أنت متأكد من حذف المكوّن "${row.name.value}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            ),
          ),
          Obx(
            () => ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _danger),
              onPressed: controller.isWorkingOnComponent.value
                  ? null
                  : () async {
                      final done = await controller.deleteComponent(row.id);
                      if (done) {
                        Navigator.pop(context, true);
                      }
                    },
              icon: controller.isWorkingOnComponent.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_outline, color: Colors.white),
              label: Text(
                controller.isWorkingOnComponent.value ? 'جاري الحذف...' : 'حذف',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      Get.snackbar('تم', 'تم حذف المكوّن');
    }
  }
}
