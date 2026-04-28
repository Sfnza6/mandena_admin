import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/controllers/AuthController.dart';
import '../../../../core/routes/app_routes.dart';

class HeaderBar extends StatelessWidget {
  static const primary = Color(0xFFB85A1B);
  static const softText = Color(0xFFF2DFC9);
  const HeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Obx(() {
            final user = auth.admin.value;

            final displayName = user?.name ?? '—'; // ✅ هنا الاسم
            final role = user?.role.isNotEmpty == true ? user!.role : 'admin';
            final avatarUrl = user?.avatarUrl ?? '';

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // صورة البروفايل
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.profile),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.2),
                    ),
                    child: ClipOval(child: _Avatar(url: avatarUrl)),
                  ),
                ),
                const SizedBox(width: 12),

                // النصوص
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        displayName, // ✅ يعرض اسم الأدمن
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: softText,
                          fontSize: 11.5,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // _iconButton(Icons.mail_outline_rounded),
                // const SizedBox(width: 8),
                // _iconButton(Icons.notifications_none_rounded),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ignore: unused_element
  static Widget _iconButton(IconData icon) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        color: Colors.white,
        alignment: Alignment.center,
        child: const Icon(Icons.person, color: HeaderBar.primary),
      );
    }
    return Image.network(
      url,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 40,
        height: 40,
        color: Colors.white,
        alignment: Alignment.center,
        child: const Icon(Icons.person, color: HeaderBar.primary),
      ),
    );
  }
}
