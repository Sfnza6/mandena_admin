import 'package:flutter/material.dart';
import 'package:get/get.dart';

const adminBrown = Color(0xFF6F3F17);
const adminPageBg = Color(0xFFF3F0ED);
const adminCard = Colors.white;
const adminText = Color(0xFF111827);
const adminMuted = Color(0xFF8B95A7);

class AdminSearchHeader extends StatelessWidget {
  const AdminSearchHeader({
    super.key,
    this.title,
    this.hintText = 'Search',
    this.controller,
    this.onChanged,
    this.onBack,
    this.trailing,
    this.showSearch = true,
    this.showBack = true,
  });

  final String? title;
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showSearch;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: adminBrown,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Row(
        children: [
          if (showBack)
            _roundIcon(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack ?? Get.back,
            ),
          if (showBack) const SizedBox(width: 10),
          if (showSearch)
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: hintText,
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
            )
          else
            Expanded(
              child: Text(
                title ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
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

class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: adminCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState(
    this.text, {
    super.key,
    this.icon = Icons.inbox_outlined,
  });
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4F0),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: adminBrown, size: 34),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                color: adminMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
