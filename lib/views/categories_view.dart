import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/views/admin_branch_scope_controller.dart';

import '../../controllers/categories_controller.dart';
import '../../controllers/items_controller.dart';
import '../../data/models/category_model.dart';
import '../../data/models/item_model.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  static const brown = Color(0xFF6F3F17);
  static const pageBg = Color(0xFFF3F0ED);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(CategoriesController());
    final pad = MediaQuery.of(context).padding;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        body: SafeArea(
          child: Column(
            children: [
              _Header(controller: c),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: AdminBranchScopeBar(),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: Obx(() {
                  final cats = c.filtered.toList();
                  if (c.loading.value && cats.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (cats.isEmpty) {
                    return const Center(child: Text('لا توجد أقسام'));
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(12, 6, 12, pad.bottom + 90),
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final CategoryModel cat = cats[i];
                      final count = c.itemCountByCatId[cat.id] ?? 0;
                      final imgUrl = CategoriesController.normalizeImageUrl(
                        cat.image,
                      );

                      return _CategoryCard(
                        title: cat.name,
                        imageUrl: imgUrl,
                        itemCount: count,
                        onTap: () =>
                            Get.to(() => CategoryItemsView(category: cat)),
                        onEdit: () => c.editCategory(cat),
                        onDelete: () => c.confirmDeleteCategory(cat),
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
            backgroundColor: brown,
            elevation: 4,
            onPressed: () =>
                Get.find<CategoriesController>().showAddCategorySheet(),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

/* ====================== الهيدر ====================== */
class _Header extends StatelessWidget {
  const _Header({required this.controller});
  final CategoriesController controller;

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: brown,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Row(
        children: [
          _roundIcon(icon: Icons.arrow_back_ios_new_rounded, onTap: Get.back),

          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller.searchCtrl,
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

/* ====================== كارت القسم ====================== */
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.imageUrl,
    required this.itemCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String imageUrl;
  final int itemCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            // صورة + أزرار الإجراء
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgFallback(),
                        )
                      : _imgFallback(),
                ),

                // أيقونات تعديل/حذف
                PositionedDirectional(
                  top: 8,
                  start: 8,
                  child: Row(
                    children: [
                      _actionIcon(
                        icon: Icons.delete_outline,
                        bg: const Color(0xFFFFEFEE),
                        color: Colors.red,
                        onTap: onDelete,
                      ),
                      const SizedBox(width: 8),
                      _actionIcon(
                        icon: Icons.edit_outlined,
                        bg: const Color(0xFFF7F4F0),
                        color: brown,
                        onTap: onEdit,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // معلومات القسم
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              alignment: Alignment.centerRight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.menu_rounded,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$itemCount صنف',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _actionIcon({
    required IconData icon,
    required Color bg,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _imgFallback() {
    return Container(
      color: const Color(0xFFF2EFEA),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.image_outlined, color: Color(0xFFB88969)),
          SizedBox(height: 6),
          Text('لا توجد صورة', style: TextStyle(color: Color(0xFFB88969))),
        ],
      ),
    );
  }
}

/* ====================== صفحة أصناف القسم ====================== */
class CategoryItemsView extends StatelessWidget {
  const CategoryItemsView({super.key, required this.category});
  final CategoryModel category;

  static const brown = Color(0xFF6F3F17);
  static const pageBg = Color(0xFFF3F0ED);

  @override
  Widget build(BuildContext context) {
    final itemsC = Get.isRegistered<ItemsController>()
        ? Get.find<ItemsController>()
        : Get.put(ItemsController(), permanent: false);

    if (itemsC.items.isEmpty && itemsC.loading.isFalse) {
      itemsC.fetchItems();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: brown,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            category.name,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Obx(() {
          final list = itemsC.items
              .where((e) => e.categoryId == category.id)
              .toList();

          if (itemsC.loading.value && list.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (list.isEmpty) {
            return const Center(child: Text('لا توجد أصناف في هذا القسم'));
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.57,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final ItemModel it = list[i];
              final imgUrl = CategoriesController.normalizeImageUrl(
                it.imageUrl,
              );

              return _ItemCardMini(
                title: it.name,
                imageUrl: imgUrl,
                price: it.price,
                subtitle: it.description,
              );
            },
          );
        }),
      ),
    );
  }
}

/// كارت مبسّط لعرض صنف داخل صفحة القسم
class _ItemCardMini extends StatelessWidget {
  const _ItemCardMini({
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.subtitle,
  });

  final String title, imageUrl, subtitle;
  final double price;

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
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
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // السعر كبادج
          Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: const EdgeInsets.only(top: 8, right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: brown,
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

          // الصورة
          AspectRatio(
            aspectRatio: 4 / 3,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(),
                  )
                : _fallback(),
          ),
          const SizedBox(height: 6),

          // العنوان والوصف
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
    color: const Color(0xFFF2EFEA),
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(
          Icons.image_not_supported_outlined,
          size: 28,
          color: Color(0xFFB88969),
        ),
        SizedBox(height: 6),
        Text(
          'لا توجد صورة',
          style: TextStyle(color: Color(0xFFB88969), fontSize: 12),
        ),
      ],
    ),
  );
}

/* ====================== BottomSheet إضافة قسم (لو احتجته) ====================== */
// ignore: unused_element
class _CategoryFormSheet extends StatelessWidget {
  const _CategoryFormSheet({required this.controller});
  final CategoriesController controller;

  static const brown = Color(0xFF6F3F17);

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
              color: brown,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Text(
              'إضافة قسم جديد',
              style: TextStyle(
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
              child: Column(
                children: [
                  _field(controller.nameCtrl, hint: 'اسم القسم'),
                  const SizedBox(height: 12),

                  // صورة من المعرض مع معاينة
                  GestureDetector(
                    onTap: controller.pickImageFromGallery,
                    child: Obx(() {
                      final localPath = controller.imagePath.value;
                      final netUrl = CategoriesController.normalizeImageUrl(
                        controller.currentImageUrl.value,
                      );

                      Widget child;
                      if (localPath.isNotEmpty &&
                          controller.imageFile != null) {
                        child = Image.file(
                          controller.imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      } else if (netUrl.isNotEmpty) {
                        child = Image.network(
                          netUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => _emptyImageBox(),
                        );
                      } else {
                        child = _emptyImageBox();
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
                    child: Obx(
                      () => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brown,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: controller.saving.value
                            ? null
                            : () async {
                                final ok = await controller.saveNewCategory();
                                if (ok) {
                                  Get.back(
                                    closeOverlays: true,
                                  ); // ← اغلاق تلقائي
                                }
                              },
                        child: controller.saving.value
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _emptyImageBox() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 36,
          color: Color(0xFFB88969),
        ),
        SizedBox(height: 8),
        Text('اختر صورة من المعرض', style: TextStyle(color: Color(0xFFB88969))),
      ],
    );
  }

  static Widget _field(TextEditingController ctrl, {required String hint}) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF2EFEA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
