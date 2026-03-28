import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/controllers/admin_order_details_controller.dart';

class AdminOrderDetailsView extends GetView<AdminOrderDetailsController> {
  const AdminOrderDetailsView({super.key});

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    // تأكيد تسجيل الكنترولر
    if (!Get.isRegistered<AdminOrderDetailsController>()) {
      Get.put(AdminOrderDetailsController());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الطلب'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.4,
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

          final d = controller.driver.value;

          return RefreshIndicator(
            onRefresh: controller.fetch,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                // رقم الطلب + شارة الحالة
                Row(
                  children: [
                    Text(
                      '#${h.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: brown.withOpacity(.08),
                        border: Border.all(color: brown.withOpacity(.25)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        h.status,
                        style: const TextStyle(color: brown),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'نوع التوصيل: ${controller.deliveryTypeArabic(h.statusOrder)}',
                  style: const TextStyle(color: Colors.black54),
                ),
                if (h.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'العنوان: ${h.address}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'التاريخ: ${h.createdAt}',
                  style: const TextStyle(color: Colors.black45),
                ),

                // ✅ 🧾 معلومات الدفع (من نفس بيانات اليوزر)
                const SizedBox(height: 8),
                _buildPaymentInfoAdmin(h),

                const SizedBox(height: 12),
                const Divider(),

                const SizedBox(height: 10),
                const Text(
                  'الأصناف',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),

                ...controller.items.map(
                  (it) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F2EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // السطر الرئيسي للصنف
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'الكمية: ${it.quantity} × ${it.price.toStringAsFixed(2)} د.ل',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              (it.lineTotalWithExtras > 0
                                      ? it.lineTotalWithExtras
                                      : it.lineTotal)
                                  .toStringAsFixed(2),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('د.ل'),
                          ],
                        ),

                        // الإضافات
                        if (it.extras.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'الإضافات',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          ...it.extras.map(
                            (ex) => Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '• ${ex.name} (${ex.quantity} × ${ex.price.toStringAsFixed(2)} د.ل)',
                                  ),
                                ),
                                Text(ex.lineTotal.toStringAsFixed(2)),
                                const SizedBox(width: 4),
                                const Text('د.ل'),
                              ],
                            ),
                          ),
                        ],

                        // المكوّنات المُضافة
                        if (it.componentsAdd.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'المكوّنات المُضافة',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          ...it.componentsAdd.map(
                            (c) => Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '• ${c.name} (${c.quantity} × ${c.price.toStringAsFixed(2)} د.ل)',
                                  ),
                                ),
                                Text((c.price * c.quantity).toStringAsFixed(2)),
                                const SizedBox(width: 4),
                                const Text('د.ل'),
                              ],
                            ),
                          ),
                        ],

                        // المكوّنات المحذوفة (بدون سعر)
                        if (it.componentsRem.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'المكوّنات المحذوفة',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          ...it.componentsRem.map((c) {
                            final label = (c.name.trim().isNotEmpty)
                                ? c.name
                                : (c.id > 0 ? '#${c.id}' : '— محذوف —');
                            return Row(
                              children: [Expanded(child: Text('• $label'))],
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),

                const Divider(height: 28),

                // رسوم التوصيل
                Row(
                  children: const [
                    Text(
                      'رسوم التوصيل',
                      style: TextStyle(color: Colors.black54),
                    ),
                    Spacer(),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(),
                    const Spacer(),
                    Text(h.deliveryFee.toStringAsFixed(2)),
                    const SizedBox(width: 4),
                    const Text('د.ل'),
                  ],
                ),
                const SizedBox(height: 8),

                // الإجمالي النهائي
                Row(
                  children: const [
                    Text(
                      'الإجمالي النهائي',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Spacer(),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(),
                    const Spacer(),
                    Text(
                      controller.computedGrandTotal.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('د.ل'),
                  ],
                ),

                // السائق
                if (d != null) ...[
                  const Divider(height: 28),
                  const Text(
                    'السائق',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_pin, color: brown),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (d['name'] ?? '-').toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (d['phone'] ?? '').toString(),
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  /// ✅ كارت بسيط لمعلومات الدفع في لوحة الأدمن
  Widget _buildPaymentInfoAdmin(AdminOrderHeaderModel h) {
    final isOnline =
        h.paymentMethod == 1 ||
        (h.gateway.isNotEmpty && h.gateway.toLowerCase() != 'cash');

    String methodLabel = isOnline ? 'دفع أونلاين' : 'دفع عند الاستلام';

    String bankLabel = 'غير محدد';
    switch (h.gateway.toLowerCase()) {
      case 'yusor':
      case 'yesser':
        bankLabel = 'مصرف الجمهورية – يسر أونلاين';
        break;
      case 'sahari':
        bankLabel = 'مصرف الصحاري';
        break;
      case 'aman':
        bankLabel = 'مصرف الأمان';
        break;
      case 'tadawul':
        bankLabel = 'تداول / بطاقة مصرفية';
        break;
      case 'cash':
      case '':
        bankLabel = isOnline ? 'غير محدد' : '—';
        break;
      default:
        bankLabel = h.gateway;
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات الدفع',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text(
                  'طريقة الدفع: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  methodLabel,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
            if (isOnline) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'المصرف: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Flexible(
                    child: Text(
                      bankLabel,
                      style: const TextStyle(color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
