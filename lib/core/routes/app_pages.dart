import 'package:get/get.dart';
import 'package:mandena_admin/controllers/admin_profile_controller.dart';
import 'package:mandena_admin/controllers/branches_controller.dart';
import 'package:mandena_admin/controllers/driver_details_controller.dart';
import 'package:mandena_admin/controllers/drivers_controller.dart';
import 'package:mandena_admin/controllers/delivery_tracking_controller.dart';
import 'package:mandena_admin/controllers/profile_controller.dart';
import 'package:mandena_admin/controllers/receiver_items_controller.dart';
import 'package:mandena_admin/controllers/staff_controller.dart';
import 'package:mandena_admin/controllers/user_details_controller.dart';
import 'package:mandena_admin/controllers/users_controller.dart';
import 'package:mandena_admin/modules/admin/views/broadcast_notification_page.dart';
import 'package:mandena_admin/modules/delivery/delivery_settings_controller.dart';
import 'package:mandena_admin/modules/delivery/delivery_settings_view.dart';
import 'package:mandena_admin/modules/settings/payment_settings/payment_settings_controller.dart';
import 'package:mandena_admin/modules/settings/payment_settings/payment_settings_page.dart';
import 'package:mandena_admin/views/branches_view.dart';
import 'package:mandena_admin/views/branch_map_picker_view.dart';
import 'package:mandena_admin/views/categories_view.dart';
import 'package:mandena_admin/views/dashboard_view.dart';
import 'package:mandena_admin/views/driver_details_view.dart';
import 'package:mandena_admin/views/delivery_tracking_view.dart';
import 'package:mandena_admin/views/drivers_view.dart' show DriversView;
import 'package:mandena_admin/views/gate/decide_gate.dart';
import 'package:mandena_admin/views/general_info_view.dart';
import 'package:mandena_admin/views/item_comments_view.dart';
import 'package:mandena_admin/views/item_components_view.dart';
import 'package:mandena_admin/views/items_view.dart';
import 'package:mandena_admin/views/login_view.dart';
import 'package:mandena_admin/views/offers_view.dart';
import 'package:mandena_admin/views/orders_view.dart';
import 'package:mandena_admin/views/profile_view.dart';
import 'package:mandena_admin/views/receiver/receiver_home_view.dart';
import 'package:mandena_admin/views/receiver/receiver_items_view.dart';
import 'package:mandena_admin/views/staff_management_view.dart';
import 'package:mandena_admin/views/user_details_view.dart';
import 'package:mandena_admin/views/users_view.dart';

import '../../controllers/dashboard_controller.dart';
import '../../controllers/orders_controller.dart';
import '../../controllers/categories_controller.dart';
import '../../controllers/items_controller.dart';
import '../../controllers/offers_controller.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = Routes.dashboard;

  static final pages = <GetPage>[
    GetPage(
      name: Routes.dashboard,
      page: () => const DashboardView(),
      binding: BindingsBuilder(() {
        Get.put<DashboardController>(DashboardController());
      }),
    ),
    GetPage(
      name: Routes.orders,
      page: () => const OrdersView(),
      binding: BindingsBuilder(() {
        Get.put<OrdersController>(OrdersController());
      }),
    ),
    GetPage(
      name: Routes.categories,
      page: () => const CategoriesView(),
      binding: BindingsBuilder(() {
        Get.put<CategoriesController>(CategoriesController());
      }),
    ),

    // صفحة تعليقات الصنف — تقرأ الـ itemId من عدة احتمالات
    GetPage(
      name: Routes.itemComments,
      page: () {
        final args = Get.arguments;
        int itemId = 0;

        if (args is int) {
          itemId = args;
        } else if (args is Map) {
          final dynamic raw =
              args['itemId'] ?? args['id'] ?? args['item_id'] ?? args['itemID'];
          itemId = int.tryParse('$raw') ?? 0;
        }

        return ItemCommentsView(itemId: itemId);
      },
    ),

    GetPage(
      name: Routes.paymentSettings,
      page: () => const PaymentSettingsPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PaymentSettingsController>(
          () => PaymentSettingsController(),
        );
      }),
    ),

    GetPage(
      name: Routes.broadcastNotification,
      page: () => const BroadcastNotificationPage(),
    ),

    GetPage(
      name: Routes.items,
      page: () => const ItemsView(),
      binding: BindingsBuilder(() {
        Get.put<ItemsController>(ItemsController());
      }),
    ),
    GetPage(
      name: Routes.offers,
      page: () => const OffersView(),
      binding: BindingsBuilder(() {
        Get.put<OffersController>(OffersController());
      }),
    ),
    GetPage(
      name: Routes.profile,
      page: () => const ProfileView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ProfileController>(() => ProfileController());
      }),
    ),
    GetPage(
      name: Routes.users,
      page: () => const UsersView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<UsersController>(() => UsersController());
      }),
    ),
    GetPage(
      name: Routes.drivers,
      page: () => const DriversView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DriversController>(() => DriversController());
      }),
    ),
    GetPage(
      name: Routes.deliveryTracking,
      page: () => const DeliveryTrackingView(),
      binding: BindingsBuilder(() {
        Get.put<DeliveryTrackingController>(DeliveryTrackingController());
      }),
    ),
    GetPage(name: Routes.login, page: () => const LoginView()),
    GetPage(name: Routes.decide, page: () => const DecideGate()),
    GetPage(name: Routes.receiverHome, page: () => const ReceiverHomeView()),
    GetPage(
      name: Routes.receiverassign,
      page: () => const DeliveryTrackingView(),
      binding: BindingsBuilder(() {
        Get.put<DeliveryTrackingController>(DeliveryTrackingController());
      }),
    ),
    GetPage(
      name: Routes.userDetails,
      page: () => const UserDetailsView(),
      binding: BindingsBuilder(() {
        final args = Get.parameters;
        final userId =
            int.tryParse(args['id'] ?? '${Get.arguments?['id'] ?? 0}') ?? 0;
        final initialName = args['name'] ?? Get.arguments?['name'];
        final initialPhone = args['phone'] ?? Get.arguments?['phone'];
        Get.put(
          UserDetailsController(
            userId,
            initialName: initialName,
            initialPhone: initialPhone,
          ),
        );
      }),
    ),
    GetPage(
      name: '/drivers/details',
      page: () => const DriverDetailsView(),
      binding: BindingsBuilder(() {
        final p = Get.parameters;
        final id = int.tryParse(p['id'] ?? '0') ?? 0;
        Get.put(
          DriverDetailsController(
            id,
            initialName: p['name'],
            initialPhone: p['phone'],
          ),
        );
      }),
    ),
    GetPage(
      name: '/admin/staff',
      page: () => const StaffManagementView(),
      binding: BindingsBuilder(() {
        Get.put(StaffController());
      }),
    ),
    GetPage(
      name: '/profile/general',
      page: () => const GeneralInfoView(),
      binding: BindingsBuilder(() {
        Get.put(AdminProfileController());
      }),
    ),

    GetPage(
      name: Routes.deliverySettings,
      page: () => const DeliverySettingsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DeliverySettingsController>(
          () => DeliverySettingsController(),
        );
      }),
    ),

    GetPage(
      name: Routes.itemComponents,
      page: () => const ItemComponentsView(),
    ),
    GetPage(
      name: Routes.receiverItems,
      page: () => const ReceiverItemsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ReceiverItemsController>(() => ReceiverItemsController());
      }),
    ),

    GetPage(
      name: Routes.branchMapPicker,
      page: () => const BranchMapPickerView(),
    ),
    GetPage(
      name: Routes.branches,
      page: () => const BranchesView(),
      binding: BindingsBuilder(() {
        Get.put<BranchesController>(BranchesController());
      }),
    ),
  ];
}
