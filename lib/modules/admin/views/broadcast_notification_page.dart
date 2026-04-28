import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

const _primary = Color(0xFFB85A1B);
const String _broadcastUrl = 'https://evoranta.ly/notify/broadcast.php';

class BroadcastNotificationPage extends StatefulWidget {
  const BroadcastNotificationPage({super.key});

  @override
  State<BroadcastNotificationPage> createState() =>
      _BroadcastNotificationPageState();
}

class _BroadcastNotificationPageState extends State<BroadcastNotificationPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'لازم تكتب عنوان ومحتوى الرسالة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(.9),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse(_broadcastUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({'title': title, 'body': body}),
      );

      Map<String, dynamic>? j;
      try {
        j = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}

      final ok =
          (res.statusCode >= 200 && res.statusCode < 300) &&
          ((j?['ok'] == true) ||
              ((j?['success_total'] is num) &&
                  (j?['success_total'] as num).toInt() > 0) ||
              ((j?['count'] is num) && (j?['count'] as num).toInt() > 0));

      if (ok) {
        Get.snackbar(
          'تم',
          j?['message']?.toString() ?? 'تم إرسال الإشعار للجميع ✅',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(.9),
          colorText: Colors.white,
        );

        // تفريغ الحقول بعد النجاح
        _titleCtrl.clear();
        _bodyCtrl.clear();
      } else {
        Get.snackbar(
          'فشل',
          j?['message']?.toString() ?? 'تعذر إرسال الإشعار',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ اتصال',
        'تحقق من الإنترنت/الدومين: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(.9),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          title: const Text('إرسال إشعار للجميع'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Input(
              controller: _titleCtrl,
              hint: 'عنوان الرسالة',
              icon: Icons.title,
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            _Input(
              controller: _bodyCtrl,
              hint: 'محتوى الرسالة',
              icon: Icons.subject,
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_loading ? 'جارٍ الإرسال...' : 'إرسال'),
                onPressed: _loading ? null : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _Input({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: _primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.2),
        ),
      ),
    );
  }
}
