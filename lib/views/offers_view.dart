import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mandena_admin/views/admin_branch_scope_controller.dart';

import '../../controllers/offers_controller.dart';
import '../../core/services/api_service.dart';
import '../../core/config/env.dart';
import '../../data/models/offer_model.dart';

class OffersView extends StatelessWidget {
  const OffersView({super.key});

  static const brown = Color(0xFF6F3F17);
  static const pageBg = Color(0xFFF3F0ED);

  // عدّل هذا حسب بيئتك
  static const String kBaseUrl = 'https://evoranta.ly';

  /// توحيد رابط الصورة (لو DB يرجّع localhost أو اسم ملف فقط)
  static String normalizeImageUrl(String? raw) {
    var u = (raw ?? '').trim();
    if (u.isEmpty) return '';
    // localhost -> IP
    u = u.replaceAll(
      RegExp(
        r'^https?://(localhost|127\.0\.0\.1)(:\d+)?',
        caseSensitive: false,
      ),
      kBaseUrl,
    );
    // يبدأ بشرطة فقط
    if (u.startsWith('/')) return '$kBaseUrl$u'.replaceAll(' ', '%20');
    // اسم ملف فقط
    final isFilename = !u.startsWith('http') && !u.startsWith('/');
    if (isFilename) {
      if (!u.toLowerCase().contains('uploads/')) {
        return '$kBaseUrl/uploads/$u'.replaceAll(' ', '%20');
      }
      return '$kBaseUrl/$u'.replaceAll(' ', '%20');
    }
    return u.replaceAll(' ', '%20');
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(OffersController());
    final pad = MediaQuery.of(context).padding;
    final searchCtrl = TextEditingController();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        body: SafeArea(
          child: Column(
            children: [
              _Header(controller: c, searchCtrl: searchCtrl),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: AdminBranchScopeBar(),
              ),
              const SizedBox(height: 10),

              // القائمة
              Expanded(
                child: Obx(() {
                  // فلترة محلية بسيطة بالعنوان
                  final q = searchCtrl.text.trim();
                  final src = c.offers;
                  final list = q.isEmpty
                      ? src
                      : src.where((o) => o.title.contains(q)).toList();

                  if (c.loading.value && list.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (list.isEmpty) {
                    return const Center(child: Text('لا توجد عروض'));
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(12, 6, 12, pad.bottom + 90),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final OfferModel o = list[i];
                      final img = normalizeImageUrl(o.imageUrl);

                      return _OfferCard(
                        title: o.title,
                        imageUrl: img,
                        price: o.price,
                        onView: () => Get.snackbar(
                          'معاينة',
                          o.title,
                          snackPosition: SnackPosition.BOTTOM,
                        ),
                        onEdit: () => _showEditSheet(context, c, o),
                        onDelete: () => _confirmDelete(c, o),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),

        // زر الإضافة
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 16),
          child: FloatingActionButton(
            backgroundColor: brown,
            elevation: 4,
            onPressed: () => _showAddSheet(context, c),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  /* =================== الحوارات / الشيت =================== */

  void _confirmDelete(OffersController c, OfferModel o) {
    Get.defaultDialog(
      title: 'تأكيد الحذف',
      middleText: 'هل تريد حذف "${o.title}" ؟',
      textConfirm: 'حذف',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        await c.deleteOffer(o.id);
      },
    );
  }

  void _showAddSheet(BuildContext context, OffersController c) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(bottom: viewInsets.bottom),
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              maxChildSize: 0.95,
              minChildSize: 0.6,
              builder: (_, __) => _OfferFormSheet(
                title: 'إضافة عرض جديد',
                onSubmit: (title, price, imageUrl, [imagePath]) async {
                  // نمرر القيم مباشرة للدالة addOffer الحديثة
                  await c.addOffer(
                    title: title,
                    price: price,
                    imageUrl: imageUrl,
                    imagePath: imagePath, // في حال كانت صورة من الجهاز
                  );
                  Get.back(closeOverlays: true);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditSheet(BuildContext context, OffersController c, OfferModel o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final viewInsets = MediaQuery.of(context).viewInsets.bottom;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(bottom: viewInsets),
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              maxChildSize: 0.95,
              minChildSize: 0.6,
              builder: (_, __) => _OfferFormSheet(
                title: 'تعديل عرض',
                initialTitle: o.title,
                initialPrice: o.price,
                initialImageUrl: o.imageUrl,
                onSubmit: (title, price, imageUrl) async {
                  final m = o.copyWith(
                    title: title,
                    imageUrl: imageUrl,
                    price: price,
                  );
                  await c.updateOffer(m);
                  Get.back(closeOverlays: true); // ← اغلاق تلقائي
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ====================== الهيدر ====================== */
class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.searchCtrl});

  final OffersController controller;
  final TextEditingController searchCtrl;

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
              controller: searchCtrl,
              onChanged: (_) =>
                  controller.update(), // فقط لإجبار Obx يعيد البناء عند البحث
              decoration: InputDecoration(
                hintText: 'Search',
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
          // _roundIcon(icon: Icons.tune_rounded, onTap: () {}),
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

/* ====================== كرت العرض ====================== */
class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String imageUrl;
  final double? price;
  final VoidCallback onView, onEdit, onDelete;

  static const brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شارة السعر (إن وُجد)
          if (price != null)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.only(top: 10, right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: brown,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'د.ل ${price!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          // الصورة + عنوان فوقها
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                Positioned.fill(
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgFallback(),
                        )
                      : _imgFallback(),
                ),
                Positioned(
                  right: 12,
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: brown,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // أكشنات (معاينة - تعديل - حذف)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionBtn(Icons.remove_red_eye_outlined, 'معاينة', onView),
                _actionBtn(Icons.edit_outlined, 'تعديل', onEdit),
                _actionBtn(Icons.delete_outline, 'حذف', onDelete, danger: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _actionBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final color = danger ? Colors.red : brown;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: danger
                    ? const Color(0xFFFFEFEE)
                    : const Color(0xFFF7F4F0),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _imgFallback() => Container(
    color: const Color(0xFFF2EFEA),
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.image_not_supported_outlined, color: Color(0xFFB88969)),
        SizedBox(height: 6),
        Text('لا توجد صورة', style: TextStyle(color: Color(0xFFB88969))),
      ],
    ),
  );
}

/* ====================== شيت الإضافة/التعديل ====================== */

class _OfferFormSheet extends StatefulWidget {
  const _OfferFormSheet({
    required this.title,
    this.initialTitle,
    this.initialPrice,
    this.initialImageUrl,
    required this.onSubmit,
  });

  final String title;
  final String? initialTitle;
  final double? initialPrice;
  final String? initialImageUrl;
  final Future<void> Function(String title, double? price, String imageUrl)
  onSubmit;

  @override
  State<_OfferFormSheet> createState() => _OfferFormSheetState();
}

class _OfferFormSheetState extends State<_OfferFormSheet> {
  static const brown = Color(0xFF6F3F17);

  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  final _imagePath = ''.obs;
  File? _imageFile;
  final _currentImageUrl = ''.obs;

  final _picker = ImagePicker();
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.initialTitle ?? '';
    _priceCtrl.text = widget.initialPrice == null
        ? ''
        : widget.initialPrice!.toString();
    _currentImageUrl.value = widget.initialImageUrl ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null) {
      _imageFile = File(picked.path);
      _imagePath.value = picked.path;
    }
  }

  Future<String?> _uploadImageIfNeeded() async {
    // لو ما غيّرنا الصورة، رجّع الرابط الحالي إن وُجد
    if (_imageFile == null) {
      final url = _currentImageUrl.value.trim();
      return url.isEmpty ? null : url;
    }

    try {
      final res = await _api.uploadFile(
        Env.uploadImage,
        filePath: _imageFile!.path,
        fieldName: 'image', // مهم يطابق $_FILES['image'] في PHP
      );

      // 1) حاول نستخرج الرابط مباشرة من أي شكل رد
      final url = _extractUploadedUrl(res);
      if (url != null && url.toString().trim().isNotEmpty) {
        return url.toString().trim();
      }

      // 2) لو كان String وجاي JSON كسلسلة، جرّب نفكّه بأمان
      if (res is String) {
        try {
          final decoded = jsonDecode(res);
          final url2 = _extractUploadedUrl(decoded);
          if (url2 != null && url2.toString().trim().isNotEmpty) {
            return url2.toString().trim();
          }
        } catch (_) {
          // إذا مش JSON (HTML / تحذير PHP) نطيّح برسالة واضحة للمستخدم
          Get.snackbar(
            'خطأ',
            'فشل رفع الصورة: الرد من السيرفر ليس JSON صالح.\nتحقق من صلاحيات مجلد الرفع واسم الحقل image.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return null;
        }
      }

      // 3) رسالة خطأ أوضح لو السيرفر رجّع كائن ومعه message
      String msg = 'فشل رفع الصورة';
      if (res is Map && res['message'] != null) {
        msg = res['message'].toString();
      }
      Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
      return null;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل رفع الصورة: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// دالة مساعدة: تحاول ترجع رابط الصورة من أكثر من مفتاح محتمل
  dynamic _extractUploadedUrl(dynamic root) {
    if (root == null) return null;

    // أشكال نجاح شائعة
    bool ok(dynamic m) {
      if (m is! Map) return false;
      return m['ok'] == true ||
          m['success'] == true ||
          m['status'] == 'ok' ||
          m['status'] == 'success';
    }

    if (root is Map) {
      // مباشرة في الجذر
      for (final k in const ['url', 'image_url', 'full_url']) {
        if (root[k] != null) return root[k];
      }
      // داخل data
      final d = root['data'];
      if (d is Map) {
        for (final k in const ['url', 'image_url', 'full_url']) {
          if (d[k] != null) return d[k];
        }
      }
      // في بعض السيرفرات يكون الملف باسم 'file'
      if (root['file'] is Map && root['file']['url'] != null) {
        return root['file']['url'];
      }

      // لو السيرفر يشترط ok/success
      if (ok(root)) {
        // حتى لو ok موجود ومافيش url، مافيش رابط يرجع
        return null;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              widget.title,
              style: const TextStyle(
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
                  _field(_titleCtrl, hint: 'عنوان العرض'),
                  const SizedBox(height: 12),
                  _field(
                    _priceCtrl,
                    hint: 'سعر (اختياري)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  // صورة
                  GestureDetector(
                    onTap: _pickImage,
                    child: Obx(() {
                      final local = _imagePath.value;
                      final net = OffersView.normalizeImageUrl(
                        _currentImageUrl.value,
                      );

                      Widget child;
                      if (local.isNotEmpty && _imageFile != null) {
                        child = Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      } else if (net.isNotEmpty) {
                        child = Image.network(
                          net,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => _emptyImageBox(),
                        );
                      } else {
                        child = _emptyImageBox();
                      }

                      return Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EFEA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: child,
                      );
                    }),
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
                      onPressed: () async {
                        final t = _titleCtrl.text.trim();
                        if (t.isEmpty) {
                          Get.snackbar(
                            'تنبيه',
                            'أدخل العنوان',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }
                        final p = _priceCtrl.text.trim().isEmpty
                            ? null
                            : double.tryParse(_priceCtrl.text.trim());

                        final url = await _uploadImageIfNeeded();
                        if (url == null || url.isEmpty) {
                          Get.snackbar(
                            'تنبيه',
                            'اختر صورة للعرض',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }

                        await widget.onSubmit(t, p, url);
                      },
                      child: const Text(
                        'حفظ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
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

  static Widget _emptyImageBox() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 36,
          color: Color(0xFFB88969),
        ),
        SizedBox(height: 8),
        Text('اختر صورة من المعرض', style: TextStyle(color: Color(0xFFB88969))),
      ],
    );
  }

  static Widget _field(
    TextEditingController ctrl, {
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF2EFEA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
