import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/branches_controller.dart';
import '../data/models/branch_model.dart';

class BranchesView extends GetView<BranchesController> {
  const BranchesView({super.key});

  static const primary = Color(0xFFB85A1B);
  static const pageBg = Color(0xFFF7F7F9);
  static const textMain = Color(0xFF111827);
  static const textSub = Color(0xFF8B95A7);
  static const soft = Color(0xFFF6E8DD);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          title: const Text('الفروع'),
          centerTitle: true,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: primary,
          onPressed: _showAddSheet,
          icon: const Icon(
            Icons.add_location_alt_outlined,
            color: Colors.white,
          ),
          label: const Text('إضافة فرع', style: TextStyle(color: Colors.white)),
        ),
        body: Obx(() {
          if (controller.loading.value) {
            return const Center(
              child: CircularProgressIndicator(color: primary),
            );
          }

          if (controller.branches.isEmpty) {
            return const Center(child: Text('لا توجد فروع'));
          }

          return RefreshIndicator(
            color: primary,
            onRefresh: controller.fetchBranches,
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: controller.branches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) =>
                  _BranchCard(branch: controller.branches[i]),
            ),
          );
        }),
      ),
    );
  }

  void _showAddSheet() {
    controller.resetForm();

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.of(Get.context!).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'إضافة فرع جديد',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
                ),
                const SizedBox(height: 6),
                const Text(
                  'أدخل اسم الفرع ثم اختر موقعه من الخريطة',
                  style: TextStyle(color: textSub, fontSize: 13),
                ),
                const SizedBox(height: 18),
                _textField(controller.nameCtrl, 'اسم الفرع'),
                const SizedBox(height: 12),
                _textField(controller.addressCtrl, 'العنوان', maxLines: 2),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        controller.latCtrl,
                        'خط العرض',
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
                        'خط الطول',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: const BorderSide(color: primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => controller.pickLocation(),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text(
                      'اختيار الموقع من الخريطة',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => SwitchListTile(
                    value: controller.isActive.value,
                    onChanged: (v) => controller.isActive.value = v,
                    title: const Text('الفرع نشط'),
                    activeThumbColor: primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Obx(
                    () => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                              'حفظ الفرع',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _BranchCard extends GetView<BranchesController> {
  const _BranchCard({required this.branch});

  final BranchModel branch;

  static const primary = BranchesView.primary;
  static const textMain = BranchesView.textMain;
  static const textSub = BranchesView.textSub;
  static const soft = BranchesView.soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.store_mall_directory_outlined,
              color: primary,
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
                          fontSize: 16,
                          color: textMain,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: branch.isActive
                            ? Colors.green.withOpacity(.12)
                            : Colors.red.withOpacity(.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        branch.isActive ? 'نشط' : 'موقوف',
                        style: TextStyle(
                          color: branch.isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  branch.addressText.isNotEmpty
                      ? branch.addressText
                      : 'بدون عنوان',
                  style: const TextStyle(color: textSub, height: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'الإحداثيات: ${branch.lat ?? '-'} , ${branch.lng ?? '-'}',
                  style: const TextStyle(fontSize: 12.5, color: textSub),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _showEditSheet(context),
                icon: const Icon(Icons.edit_outlined, color: Color(0xFFB85A1B)),
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

  void _showEditSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: branch.name);
    final addressCtrl = TextEditingController(text: branch.addressText);
    final latCtrl = TextEditingController(
      text: branch.lat != null ? '${branch.lat}' : '',
    );
    final lngCtrl = TextEditingController(
      text: branch.lng != null ? '${branch.lng}' : '',
    );
    final isActive = branch.isActive.obs;

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'تعديل الفرع',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
                ),
                const SizedBox(height: 18),
                _field(nameCtrl, 'اسم الفرع'),
                const SizedBox(height: 12),
                _field(addressCtrl, 'العنوان', maxLines: 2),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        latCtrl,
                        'خط العرض',
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
                        'خط الطول',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: const BorderSide(color: primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => controller.pickLocation(
                      latController: latCtrl,
                      lngController: lngCtrl,
                      addressController: addressCtrl,
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text(
                      'تعديل الموقع من الخريطة',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => SwitchListTile(
                    value: isActive.value,
                    onChanged: (v) => isActive.value = v,
                    title: const Text('الفرع نشط'),
                    activeThumbColor: primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      final ok = await controller.updateBranch(
                        branch,
                        name: nameCtrl.text,
                        addressText: addressCtrl.text,
                        latText: latCtrl.text,
                        lngText: lngCtrl.text,
                        isActiveValue: isActive.value,
                      );
                      if (ok) Get.back();
                    },
                    child: const Text(
                      'حفظ التعديلات',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
