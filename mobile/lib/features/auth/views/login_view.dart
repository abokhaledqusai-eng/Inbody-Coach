import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_colors.dart';
import 'register_view.dart';
import 'forgot_password_view.dart';
import '../controllers/auth_controller.dart';

class LoginView extends StatelessWidget {
  LoginView({super.key});

  static const String _gymEmailSuffix = '@gym.com';
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authController = Get.put(AuthController());
  final RxBool isPasswordHidden = true.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Base primary background
      body: Stack(
        children: [
          // ── Immersive Background ──────────────────────────────
          _buildImmersiveBackground(),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // ── Top Branding ────────────────────────────────
                  _buildTopBranding(),
                  
                  const SizedBox(height: 50),
                  
                  // ── Bottom Form Card ────────────────────────────
                  _buildFormCard(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImmersiveBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
            Colors.white,
          ],
          stops: const [0.0, 0.4, 0.45],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 100,
            left: -50,
            child: Icon(Icons.bolt_rounded, size: 300, color: Colors.white.withValues(alpha: 0.05)),
          ),
          Positioned(
            top: 250,
            right: -30,
            child: Icon(Icons.fitness_center_rounded, size: 200, color: Colors.white.withValues(alpha: 0.03)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBranding() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 15),
          RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900),
              children: [
                const TextSpan(text: 'INBODY', style: TextStyle(color: Colors.white, letterSpacing: 1.5)),
                TextSpan(text: 'COACH', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'خطوتك نحو جسم أفضل 🦾',
            style: GoogleFonts.cairo(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          Text(
            'أدخل بياناتك للمتابعة من حيث توقفت',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.blueGrey.shade400,
            ),
          ),
          const SizedBox(height: 35),
          
          // Form Fields
          _buildModernField(
            controller: emailController,
            label: 'البريد الإلكتروني',
            hint: 'email name',
            icon: Icons.person_outline_rounded,
            isLtr: true,
            suffixText: _gymEmailSuffix,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\u0600-\u06FF\s@]'))],
          ),
          const SizedBox(height: 20),
          Obx(() => _buildModernField(
            controller: passwordController,
            label: 'كلمة المرور',
            hint: '••••••••',
            icon: Icons.lock_open_rounded,
            isPassword: true,
            isPasswordHidden: isPasswordHidden.value,
            onPasswordToggle: () => isPasswordHidden.value = !isPasswordHidden.value,
          )),
          
          const SizedBox(height: 12),
          // Links Row
          _buildLinksRow(),
          
          const SizedBox(height: 35),
          _buildActionButtons(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLinksRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Right: Create Account
        InkWell(
          onTap: () => Get.to(() => const RegisterView()),
          child: Text(
            'إنشاء حساب جديد',
            style: GoogleFonts.cairo(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        // Left: Forgot Password
        InkWell(
          onTap: () => Get.to(() => const ForgotPasswordView()),
          child: Text(
            'نسيت كلمة المرور؟',
            style: GoogleFonts.cairo(
              color: Colors.blueGrey.shade400,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isLtr = false,
    bool isPassword = false,
    bool isPasswordHidden = false,
    VoidCallback? onPasswordToggle,
    String? suffixText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF334155),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueGrey.shade100.withValues(alpha: 0.5)),
          ),
          child: Directionality(
            textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
            child: TextFormField(
              controller: controller,
              obscureText: isPassword && isPasswordHidden,
              textAlign: isLtr ? TextAlign.end : TextAlign.right,
              inputFormatters: inputFormatters,
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.blueGrey.shade200),
                prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
                suffixText: suffixText,
                suffixStyle: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold),
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(isPasswordHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, 
                                   color: Colors.blueGrey.shade400, size: 20),
                        onPressed: onPasswordToggle,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: Obx(() => ElevatedButton(
        onPressed: authController.isLoading.value
            ? null
            : () {
                HapticFeedback.heavyImpact();
                final localEmailPart = emailController.text.trim();
                authController.login(
                  localEmailPart.isEmpty ? '' : '$localEmailPart$_gymEmailSuffix',
                  passwordController.text,
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
        child: authController.isLoading.value
            ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'انطلق الآن',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
      )),
    );
  }


}
