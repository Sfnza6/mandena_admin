import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // ✅ كاش خفيف

import '../../core/services/api_service.dart';
import '../../core/config/env.dart';

class DeliverySettingsController extends GetxController {
  final _api = ApiService();

  /// صندوق الكاش
  final _box = GetStorage('delivery_settings_box');

  /// سعر الكيلومتر (د.ل / كم)
  final priceCtrl = TextEditingController();

  /// وضعية التوصيل المجاني (زر يخلي السعر 0)
  final freeMode = false.obs;

  /// حالات تحميل / حفظ
  final loading = false.obs;
  final saving = false.obs;

  /// رسائل حالة بسيطة (لو حاب تستخدمها في الواجهة)
  final errorMessage = ''.obs;
  final successMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();

    // ✅ أولاً: حاول نقرأ من الكاش مباشرة (عرض سريع بدون انتظار سيرفر)
    _loadFromCache();

    // ثم نجلب من السيرفر لتحديث القيم
    _loadConfig();
  }

  @override
  void onClose() {
    priceCtrl.dispose();
    super.onClose();
  }

  /// قراءة الإعدادات من الكاش (لو موجودة)
  void _loadFromCache() {
    try {
      final cached = _box.read('delivery_config');
      if (cached is Map) {
        final price = (cached['price_per_km'] ?? 1.0).toString();
        final free = cached['free_mode'] == true || cached['free_mode'] == 1;

        priceCtrl.text = price;
        freeMode.value = free;
      }
    } catch (_) {
      // لو صار خطأ في الكاش نتجاهله ولا نكسر شي
    }
  }

  /// حفظ في الكاش
  void _saveToCache({
    required double pricePerKm,
    required bool free,
  }) {
    final data = {
      'price_per_km': pricePerKm,
      'free_mode': free ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
    _box.write('delivery_config', data);
  }

  /// جلب الإعدادات الحالية من السيرفر
  Future<void> _loadConfig() async {
    loading.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      // عدل المسار لو عندك prefix مختلف
      final url = '${Env.base}/admin/delivery/get_config.php';

      final res = await _api.get(url);
      // لو ApiService يرجع String → نفك JSON
      final data = (res is String) ? jsonDecode(res) : res;

      if (data is Map && data['ok'] == true) {
        final priceVal = (data['price_per_km'] ?? 1.0);
        final price = priceVal.toString();
        final free  = (data['free_mode'] == 1 || data['free_mode'] == true);

        priceCtrl.text = price;
        freeMode.value = free;

        // ✅ خزّن آخر إعدادات ناجحة في الكاش
        final parsedPrice =
            (priceVal is num) ? priceVal.toDouble() : double.tryParse(price) ?? 1.0;
        _saveToCache(pricePerKm: parsedPrice, free: free);
      } else {
        errorMessage.value =
            data['message']?.toString() ?? 'فشل في جلب الإعدادات';
      }
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء جلب الإعدادات: $e';
    } finally {
      loading.value = false;
    }
  }

  /// حفظ الإعدادات في السيرفر
  Future<void> save() async {
    final txt = priceCtrl.text.trim().replaceAll(',', '.');

    if (txt.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى إدخال سعر الكيلومتر',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final price = double.tryParse(txt) ?? -1;
    if (price < 0) {
      Get.snackbar(
        'تنبيه',
        'قيمة السعر غير صحيحة',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    saving.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      final url = '${Env.base}/admin/delivery/save_config.php';

      /// لو ApiService عندك فيه postForm استخدمه، المهم يرسل كـ x-www-form-urlencoded
      final res = await _api.post(
        url,
        body: {
          'price_per_km': price.toString(),
          'free_mode': freeMode.value ? '1' : '0',
        },
      );

      final data = (res is String) ? jsonDecode(res) : res;

      if (data is Map && data['ok'] == true) {
        successMessage.value =
            data['message']?.toString() ?? 'تم حفظ إعدادات التوصيل بنجاح';

        // ✅ حدث الكاش بعد حفظ ناجح
        _saveToCache(pricePerKm: price, free: freeMode.value);

        Get.snackbar(
          'تم الحفظ',
          successMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
        );
      } else {
        final msg = data['message']?.toString() ?? 'تعذّر حفظ الإعدادات';
        errorMessage.value = msg;
        Get.snackbar(
          'خطأ',
          msg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء الحفظ: $e';
      Get.snackbar(
        'خطأ',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      saving.value = false;
    }
  }

  /// إعادة تحميل من السيرفر (زر تحديث لو حبيت تضيفه)
  Future<void> reload() => _loadConfig();
}
