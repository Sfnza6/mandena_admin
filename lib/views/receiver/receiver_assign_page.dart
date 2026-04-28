// lib/views/receiver/receiver_assign_page.dart
// تم إلغاء التكليف اليدوي. هذه الصفحة أصبحت صفحة تتبع التوصيل.
import 'package:flutter/material.dart';
import 'package:mandena_admin/views/delivery_tracking_view.dart';

class ReceiverAssignPage extends StatelessWidget {
  const ReceiverAssignPage({super.key});

  @override
  Widget build(BuildContext context) => const DeliveryTrackingView();
}
