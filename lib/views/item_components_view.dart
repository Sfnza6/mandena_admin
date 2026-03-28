import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/item_components_controller.dart';

/// ألوان وخطوط
const _brand = Color.fromARGB(255, 112, 56, 30); // لون الهوية
const _bg = Color(0xFFF8F8FA);
const _cardB = Color(0xFFE9ECF1);
const _textD = Color(0xFF2B2F36);
const _textM = Color(0xFF60636B);
const _textL = Color(0xFF9AA0A6);

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
          title: const Text(
            'ربط المكوّنات بالصنف',
            style: TextStyle(color: _textD, fontWeight: FontWeight.w700),
          ),
          iconTheme: const IconThemeData(color: _textD),
        ),

        floatingActionButton: Obx(
          () => FloatingActionButton.extended(
            onPressed: c.isSaving.value ? null : c.save,
            backgroundColor: const Color.fromARGB(255, 112, 60, 36),
            foregroundColor: Colors.white,
            label: const Text('حفظ'),
            icon: const Icon(Icons.save_outlined),
          ),
        ),

        body: Obx(() {
          if (c.isBusy.value && c.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'الصنف',
                    icon: Icons.inventory_2_outlined,
                  ),
                  const SizedBox(height: 10),

                  // ✅ كرت اختيار الصنف مع بحث داخل BottomSheet
                  _CardWrap(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'اختر المنتج الذي تريد إضافة مكوّنات له:',
                          style: TextStyle(
                            fontSize: 13,
                            color: _textM,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _showItemPicker(context, c),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _cardB),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search_rounded,
                                  color: _textM,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Obx(
                                    () => Text(
                                      c.selectedItem.value?.name ??
                                          'اضغط هنا للبحث عن صنف...',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            c.selectedItem.value == null
                                                ? FontWeight.w400
                                                : FontWeight.w600,
                                        color: c.selectedItem.value == null
                                            ? _textL
                                            : _textD,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Obx(
                                  () => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _bg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${c.items.length} صنف',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _textM,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Obx(
                          () => c.selectedItem.value == null
                              ? const SizedBox()
                              : Text(
                                  'ID: ${c.selectedItem.value!.id}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _textL,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'إدارة المكوّنات',
                    icon: Icons.tune_rounded,
                    trailing: _OutlinedIconButton(
                      icon: Icons.add_rounded,
                      label: 'مكوّن جديد',
                      onTap: () => _showAddComponentDialog(context, c),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ بحث عن الإضافات والمحذوفات في سطر بسيط
                  _CardWrap(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _SearchField(
                                hint: 'بحث في الإضافات (+)',
                                onChanged: (s) =>
                                    c.searchAdd.value = s.trim(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SearchField(
                                hint: 'بحث في المحذوفات (-)',
                                onChanged: (s) =>
                                    c.searchRem.value = s.trim(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ✅ قائمة الإضافات مع عدّاد "مفعّل: X"
                  _ComponentList(
                    title: 'مكوّنات إضافية (+)',
                    rows: c.filteredAdditions,
                    showPrice: true,
                  ),
                  const SizedBox(height: 14),

                  // ✅ قائمة المكوّنات التي يمكن حذفها مع عدّاد
                  _ComponentList(
                    title: 'مكوّنات تُحذف من الصنف (-)',
                    rows: c.filteredRemovals,
                    showPrice: false,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Dialog: إضافة مكوّن جديد (الاسم + السعر)
  static Future<void> _showAddComponentDialog(
    BuildContext context,
    ItemComponentsController c,
  ) async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة مكوّن'),
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
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 112, 57, 32),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
              if (name.isEmpty) {
                Get.snackbar('تنبيه', 'أدخل اسم المكوّن');
                return;
              }
              final ok = await c.addNewComponent(name: name, price: price);
              if (ok) {
                Get.snackbar('تم', 'تمت إضافة المكوّن');
                Navigator.pop(context);
              } else {
                Get.snackbar('خطأ', 'تعذّرت الإضافة');
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  /// BottomSheet لاختيار صنف مع بحث عملي
  static Future<void> _showItemPicker(
    BuildContext context,
    ItemComponentsController c,
  ) async {
    c.itemSearch.value = '';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E4EA),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'اختر صنفًا',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (v) => c.itemSearch.value = v.trim(),
                decoration: const InputDecoration(
                  hintText: 'بحث بالاسم أو رقم الصنف...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(
                  () {
                    final list = c.filteredItems;
                    if (list.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد أصناف مطابقة',
                          style: TextStyle(color: _textL),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final it = list[i];
                        final selected =
                            c.selectedItem.value?.id == it.id;
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: selected
                              ? _brand.withOpacity(.06)
                              : Colors.white,
                          leading: CircleAvatar(
                            backgroundColor: _bg,
                            child: Text(
                              '${it.id}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _textM,
                              ),
                            ),
                          ),
                          title: Text(
                            it.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: _brand,
                                )
                              : const Icon(
                                  Icons.radio_button_unchecked,
                                  color: _textL,
                                ),
                          onTap: () async {
                            await c.loadItemBinding(it);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/* -------------------------- Widgets مساعدة -------------------------- */

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
      margin: const EdgeInsets.only(bottom: 4),
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

class _OutlinedIconButton extends StatelessWidget {
  const _OutlinedIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: const Color.fromARGB(255, 112, 61, 37)),
      label: Text(
        label,
        style: const TextStyle(color: Color.fromARGB(255, 112, 65, 43)),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color.fromARGB(255, 112, 66, 45)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/* ===================== قائمة المكوّنات (مع عدّاد مفعّل) ===================== */

class _ComponentList extends StatelessWidget {
  const _ComponentList({
    required this.title,
    required this.rows,
    required this.showPrice,
  });

  final String title;
  final List<ComponentRow> rows;
  final bool showPrice;

  static const _tileRadius = 14.0;
  static const _tilePad = EdgeInsets.symmetric(horizontal: 12, vertical: 10);

  @override
  Widget build(BuildContext context) {
    return _CardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان + عدّاد مفعّل
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textM,
                  ),
                ),
              ),
              Obx(() {
                final active = rows.where((r) => r.selected.value).length;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: active > 0
                        ? _brand.withOpacity(.08)
                        : const Color(0xFFF1F3F7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active > 0
                          ? _brand.withOpacity(.5)
                          : _cardB,
                    ),
                  ),
                  child: Text(
                    'مفعّل: $active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          active > 0 ? FontWeight.w700 : FontWeight.w500,
                      color: active > 0 ? _brand : _textL,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),

          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'لا توجد بيانات',
                  style: TextStyle(color: _textL),
                ),
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
                    borderRadius:
                        BorderRadius.circular(_tileRadius + 4),
                    onTap: () => row.selected.value = !isOn,
                    child: Container(
                      padding: _tilePad,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(_tileRadius),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x11000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: isOn
                              ? const Color(0xFFFFD9C8)
                              : const Color(0xFFE7EAF0),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Checkbox(
                              value: isOn,
                              onChanged: (v) =>
                                  row.selected.value = v ?? false,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              side: const BorderSide(
                                color: Color(0xFFBDC3CA),
                              ),
                              activeColor: const Color.fromARGB(
                                255,
                                112,
                                55,
                                29,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // الاسم والسعر
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  row.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _textD,
                                  ),
                                ),
                                if (showPrice) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${price % 1 == 0 ? price.toInt() : price} د.ل',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isOn ? _textD : _textL,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isOn)
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints:
                                              const BoxConstraints(
                                                minWidth: 32,
                                                minHeight: 32,
                                              ),
                                          iconSize: 18,
                                          onPressed: () =>
                                              _editPrice(context, row),
                                          icon: const Icon(
                                            Icons.edit_rounded,
                                            color: _brand,
                                          ),
                                          tooltip: 'تعديل السعر',
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
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

  /// BottomSheet لتعديل السعر (منع Overflow)
  static Future<void> _editPrice(
      BuildContext context, ComponentRow row) async {
    final controller = TextEditingController(
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
              const SizedBox(height: 6),
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
                  'تعديل سعر الإضافة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '0',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final v =
                        double.tryParse(controller.text.trim()) ?? 0.0;
                    row.price.value = v;
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('تأكيد'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
