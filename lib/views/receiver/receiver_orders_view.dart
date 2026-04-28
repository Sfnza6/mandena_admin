// lib/views/receiver/receiver_orders_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/controllers/ReceiverOrdersController.dart';
import 'package:mandena_admin/views/admin_order_details_view.dart';
// واجهة تفاصيل الطلب

class ReceiverOrdersView extends StatelessWidget {
  const ReceiverOrdersView({super.key});

  /// ألوان الهوية:
  /// اللون المطلوب: 0xFF6F3F17 (بني دافيء)
  static const Color kPrimary = Color(0xFFB85A1B);
  static const Color kBg = Color(0xFFF7F7F9);
  static const Color kCard = Colors.white;

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<ReceiverOrdersController>()
        ? Get.find<ReceiverOrdersController>()
        : Get.put(ReceiverOrdersController());

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
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'تم التجهيز',
                        isSelected: c.orderFilter.value == 'ready_pickup',
                        onTap: () => c.setOrderFilter('ready_pickup'),
                      ),
                    ],
                  ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'طلب #${o.id}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 18,
                                                color: Color(0xFF1F1F1F),
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isPickup
                                                      ? Icons
                                                            .shopping_bag_outlined
                                                      : Icons.delivery_dining,
                                                  size: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  isPickup ? 'استلام' : 'توصيل',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              children: [
                                                _Chip(
                                                  label: badge.label,
                                                  color: badge.color
                                                      .withOpacity(.12),
                                                  borderColor: badge.color
                                                      .withOpacity(.35),
                                                  textColor: badge.color,
                                                ),
                                                if (cachedItems != null)
                                                  _Chip(
                                                    label:
                                                        '${cachedItems.length} عنصر',
                                                    color: Colors.black12,
                                                    textColor: Colors.black87,
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(
                                      right: 4,
                                      top: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (o.address.isNotEmpty)
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    height: 1.35,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 8),
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
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
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
                                          if (o.status == 'pending' ||
                                              o.status == 'processing' ||
                                              o.status == 'ready_pickup') ...[
                                            const SizedBox(height: 10),
                                            if (o.status == 'pending')
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _ActionBtn.outlined(
                                                      label: 'رفض',
                                                      icon: Icons.close_rounded,
                                                      color:
                                                          Colors.red.shade600,
                                                      onTap: () =>
                                                          c.reject(o.id),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: _ActionBtn.filled(
                                                      label: 'موافقة التحضير',
                                                      icon: Icons.check_rounded,
                                                      color: kPrimary,
                                                      onTap: () async {
                                                        await c.approve(o.id);
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else if (o.status == 'ready_pickup')
                                              SizedBox(
                                                width: double.infinity,
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
                                              SizedBox(
                                                width: double.infinity,
                                                child: _ActionBtn.filled(
                                                  label: isPickup
                                                      ? 'تم التجهيز'
                                                      : 'جهز للتوصيل',
                                                  icon: isPickup
                                                      ? Icons
                                                            .inventory_2_outlined
                                                      : Icons.route_outlined,
                                                  color: kPrimary,
                                                  onTap: () async {
                                                    if (isPickup) {
                                                      await c.markReadyPickup(
                                                        o.id,
                                                      );
                                                    } else {
                                                      await c
                                                          .markReadyForDriver(
                                                            o.id,
                                                          );
                                                      await c.fetch(
                                                        silent: true,
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                          ],
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
          borderRadius: BorderRadius.circular(20),
          color: ReceiverOrdersView.kCard,
          border: Border.all(
            color: ReceiverOrdersView.kPrimary.withOpacity(.10),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(20), child: child),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
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
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              height: 1.2,
            ),
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
        return const _Status('معلّق', Color(0xFFB85A1B));
      case 'processing':
        return const _Status('جاري التحضير', ReceiverOrdersView.kPrimary);
      case 'ready_pickup':
        return const _Status('تم التجهيز', Colors.green);
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
