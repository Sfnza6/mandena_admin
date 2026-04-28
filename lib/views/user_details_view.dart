import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_details_controller.dart';
import '../../data/models/order_model.dart';

class UserDetailsView extends GetView<UserDetailsController> {
  const UserDetailsView({super.key});

  static const primary = Color(0xFFB85A1B);
  static const pageBg = Color(0xFFF7F7F9);

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
              _Header(
                name: controller.name,
                phone: controller.phone,
                isBanned: controller.isBanned,
                onToggleBan: () async {
                  await _confirmToggleBan(context, controller);
                },
              ),
              const SizedBox(height: 12),

              // كرت إحصائية + حالة التقييد
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _StatsCard(ordersRx: controller.orders)),
                    const SizedBox(width: 10),
                    _BanBadge(isBanned: controller.isBanned),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: Obx(() {
                  if (controller.loading.value && controller.orders.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.orders.isEmpty) {
                    return const Center(
                      child: Text('لا توجد طلبات لهذا المستخدم'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => controller.fetchUserOrders(),
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(12, 8, 12, pad.bottom + 16),
                      itemCount: controller.orders.length,
                      itemBuilder: (_, i) {
                        final OrderModel o = controller.orders[i];
                        return _OrderTile(
                          order: o,
                          statusAr: controller.statusArabic(o.status),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// حوار تأكيد + إدخال سبب عند التقييد
  Future<void> _confirmToggleBan(
    BuildContext context,
    UserDetailsController c,
  ) async {
    final bannedNow = c.isBanned.value;

    if (!bannedNow) {
      // تقييد: اعرض إدخال سبب (اختياري)
      final reasonCtrl = TextEditingController();
      final res = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(
            'تأكيد التقييد',
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('هل تريد تقييد هذا المستخدم؟'),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'سبب التقييد (اختياري)',
                  border: OutlineInputBorder(),
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'تقييد',
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
            ),
          ],
        ),
      );
      if (res == true) {
        await c.toggleBan(reason: reasonCtrl.text.trim());
      }
    } else {
      // إلغاء تقييد: تأكيد بسيط
      final res = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('إلغاء التقييد'),
          content: const Text('هل تريد إلغاء تقييد هذا المستخدم؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );
      if (res == true) {
        await c.toggleBan();
      }
    }
  }
}

/* ---------------- Header ---------------- */
class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.phone,
    required this.isBanned,
    required this.onToggleBan,
  });
  final RxString name;
  final RxString phone;
  final RxBool isBanned;
  final VoidCallback onToggleBan;

  static const primary = Color(0xFFB85A1B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: const BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Row(
        children: [
          _roundIcon(icon: Icons.arrow_back_ios_new_rounded, onTap: Get.back),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.value.isEmpty ? '...' : name.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phone.value.isEmpty ? '—' : phone.value,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              );
            }),
          ),
          Obx(() {
            final banned = isBanned.value;
            return ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: banned ? Colors.red : Colors.white,
                foregroundColor: banned ? Colors.white : primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onToggleBan,
              icon: Icon(banned ? Icons.lock_open_rounded : Icons.lock_rounded),
              label: Text(banned ? 'إلغاء التقييد' : 'تقييد'),
            );
          }),
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

/* ---------------- بادج التقييد ---------------- */
class _BanBadge extends StatelessWidget {
  const _BanBadge({required this.isBanned});
  final RxBool isBanned;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final banned = isBanned.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: banned
              ? Colors.red.withOpacity(.1)
              : Colors.green.withOpacity(.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: banned ? Colors.red : Colors.green),
        ),
        child: Row(
          children: [
            Icon(
              banned ? Icons.block : Icons.verified_user,
              color: banned ? Colors.red : Colors.green,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              banned ? 'مقَيَّد' : 'نشِط',
              style: TextStyle(
                color: banned ? Colors.red : Colors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    });
  }
}

/* ---------------- إحصائية صغيرة ---------------- */
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.ordersRx});
  final RxList<OrderModel> ordersRx;

  static const primary = Color(0xFFB85A1B);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = ordersRx.length;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long, color: primary),
            const SizedBox(width: 10),
            const Text(
              'سجل الطلبات',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/* ---------------- عنصر الطلب ---------------- */
class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.statusAr});
  final OrderModel order;
  final String statusAr;

  static const primary = Color(0xFFB85A1B);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 44,
            decoration: BoxDecoration(
              color: _statusColor(order.status),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.id}  •  $statusAr',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'الإجمالي: ${order.total.toStringAsFixed(1)} د.ل  •  ${order.createdAt}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.amber;
      case 'accepted':
      case 'processing':
      case 'preparing':
        return const Color(0xFFB85A1B);
      case 'assigned':
      case 'onway':
      case 'delivering':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'canceled':
      case 'rejected':
        return Colors.red;
      default:
        return primary;
    }
  }
}
