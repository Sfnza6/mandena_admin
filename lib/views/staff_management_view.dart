import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/staff_controller.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/staff_model.dart';

class StaffManagementView extends GetView<StaffController> {
  const StaffManagementView({super.key});

  static const brown = Color(0xFF6F3F17);
  static const pageBg = Color(0xFFF3F0ED);

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        body: SafeArea(
          child: Column(
            children: [
              _Header(controller: controller),
              const SizedBox(height: 8),
              Expanded(
                child: Obx(() {
                  final list = controller.filtered;
                  if (controller.loading.value && list.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (list.isEmpty) {
                    return const Center(child: Text('لا يوجد طاقم'));
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, pad.bottom + 90),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final StaffModel s = list[i];
                      return _StaffTile(
                        s: s,
                        branchName: controller.branchNameById(s.branchId),
                        onChangeRole: () => _showChangeRoleSheet(context, s),
                        onDelete: () => controller.deleteStaff(s),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
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
              initialChildSize: 0.82,
              maxChildSize: 0.95,
              minChildSize: 0.55,
              builder: (_, __) => _AddStaffSheet(
                onSubmit: () async {
                  final ok = await controller.addStaff();
                  if (ok) Get.back();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChangeRoleSheet(BuildContext context, StaffModel s) {
    var role = s.role;
    int? selectedBranchId = s.branchId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              final roleNeedsBranch = role != 'owner';

              return Wrap(
                runSpacing: 12,
                children: [
                  const Text(
                    'تغيير الصلاحية',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: _decor('اختر الصلاحية'),
                    items: const [
                      DropdownMenuItem(
                        value: 'owner',
                        child: Text('مالك المطعم (owner)'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('مدير فرع (admin)'),
                      ),
                      DropdownMenuItem(
                        value: 'receiver',
                        child: Text('مستقبل طلبات (receiver)'),
                      ),
                    ],
                    onChanged: (v) {
                      role = v ?? role;
                      if (role == 'owner') {
                        selectedBranchId = null;
                      }
                      setState(() {});
                    },
                  ),
                  if (roleNeedsBranch)
                    Obx(() {
                      if (controller.loadingBranches.value) {
                        return const LinearProgressIndicator();
                      }

                      return DropdownButtonFormField<int>(
                        initialValue: selectedBranchId,
                        decoration: _decor('اختر الفرع'),
                        items: controller.branches
                            .map(
                              (b) => DropdownMenuItem<int>(
                                value: b.id,
                                child: Text('${b.name} (${b.code})'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          selectedBranchId = v;
                        },
                      );
                    }),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final ok = await controller.updateRole(
                          s,
                          role,
                          branchId: selectedBranchId,
                        );
                        if (ok) Get.back();
                      },
                      child: const Text(
                        'حفظ',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

InputDecoration _decor(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: const Color(0xFFF2EFEA),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderSide: BorderSide.none,
    borderRadius: BorderRadius.circular(14),
  ),
);

class _Header extends StatelessWidget {
  const _Header({required this.controller});
  final StaffController controller;
  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: brown,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Row(
        children: [
          _roundIcon(icon: Icons.arrow_back_ios_new_rounded, onTap: Get.back),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller.searchCtrl,
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'بحث في الطاقم',
                hintStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  static Widget _roundIcon({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.95),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.black87, size: 18),
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({
    required this.s,
    required this.branchName,
    this.onChangeRole,
    this.onDelete,
  });

  final StaffModel s;
  final String branchName;
  final VoidCallback? onChangeRole;
  final VoidCallback? onDelete;

  static const brown = Color(0xFF6F3F17);

  Color _roleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.deepOrange;
      case 'admin':
        return Colors.green;
      case 'receiver':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'مالك المطعم';
      case 'admin':
        return 'مدير فرع';
      case 'receiver':
        return 'مستقبل طلبات';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = StaffController.rolePermissions[s.role] ?? const [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEEE3D9),
            child: Text(
              s.name.isNotEmpty ? s.name.characters.first : 'ط',
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
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _roleColor(s.role).withOpacity(.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _roleLabel(s.role),
                        style: TextStyle(
                          color: _roleColor(s.role),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(s.phone, style: const TextStyle(color: Colors.black54)),
                if (s.role != 'owner') ...[
                  const SizedBox(height: 4),
                  Text(
                    'الفرع: $branchName',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: -6,
                  children: permissions
                      .map(
                        (p) => Chip(
                          label: Text(p, style: const TextStyle(fontSize: 11)),
                          side: BorderSide.none,
                          backgroundColor: const Color(0xFFF5F1ED),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onChangeRole,
                icon: const Icon(Icons.security, color: Colors.orange),
                tooltip: 'تغيير الصلاحية',
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'حذف',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddStaffSheet extends StatelessWidget {
  const _AddStaffSheet({required this.onSubmit});
  final VoidCallback onSubmit;

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    final c = Get.find<StaffController>();

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
              'إضافة مستخدم إدارة',
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
                  _field(c.nameCtrl, 'الاسم'),
                  const SizedBox(height: 12),
                  _field(
                    c.phoneTextCtrl,
                    'الهاتف',
                    keyboard: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _field(c.passTextCtrl, 'كلمة المرور', obscure: true),
                  const SizedBox(height: 12),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: c.selectedRole.value,
                      decoration: _decor('الصلاحية'),
                      items: const [
                        DropdownMenuItem(
                          value: 'owner',
                          child: Text('مالك المطعم (owner)'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('مدير فرع (admin)'),
                        ),
                        DropdownMenuItem(
                          value: 'receiver',
                          child: Text('مستقبل طلبات (receiver)'),
                        ),
                      ],
                      onChanged: (v) => c.onRoleChanged(v ?? 'admin'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    if (!c.roleNeedsBranch) {
                      return const SizedBox.shrink();
                    }

                    if (c.loadingBranches.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      );
                    }

                    return DropdownButtonFormField<int>(
                      initialValue: c.selectedBranchId.value,
                      decoration: _decor('اختر الفرع'),
                      items: c.branches
                          .map(
                            (BranchModel b) => DropdownMenuItem<int>(
                              value: b.id,
                              child: Text('${b.name} (${b.code})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => c.selectedBranchId.value = v,
                    );
                  }),
                  const SizedBox(height: 12),
                  Obx(
                    () => SwitchListTile(
                      value: c.active.value,
                      onChanged: (v) => c.active.value = v,
                      title: const Text('الحساب نشط'),
                      activeThumbColor: brown,
                    ),
                  ),
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
