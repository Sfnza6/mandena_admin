import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PaymentSettingsController extends GetxController {
  final isLoading = false.obs;

  final onlineEnabled = false.obs;
  final masrafyEnabled = true.obs;
  final yesserEnabled = true.obs;
  final sahariEnabled = true.obs;

  static const String getUrl =
      'https://evoranta.ly/api/settings/payment_config.php';
  static const String updateUrl =
      'https://evoranta.ly/api/settings/payment_config_update.php';

  // ✅ نفس المفتاح الموجود في PHP
  static const String adminKey = 'CHANGE_ME_STRONG_KEY';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final r = await http.get(Uri.parse(getUrl)).timeout(const Duration(seconds: 20));
      final decoded = jsonDecode(r.body);

      if (decoded is Map && decoded['ok'] == true) {
        onlineEnabled.value = (decoded['online_enabled'] == 1 || decoded['online_enabled'] == true);

        final enabled = (decoded['enabled_gateways'] is List)
            ? (decoded['enabled_gateways'] as List).map((e) => e.toString()).toList()
            : <String>[];

        masrafyEnabled.value = enabled.contains('masrafy');
        yesserEnabled.value = enabled.contains('yesser');
        sahariEnabled.value = enabled.contains('sahari');
      }
    } catch (_) {
      // تجاهل
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save() async {
    isLoading.value = true;
    try {
      final body = {
        'admin_key': adminKey,
        'online_enabled': onlineEnabled.value ? '1' : '0',
        'masrafy_enabled': masrafyEnabled.value ? '1' : '0',
        'yesser_enabled': yesserEnabled.value ? '1' : '0',
        'sahari_enabled': sahariEnabled.value ? '1' : '0',
      };

      final r = await http.post(
        Uri.parse(updateUrl),
        body: body,
        headers: {'X-Admin-Key': adminKey},
      ).timeout(const Duration(seconds: 20));

      final decoded = jsonDecode(r.body);
      return decoded is Map && decoded['ok'] == true;
    } catch (_) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
