import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/core/routes/app_routes.dart';

import '../controllers/item_comments_controller.dart';
import '../controllers/AuthController.dart';

const _brown = Color(0xFF6F3F17);
const _bg = Color(0xFFF8F3EF);

class ItemCommentsView extends StatelessWidget {
  final int itemId;
  const ItemCommentsView({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(
      ItemCommentsController(itemId),
      tag: 'item_comments_$itemId',
    );

    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final bool isAdmin = auth?.isAdmin ?? true;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _bg,
          foregroundColor: _brown,
          centerTitle: true,
          title: const Text(
            'تعليقات الصنف',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: _brown,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => c.fetchComments(force: true),
            ),
          ],
        ),
        body: Obx(() {
          if (c.loading.value) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(_brown),
              ),
            );
          }

          if (c.comments.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد تعليقات بعد',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: c.comments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final cm = c.comments[i];
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // أعلى الكارت: اسم المستخدم + التاريخ
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cm.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cm.createdAt,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // نص التعليق
                      Text(
                        cm.comment,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // أزرار الحركة في أسفل الكارت
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isAdmin) ...[
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              onPressed: () {
                                Get.toNamed(
                                  Routes.userDetails,
                                  arguments: {
                                    'id': cm.userId,
                                    'name': cm.userName,
                                  },
                                );
                              },
                              icon: const Icon(
                                Icons.person_outline,
                                size: 18,
                                color: _brown,
                              ),
                              label: const Text(
                                'حساب صاحب التعليق',
                                style: TextStyle(
                                  color: _brown,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              onPressed: () {
                                Get.defaultDialog(
                                  title: 'تأكيد الحذف',
                                  middleText: 'هل تريد حذف هذا التعليق؟',
                                  textConfirm: 'حذف',
                                  textCancel: 'إلغاء',
                                  confirmTextColor: Colors.white,
                                  buttonColor: Colors.red,
                                  onConfirm: () async {
                                    // نقفل الديالوج
                                    Get.back();
                                    // ننفذ الحذف فعلياً
                                    await c.deleteComment(
                                      commentId: cm.id,
                                      userId: cm.userId,
                                    );
                                  },
                                );
                              },
                              icon: const Icon(
                                Icons.delete_forever,
                                size: 18,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'حذف',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
