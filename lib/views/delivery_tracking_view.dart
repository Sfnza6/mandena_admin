import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/delivery_tracking_controller.dart';

class DeliveryTrackingView extends GetView<DeliveryTrackingController> {
  const DeliveryTrackingView({super.key});

  static const Color primary = Color(0xFFB85A1B);
  static const Color pageBg = Color(0xFFF7F5F3);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<DeliveryTrackingController>()) {
      Get.put(DeliveryTrackingController());
    }

    final DeliveryTrackingController c = Get.find<DeliveryTrackingController>();
    final pad = MediaQuery.of(context).padding;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          title: const Text('تتبع التوصيل'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => c.fetch(force: true),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            _Header(controller: c),
            Expanded(
              child: Obx(() {
                final bool isLoading = c.loading.value;
                final String errorText = c.error.value;
                final List<Map<String, dynamic>> list = c.filteredOrders;

                if (isLoading && c.orders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (errorText.isNotEmpty && c.orders.isEmpty) {
                  return _EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'تعذر تحميل التتبع',
                    subtitle: errorText,
                    onRefresh: () => c.fetch(force: true),
                  );
                }

                if (list.isEmpty) {
                  return _EmptyState(
                    icon: Icons.route_outlined,
                    title: 'لا توجد طلبات في هذا التصنيف',
                    subtitle: 'غيّر الفلتر أو اسحب لتحديث الصفحة.',
                    onRefresh: () => c.fetch(force: true),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => c.fetch(force: true),
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(12, 10, 12, pad.bottom + 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _TrackingCard(row: list[i], controller: c),
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

class _Header extends StatelessWidget {
  const _Header({required this.controller});
  final DeliveryTrackingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: DeliveryTrackingView.primary,
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
              hintText: 'بحث برقم الطلب / الزبون / الهاتف / السائق / العنوان',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: Obx(() {
              final selectedStatus = controller.status.value;
              final tabs = controller.filters;

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t = tabs[i];
                  final selected = selectedStatus == t.key;

                  return ChoiceChip(
                    label: Text(t.value),
                    selected: selected,
                    onSelected: (_) => controller.setStatus(t.key),
                    selectedColor: Colors.white,
                    backgroundColor: const Color.fromARGB(
                      255,
                      223,
                      223,
                      223,
                    ).withOpacity(.18),
                    labelStyle: TextStyle(
                      color: selected
                          ? DeliveryTrackingView.primary
                          : const Color.fromARGB(255, 199, 105, 16),
                      fontWeight: FontWeight.w800,
                    ),
                    side: BorderSide(color: Colors.white.withOpacity(.30)),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({required this.row, required this.controller});

  final Map<String, dynamic> row;
  final DeliveryTrackingController controller;

  bool _hasValue(dynamic v) {
    final s = '$v'.trim();
    return s.isNotEmpty && s != 'null';
  }

  @override
  Widget build(BuildContext context) {
    final orderId = int.tryParse('${row['order_id'] ?? row['id'] ?? 0}') ?? 0;
    final statusRaw = '${row['status'] ?? ''}';
    final driverName = row['driver_name'];
    final offerStatus = row['offer_status'];
    final expiresAt = row['offer_expires_at'] ?? row['driver_offer_expires_at'];
    final distance = row['driver_distance_km'] ?? row['distance_km'];

    final statusText = controller.displayStatus(row);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: DeliveryTrackingView.primary.withOpacity(.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'طلبية #$orderId',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(text: statusText, row: row, controller: controller),
            ],
          ),
          const SizedBox(height: 10),
          _InfoLine(
            icon: Icons.storefront_outlined,
            text: 'الفرع: ${row['branch_name'] ?? '-'}',
          ),
          _InfoLine(
            icon: Icons.person_outline_rounded,
            text:
                'الزبون: ${row['user_name'] ?? '-'} | ${row['user_phone'] ?? '-'}',
          ),
          _InfoLine(
            icon: Icons.location_on_outlined,
            text: 'العنوان: ${row['address'] ?? '-'}',
          ),
          _InfoLine(
            icon: Icons.payments_outlined,
            text: 'الإجمالي: ${row['total'] ?? '0'} د.ل',
          ),
          const Divider(height: 22),
          if (_hasValue(driverName)) ...[
            _InfoLine(
              icon: Icons.delivery_dining_outlined,
              text: 'السائق: $driverName | ${row['driver_phone'] ?? '-'}',
            ),
            if (_hasValue(row['is_online']))
              _InfoLine(
                icon: Icons.wifi_tethering_rounded,
                text:
                    'متصل: ${('${row['is_online']}' == '1') ? 'نعم' : 'لا'} | آخر تحديث: ${row['driver_location_updated_at'] ?? row['last_seen'] ?? '-'}',
              ),
          ] else ...[
            const _InfoLine(
              icon: Icons.delivery_dining_outlined,
              text: 'السائق: لم يتم التعيين بعد',
            ),
          ],
          if (_hasValue(offerStatus))
            _InfoLine(
              icon: Icons.timer_outlined,
              text:
                  'حالة العرض: ${controller.offerArabic(offerStatus)} | ينتهي: ${_hasValue(expiresAt) ? expiresAt : '-'}',
            ),
          if (_hasValue(distance))
            _InfoLine(
              icon: Icons.route_outlined,
              text: 'بعد السائق عن الفرع: $distance كم',
            ),
          if (statusRaw == 'processing') ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DeliveryTrackingView.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: orderId <= 0
                    ? null
                    : () => controller.markReady(orderId),
                icon: const Icon(Icons.route_outlined),
                label: const Text('تجهيز للتوصيل والبحث عن أقرب سائق'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: DeliveryTrackingView.primary.withOpacity(.78),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.text,
    required this.row,
    required this.controller,
  });

  final String text;
  final Map<String, dynamic> row;
  final DeliveryTrackingController controller;

  Color get _color {
    if (controller.isDelivered(row)) return Colors.green.shade700;
    if (controller.isDelivering(row)) return Colors.blue.shade700;
    if (controller.isSearchingDriver(row)) return Colors.orange.shade700;

    final status = '${row['status'] ?? ''}'.toLowerCase().trim();
    switch (status) {
      case 'processing':
        return Colors.orange.shade700;
      case 'cancelled':
      case 'rejected':
        return Colors.red.shade700;
      default:
        return DeliveryTrackingView.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
        children: [
          Icon(icon, size: 58, color: Colors.black38),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
