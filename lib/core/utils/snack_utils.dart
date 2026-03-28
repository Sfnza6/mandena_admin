import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// إشعارات احترافية — لا تعرض أبداً استجابة السيرفر أو تفاصيل الاستثناء للمستخدم
class AppSnack {
  static const _duration = Duration(seconds: 3);

  static SnackbarController _show({
    required String title,
    required String message,
    required bool isError,
    IconData? icon,
  }) {
    final bg = isError ? Colors.red.shade50 : const Color(0xFFE8F5E9);
    final fg = isError ? Colors.red.shade800 : Colors.green.shade800;
    final ico = icon ?? (isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded);
    return Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: bg,
      colorText: fg,
      icon: Icon(ico, color: fg, size: 22),
      margin: const EdgeInsets.all(12),
      duration: _duration,
      maxWidth: 420,
      borderRadius: 12,
      isDismissible: true,
    );
  }

  static void error(String message) => _show(
        title: 'خطأ',
        message: message,
        isError: true,
      );

  static void success(String message) => _show(
        title: 'تم',
        message: message,
        isError: false,
      );

  static void successWithDetails(String title, String message, {Duration? duration}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFE8F5E9),
      colorText: Colors.green.shade800,
      icon: Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade800, size: 22),
      margin: const EdgeInsets.all(12),
      duration: duration ?? _duration,
      maxWidth: 420,
      borderRadius: 12,
      isDismissible: true,
    );
  }

  static void warning(String message) => _show(
        title: 'تنبيه',
        message: message,
        isError: false,
        icon: Icons.info_outline_rounded,
      );

  /// تحويل خطأ تغيير كلمة السر لرسالة آمنة
  static String passwordChangeError(dynamic res) {
    final msg = _rawMessage(res).toLowerCase();
    if (msg.contains('current') || msg.contains('الحالية') || msg.contains('old') || msg.contains('incorrect')) {
      return 'كلمة السر الحالية غير صحيحة';
    }
    return 'تعذّر تغيير كلمة السر';
  }

  /// تحويل خطأ تسجيل الدخول لرسالة آمنة (لا تُرجع استجابة السيرفر)
  static String loginError(dynamic res) {
    final msg = _rawMessage(res);
    final m = msg.toLowerCase();
    if (m.contains('password') || m.contains('كلمة') || m.contains('رمز') ||
        m.contains('wrong') || m.contains('incorrect') || m.contains('invalid') && m.contains('pass')) {
      return 'كلمة السر غير صحيحة';
    }
    if (m.contains('phone') || m.contains('هاتف') || m.contains('user') || m.contains('not found') ||
        m.contains('غير مسجل') || m.contains('لا يوجد')) {
      return 'رقم الهاتف غير مسجّل';
    }
    return 'بيانات الدخول غير صحيحة';
  }

  /// تحويل أي خطأ لرسالة آمنة — لا تُعرض أبداً استجابة السيرفر أو الاستثناء
  static String friendlyError(dynamic e, {String fallback = 'حدث خطأ، جرّب لاحقاً'}) {
    final msg = _rawMessage(e);
    if (msg.isEmpty) return fallback;
    final m = msg.toLowerCase();
    if (m.contains('socket') || m.contains('connection') || m.contains('network') || m.contains('timeout')) {
      return 'فشل الاتصال. تحقق من الإنترنت';
    }
    if (m.contains('401') || m.contains('unauthorized')) return 'انتهت الجلسة، سجّل دخولك مجدداً';
    if (m.contains('403') || m.contains('forbidden')) return 'ليس لديك صلاحية لهذا الإجراء';
    if (m.contains('404')) return 'المطلوب غير موجود';
    if (m.contains('500') || m.contains('server')) return 'خطأ من الخادم، جرّب لاحقاً';
    return fallback;
  }

  static String _rawMessage(dynamic e) {
    if (e == null) return '';
    if (e is Map) {
      final m = e['message'] ?? e['msg'] ?? e['error'] ?? e['reason'];
      return (m ?? '').toString().trim();
    }
    return e.toString().trim();
  }
}
