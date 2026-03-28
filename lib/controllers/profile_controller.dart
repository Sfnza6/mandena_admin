import 'package:get/get.dart';

class ProfileController extends GetxController {
  // بيانات المستخدم (اربطها لاحقاً بالـ API إن حبيت)
  final name = 'عبدالرحيم خالد'.obs;
  final role = 'admin'.obs; // يظهر تحت الاسم
  final avatar = 'https://i.pravatar.cc/150?img=15'.obs;

  // الكروت الأولى
  final primaryCards = const [
    ProfileItem('معلومات عامة', 'person_outline'),
    // ProfileItem('العناوين', 'map_outlined'),
    ProfileItem('سجل الطلبات', 'history_toggle_off'),
  ];

  // الكروت الثانية
  final secondaryCards = const [
    ProfileItem('المستخدمين', 'groups_2_outlined'),
    ProfileItem('السائقين', 'local_shipping_outlined'),
    // ProfileItem('الشكاوي', 'mark_email_unread_outlined'),
    ProfileItem('الإدارة', 'admin_panel_settings_outlined'),
  ];
}

class ProfileItem {
  final String title;
  final String iconName;
  const ProfileItem(this.title, this.iconName);
}
