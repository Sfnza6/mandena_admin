import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/controllers/AuthController.dart';
import '../../core/routes/app_routes.dart';

class DecideGate extends StatefulWidget {
  const DecideGate({super.key});

  @override
  State<DecideGate> createState() => _DecideGateState();
}

class _DecideGateState extends State<DecideGate> {
  bool _navigated = false;

  void _go() {
    if (_navigated) return;
    _navigated = true;

    final auth = Get.find<AuthController>();

    if (!auth.isLoggedIn) {
      Get.offAllNamed(Routes.login);
      return;
    }

    final role = auth.currentRole;
    if (role == 'receiver') {
      Get.offAllNamed(Routes.receiverHome);
    } else {
      Get.offAllNamed(Routes.dashboard);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _go();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
