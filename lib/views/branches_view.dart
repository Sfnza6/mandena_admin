import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/branches_controller.dart';
import '../data/models/branch_model.dart';

class BranchesView extends GetView<BranchesController> {
  const BranchesView({super.key});

  static const brown = Color(0xFF6F3F17);
  static const pageBg = Color(0xFFF3F0ED);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          title: const Text('الفروع'),
          centerTitle: true,
          backgroundColor: brown,
          foregroundColor: Colors.white,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: brown,
          onPressed: _showAddSheet,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.branches.isEmpty) {
            return const Center(child: Text('لا توجد فروع'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: controller.branches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _BranchCard(branch: controller.branches[i]),
          );
        }),
      ),
    );
  }

  void _showAddSheet() {
    controller.resetForm();

    Get.bottomSheet(
      isScrollControlled: true,
      Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(Get.context!).viewInsets.bottom + 24,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'إضافة فرع',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  // const SizedBox(height: 14),
                  // _textField(controller.codeCtrl, 'رمز الفرع (code)'),
                  const SizedBox(height: 12),
                  _textField(controller.nameCtrl, 'اسم الفرع'),
                  const SizedBox(height: 12),
                  _textField(controller.addressCtrl, 'العنوان'),
                  const SizedBox(height: 12),
                  _textField(
                    controller.phoneCtrl,
                    'الهاتف',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _textField(
                          controller.latCtrl,
                          'lat',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _textField(
                          controller.lngCtrl,
                          'lng',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _textField(
                          controller.pricePerKmCtrl,
                          'سعر الكيلو',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _textField(
                          controller.maxDeliveryKmCtrl,
                          'أقصى مسافة توصيل',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Column(
                      children: [
                        SwitchListTile(
                          value: controller.supportsDelivery.value,
                          onChanged: (v) =>
                              controller.supportsDelivery.value = v,
                          title: const Text('يدعم التوصيل'),
                          activeThumbColor: brown,
                        ),
                        SwitchListTile(
                          value: controller.supportsPickup.value,
                          onChanged: (v) => controller.supportsPickup.value = v,
                          title: const Text('يدعم الاستلام'),
                          activeThumbColor: brown,
                        ),
                        SwitchListTile(
                          value: controller.isActive.value,
                          onChanged: (v) => controller.isActive.value = v,
                          title: const Text('الفرع نشط'),
                          activeThumbColor: brown,
                        ),
                        // SwitchListTile(
                        //   value: controller.isDefault.value,
                        //   onChanged: (v) => controller.isDefault.value = v,
                        //   title: const Text('فرع افتراضي'),
                        //   activeColor: brown,
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Obx(
                      () => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brown,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: controller.saving.value
                            ? null
                            : () async {
                                final ok = await controller.addBranch();
                                if (ok) Get.back();
                              },
                        child: controller.saving.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'حفظ',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: _decor(hint),
    );
  }

  InputDecoration _decor(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF2EFEA),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}

class _BranchCard extends GetView<BranchesController> {
  const _BranchCard({required this.branch});

  final BranchModel branch;

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: const Color(0xFFEEE3D9),
            child: Text(
              branch.name.isNotEmpty ? branch.name.characters.first : 'ف',
              style: const TextStyle(color: brown, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        branch.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: branch.isActive
                            ? Colors.green.withOpacity(.12)
                            : Colors.red.withOpacity(.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        branch.isActive ? 'نشط' : 'موقوف',
                        style: TextStyle(
                          color: branch.isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'الكود: ${branch.code}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  branch.addressText.isNotEmpty
                      ? branch.addressText
                      : 'بدون عنوان',
                  style: const TextStyle(color: Colors.black54),
                ),
                if (branch.phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'الهاتف: ${branch.phone}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _chip('التوصيل', branch.supportsDelivery),
                    _chip('الاستلام', branch.supportsPickup),
                    if (branch.isDefault) _defaultChip(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'سعر الكيلو: ${branch.pricePerKm}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                Text(
                  'أقصى مسافة: ${branch.maxDeliveryKm} كم',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                if (branch.lat != null || branch.lng != null)
                  Text(
                    'الموقع: ${branch.lat ?? '-'} , ${branch.lng ?? '-'}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _showEditSheet(context),
                icon: const Icon(Icons.edit_outlined, color: Colors.orange),
              ),
              IconButton(
                onPressed: () => controller.deleteBranch(branch),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withOpacity(.12)
            : Colors.grey.withOpacity(.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.green : Colors.grey[700],
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _defaultChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withOpacity(.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'افتراضي',
        style: TextStyle(
          color: Colors.deepOrange,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    final codeCtrl = TextEditingController(text: branch.code);
    final nameCtrl = TextEditingController(text: branch.name);
    final addressCtrl = TextEditingController(text: branch.addressText);
    final phoneCtrl = TextEditingController(text: branch.phone);
    final latCtrl = TextEditingController(
      text: branch.lat != null ? '${branch.lat}' : '',
    );
    final lngCtrl = TextEditingController(
      text: branch.lng != null ? '${branch.lng}' : '',
    );
    final priceCtrl = TextEditingController(text: '${branch.pricePerKm}');
    final maxCtrl = TextEditingController(text: '${branch.maxDeliveryKm}');

    final supportsDelivery = branch.supportsDelivery.obs;
    final supportsPickup = branch.supportsPickup.obs;
    final isActive = branch.isActive.obs;
    final isDefault = branch.isDefault.obs;

    Get.bottomSheet(
      isScrollControlled: true,
      Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'تعديل الفرع',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  // const SizedBox(height: 14),
                  // _field(codeCtrl, 'رمز الفرع (code)'),
                  const SizedBox(height: 12),
                  _field(nameCtrl, 'اسم الفرع'),
                  const SizedBox(height: 12),
                  _field(addressCtrl, 'العنوان'),
                  const SizedBox(height: 12),
                  _field(
                    phoneCtrl,
                    'الهاتف',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          latCtrl,
                          'lat',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _field(
                          lngCtrl,
                          'lng',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          priceCtrl,
                          'سعر الكيلو',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _field(
                          maxCtrl,
                          'أقصى مسافة توصيل',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Column(
                      children: [
                        SwitchListTile(
                          value: supportsDelivery.value,
                          onChanged: (v) => supportsDelivery.value = v,
                          title: const Text('يدعم التوصيل'),
                          activeThumbColor: brown,
                        ),
                        SwitchListTile(
                          value: supportsPickup.value,
                          onChanged: (v) => supportsPickup.value = v,
                          title: const Text('يدعم الاستلام'),
                          activeThumbColor: brown,
                        ),
                        SwitchListTile(
                          value: isActive.value,
                          onChanged: (v) => isActive.value = v,
                          title: const Text('الفرع نشط'),
                          activeThumbColor: brown,
                        ),
                        // SwitchListTile(
                        //   value: isDefault.value,
                        //   onChanged: (v) => isDefault.value = v,
                        //   title: const Text('فرع افتراضي'),
                        //   activeColor: brown,
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final ok = await controller.updateBranch(
                          branch,
                          code: codeCtrl.text,
                          name: nameCtrl.text,
                          addressText: addressCtrl.text,
                          phone: phoneCtrl.text,
                          latText: latCtrl.text,
                          lngText: lngCtrl.text,
                          pricePerKmText: priceCtrl.text,
                          maxDeliveryKmText: maxCtrl.text,
                          supportsDeliveryValue: supportsDelivery.value,
                          supportsPickupValue: supportsPickup.value,
                          isActiveValue: isActive.value,
                          isDefaultValue: isDefault.value,
                        );
                        if (ok) Get.back();
                      },
                      child: const Text(
                        'حفظ التعديل',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF2EFEA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
