import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/receiver_items_controller.dart';
import '../../data/models/item_model.dart';

class ReceiverItemsView extends GetView<ReceiverItemsController> {
  const ReceiverItemsView({super.key});

  static const brown = Color(0xFF6F3F17);
  static const pageBg = Color(0xFFF3F0ED);

  /// حالة تنفيذ زر (تشغيل/إيقاف جميع الأصناف)
  static final RxBool _bulkBusy = false.obs;

  @override
  Widget build(BuildContext context) {
    // تأكيد تسجيل الكونترولر لو ما تمّ ببايندينغ
    Get.put<ReceiverItemsController>(
      ReceiverItemsController(),
      permanent: false,
    );

    final pad = MediaQuery.of(context).padding;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: brown,
          title: const Text('أصناف اليوم'),
          centerTitle: true,
        ),
        body: Obx(() {
          // حالات التحميل وعدم وجود أصناف
          if (controller.loading.value && controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.items.isEmpty) {
            return const Center(child: Text('لا توجد أصناف'));
          }

          final hasAnyActive = controller.items.any(
            (it) => it.isActive == true,
          );
          final busy = _bulkBusy.value;

          final byCategory = controller.itemsByCategory;
          final gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.62,
          );

          return RefreshIndicator(
            onRefresh: () => controller.fetchItems(force: true),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, pad.bottom + 12),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      // زر تشغيل/إيقاف جميع الأصناف
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      _bulkBusy.value = true;
                                      try {
                                        final target = !hasAnyActive;
                                        for (final it in controller.items) {
                                          if (it.isActive != target) {
                                            await controller.toggleItem(
                                              it,
                                              target,
                                            );
                                          }
                                        }
                                      } finally {
                                        _bulkBusy.value = false;
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasAnyActive
                                    ? Colors.red.shade600
                                    : brown,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      hasAnyActive
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                    ),
                              label: Text(
                                hasAnyActive
                                    ? 'إيقاف جميع الأصناف'
                                    : 'تشغيل جميع الأصناف',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // أقسام: كل قسم = عنوان + زر إغلاق/فتح القسم + شبكة الأصناف
                      ...byCategory.entries
                          .map((e) {
                            final categoryId = e.key;
                            final list = e.value;
                            final catName =
                                controller.categoryNames[categoryId] ??
                                (categoryId == 0
                                    ? 'بدون قسم'
                                    : 'قسم #$categoryId');
                            final sectionHasActive = list.any(
                              (it) => it.isActive,
                            );
                            return [
                              SliverToBoxAdapter(
                                child: _SectionHeader(
                                  title: catName,
                                  itemCount: list.length,
                                  hasAnyActive: sectionHasActive,
                                  busy: busy,
                                  onToggleSection: () async {
                                    _bulkBusy.value = true;
                                    try {
                                      await controller.toggleCategory(
                                        categoryId,
                                        !sectionHasActive,
                                      );
                                    } finally {
                                      _bulkBusy.value = false;
                                    }
                                  },
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.only(bottom: 16),
                                sliver: SliverGrid(
                                  gridDelegate: gridDelegate,
                                  delegate: SliverChildBuilderDelegate((_, i) {
                                    final it = list[i];
                                    return _ItemCard(
                                      it: it,
                                      onToggle: (v) =>
                                          controller.toggleItem(it, v),
                                      onEditQuota: () =>
                                          _showQuotaDialog(context, it),
                                    );
                                  }, childCount: list.length),
                                ),
                              ),
                            ];
                          })
                          .expand((e) => e),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _showQuotaDialog(BuildContext context, ItemModel it) async {
    final ctrl = TextEditingController(text: it.dailyQuota?.toString() ?? '');
    final res = await showDialog<int?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تحديد الكمية اليومية'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'اتركه فارغاً لإلغاء الحد اليومي',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.isEmpty) {
                Navigator.pop(context, null);
              } else {
                Navigator.pop(context, int.tryParse(t) ?? 0);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    await controller.setDailyQuota(it, res);
  }
}

/* --------- رأس قسم (اسم القسم + إغلاق/فتح القسم كاملاً) --------- */
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.itemCount,
    required this.hasAnyActive,
    required this.busy,
    required this.onToggleSection,
  });

  final String title;
  final int itemCount;
  final bool hasAnyActive;
  final bool busy;
  final VoidCallback onToggleSection;

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: brown.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: brown.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.category_outlined, color: brown, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF3D2914),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '($itemCount صنف)',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: hasAnyActive ? Colors.red.shade50 : brown.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: busy ? null : onToggleSection,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: brown,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasAnyActive
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18,
                            color: hasAnyActive ? Colors.red.shade700 : brown,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hasAnyActive ? 'إغلاق القسم' : 'فتح القسم',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: hasAnyActive ? Colors.red.shade700 : brown,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* --------- بطاقة الصنف --------- */
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.it,
    required this.onToggle,
    required this.onEditQuota,
  });

  final ItemModel it;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEditQuota;

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    final remain = it.remaining;
    final quota = it.dailyQuota;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الصف العلوي: السعر + المفتاح
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: brown,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${it.price.toStringAsFixed(0)} د.ل',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Transform.scale(
                scale: 0.9,
                child: Switch.adaptive(
                  value: it.isActive,
                  onChanged: onToggle,
                  activeColor: brown,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // الصورة
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: it.imageUrl.isEmpty
                  ? _empty()
                  : Image.network(
                      it.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _empty(),
                    ),
            ),
          ),

          const SizedBox(height: 8),

          // الاسم
          Text(
            it.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: 2),

          // الوصف
          Text(
            it.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54, fontSize: 11.5),
          ),

          const SizedBox(height: 6),

          // سطر التحكم بالكمية اليومية
          InkWell(
            onTap: onEditQuota,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_calendar_outlined,
                    size: 18,
                    color: brown,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quota == null
                          ? 'بدون حدّ يومي'
                          : 'الحد: $quota • المتبقّي: ${remain ?? (quota - it.quotaUsed)}',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: brown,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _empty() => Container(
    color: const Color(0xFFF2EFEA),
    alignment: Alignment.center,
    child: const Icon(
      Icons.image_not_supported_outlined,
      color: Color(0xFFB88969),
      size: 36,
    ),
  );
}
