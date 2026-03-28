import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/routes/app_routes.dart';

class BottomNav extends StatelessWidget {
  /// 0 = Dashboard, 1 = وسط (اختياري), 2 = Menu
  final int currentIndex;

  /// يُستدعى عند ضغط زر الوسط (لو تحب تغيّر حالة/يفتح شاشة أخرى)
  final VoidCallback? onMiddle;

  /// فتح القائمة المنسدلة (نمرر ctx من الخارج عشان showGeneralDialog)
  final void Function(BuildContext ctx) onOpenMenu;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onOpenMenu,
    this.onMiddle,
  });

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: brown,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // ✅ اليسار: لوحة التحكم
          // ✅ اليمين: القائمة المنسدلة
          IconButton(
            tooltip: 'القائمة',
            onPressed: () => onOpenMenu(context),
            icon: Icon(
              Icons.menu_rounded,
              color: Colors.white,
              size: currentIndex == 2 ? 28 : 24,
            ),
          ),

          // الوسط (مثلاً مفضلة/مستقبلاً أيقونة ثانية)
          // IconButton(
          //   tooltip: 'الوسط',
          //   onPressed: onMiddle,
          //   icon: Icon(
          //     Icons.star,
          //     color: Colors.white,
          //     size: currentIndex == 1 ? 28 : 24,
          //   ),
          // ),
          IconButton(
            tooltip: 'لوحة التحكم',
            onPressed: () {
              if (currentIndex != 0) {
                Get.offNamed(Routes.dashboard); // رجوع للداشبورد
              }
            },
            icon: Icon(
              Icons.analytics_outlined, // أو Icons.bar_chart_rounded
              color: Colors.white,
              size: currentIndex == 0 ? 28 : 24,
            ),
          ),
        ],
      ),
    );
  }
}
