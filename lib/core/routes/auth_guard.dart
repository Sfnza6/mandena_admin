import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/controllers/AuthController.dart';
import 'app_routes.dart';

class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final isLogged = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().isLoggedIn
        : false;
    if (!isLogged && route != Routes.login) {
      return const RouteSettings(name: Routes.login);
    }
    return null;
  }
}
