// lib/views/receiver/receiver_home_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/controllers/ReceiverOrdersController.dart';
import 'package:mandena_admin/views/receiver/receiver_assign_page.dart';
import 'package:mandena_admin/views/receiver/receiver_items_view.dart';
import 'package:mandena_admin/views/receiver/receiver_orders_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/items_controller.dart';
import '../../controllers/AuthController.dart';
import '../../core/routes/app_routes.dart';

class ReceiverHomeView extends StatefulWidget {
  const ReceiverHomeView({super.key});

  @override
  State<ReceiverHomeView> createState() => _ReceiverHomeViewState();
}

class _ReceiverHomeViewState extends State<ReceiverHomeView> {
  static const brown = Color(0xFF6F3F17);
  static const pageBg = Color(0xFFF3F0ED);

  static const _tabCacheKey = 'receiver_home_tab_index';

  int _index = 0;

  final _pages = const [
    ReceiverOrdersView(),
    ReceiverItemsView(),
    ReceiverAssignPage(),
  ];

  @override
  void initState() {
    super.initState();

    // تأكد من وجود الكنترولات
    if (!Get.isRegistered<ReceiverOrdersController>()) {
      Get.put(ReceiverOrdersController(), permanent: false);
    }
    if (!Get.isRegistered<ItemsController>()) {
      Get.put(ItemsController(), permanent: false);
    }

    _restoreLastTab();
  }

  Future<void> _restoreLastTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_tabCacheKey);
      if (saved != null && saved >= 0 && saved < _pages.length && mounted) {
        setState(() => _index = saved);
      }
    } catch (_) {
      // لو صار خطأ في الكاش نتجاهله بهدوء
    }
  }

  Future<void> _saveTab(int i) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_tabCacheKey, i);
    } catch (_) {
      // تجاهل أخطاء التخزين
    }
  }

  void _onTabChanged(int i) {
    if (_index == i) return;
    setState(() => _index = i);
    _saveTab(i);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: brown,
          centerTitle: true,
          elevation: 0,
          title: const Text(
            'مستقبل الطلبات',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              tooltip: 'تسجيل خروج',
              onPressed: () async {
                await auth.logout();
                Get.offAllNamed(Routes.login);
              },
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(index: _index, children: _pages),
        ),
        bottomNavigationBar: _BottomNav(
          current: _index,
          onChanged: _onTabChanged,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.onChanged});

  final int current;
  final ValueChanged<int> onChanged;

  static const brown = Color(0xFF6F3F17);
  static const bg = Colors.white;
  static const indicator = Color(0xFFF3F0ED);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: bg,
            indicatorColor: indicator,
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
              states,
            ) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? brown : Colors.black54,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 22,
                color: selected ? brown : Colors.black54,
              );
            }),
          ),
          child: NavigationBar(
            height: 64,
            selectedIndex: current,
            onDestinationSelected: onChanged,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'الطلبات',
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu),
                label: 'الأصناف',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_shipping_outlined),
                selectedIcon: Icon(Icons.local_shipping),
                label: 'تكليف',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
