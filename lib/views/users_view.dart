import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/users_controller.dart';
import '../../data/models/user_model.dart';

class UsersView extends GetView<UsersController> {
  const UsersView({super.key});

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: brown,
          title: const Text('المستخدمين'),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TextField(
                  onChanged: controller.setSearch,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'بحث بالاسم أو رقم الهاتف أو رقم المستخدم',
                    hintStyle: TextStyle(fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Obx(() {
          if (controller.loading.value && controller.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // فلترة حسب نص البحث
          final q = controller.searchQuery.value.trim().toLowerCase();
          List<UserModel> list;
          if (q.isEmpty) {
            list = controller.users;
          } else {
            list = controller.users.where((u) {
              final name = (u.username).toLowerCase();
              final phone = (u.phone).toLowerCase();
              final idStr = u.id.toString();
              return name.contains(q) ||
                  phone.contains(q) ||
                  idStr.contains(q);
            }).toList();
          }

          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: controller.fetchUsers,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('لا يوجد مستخدمون مطابقون')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.fetchUsers,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _UserTile(list[i]),
            ),
          );
        }),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile(this.u);
  final UserModel u;

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // انتقال إلى شاشة التفاصيل وتمرير البيانات
        Get.toNamed(
          '/users/details',
          parameters: {
            'id': u.id.toString(),
            'name': u.username,
            'phone': u.phone,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: brown,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 8),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          // للسياق العربي: السهم على اليسار
          leading: const Icon(Icons.chevron_left, color: Colors.white),
          trailing: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            backgroundImage: (u.avatarUrl.isEmpty)
                ? null
                : NetworkImage(u.avatarUrl),
            child: (u.avatarUrl.isEmpty)
                ? const Icon(Icons.person, color: brown)
                : null,
          ),
          title: Text(
            u.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
