import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/data/models/staff_model.dart';
import '../../controllers/admin_profile_controller.dart';
import '../../controllers/AuthController.dart'; // لو عندك AuthController موجود

class GeneralInfoView extends GetView<AdminProfileController> {
  const GeneralInfoView({super.key});

  static const primary = Color(0xFFB85A1B);
  static const pageBg = Color(0xFFF7F7F9);

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;

    // لو عندك AuthController وتريد تعيين الادمن منه بدل fetch:
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      if (controller.admin.value == null && auth.admin.value != null) {
        // <-- التحويل هنا
        controller.admin.value = StaffModel.fromAdminUser(auth.admin.value);
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: primary,
          title: const Text('معلومات عامة'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Obx(() {
            final adm = controller.admin.value;
            if (controller.loading.value && adm == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (adm == null) {
              return Center(
                child: Text(
                  'لم تُحمّل بيانات الأدمن',
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }

            return ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, pad.bottom + 16),
              children: [
                // بطاقة البيانات
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // CircleAvatar(
                      //   radius: 36,
                      //   backgroundColor: const Color(0xFFF2EFEA),
                      //   backgroundImage: adm.avatarUrl.isEmpty ? null : NetworkImage(adm.avatarUrl),
                      //   child: adm.avatarUrl.isEmpty ? Icon(Icons.person, color: primary, size: 32) : null,
                      // ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              adm.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              adm.phone,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2EFEA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                adm.role,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // تغيير كلمة السر
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'تغيير كلمة السر',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller.curPassCtrl,
                        obscureText: true,
                        decoration: _dec('كلمة السر الحالية'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller.newPassCtrl,
                        obscureText: true,
                        decoration: _dec('كلمة السر الجديدة'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller.confirmPassCtrl,
                        obscureText: true,
                        decoration: _dec('تأكيد كلمة السر الجديدة'),
                      ),
                      const SizedBox(height: 12),
                      Obx(
                        () => ElevatedButton(
                          onPressed: controller.saving.value
                              ? null
                              : controller.changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: controller.saving.value
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'حفظ التغييرات',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF2EFEA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
