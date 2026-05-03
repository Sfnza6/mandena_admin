class Env {
  static const base = "https://mandena.ly/mandena"; // عدّلها
  static const String driverApiBase = '$base/api/driver/';

  // ===== المكوّنات والأصناف (Admin) =====
  static const itemsSimpleList = '$base/admin_get_items.php';
  static const componentsList = '$base/admin_get_components.php';
  static const itemComponentsGet = '$base/admin_get_item_components.php';
  static const itemComponentsSave = '$base/admin_save_item_components.php';
  static const componentAdd = '$base/admin_add_component.php';
  static const componentUpdate = '$base/admin_update_component.php';
  static const componentDelete = '$base/admin_delete_component.php';

  // (الباقي كما هو عندك)

  static String url(String path) {
    if (path.startsWith('http')) return path;
    // نتأكد من عدم تكرار الشرطتين المائلتين
    final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final p = path.startsWith('/') ? path.substring(1) : path;
    return '$b/$p';
  }

  // توكن الأدمن (لو سكربتاتك تحتاجه)
  static const adminToken = "PUT-ADMIN-TOKEN";
  static const uploadImage = "$base/upload_image.php"; // جديد

  // Orders
  static const ordersList = "$base/get_orders.php"; // GET ?status=pending
  static const orderUpdate =
      "$base/update_order_status.php"; // POST order_id,status
  static const orderDetails =
      '/get_order_details.php'; // 👈 الجديد: تفاصيل الطلب (نفس المستخدم)

  // Categories
  static const categoriesList = "$base/get_categories.php"; // GET
  static const categoryAdd =
      "$base/add_category.php"; // POST name (+ image multipart إن وُجدت)
  static const categoryUpdate =
      "$base/update_category.php"; // POST id,name,image_url,active
  static const categoryDelete = "$base/delete_category.php"; // POST id

  // Items
  static const itemsList = "$base/get_items.php";
  static const itemAdd = "$base/add_item.php";
  static const itemUpdate = "$base/update_item.php";
  static const itemDelete = "$base/delete_item.php";

  // Offers
  static const offersList = "$base/get_offers.php";
  static const offerAdd = "$base/add_offer.php";
  static const offerUpdate = "$base/update_offer.php";
  static const offerDelete = "$base/delete_offer.php";

  // Dashboard (لو عندك سكربتات)
  static const stats = "$base/dashboard_stats.php";
  static const mostOrdered = "$base/admin_most_ordered.php";
  static const reviews = "$base/reviews.php";

  // Users
  static const usersList = "$base/get_user.php";
  static const userById = "$base/get_user_by_id.php"; // ?user_id=#
  static const userOrders = "$base/get_user_orders.php"; // ?user_id=#
  static const getUserDetails = '$base/get_user_details.php';
  static const updateuserban = '$base/update_user_ban.php';

  // Drivers
  static const addDriver = "$base/add_driver.php";
  static const deleteDriver = "$base/delete_driver.php";
  static const driverById = "$base/get_driver_by_id.php";
  static const driversList = "$base/get_drivers.php";
  static const orderAssignDriver = "$base/assign_driver.php";
  static const assignedOrders = '$base/get_assigned_orders.php';

  // تتبع التوصيل التلقائي للأدمن / الريسيفر
  static const adminDriverTracking =
      '$base/api/driver/admin_driver_tracking.php';
  static const adminDriversLive = '$base/api/driver/admin_drivers_live.php';
  static const forceAssignDriver = '$base/api/driver/force_assign_driver.php';

  // ✅ مسارات واجهة السائق (داش بورد + الإغلاقات)
  static const String driverDashboard = '${driverApiBase}dashboard.php';
  static const String driverClosuresList = '${driverApiBase}closures_list.php';

  // Admins
  static const loginAdmin = '$base/login_admin.php';
  static const me = '$base/me.php';
  static const addAdmin = '$base/add_admin.php';
  static const adminGetById = "$base/get_staff_by_id.php";
  static const adminChangePassword = "$base/update_admin_password.php";

  // receivers
  static const String orderItems =
      '$base/get_order_items.php'; // جديد لعرض العناصر
  static const String assignDriver =
      '$base/assign_driver.php'; // جديد لتكليف السائق
  static const receiverLogin = '$base/login_receiver.php';
  static const ordersInbox = '$base/orders_inbox.php';
  static const orderSetStatus = '$base/order_set_status.php';
  static const itemsWithActive = '$base/items_list_with_active.php';
  static const itemToggleActive = '$base/iforenta_api/item_toggle_active.php';
  static const String ordersVersion = 'orders_version.php'; // نسبي
  static const String ordersVersionAbs = '$base/orders_version.php'; // مطلق

  ///
  // Staff
  static const staffList = "$base/get_staff.php";
  static const staffAdd = "$base/add_admin.php";
  static const staffDelete = "$base/delete_staff.php";
  static const staffUpdateRole = "$base/update_staff_role.php";

  // Receiver items
  static const receiverGetItems = '$base/receiver_get_items.php';
  static const receiverToggleItem = '$base/receiver_toggle_item.php';
  static const receiverSetQuota = '$base/receiver_set_quota.php';
  // يُستخدم عند تأكيد الطلب لتخفيض الكمية
  static const receiverDecQuota = '$base/receiver_decrement_quota.php';

  // إضافة ثابتين للمسارات (مثال)
  static const String itemComments =
      '$base/item_comments.php'; // موجود عندك مسبقًا أو المسار الفعلي
  static const String adminDeleteComment =
      '$base/admin_delete_comment.php'; // المسار الجديد

  // =============================
  // 🔥 إعدادات التوصيل (Admin)
  // =============================
  static const deliveryConfigGet = '$base/admin/delivery/get_config.php';
  static const deliveryConfigSave = '$base/admin/delivery/save_config.php';

  // Branches
  static const branchesList = "$base/get_branches.php";
  static const branchAdd = "$base/add_branch.php";
  static const branchUpdate = "$base/update_branch.php";
  static const branchDelete = "$base/delete_branch.php";
}
