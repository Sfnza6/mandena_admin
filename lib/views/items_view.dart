import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/views/admin_branch_scope_controller.dart';
import '../../controllers/items_controller.dart';
import '../../data/models/item_model.dart';
import '../../data/models/category_model.dart';
import '../../core/routes/app_routes.dart'; // 👈 جديد

class ItemsView extends GetView<ItemsController> {
  const ItemsView({super.key});

  static const primary = Color(0xFFB85A1B);
  static const pageBg = Color(0xFFF7F7F9);

  // عدّل هذا ليتوافق مع سيرفرك (نفس BASE_URL في PHP)
  static const String kBaseUrl = 'https://evoranta.ly';

  /// تطبيع رابط الصورة:
  static String normalizeImageUrl(String? raw) {
    var u = (raw ?? '').trim();
    if (u.isEmpty) return '';

    u = u.replaceAll(
      RegExp(
        r'^https?://(localhost|127\.0\.0\.1)(:\d+)?',
        caseSensitive: false,
      ),
      kBaseUrl,
    );

    if (u.startsWith('/')) return '$kBaseUrl$u'.replaceAll(' ', '%20');

    final looksLikeFilename =
        !u.startsWith('http://') &&
        !u.startsWith('https://') &&
        !u.startsWith('/');
    if (looksLikeFilename) {
      if (!u.toLowerCase().contains('uploads/')) {
        return '$kBaseUrl/uploads/$u'.replaceAll(' ', '%20');
      }
      return '$kBaseUrl/$u'.replaceAll(' ', '%20');
    }

    return u.replaceAll(' ', '%20');
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        body: SafeArea(
          child: Column(
            children: [
              _Header(controller: controller),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: AdminBranchScopeBar(),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  final items = controller.filtered.toList();
                  if (controller.loading.value && items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (items.isEmpty) {
                    return const Center(child: Text('لا توجد أصناف'));
                  }

                  final Map<int, String> catNameById = {};
                  for (final CategoryModel c in controller.categories) {
                    catNameById[c.id] = c.name;
                  }

                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, pad.bottom + 90),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          // نسبة ارتفاع/عرض أعلى عشان نكسب ارتفاع للبطاقة
                          childAspectRatio: 0.7,
                        ),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final ItemModel it = items[i];
                      final catName = catNameById[it.categoryId] ?? '';
                      final imgUrl = normalizeImageUrl(it.imageUrl);

                      return _ItemCard(
                        title: it.name,
                        imageUrl: imgUrl,
                        price: it.price,
                        subtitle: it.description,
                        categoryName: catName,
                        // 👇 هنا نفتح صفحة تعليقات الصنف ونمرر itemId الصحيح
                        onView: () {
                          Get.toNamed(Routes.itemComments, arguments: it.id);
                        },
                        onEdit: () => _showEditItemSheet(context, it),
                        onDelete: () => controller.confirmDelete(it),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 16),
          child: FloatingActionButton(
            backgroundColor: primary,
            elevation: 4,
            onPressed: () => _showAddItemSheet(context),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  // ===== BottomSheet (إضافة صنف) =====
  void _showAddItemSheet(BuildContext context) async {
    await controller.fetchCategories(force: true, silentIfNoBranch: true);
    controller.resetForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final viewInsets = MediaPreventOverflow.of(context);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(bottom: viewInsets),
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              maxChildSize: 0.95,
              minChildSize: 0.6,
              builder: (_, __) => _ItemFormSheet(
                title: 'إضافة صنف جديد',
                onSubmit: () async {
                  final ok = await controller.saveNewItem();
                  if (ok) Get.back(closeOverlays: true);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditItemSheet(BuildContext context, ItemModel it) async {
    await controller.fetchCategories(force: true, silentIfNoBranch: true);
    controller.prepareEdit(it);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final viewInsets = MediaPreventOverflow.of(context);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(bottom: viewInsets),
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              maxChildSize: 0.95,
              minChildSize: 0.6,
              builder: (_, __) => _ItemFormSheet(
                title: 'تعديل صنف',
                onSubmit: () async {
                  final ok = await controller.updateItem(it.id);
                  if (ok) Get.back(closeOverlays: true);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// أداة بسيطة لجلب الـviewInsets.bottom بأمان
extension MediaPreventOverflow on MediaQueryData {
  static double of(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom;
}

/* ====================== الهيدر ====================== */
class _Header extends StatelessWidget {
  const _Header({required this.controller});
  final ItemsController controller;

  static const primary = Color(0xFFB85A1B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Row(
        children: [
          _roundIcon(icon: Icons.arrow_back_ios_new_rounded, onTap: Get.back),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller.searchCtrl,
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  static Widget _roundIcon({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.95),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.black87, size: 18),
      ),
    );
  }
}

/* ====================== بطاقة الصنف ====================== */
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.subtitle,
    required this.categoryName,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final String title, imageUrl, subtitle, categoryName;
  final double price;
  final VoidCallback onView, onEdit, onDelete;

  static const primary = Color(0xFFB85A1B);

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
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
            // شارة السعر
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${price.toStringAsFixed(0)} د.ل',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // الصورة مرنة لمنع overflow
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasUrl
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _emptyImageBox(),
                        loadingBuilder: (ctx, child, progress) =>
                            progress == null
                            ? child
                            : const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                      )
                    : _emptyImageBox(),
              ),
            ),
            const SizedBox(height: 8),

            if (categoryName.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EFEA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 6),

            // العنوان والوصف بخط أصغر وسطر واحد لتجنّب الطول الزائد
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 6),

            // الأزرار
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 👇 زر التعليقات (يستخدم onView)
                _iconBtn(
                  icon: Icons.comment_outlined,
                  tooltip: 'تعليقات الصنف',
                  onTap: onView,
                ),
                const SizedBox(width: 8),
                _iconBtn(
                  icon: Icons.edit_outlined,
                  tooltip: 'تعديل',
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                _iconBtn(
                  icon: Icons.delete_outline,
                  tooltip: 'حذف',
                  onTap: onDelete,
                  danger: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _emptyImageBox() {
    return Container(
      color: const Color(0xFFF2EFEA),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.image_not_supported_outlined,
            size: 32,
            color: Color(0xFFB88969),
          ),
          SizedBox(height: 4),
          Text(
            'لا توجد صورة',
            style: TextStyle(color: Color(0xFFB88969), fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  static Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    bool danger = false,
  }) {
    final color = danger ? Colors.red : primary;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: danger ? const Color(0xFFFFEFEE) : const Color(0xFFF7F4F0),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

/* ====================== BottomSheet: النموذج ====================== */
class _ItemFormSheet extends StatelessWidget {
  const _ItemFormSheet({required this.title, required this.onSubmit});
  final String title;
  final VoidCallback onSubmit;

  static const primary = Color(0xFFB85A1B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: GetBuilder<ItemsController>(
                builder: (c) {
                  return Column(
                    children: [
                      _textField(c.nameCtrl, hint: 'اسم الصنف'),
                      const SizedBox(height: 12),
                      _textField(c.descCtrl, hint: 'الوصف', maxLines: 4),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _textField(
                              c.priceCtrl,
                              hint: 'السعر',
                              keyboard: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _textField(
                              c.discountCtrl,
                              hint: 'خصم',
                              keyboard: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InputDecorator(
                        decoration: _fieldDecoration('القسم'),
                        child: Obx(() {
                          final List<CategoryModel> cats = c.categories
                              .toList();
                          return DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: c.selectedCategoryId.value,
                              hint: const Text('اختر قسماً'),
                              items: cats
                                  .map(
                                    (e) => DropdownMenuItem<int>(
                                      value: e.id,
                                      child: Text(e.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => c.selectedCategoryId.value = v,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: c.pickImageFromGallery,
                        child: Obx(() {
                          final localPath = c.imagePath.value;
                          final netUrl = ItemsView.normalizeImageUrl(
                            c.currentImageUrl.value,
                          );

                          Widget child;
                          if (localPath.isNotEmpty && c.imageFile != null) {
                            child = Image.file(
                              c.imageFile!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            );
                          } else if (netUrl.isNotEmpty) {
                            child = Image.network(
                              netUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _ItemCard._emptyImageBox(),
                            );
                          } else {
                            child = _ItemCard._emptyImageBox();
                          }

                          return Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2EFEA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            alignment: Alignment.center,
                            child: child,
                          );
                        }),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: onSubmit,
                          child: Obx(
                            () => Get.find<ItemsController>().saving.value
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'حفظ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ====================== أدوات الحقول ====================== */
InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF2EFEA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(14),
    ),
  );
}

Widget _textField(
  TextEditingController ctrl, {
  required String hint,
  int maxLines = 1,
  TextInputType keyboard = TextInputType.text,
}) {
  return TextField(
    controller: ctrl,
    keyboardType: keyboard,
    maxLines: maxLines,
    decoration: _fieldDecoration(hint),
  );
}
