import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  static const String _gymEmailSuffix = '@gym.com';
  final _emailController = TextEditingController();
  final _answerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthController _auth = Get.put(AuthController());
  String? _fetchedQuestion;
  bool _pwdTooShort = false;
  bool _pwdMismatch = false;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;
  bool _isFetchingQuestion = false;

  Future<void> _verifyEmailAndFetchQuestion() async {
    final localEmailPart = _emailController.text.trim();
    if (localEmailPart.isEmpty) {
      Get.snackbar('تنبيه ⚠️', 'يرجى إدخال البريد الإلكتروني',
          backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      return;
    }
    final email = '$localEmailPart$_gymEmailSuffix';
    
    setState(() {
      _isFetchingQuestion = true;
    });
    
    final q = await _auth.fetchSecurityQuestionByEmail(email);
    
    setState(() {
      _isFetchingQuestion = false;
    });

    if (q == null || q.isEmpty) {
      Get.snackbar('خطأ ❌', 'لم يتم العثور على سؤال أمان لهذا البريد',
          backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.TOP);
    } else {
      setState(() {
        _fetchedQuestion = q;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استعادة الحساب')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                'إعادة تعيين كلمة المرور',
                style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('أجب على سؤال الأمان لتتمكن من إعادة التعيين'),
              const SizedBox(height: 32),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textAlign: TextAlign.end,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'[\u0600-\u06FF\s@]')),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'email name',
                    suffixText: _gymEmailSuffix,
                    suffixStyle: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isFetchingQuestion ? null : _verifyEmailAndFetchQuestion,
                  child: _isFetchingQuestion
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('التحقق من البريد وجلب سؤال الأمان'),
                ),
              ),
              const SizedBox(height: 12),
              if (_fetchedQuestion != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _fetchedQuestion!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _answerController,
                  decoration: const InputDecoration(hintText: 'إجابة سؤال الأمان'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _hideNewPassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  enableInteractiveSelection: false,
                  obscuringCharacter: '•',
                  onChanged: (val) => setState(() {
                    _pwdTooShort = val.length < 6;
                    _pwdMismatch = _confirmPasswordController.text.isNotEmpty &&
                        _confirmPasswordController.text != val;
                  }),
                  decoration: InputDecoration(
                    hintText: 'كلمة المرور الجديدة',
                    errorText: _pwdTooShort ? 'كلمة المرور يجب أن تكون 6 محارف على الأقل' : null,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(_hideNewPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _hideNewPassword = !_hideNewPassword),
                        ),
                        if (_newPasswordController.text.isNotEmpty && !_pwdTooShort)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.check_circle, color: Colors.green),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _hideConfirmPassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  enableInteractiveSelection: false,
                  obscuringCharacter: '•',
                  onChanged: (val) => setState(() {
                    _pwdMismatch = val != _newPasswordController.text;
                  }),
                  decoration: InputDecoration(
                    hintText: 'تأكيد كلمة المرور الجديدة',
                    errorText: _pwdMismatch ? 'كلمة المرور غير متطابقة' : null,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(_hideConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _hideConfirmPassword = !_hideConfirmPassword),
                        ),
                        if (_confirmPasswordController.text.isNotEmpty && !_pwdMismatch && !_pwdTooShort)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.check_circle, color: Colors.green),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _auth.isLoading.value ? null : () {
                      if (_pwdTooShort) {
                        Get.snackbar('تنبيه ⚠️', 'كلمة المرور يجب أن تكون 6 محارف على الأقل',
                            backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.TOP);
                        return;
                      }
                      if (_pwdMismatch) {
                        Get.snackbar('تنبيه ⚠️', 'كلمة المرور الجديدة وتأكيدها غير متطابقتين',
                            backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.TOP);
                        return;
                      }
                      final localEmailPart = _emailController.text.trim();
                      _auth.forgotPassword(
                        email: localEmailPart.isEmpty ? '' : '$localEmailPart$_gymEmailSuffix',
                        securityAnswer: _answerController.text.trim(),
                        newPassword: _newPasswordController.text,
                        confirmPassword: _confirmPasswordController.text,
                      );
                    },
                    child: _auth.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('تغيير كلمة المرور'),
                  ),
                )),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
