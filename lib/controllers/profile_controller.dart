import 'package:get/get.dart';

import 'AuthController.dart';

class ProfileController extends GetxController {
  final _auth = Get.find<AuthController>();

  String get role => _auth.currentRole;
  bool get canManageStaff => _auth.isOwner;

  List<ProfileItem> get primaryCards => const [
    ProfileItem('معلومات عامة', 'person_outline'),
    ProfileItem('سجل الطلبات', 'history_toggle_off'),
  ];

  List<ProfileItem> get secondaryCards => [
    const ProfileItem('المستخدمين', 'groups_2_outlined'),
    const ProfileItem('السائقين', 'local_shipping_outlined'),
    if (canManageStaff)
      const ProfileItem('الإدارة', 'admin_panel_settings_outlined'),
  ];
}

class ProfileItem {
  final String title;
  final String iconName;
  const ProfileItem(this.title, this.iconName);
}
