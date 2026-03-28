// lib/views/receiver/receiver_orders_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/controllers/ReceiverOrdersController.dart';
import 'package:mandena_admin/controllers/drivers_controller.dart';
import 'package:mandena_admin/views/admin_order_details_view.dart';
// واجهة تفاصيل الطلب

class ReceiverOrdersView extends StatelessWidget {
  const ReceiverOrdersView({super.key});

  /// ألوان الهوية:
  /// اللون المطلوب: 0xFF6F3F17 (بني دافيء)
  static const Color kPrimary = Color(0xFF6F3F17);
  static const Color kBg = Color(0xFFF3F0ED);
  static const Color kCard = Colors.white;

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<ReceiverOrdersController>()
        ? Get.find<ReceiverOrdersController>()
        : Get.put(ReceiverOrdersController());

    final driversC = Get.isRegistered<DriversController>()
        ? Get.find<DriversController>()
        : Get.put(DriversController());

    // تحميل أولي للسائقين
    if (driversC.drivers.isEmpty && driversC.loading.isFalse) {
      driversC.fetchDrivers();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          titleSpacing: 0,
          title: const Text(
            'الطلبات الواردة',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => c.fetch(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Obx(() {
          final filtered = c.filteredOrders;
          final isLoading = c.loading.value && c.orders.isEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // شريط الفلترة — ظاهر دائماً
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      isSelected: c.orderFilter.value == 'all',
                      onTap: () => c.setOrderFilter('all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'المعلقة',
                      isSelected: c.orderFilter.value == 'pending',
                      onTap: () => c.setOrderFilter('pending'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'جاري التحضير',
                      isSelected: c.orderFilter.value == 'processing',
                      onTap: () => c.setOrderFilter('processing'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : c.orders.isEmpty
                    ? RefreshIndicator(
                        onRefresh: () => c.fetch(),
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: const [
                            SizedBox(height: 60),
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'لا توجد طلبات معلّقة أو قيد التحضير',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'لا توجد طلبات في هذا التصنيف',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => c.fetch(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final o = filtered[i];

                            final v = c.itemsVersion[o.id] ?? 0;
                            final cachedItems = c.itemsCache[o.id];

                            final badge = _Status.badgeFor(o.status);
                            final isPickup = o.statusOrder == 'pickup';

                            return _Card(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.transparent,
                                  splashColor: kPrimary.withOpacity(.06),
                                  highlightColor: kPrimary.withOpacity(.04),
                                ),
                                child: ExpansionTile(
                                  key: PageStorageKey('order_${o.id}'),
                                  maintainState: true,
                                  initiallyExpanded: c.isExpanded(o.id),
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  onExpansionChanged: (opened) {
                                    c.setExpanded(o.id, opened);
                                    if (opened) {
                                      c.loadItems(o.id, force: true);
                                    }
                                  },
                                  title: Row(
                                    children: [
                                      Text(
                                        'طلب #${o.id}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (cachedItems != null)
                                        _Chip(
                                          label: '${cachedItems.length} عنصر',
                                          color: Colors.black12,
                                          textColor: Colors.black87,
                                        ),
                                      const Spacer(),
                                      _Chip(
                                        label: badge.label,
                                        color: badge.color.withOpacity(.12),
                                        borderColor: badge.color.withOpacity(
                                          .35,
                                        ),
                                        textColor: badge.color,
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(
                                      right: 4,
                                      top: 6,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (o.address.isNotEmpty)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on_outlined,
                                                size: 16,
                                                color: Colors.black45,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  o.address,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.delivery_dining,
                                              size: 16,
                                              color: Colors.grey.shade700,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isPickup
                                                  ? 'استلام ذاتي'
                                                  : 'توصيل',
                                              style: const TextStyle(
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${o.total.toStringAsFixed(2)} د.ل',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  children: [
                                    // تفاصيل العناصر
                                    FutureBuilder(
                                      key: ValueKey('fb_${o.id}_$v'),
                                      future: c.loadItems(o.id),
                                      builder: (ctx, snap) {
                                        if (snap.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            child: LinearProgressIndicator(
                                              minHeight: 2,
                                            ),
                                          );
                                        }
                                        final items =
                                            snap.data ??
                                            const <ReceiverOrderItem>[];
                                        if (items.isEmpty) {
                                          return Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.fastfood_outlined,
                                                  color: Colors.black45,
                                                ),
                                                const SizedBox(width: 8),
                                                const Expanded(
                                                  child: Text(
                                                    'لا توجد تفاصيل عناصر لهذا الطلب',
                                                    style: TextStyle(
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: 'تحديث التفاصيل',
                                                  icon: const Icon(
                                                    Icons.refresh_rounded,
                                                  ),
                                                  onPressed: () async {
                                                    await c.loadItems(
                                                      o.id,
                                                      force: true,
                                                    );
                                                    c.itemsVersion[o.id] =
                                                        (c.itemsVersion[o.id] ??
                                                            0) +
                                                        1;
                                                    c.orders.refresh();
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            6,
                                            12,
                                            12,
                                          ),
                                          child: Column(
                                            children: items
                                                .map((it) => _ItemRow(it: it))
                                                .toList(),
                                          ),
                                        );
                                      },
                                    ),

                                    const Divider(height: 1),

                                    // إجراءات الطلب
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        10,
                                        12,
                                        12,
                                      ),
                                      child: Row(
                                        children: [
                                          if (o.status == 'pending') ...[
                                            Expanded(
                                              child: _ActionBtn.outlined(
                                                label: 'رفض',
                                                icon: Icons.close_rounded,
                                                color: Colors.red.shade600,
                                                onTap: () => c.reject(o.id),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _ActionBtn.filled(
                                                label: 'موافقة (تحضير)',
                                                icon: Icons.check_rounded,
                                                color: kPrimary,
                                                onTap: () async {
                                                  await c.approve(o.id);
                                                },
                                              ),
                                            ),
                                          ] else if (o.status ==
                                              'processing') ...[
                                            if (isPickup)
                                              Expanded(
                                                child: _ActionBtn.filled(
                                                  label: 'تم التسليم',
                                                  icon: Icons
                                                      .check_circle_outline_rounded,
                                                  color: Colors.green.shade600,
                                                  onTap: () async {
                                                    await c.markDelivered(o.id);
                                                  },
                                                ),
                                              )
                                            else
                                              Expanded(
                                                child: _ActionBtn.filled(
                                                  label: 'تكليف سائق',
                                                  icon: Icons
                                                      .local_shipping_outlined,
                                                  color: kPrimary,
                                                  onTap: () async {
                                                    final id =
                                                        await _pickDriverSheet(
                                                          driversC,
                                                        );
                                                    if (id == null) return;

                                                    await driversC
                                                        .assignOrderToDriver(
                                                          orderId: o.id,
                                                          driverId: id,
                                                        );

                                                    // ✅ إخفاء الطلب مباشرة من "الطلبات الواردة"
                                                    c.onOrderAssignedExternally(
                                                      o.id,
                                                    );

                                                    Get.snackbar(
                                                      'تم',
                                                      'تم تكليف السائق للطلب #${o.id}',
                                                      snackPosition:
                                                          SnackPosition.BOTTOM,
                                                    );

                                                    // تحديث من السيرفر للتأكيد
                                                    await c.fetch(silent: true);
                                                  },
                                                ),
                                              ),
                                          ],

                                          const SizedBox(width: 10),

                                          // زر تفاصيل الطلب – يظهر دائماً
                                          Expanded(
                                            child: _ActionBtn.outlined(
                                              label: 'تفاصيل الطلب',
                                              icon: Icons.receipt_long_rounded,
                                              color: Colors.grey.shade800,
                                              onTap: () {
                                                Get.to(
                                                  () =>
                                                      const AdminOrderDetailsView(),
                                                  arguments: {
                                                    'orderId': o.id,
                                                    'user_id': o.userId,
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// BottomSheet لاختيار السائق
  Future<int?> _pickDriverSheet(DriversController c) async {
    if (c.loading.isTrue) {
      await c.fetchDrivers();
    }
    return showModalBottomSheet<int>(
      context: Get.context!,
      useSafeArea: true,
      backgroundColor: kCard,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SizedBox(
          height: Get.height * .6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Obx(() {
              if (c.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = c.drivers;
              if (list.isEmpty) {
                return const Center(child: Text('لا يوجد سائقون متاحون'));
              }
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final d = list[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kPrimary.withOpacity(.12),
                      child: Text(
                        d.name.isNotEmpty ? d.name.characters.first : '?',
                        style: const TextStyle(color: kPrimary),
                      ),
                    ),
                    title: Text(
                      d.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(d.phone),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => Get.back(result: d.id),
                  );
                },
              );
            }),
          ),
        );
      },
    );
  }
}

/* -------------------- Widgets مساعدة -------------------- */

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? ReceiverOrdersView.kPrimary.withOpacity(.15)
          : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? ReceiverOrdersView.kPrimary
                  : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
              color: isSelected
                  ? ReceiverOrdersView.kPrimary
                  : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ReceiverOrdersView.kCard,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: ReceiverOrdersView.kCard,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.color,
    this.textColor,
    this.borderColor,
  });

  final String label;
  final Color? color;
  final Color? textColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color ?? Colors.black12,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? Colors.transparent),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.it});
  final ReceiverOrderItem it;

  @override
  Widget build(BuildContext context) {
    // سطور الإضافات
    List<Widget> buildExtrasLines() {
      if (it.extras.isEmpty) return [];
      return [
        const SizedBox(height: 6),
        const Text(
          'الإضافات:',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        const SizedBox(height: 2),
        ...it.extras.map((e) {
          final m = Map<String, dynamic>.from(e);
          final name = (m['name'] ?? m['title'] ?? 'مكوّن إضافي').toString();
          final qty = int.tryParse('${m['quantity'] ?? 1}') ?? 1;
          final price = (m['line_total'] ?? m['price'] ?? '').toString();
          String suffix = '';
          if (price.isNotEmpty && price != '0' && price != '0.0') {
            suffix = ' (+$price)';
          }
          return Text(
            '• $name × $qty$suffix',
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          );
        }),
      ];
    }

    // سطور المكونات المضافة
    List<Widget> buildAddedLines() {
      if (it.componentsAdd.isEmpty) return [];
      return [
        const SizedBox(height: 6),
        const Text(
          'مكوّنات مضافة:',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        const SizedBox(height: 2),
        ...it.componentsAdd.map((e) {
          final m = Map<String, dynamic>.from(e);
          final name = (m['name'] ?? m['title'] ?? 'مكوّن').toString();
          final qty = int.tryParse('${m['quantity'] ?? 1}') ?? 1;
          final price = (m['price'] ?? '').toString();
          String suffix = '';
          if (price.isNotEmpty && price != '0' && price != '0.0') {
            suffix = ' (+$price)';
          }
          return Text(
            '• $name × $qty$suffix',
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          );
        }),
      ];
    }

    // سطور المكونات المحذوفة
    List<Widget> buildRemovedLines() {
      if (it.componentsRem.isEmpty) return [];
      return [
        const SizedBox(height: 6),
        const Text(
          'مكوّنات محذوفة:',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        const SizedBox(height: 2),
        ...it.componentsRem.map((e) {
          final m = Map<String, dynamic>.from(e);
          final name = (m['name'] ?? m['title'] ?? 'مكوّن').toString();
          return Text(
            '• بدون $name',
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          );
        }),
      ];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: ReceiverOrdersView.kPrimary.withOpacity(.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fastfood_outlined,
                color: ReceiverOrdersView.kPrimary.withOpacity(.9),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  it.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '× ${it.quantity}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(width: 10),
              Text(
                it.lineTotal.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 4),
              const Text('د.ل'),
            ],
          ),
          ...buildExtrasLines(),
          ...buildAddedLines(),
          ...buildRemovedLines(),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn._({
    required this.onTap,
    required this.label,
    required this.icon,
    required this.style,
    required this.isFilled,
  });

  /// زر ممتلئ
  factory _ActionBtn.filled({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
    Color color = ReceiverOrdersView.kPrimary,
  }) {
    return _ActionBtn._(
      onTap: onTap,
      label: label,
      icon: icon,
      isFilled: true,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
      ),
    );
  }

  /// زر مفرغ
  factory _ActionBtn.outlined({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
    Color color = Colors.red,
  }) {
    return _ActionBtn._(
      onTap: onTap,
      label: label,
      icon: icon,
      isFilled: false,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final ButtonStyle style;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      ],
    );

    return isFilled
        ? ElevatedButton(onPressed: onTap, style: style, child: child)
        : OutlinedButton(onPressed: onTap, style: style, child: child);
  }
}

class _Status {
  final String label;
  final Color color;

  const _Status(this.label, this.color);

  static _Status badgeFor(String status) {
    switch (status) {
      case 'pending':
        return const _Status('معلّق', Colors.orange);
      case 'processing':
        return const _Status('جاري التحضير', ReceiverOrdersView.kPrimary);
      case 'assigned':
        return const _Status('جاري التوصيل', Colors.teal);
      case 'delivered':
        return const _Status('تم التسليم', Colors.green);
      case 'rejected':
      case 'cancelled':
        return const _Status('مرفوض', Colors.red);
      default:
        return _Status(status, Colors.grey);
    }
  }
}
