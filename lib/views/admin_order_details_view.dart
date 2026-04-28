import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/controllers/admin_order_details_controller.dart';

class AdminOrderDetailsView extends GetView<AdminOrderDetailsController> {
  const AdminOrderDetailsView({super.key});

  static const primary = Color(0xFFB85A1B);
  static const cardBg = Color(0xFFFFFCFA);
  static const soft = Color(0xFFF3ECE6);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AdminOrderDetailsController>()) {
      Get.put(AdminOrderDetailsController());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F3),
        appBar: AppBar(
          title: const Text('تفاصيل الطلب'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: .2,
        ),
        body: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final h = controller.header.value;
          if (h == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('لا توجد بيانات لهذا الطلب'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: controller.fetch,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final customer = controller.customer.value;
          final branch = controller.branch.value;
          final driver = controller.driver.value;

          return RefreshIndicator(
            onRefresh: controller.fetch,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _heroCard(h, branch),
                const SizedBox(height: 14),
                _sectionCard(
                  title: 'بيانات العميل',
                  icon: Icons.person_outline_rounded,
                  child: Column(
                    children: [
                      _infoRow(
                        'الاسم',
                        customer?.name.isNotEmpty == true
                            ? customer!.name
                            : 'غير متوفر',
                      ),
                      _infoRow(
                        'الهاتف',
                        customer?.phone.isNotEmpty == true
                            ? customer!.phone
                            : 'غير متوفر',
                      ),
                      _infoRow(
                        'العنوان',
                        h.address.trim().isNotEmpty
                            ? h.address.trim()
                            : (customer?.address.isNotEmpty == true
                                  ? customer!.address
                                  : 'غير متوفر'),
                        multiLine: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  title: 'بيانات الطلب',
                  icon: Icons.receipt_long_outlined,
                  child: Column(
                    children: [
                      _infoRow('رقم الطلب', '#${h.id}'),
                      _infoRow('حالة الطلب', controller.statusArabic(h.status)),
                      _infoRow(
                        'نوع الطلب',
                        controller.orderTypeArabic(h.statusOrder),
                      ),
                      _infoRow('التاريخ', h.createdAt),
                      _infoRow(
                        'الفرع',
                        branch?.name.isNotEmpty == true
                            ? branch!.name
                            : 'غير متوفر',
                      ),
                      _infoRow(
                        'عنوان الفرع',
                        branch?.address.isNotEmpty == true
                            ? branch!.address
                            : 'غير متوفر',
                        multiLine: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  title: 'معلومات الدفع',
                  icon: Icons.account_balance_wallet_outlined,
                  child: Column(
                    children: [
                      _infoRow(
                        'طريقة الدفع',
                        controller.paymentMethodArabic(h),
                      ),
                      if (h.gateway.trim().isNotEmpty &&
                          h.gateway.toLowerCase() != 'cash')
                        _infoRow(
                          'بوابة الدفع',
                          controller.gatewayArabic(h.gateway),
                        ),
                    ],
                  ),
                ),
                if (driver != null) ...[
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'السائق',
                    icon: Icons.local_shipping_outlined,
                    child: Column(
                      children: [
                        _infoRow(
                          'الاسم',
                          (driver['name'] ?? 'غير متوفر').toString(),
                        ),
                        _infoRow(
                          'الهاتف',
                          (driver['phone'] ?? 'غير متوفر').toString(),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.only(right: 4, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'الأصناف',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                ...controller.items.map(_itemCard),
                const SizedBox(height: 8),
                _totalsCard(h),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _heroCard(AdminOrderHeaderModel h, AdminOrderBranchModel? branch) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primary.withOpacity(.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: primary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary.withOpacity(.18)),
                ),
                child: Text(
                  controller.statusArabic(h.status),
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'ملف الطلب',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#${h.id}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                Icons.storefront_outlined,
                branch?.name.isNotEmpty == true ? branch!.name : 'غير متوفر',
              ),
              _pill(
                Icons.delivery_dining_outlined,
                controller.orderTypeArabic(h.statusOrder),
              ),
              _pill(Icons.schedule_rounded, h.createdAt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withOpacity(.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(fontSize: 12.5, height: 1.2)),
          const SizedBox(width: 6),
          Icon(icon, size: 16, color: primary),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primary.withOpacity(.10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool multiLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: multiLine
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black54, fontSize: 14.5),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15.2,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(AdminOrderItemModel it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الإجمالي',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${it.lineTotalWithExtras.toStringAsFixed(2)} د.ل',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      it.name,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${it.quantity} × ${it.price.toStringAsFixed(2)} د.ل',
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (it.extras.isNotEmpty) ...[
            const SizedBox(height: 12),
            _subTitle('الإضافات'),
            ...it.extras.map(
              (e) => _detailLine(
                '• ${e.name}',
                '${e.quantity} × ${e.price.toStringAsFixed(2)} د.ل',
              ),
            ),
          ],
          if (it.componentsAdd.isNotEmpty) ...[
            const SizedBox(height: 10),
            _subTitle('المكوّنات المضافة'),
            ...it.componentsAdd.map(
              (c) => _detailLine(
                '• ${c.name}',
                '${c.quantity} × ${c.price.toStringAsFixed(2)} د.ل',
              ),
            ),
          ],
          if (it.componentsRem.isNotEmpty) ...[
            const SizedBox(height: 10),
            _subTitle('المكوّنات المحذوفة'),
            ...it.componentsRem.map(
              (c) => _detailLine(
                '• ${c.name.trim().isNotEmpty ? c.name : '—'}',
                'محذوف',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _subTitle(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(fontWeight: FontWeight.w700, color: primary),
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _totalsCard(AdminOrderHeaderModel h) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primary.withOpacity(.12)),
      ),
      child: Column(
        children: [
          _moneyRow('سعر الطلبية', controller.itemsBaseTotal),
          _moneyRow('سعر الإضافات والمكوّنات', controller.extrasAndAddsTotal),
          _moneyRow('سعر التوصيل', h.deliveryFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _moneyRow(
            'الإجمالي النهائي',
            controller.computedGrandTotal,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
      fontSize: bold ? 17 : 15,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: style.copyWith(
                color: bold ? Colors.black87 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${value.toStringAsFixed(2)} د.ل', style: style),
        ],
      ),
    );
  }
}
