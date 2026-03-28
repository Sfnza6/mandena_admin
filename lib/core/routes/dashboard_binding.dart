// lib/core/routes/dashboard_binding.dart
import 'package:get/get.dart';
import 'package:mandena_admin/controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}
