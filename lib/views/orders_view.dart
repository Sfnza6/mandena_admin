import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/orders_controller.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/order_model.dart';

class OrdersView extends StatelessWidget {
  const OrdersView({super.key});

  static const primary = Color(0xFFB85A1B);
  static const pageBg = Color(0xFFF7F7F9);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(OrdersController());
    final pad = MediaQuery.of(context).padding;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: primary,
          title: const Text(
            'سجل الطلبات',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [const SizedBox(width: 4)],
        ),
        body: Column(
          children: [
            _SearchAndTabs(controller: c),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                final list = c.filtered;
                if (c.loading.value && list.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (list.isEmpty) {
                  return const Center(child: Text('لا توجد طلبات'));
                }
                return RefreshIndicator(
                  onRefresh: c.fetch,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, pad.bottom + 12),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final o = list[i];
                      return _OrderCard(order: o);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------- شريط البحث + التبويبات -------------------- */

class _SearchAndTabs extends StatelessWidget {
  const _SearchAndTabs({required this.controller});
  final OrdersController controller;

  static const primary = Color(0xFFB85A1B);

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      'الكل',
      'قيد الانتظار',
      'قيد التحضير',
      'قيد التوصيل',
      'ملغاة',
      'مكتملة',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            onChanged: controller.setSearch,
            decoration: InputDecoration(
              hintText:
                  'ابحث برقم الطلب / اسم المستخدم / الهاتف / العنوان / السائق',
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

          if (controller.canFilterBranches)
            Obx(() {
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: controller.branchFilterValue,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: [
                        const DropdownMenuItem<int>(
                          value: 0,
                          child: Text(
                            'كل الفروع',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...controller.branches.map(
                          (BranchModel b) => DropdownMenuItem<int>(
                            value: b.id,
                            child: Text(
                              b.name.trim().isNotEmpty
                                  ? b.name
                                  : 'فرع #${b.id}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => controller.setBranchFilter(v ?? 0),
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(height: 10),

          Obx(() {
            final sel = controller.filterIndex.value;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: List.generate(tabs.length, (i) {
                  final active = i == sel;
                  return Padding(
                    padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 8),
                    child: ChoiceChip(
                      selected: active,
                      onSelected: (_) => controller.setFilter(i),
                      label: Text(tabs[i]),
                      selectedColor: Colors.white,
                      labelStyle: TextStyle(
                        color: active ? primary : Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      backgroundColor: const Color.fromARGB(255, 145, 58, 0),
                      side: BorderSide.none,
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/* -------------------- كارت الطلب (عرض فقط) -------------------- */

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderModel order;

  static const primary = Color(0xFFB85A1B);

  Color _statusColor(String s) {
    return switch (s) {
      'pending' => Colors.orange,
      'processing' => Colors.blue,
      'assigned' => Colors.teal,
      'cancelled' => Colors.red,
      'success' => Colors.green,
      'delivered' => Colors.green,
      _ => Colors.grey,
    };
  }

  String _statusText(String s) {
    return switch (s) {
      'pending' => 'قيد الانتظار',
      'processing' => 'قيد التحضير',
      'assigned' => 'قيد التوصيل',
      'cancelled' => 'ملغاة',
      'success' => 'مكتملة',
      'delivered' => 'مكتملة',
      _ => s,
    };
  }

  @override
  Widget build(BuildContext context) {
    final userLabel = (order.userName != null && order.userName!.isNotEmpty)
        ? order.userName!
        : 'مستخدم #${order.userId}';

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
          // رأس البطاقة
          Row(
            children: [
              Text(
                '#${order.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withOpacity(.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusText(order.status),
                  style: TextStyle(
                    color: _statusColor(order.status),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // المستخدم + السائق
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  userLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if ((order.userPhone ?? '').isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  order.userPhone!,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ],
          ),

          if (order.address.isNotEmpty) ...[
            const SizedBox(height: 4),
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
                    maxLines: 1,
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
                  color: primary,
                ),
              ),
              const Spacer(),
              Text(
                order.createdAt,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
