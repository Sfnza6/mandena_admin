import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'payment_settings_controller.dart';

const _brown = Color(0xFF6F3F17);

class PaymentSettingsPage extends StatelessWidget {
  const PaymentSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(PaymentSettingsController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إعدادات الدفع',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
          centerTitle: true,
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        ),
        body: Obx(() {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                activeThumbColor: _brown,
                title: const Text('تفعيل الدفع الإلكتروني في تطبيق المستخدم'),
                value: c.onlineEnabled.value,
                onChanged: (v) => c.onlineEnabled.value = v,
              ),
              const Divider(),

              SwitchListTile(
                activeThumbColor: _brown,
                title: const Text('مصرفي باي (الجمهورية)'),
                value: c.masrafyEnabled.value,
                onChanged: c.onlineEnabled.value
                    ? (v) => c.masrafyEnabled.value = v
                    : null,
              ),
              SwitchListTile(
                activeThumbColor: _brown,
                title: const Text('يسر أونلاين (التجاري)'),
                value: c.yesserEnabled.value,
                onChanged: c.onlineEnabled.value
                    ? (v) => c.yesserEnabled.value = v
                    : null,
              ),
              SwitchListTile(
                activeThumbColor: _brown,
                title: const Text('صحاري باي (الصحاري)'),
                value: c.sahariEnabled.value,
                onChanged: c.onlineEnabled.value
                    ? (v) => c.sahariEnabled.value = v
                    : null,
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: c.isLoading.value
                      ? null
                      : () async {
                          final ok = await c.save();
                          if (ok) {
                            Get.snackbar(
                              'تم',
                              'تم حفظ الإعدادات بنجاح',
                              backgroundColor: const Color(0xFF065F46),
                              colorText: Colors.white,
                            );
                          } else {
                            Get.snackbar(
                              'خطأ',
                              'تعذر حفظ الإعدادات',
                              backgroundColor: const Color(0xFF1F2937),
                              colorText: Colors.white,
                            );
                          }
                        },
                  icon: c.isLoading.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'حفظ',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'عند إطفاء الدفع الإلكتروني سيظهر للمستخدم خيار "نقدًا" فقط.',
                style: TextStyle(
                  color: Colors.black.withOpacity(.55),
                  fontSize: 12.5,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
