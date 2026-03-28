import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'delivery_settings_controller.dart';

const _brown = Color(0xFF6F3F17);
const _bg = Color(0xFFF8F3EF); // خلفية ناعمة قريبة من الطلبات

class DeliverySettingsView extends StatelessWidget {
  const DeliverySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GetBuilder<DeliverySettingsController>(
        init: DeliverySettingsController(),
        builder: (c) {
          return Scaffold(
            backgroundColor: _bg,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: _bg,
              foregroundColor: _brown,
              centerTitle: true,
              title: const Text(
                'إعدادات التوصيل',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: _brown,
                ),
              ),
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),

                      // كارد رئيسي بشكل قريب من كروت الطلبات
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.delivery_dining_outlined,
                                    color: _brown,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'سعر التوصيل',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _brown,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'يمكنك التحكم في تكلفة التوصيل حسب المسافة.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 18),

                              const Text(
                                'سعر التوصيل لكل كيلومتر زائد بعد أول 5 كم',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _brown,
                                ),
                              ),
                              const SizedBox(height: 8),

                              Container(
                                decoration: BoxDecoration(
                                  color: _bg.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: TextField(
                                  controller: c.priceCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: false,
                                      ),
                                  decoration: const InputDecoration(
                                    hintText: 'مثال: 10',
                                    border: InputBorder.none,
                                    suffixText: 'د.ل / كم إضافي',
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6),
                              const Text(
                                'ملاحظة: أول 5 كم = 5 د.ل ثابتة، وبعدها يُحسب الكيلومتر بهذا السعر.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.black54,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // سويتش التوصيل المجاني
                              Obx(
                                () => Container(
                                  decoration: BoxDecoration(
                                    color: _bg.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'تفعيل التوصيل المجاني',
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                                color: _brown,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'عند التفعيل يصبح سعر التوصيل 0 لجميع الطلبات.',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: c.freeMode.value,
                                        activeThumbColor: Colors.white,
                                        activeTrackColor: _brown,
                                        onChanged: (val) {
                                          c.freeMode.value = val;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // رسائل حالة (اختيارية)
                      Obx(() {
                        if (c.errorMessage.value.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              c.errorMessage.value,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        if (c.successMessage.value.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              c.successMessage.value,
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),

                // زر حفظ في الأسفل بنفس روح زر "تتبع الطلب"
                Obx(
                  () => Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      decoration: BoxDecoration(
                        color: _bg.withOpacity(0.98),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0, -2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brown,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: c.saving.value ? null : c.save,
                          child: c.saving.value
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'حفظ الإعدادات',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                // لودينغ شفاف عند تحميل البيانات لأول مرة
                Obx(
                  () => c.loading.value
                      ? Container(
                          color: Colors.white.withOpacity(0.6),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.8,
                              valueColor: AlwaysStoppedAnimation<Color>(_brown),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
