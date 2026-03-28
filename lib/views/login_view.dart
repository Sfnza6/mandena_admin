import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena_admin/controllers/AuthController.dart';
import '../../core/routes/app_routes.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final auth = Get.find<AuthController>();

  bool _obscure = true;

  @override
  void dispose() {
    phoneCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const kCharcoal = Color(0xFF242226);
    const kGold = Color(0xFFC9A227);
    const kSoftBg = Color(0xFFF6F4F1);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pageBg = isDark ? const Color(0xFF111114) : kSoftBg;
    final cardColor = isDark ? const Color(0xFF1A1A1F) : Colors.white;
    final primaryText = isDark ? Colors.white : kCharcoal;
    final secondaryText = isDark ? Colors.white70 : const Color(0xFF7C7A80);
    final fieldFill = isDark
        ? const Color(0xFF141418)
        : const Color(0xFFF3F1EE);
    final fieldBorder = isDark
        ? Colors.white.withOpacity(.08)
        : const Color(0xFFE7E2DB);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _EvorantaBackgroundPainter(
                  strokeColor: isDark
                      ? Colors.white.withOpacity(.05)
                      : kCharcoal.withOpacity(.06),
                  accentColor: kGold.withOpacity(isDark ? .09 : .12),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),

                        Container(
                          width: 94,
                          height: 94,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(.08)
                                  : kCharcoal.withOpacity(.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.06),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/images/ev.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.restaurant_menu_rounded,
                                  size: 38,
                                  color: kCharcoal,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          'Mandena Admin',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 23,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 72,
                          height: 3,
                          decoration: BoxDecoration(
                            color: kGold,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'لوحة تحكم مندينا',
                          style: TextStyle(
                            color: primaryText,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'سجّل دخولك لإدارة الطلبات والمستخدمين',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 22),

                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: fieldBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.05),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                            child: Form(
                              key: _formKey,
                              child: Obx(
                                () => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'تسجيل الدخول',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: primaryText,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'أدخل بيانات حساب الأدمن أو المستقبِل',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: secondaryText,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    TextFormField(
                                      controller: phoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      decoration: _dec(
                                        hint: 'رقم الهاتف',
                                        icon: Icons.phone_iphone_rounded,
                                        fillColor: fieldFill,
                                        borderColor: fieldBorder,
                                        labelColor: isDark
                                            ? Colors.white70
                                            : const Color(0xFF66626A),
                                        iconColor: isDark
                                            ? Colors.white70
                                            : const Color(0xFF5E5A60),
                                      ),
                                      validator: (v) => v!.trim().isEmpty
                                          ? 'أدخل رقم الهاتف'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),

                                    TextFormField(
                                      controller: passCtrl,
                                      obscureText: _obscure,
                                      decoration: _dec(
                                        hint: 'كلمة المرور',
                                        icon: Icons.lock_outline_rounded,
                                        fillColor: fieldFill,
                                        borderColor: fieldBorder,
                                        labelColor: isDark
                                            ? Colors.white70
                                            : const Color(0xFF66626A),
                                        iconColor: isDark
                                            ? Colors.white70
                                            : const Color(0xFF5E5A60),
                                        suffix: IconButton(
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black45,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscure = !_obscure;
                                            });
                                          },
                                        ),
                                      ),
                                      validator: (v) => v!.isEmpty
                                          ? 'أدخل كلمة المرور'
                                          : null,
                                    ),
                                    const SizedBox(height: 18),

                                    SizedBox(
                                      height: 52,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kCharcoal,
                                          disabledBackgroundColor: kCharcoal
                                              .withOpacity(.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: auth.isBusy.value
                                            ? null
                                            : () async {
                                                if (!_formKey.currentState!
                                                    .validate()) {
                                                  return;
                                                }
                                                final ok = await auth.login(
                                                  phone: phoneCtrl.text.trim(),
                                                  password: passCtrl.text,
                                                );
                                                if (!ok) return;

                                                final role =
                                                    (auth.admin.value?.role ??
                                                            '')
                                                        .toLowerCase()
                                                        .trim();
                                                if (role == 'receiver') {
                                                  Get.offAllNamed(
                                                    Routes.receiverHome,
                                                  );
                                                } else {
                                                  Get.offAllNamed(
                                                    Routes.dashboard,
                                                  );
                                                }
                                              },
                                        child: auth.isBusy.value
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'دخول',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'هذا الدخول مخصّص لفريق المطعم فقط',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec({
    required String hint,
    required IconData icon,
    required Color fillColor,
    required Color borderColor,
    required Color labelColor,
    required Color iconColor,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: labelColor, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: iconColor),
      suffixIcon: suffix,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFC9A227), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

class _EvorantaBackgroundPainter extends CustomPainter {
  final Color strokeColor;
  final Color accentColor;

  const _EvorantaBackgroundPainter({
    required this.strokeColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final double w = size.width * .58;
    final double h = 210;
    final double left = (size.width - w) / 2;
    const double top = 26;
    const double r = 42;

    final frame = Path()
      ..moveTo(left, top + 48)
      ..lineTo(left, top + r)
      ..quadraticBezierTo(left, top, left + r, top)
      ..lineTo(left + w - r, top)
      ..quadraticBezierTo(left + w, top, left + w, top + r)
      ..lineTo(left + w, top + 92)
      ..moveTo(left, top + 146)
      ..lineTo(left, top + h - r)
      ..quadraticBezierTo(left, top + h, left + r, top + h)
      ..lineTo(left + w - r, top + h)
      ..quadraticBezierTo(left + w, top + h, left + w, top + h - r)
      ..lineTo(left + w, top + 146);

    canvas.drawPath(frame, framePaint);

    final accentLine = Path()
      ..moveTo(size.width * .28, top + 118)
      ..lineTo(size.width * .72, top + 118);

    canvas.drawPath(accentLine, accentPaint);
  }

  @override
  bool shouldRepaint(covariant _EvorantaBackgroundPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.accentColor != accentColor;
  }
}
