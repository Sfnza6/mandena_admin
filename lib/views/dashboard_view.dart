import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/views/widgets/bottom_nav.dart';
import 'package:mandena_admin/views/widgets/header_bar.dart';
import 'package:mandena_admin/views/widgets/most_ordered_list.dart';
import 'package:mandena_admin/views/widgets/side_overlay_menu.dart';
import 'package:mandena_admin/views/widgets/stat_card.dart';
// import 'package:iforenta_admin_2/views/widgets/reviews_carousel.dart';

import '../../controllers/dashboard_controller.dart';
import '../../controllers/AuthController.dart';
import '../../views/admin_branch_scope_controller.dart';

// Widgets مشتركة

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, pad.bottom + 16),
            children: [
              // الشريط العلوي (مطابق للصورة)
              const HeaderBar(),
              const SizedBox(height: 12),

              Obx(() {
                final auth = Get.find<AuthController>();
                if (!auth.isOwner) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: AdminBranchScopeBar(),
                );
              }),

              // بطاقات الإحصائيات من الـ API
              Obx(() {
                final loading = controller.loadingStats.value;
                final s = controller.stats.value;

                final cardWidth =
                    (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2;

                if (loading && s == null) {
                  // هيكل تحميل بسيط
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(
                      4,
                      (_) => Container(
                        width: cardWidth,
                        height: 92,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6E8DD),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  );
                }

                final tiles = [
                  (
                    'عدد السائقين',
                    '${s?.drivers ?? 0}',
                    Icons.delivery_dining_outlined,
                  ),
                  (
                    'عدد الأصناف',
                    '${s?.items ?? 0}',
                    Icons.lunch_dining_outlined,
                  ),
                  (
                    'إجمالي الطلبات',
                    '${s?.orders ?? 0}',
                    Icons.receipt_long_outlined,
                  ),
                  (
                    'إجمالي العملاء',
                    '${s?.customers ?? 0}',
                    Icons.group_outlined,
                  ),
                ];

                return RefreshIndicator(
                  onRefresh: controller.fetchStats,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(tiles.length, (i) {
                      final t = tiles[i];
                      return SizedBox(
                        width: cardWidth,
                        child: StatCard(title: t.$1, value: t.$2, icon: t.$3),
                      );
                    }),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // الأكثر طلبًا (تقدر تربطه لاحقًا بendpoint إن حبيت)
              Obx(() {
                final items = controller.mostOrdered.toList();
                return MostOrderedList(
                  period: controller.period.value,
                  onChange: (i) => controller.period.value = i,
                  items: items,
                );
              }),

              const SizedBox(height: 16),

              // تقييمات العملاء (مافيش جدول تقييمات عندكم؛ خليّناها اختيارية)
              // Obx(() => ReviewsCarousel(reviews: controller.reviews.toList())),
            ],
          ),
        ),

        // الشريط السفلي
        bottomNavigationBar: BottomNav(
          currentIndex: 0, // اليسار = لوحة التحكم
          onOpenMenu: (ctx) => showSideOverlayMenu(ctx),
          onMiddle: () {},
        ),
      ),
    );
  }
}
