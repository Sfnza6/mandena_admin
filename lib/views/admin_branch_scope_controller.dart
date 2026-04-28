import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/controllers/admin_branch_scope_controller.dart';

import '../data/models/branch_model.dart';

class AdminBranchScopeBar extends GetView<AdminBranchScopeController> {
  const AdminBranchScopeBar({super.key});

  static const primary = Color(0xFFB85A1B);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final enabled = controller.canChooseBranch;
      final currentId = controller.effectiveBranchId;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.store_mall_directory_outlined,
              color: primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                currentId == null
                    ? 'اختر الفرع قبل الإضافة أو عرض البيانات'
                    : 'الفرع الحالي: ${controller.currentBranchLabel}',
                style: const TextStyle(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (enabled)
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: controller.selectedBranchId.value,
                  hint: const Text('اختر'),
                  items: controller.branches
                      .map(
                        (BranchModel b) => DropdownMenuItem<int>(
                          value: b.id,
                          child: Text(b.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => controller.selectBranch(v),
                ),
              )
            else
              Text(
                controller.currentBranchLabel,
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      );
    });
  }
}
