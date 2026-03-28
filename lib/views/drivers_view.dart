import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/drivers_controller.dart';
import '../../data/models/driver_model.dart';

class DriversView extends GetView<DriversController> {
  const DriversView({super.key});

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: brown,
          title: const Text('السائقين'),
          centerTitle: true,
          // ✅ شريط البحث
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TextField(
                  controller: controller.searchCtrl,
                  onChanged: controller.onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'بحث بالاسم أو رقم الهاتف أو رقم السائق',
                    hintStyle: TextStyle(fontSize: 13),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Obx(() {
          final List<DriverModel> list = controller.filtered;

          if (controller.loading.value && list.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: controller.fetchDrivers,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('لا يوجد سائقون')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.fetchDrivers,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final d = list[i];
                return _DriverTile(
                  d,
                  onDelete: () => controller.deleteDriver(d),
                );
              },
            ),
          );
        }),

        // زر إضافة سائق جديد (يبقى كما هو)
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 16),
          child: FloatingActionButton(
            backgroundColor: brown,
            onPressed: () => _showAddSheet(context),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    controller.resetForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final inset = MediaQuery.of(context).viewInsets.bottom;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(bottom: inset),
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (_, __) => _AddDriverSheet(
                onSubmit: () async {
                  final ok = await controller.addDriver();
                  if (ok) Get.back();
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/* -------- كرت السائق (بنفس تصميم المستخدم تقريباً) -------- */

class _DriverTile extends StatelessWidget {
  const _DriverTile(this.d, {this.onDelete});

  final DriverModel d;
  final VoidCallback? onDelete;

  static const brown = Color(0xFF6F3F17);

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.assignment_turned_in_outlined,
                    color: brown,
                  ),
                  title: const Text(
                    'الطلبات المكلّف بها حاليًا',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'عرض كل الطلبات الحالية للسائق ${''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Get.back();
                    Get.to(() => DriverAssignedOrdersView(driver: d));
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading:
                      const Icon(Icons.analytics_outlined, color: brown),
                  title: const Text(
                    'اللوحة المالية للسائق',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'تفاصيل الربح، المستحقات، المديونية والإغلاقات',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Get.back();
                    Get.to(() => DriverFinanceView(driver: d));
                  },
                ),
                if (onDelete != null) ...[
                  const Divider(height: 0),
                  ListTile(
                    leading:
                        const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text(
                      'حذف السائق',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                    onTap: () {
                      Get.back();
                      onDelete?.call();
                    },
                  ),
                ],
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String initial = d.name.trim().isNotEmpty
        ? d.name.trim().characters.first
        : 'س';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showOptions(context),
      // حذف عن طريق الضغط المطوّل (مع الحفاظ على التصميم النظيف)
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: brown,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 8),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          leading: const Icon(Icons.chevron_left, color: Colors.white),
          trailing: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Text(
              initial,
              style: const TextStyle(
                color: brown,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          title: Text(
            d.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            d.phone,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

/* -------- BottomSheet (إضافة سائق) -------- */

class _AddDriverSheet extends StatelessWidget {
  const _AddDriverSheet({required this.onSubmit});
  final VoidCallback onSubmit;

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DriversController>();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: brown,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Text(
              'إضافة سائق جديد',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  _field(c.nameCtrl, 'اسم السائق'),
                  const SizedBox(height: 12),
                  _field(c.phoneCtrl, 'الهاتف', keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field(c.passCtrl, 'الرقم السري', obscure: true),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: onSubmit,
                      child: Obx(
                        () => c.saving.value
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'حفظ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decor(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF2EFEA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
      );

  Widget _field(
    TextEditingController c,
    String hint, {
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: _decor(hint),
    );
  }
}

/* -------- شاشة: الطلبات المكلّف بها للسائق -------- */

class DriverAssignedOrdersView extends StatefulWidget {
  const DriverAssignedOrdersView({super.key, required this.driver});
  final DriverModel driver;

  @override
  State<DriverAssignedOrdersView> createState() =>
      _DriverAssignedOrdersViewState();
}

class _DriverAssignedOrdersViewState extends State<DriverAssignedOrdersView> {
  late DriversController c;

  @override
  void initState() {
    super.initState();
    c = Get.find<DriversController>();
    // جلب الطلبات المكلّف بها لهذا السائق
    c.fetchAssignedOrders(driverId: widget.driver.id, force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: DriversView.brown,
          title: Text('طلبات السائق: ${widget.driver.name}'),
          centerTitle: true,
        ),
        body: Obx(() {
          if (c.assignedLoading.value && c.assignedOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (c.assignedOrders.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => c.fetchAssignedOrders(
                  driverId: widget.driver.id, force: true),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('لا توجد طلبات مكلّف بها لهذا السائق')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => c.fetchAssignedOrders(
                driverId: widget.driver.id, force: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: c.assignedOrders.length,
              itemBuilder: (_, i) {
                final o = c.assignedOrders[i];
                // نفترض أن OrderModel يحتوي على id و total على الأقل
                final title = 'طلب #${o.id}';
                final subtitle = 'الإجمالي: ${o.total}';

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text(title),
                    subtitle: Text(subtitle),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

/* -------- شاشة: اللوحة المالية للسائق -------- */

class DriverFinanceView extends StatefulWidget {
  const DriverFinanceView({super.key, required this.driver});
  final DriverModel driver;

  @override
  State<DriverFinanceView> createState() => _DriverFinanceViewState();
}

class _DriverFinanceViewState extends State<DriverFinanceView> {
  late DriversController c;

  @override
  void initState() {
    super.initState();
    c = Get.find<DriversController>();
    c.loadDriverFinance(widget.driver.id);
  }

  Widget _rangeChips() {
    final items = ['all', 'month', 'week', 'today'];
    String labelOf(String r) {
      if (r == 'all') return 'كل الوقت';
      if (r == 'month') return 'هذا الشهر';
      if (r == 'week') return 'هذا الأسبوع';
      return 'اليوم';
    }

    return Obx(
      () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((r) {
              final selected = c.driverFinanceRange.value == r;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text(labelOf(r)),
                  selected: selected,
                  onSelected: (_) =>
                      c.loadDriverFinance(widget.driver.id, range: r),
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  backgroundColor: Colors.transparent,
                  selectedColor: DriversView.brown.withOpacity(.14),
                  labelStyle: TextStyle(
                    color: selected ? Colors.black87 : Colors.grey.shade700,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: selected
                          ? DriversView.brown
                          : Colors.grey.shade300,
                    ),
                  ),
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                  visualDensity:
                      const VisualDensity(horizontal: -2, vertical: -2),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Obx(() {
      final s = c.driverFinanceSummary;
      final today = c.driverFinanceToday;

      final delivered = s['delivered'] ?? 0;
      final rejected = s['rejected'] ?? 0;
      final profitAll = (s['profit_all'] ?? 0).toString();
      final duesToday =
          (s['dues_today'] ?? today['dues_today'] ?? 0).toString();
      final debtToday =
          (s['debt_today'] ?? today['debt_today'] ?? 0).toString();

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ملخّص الأداء',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _chipStat('تم التسليم', '$delivered'),
                  _chipStat('تم الرفض', '$rejected'),
                  _chipStat('الربح الكلي', profitAll),
                  _chipStat('مستحقات اليوم', duesToday),
                  _chipStat('مديونية اليوم', debtToday),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _chipStat(String label, String value) {
    return Chip(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF6F6F8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _closuresSection({
    required String title,
    required RxList<Map<String, dynamic>> source,
  }) {
    return Obx(() {
      final list = source;
      if (list.isEmpty) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '$title\nلا توجد سجلات حتى الآن.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        );
      }

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              ...list.map((row) {
                final date = '${row['closing_date'] ?? ''}';
                final cnt =
                    row['deliveries_count'] ?? row['orders_count'] ?? 0;
                final amount = row['delivery_earnings_total'] ??
                    row['orders_total'] ??
                    0;
                final orders = (row['orders'] ?? []) as List;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: const Color(0xFFF6F6F8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 10),
                    title: Text(
                      '$date — $amount',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'عدد الطلبات: $cnt',
                      style: const TextStyle(fontSize: 12),
                    ),
                    children: orders.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'لا توجد تفاصيل طلبات لهذا الإغلاق',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ]
                        : orders.map((o) {
                            final id = o['id'];
                            final username = o['username'] ?? '';
                            final phone = o['phone'] ?? '';
                            final total = o['total'] ?? 0;
                            final fee = o['delivery_fee'] ?? 0;
                            final due = o['restaurant_due'] ?? 0;
                            return ListTile(
                              dense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              title: Text(
                                '#$id — $username ($phone)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'الإجمالي: $total — عمولة التوصيل: $fee — مديونية المطعم: $due',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          }).toList(),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: DriversView.brown,
          title: Text('اللوحة المالية: ${widget.driver.name}'),
          centerTitle: true,
        ),
        body: Obx(() {
          final loading = c.driverFinanceLoading.value;
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  _rangeChips(),
                  _summaryCard(),
                  const SizedBox(height: 4),
                  _closuresSection(
                    title: 'إغلاقات السائق اليومية (مستحقّات السائق)',
                    source: c.driverFinanceDriverClosures,
                  ),
                  _closuresSection(
                    title: 'إغلاقات المطعم اليومية (مديونية المطعم)',
                    source: c.driverFinanceRestaurantClosures,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
              if (loading)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: CircularProgressIndicator(),
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
