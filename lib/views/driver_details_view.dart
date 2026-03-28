import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/driver_details_controller.dart';
import '../../data/models/order_model.dart';

class DriverDetailsView extends GetView<DriverDetailsController> {
  const DriverDetailsView({super.key});

  static const brown = Color(0xFF6F3F17);
  static const pageBg = Color(0xFFF3F0ED);

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
                nameRx: controller.name,
                phoneRx: controller.phone,
                createdAtRx: controller.createdAt,
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                // child: _StatsCard(countRx: controller.orders.length.obs),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: Obx(() {
                  if (controller.loading.value && controller.orders.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.orders.isEmpty) {
                    return const Center(
                      child: Text('لا توجد طلبات مكلّفة لهذا السائق'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => controller.fetchAssignedOrders(),
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(12, 8, 12, pad.bottom + 16),
                      itemCount: controller.orders.length,
                      itemBuilder: (_, i) =>
                          _OrderTile(order: controller.orders[i]),
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
}

/* ---------------- Header ---------------- */
class _Header extends StatelessWidget {
  const _Header({
    required this.nameRx,
    required this.phoneRx,
    required this.createdAtRx,
  });

  final RxString nameRx;
  final RxString phoneRx;
  final RxString createdAtRx;

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: const BoxDecoration(
        color: brown,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Row(
        children: [
          _roundIcon(icon: Icons.arrow_back_ios_new_rounded, onTap: Get.back),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              final name = nameRx.value.isEmpty ? '...' : nameRx.value;
              final phone = phoneRx.value.isEmpty ? '—' : phoneRx.value;
              final created = createdAtRx.value.isEmpty
                  ? ''
                  : createdAtRx.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(phone, style: const TextStyle(color: Colors.white70)),
                  if (created.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'منذ: $created',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFEEDFD2),
            child: Icon(Icons.delivery_dining, color: brown),
          ),
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

/* ---------------- إحصائية صغيرة ---------------- */
// class _StatsCard extends StatelessWidget {
//   const _StatsCard({required this.countRx});
//   final RxInt countRx;

//   static const brown = Color(0xFF6F3F17);

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       return Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(.06),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             const Icon(Icons.assignment_ind, color: brown),
//             const SizedBox(width: 10),
//             const Text(
//               'طلبات مكلّفة',
//               style: TextStyle(fontWeight: FontWeight.w900),
//             ),
//             const Spacer(),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//               decoration: BoxDecoration(
//                 color: brown,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Text(
//                 '${countRx.value}',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }
// }

/* ---------------- عنصر الطلب ---------------- */
class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final OrderModel order;

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    final status = order.status;

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
              color: _statusColor(status),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.id}  •  ${_statusText(status)}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'الإجمالي: ${order.total.toStringAsFixed(1)} د.ل'
                  '  •  ${order.createdAt}',
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

  // 🟤 ترجمة الحالة للعربي
  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'جاري التحضير';
      case 'assigned':
        return 'مكلّف بالتوصيل';
      case 'delivering':
      case 'out_for_delivery':
        return 'جاري التوصيل';
      case 'delivered':
      case 'success':
        return 'تم التسليم';
      case 'cancelled':
      case 'canceled':
        return 'ملغي';
      default:
        return status; // لو حالة جديدة ما عرفناها
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.amber;
      case 'processing':
      case 'assigned':
        return Colors.orange;
      case 'delivering':
      case 'out_for_delivery':
        return Colors.blue;
      case 'delivered':
      case 'success':
        return Colors.green;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      default:
        return brown;
    }
  }
}
