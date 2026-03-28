import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/controllers/AuthController.dart';
import '../../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  static const brown = Color(0xFF6F3F17);
  static const pageBg = Color(0xFFF3F0ED);

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    final auth = Get.find<AuthController>(); // ← مصدر بيانات الأدمن

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, pad.bottom + 24),
            children: [
              // شريط علوي بسيط
              Row(
                children: [
                  _circleSoft(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: Get.back,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'الملف الشخصي',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Spacer(),
                ],
              ),

              const SizedBox(height: 20),

              // الاسم + الدور + الصورة (تلقائي من AuthController)
              Obx(() {
                final user = auth.admin.value;
                final name = user?.name ?? '—';
                final role = (user?.role.isNotEmpty ?? false)
                    ? user!.role
                    : 'admin';
                final avatar = user?.avatarUrl ?? '';

                return Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: avatar.isEmpty
                            ? const _AvatarFallback()
                            : Image.network(
                                avatar,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const _AvatarFallback(),
                              ),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 18),

              // الكرت الأول (معلومات عامة + سجل الطلبات)
              _SectionCard(
                items: controller.primaryCards,
                onTapItem: (i) {
                  final it = controller.primaryCards[i];

                  // معلومات عامة
                  if (it.title.trim() == 'معلومات عامة' ||
                      it.iconName == 'person_outline') {
                    Get.toNamed('/profile/general'); // ← يفتح صفحة معلومات عامة
                    return;
                  }

                  // سجل الطلبات (اختياري إذا كنت مجهزه)
                  if (it.title.contains('سجل الطلبات') ||
                      it.iconName == 'history_toggle_off') {
                    Get.toNamed('/orders/history');
                    return;
                  }

                  // زر الإدارة لو كان ضمن الكرت الأول
                  if (it.title.trim() == 'الإدارة' ||
                      it.iconName == 'admin_panel_settings_outlined') {
                    Get.toNamed('/admin/staff');
                    return;
                  }
                },
              ),

              const SizedBox(height: 16),

              // الكرت الثاني (مستخدمين / سائقين / شكاوي / إدارة)
              _SectionCard(
                items: controller.secondaryCards,
                onTapItem: (i) {
                  final it = controller.secondaryCards[i];

                  if (i == 0 || it.title.contains('المستخدمين')) {
                    Get.toNamed('/users');
                    return;
                  }
                  if (i == 1 || it.title.contains('السائقين')) {
                    Get.toNamed('/drivers');
                    return;
                  }
                  if (it.title.trim() == 'الإدارة' ||
                      it.iconName == 'admin_panel_settings_outlined') {
                    Get.toNamed('/admin/staff');
                    return;
                  }
                },
              ),

              const SizedBox(height: 16),

              // تسجيل خروج
              _LogoutTile(
                onTap: () async {
                  await auth.logout();
                  Get.offAllNamed('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _circleSoft({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }
}

/* -------------------------- Widgets داخلية -------------------------- */

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: Colors.white,
      alignment: Alignment.center,
      child: const Icon(Icons.person, color: ProfileView.brown),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.items, required this.onTapItem});
  final List<ProfileItem> items;
  final void Function(int index) onTapItem;

  static const brown = Color(0xFF6F3F17);

  IconData _iconFromName(String name) {
    switch (name) {
      case 'person_outline':
        return Icons.person_outline;
      case 'map_outlined':
        return Icons.map_outlined;
      case 'history_toggle_off':
        return Icons.history_toggle_off;
      case 'groups_2_outlined':
        return Icons.groups_2_outlined;
      case 'local_shipping_outlined':
        return Icons.local_shipping_outlined;
      case 'mark_email_unread_outlined':
        return Icons.mark_email_unread_outlined;
      case 'admin_panel_settings_outlined':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: brown,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: List.generate(items.length, (i) {
            final it = items[i];
            final icon = _iconFromName(it.iconName);
            return Column(
              children: [
                ListTile(
                  onTap: () => onTapItem(i),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  trailing: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: brown),
                  ),
                  leading: const Icon(Icons.chevron_left, color: Colors.white),
                  title: Text(
                    it.title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (i != items.length - 1)
                  Divider(
                    color: Colors.white.withOpacity(.14),
                    height: 0,
                    thickness: 1,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            children: const [
              Icon(Icons.chevron_left, color: Color(0xFF6F3F17)),
              Spacer(),
              Text('تسجيل خروج', style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFF5E6DC),
                child: Icon(Icons.logout, color: Color(0xFF6F3F17), size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
