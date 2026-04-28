import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/branch_model.dart';
import 'delivery_settings_controller.dart';

const _primary = Color(0xFFB85A1B);
const _bg = Color(0xFFF8F3EF);

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
              foregroundColor: _primary,
              centerTitle: true,
              title: const Text(
                'إعدادات التوصيل',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: _primary,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'تحديث',
                  onPressed: c.loading.value ? null : c.reload,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
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
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.storefront_outlined,
                                    color: _primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      c.selectedBranchId != null &&
                                              c.selectedBranchId! > 0
                                          ? 'إعدادات التوصيل الخاصة بفرع ${c.selectedBranchName}'
                                          : 'اختر الفرع أولاً لتعديل إعدادات التوصيل',
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: _primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (c.canChooseBranch)
                                Obx(() {
                                  final items = c.branches
                                      .map(
                                        (BranchModel b) =>
                                            DropdownMenuItem<int>(
                                              value: b.id,
                                              child: Text(
                                                b.name,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                      )
                                      .toList();

                                  return DropdownButtonFormField<int>(
                                    initialValue: c.selectedBranchId,
                                    isExpanded: true,
                                    items: items,
                                    onChanged: c.loading.value
                                        ? null
                                        : c.changeBranch,
                                    decoration: InputDecoration(
                                      labelText: 'اختر الفرع بالاسم',
                                      labelStyle: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                      filled: true,
                                      fillColor: _bg.withOpacity(0.6),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 14,
                                          ),
                                    ),
                                    dropdownColor: Colors.white,
                                    iconEnabledColor: _primary,
                                  );
                                })
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    color: _bg.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  child: Text(
                                    c.selectedBranchName,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                                    color: _primary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'إعدادات التوصيل الخاصة بالفرع',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'كل فرع له إعدادات مستقلة. تقدر تخلي فرع مجاني وفرع ثاني مدفوع بدون ما يأثر واحد على الثاني.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'سعر كل كيلومتر إضافي بعد أول 5 كم',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _primary,
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
                                    hintText: 'مثال: 1.5',
                                    border: InputBorder.none,
                                    suffixText: 'د.ل / كم إضافي',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'أقصى مسافة للتوصيل لهذا الفرع',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _primary,
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
                                  controller: c.maxDistanceCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: false,
                                      ),
                                  decoration: const InputDecoration(
                                    hintText: 'مثال: 30',
                                    border: InputBorder.none,
                                    suffixText: 'كم',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'أول 5 كم = 5 د.ل ثابتة، وبعدها يُحسب الكيلومتر بهذا السعر. وإذا تجاوزت المسافة الحد الأقصى يُرفض التوصيل.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 20),
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
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'تفعيل التوصيل المجاني',
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                                color: _primary,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'عند التفعيل يصبح سعر التوصيل 0 لجميع الطلبات في هذا الفرع فقط.',
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
                                        activeTrackColor: _primary,
                                        onChanged: (val) =>
                                            c.freeMode.value = val,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: c.saving.value ? null : c.save,
                                  icon: c.saving.value
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save_rounded),
                                  label: Text(
                                    c.saving.value
                                        ? 'جاري الحفظ...'
                                        : 'حفظ الإعدادات',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              if (c.errorMessage.value.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  c.errorMessage.value,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                              if (c.successMessage.value.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  c.successMessage.value,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (c.loading.value)
                  Container(
                    color: Colors.black.withOpacity(0.06),
                    child: const Center(
                      child: CircularProgressIndicator(color: _primary),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
