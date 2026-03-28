// lib/views/receiver/receiver_assign_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/drivers_controller.dart';
import '../../data/models/order_model.dart';

class ReceiverAssignPage extends StatelessWidget {
  const ReceiverAssignPage({super.key});

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    // نحتاج فقط الكنترولر الخاص بالسائقين لأنه مسؤول عن API "المكلّفة"
    final driversC = Get.isRegistered<DriversController>()
        ? Get.find<DriversController>()
        : Get.put(DriversController(), permanent: false);

    // تحميل أولي لقائمة الطلبات المكلّفة
    if (driversC.assignedOrders.isEmpty && driversC.assignedLoading.isFalse) {
      driversC.fetchAssignedOrders();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F0ED),
        appBar: AppBar(
          backgroundColor: brown,
          title: const Text(
            'الطلبات المكلفة',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: driversC.fetchAssignedOrders,
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Obx(() {
          final list = driversC.assignedOrders;

          if (driversC.assignedLoading.value && list.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: driversC.fetchAssignedOrders,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 120),
                children: const [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 56,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Center(child: Text('لا توجد طلبات مكلفة حتى الآن')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: driversC.fetchAssignedOrders,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _AssignedOrderCard(order: list[i]),
            ),
          );
        }),
      ),
    );
  }
}

/* ==================== كارت الطلب المكلّف ==================== */

class _AssignedOrderCard extends StatelessWidget {
  const _AssignedOrderCard({required this.order});
  final OrderModel order;

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    final driverName = (order.driverName ?? '').trim();
    final driverPhone = (order.driverPhone ?? '').trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // العنوان
          Row(
            children: [
              Text(
                '#${order.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: brown,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'مكلف',
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // معلومات السائق
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: Colors.black54,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  driverName.isEmpty ? '—' : 'السائق: $driverName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (driverPhone.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.phone_outlined,
                  size: 18,
                  color: Colors.black54,
                ),
                const SizedBox(width: 6),
                Text(driverPhone),
              ],
            ],
          ),

          // العنوان
          if (order.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.black54,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.address,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 18,
                color: Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                '${order.total.toStringAsFixed(2)} د.ل',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: brown,
                ),
              ),
              const Spacer(),
              Text(
                order.statusOrder == 'pickup' ? 'استلام ذاتي' : 'توصيل',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
