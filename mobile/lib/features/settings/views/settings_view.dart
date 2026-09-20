import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../coaches/views/select_coach_view.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final SettingsController _controller = Get.put(SettingsController());

  @override
  void initState() {
    super.initState();
    _controller.fetchMe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.userData.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final profileImageUrl = _controller.userData['profile_image_url']?.toString() ?? '';
        final name = _controller.userData['name']?.toString() ?? 'مستخدم';

        return RefreshIndicator(
          onRefresh: _controller.fetchMe,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                      child: profileImageUrl.isEmpty
                          ? const Icon(Icons.person, color: AppColors.primary, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'تحكم بالملف الشخصي',
                            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.to(() => EditProfileView(controller: _controller)),
                      icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle('الحساب والخصوصية'),
              const SizedBox(height: 8),
              _item(
                title: 'المدرب المخصص',
                icon: Icons.fitness_center_rounded,
                onTap: () {
                  final coach = _controller.userData['coach'];
                  if (coach != null) {
                    Get.to(() => AssignedCoachView(coach: coach, assignedAt: _controller.userData['coach_assigned_at']));
                  } else {
                    Get.to(() => const SelectCoachView());
                  }
                },
              ),
              _item(
                title: 'تعديل الملف الشخصي',
                icon: Icons.edit_outlined,
                onTap: () => Get.to(() => EditProfileView(controller: _controller)),
              ),
              _item(
                title: 'معلومات الحساب',
                icon: Icons.account_box_outlined,
                onTap: () => Get.to(() => AccountInfoView(controller: _controller)),
              ),
              _item(
                title: 'الأمان',
                icon: Icons.lock_outline,
                onTap: () => Get.to(() => SecurityMenuView(controller: _controller)),
              ),
              const SizedBox(height: 16),
              _sectionTitle('الدعم والمساعدة'),
              const SizedBox(height: 8),
              _item(title: 'تواصل معنا', icon: Icons.support_agent, onTap: _showContactOptions),
              const SizedBox(height: 16),
              _item(
                title: 'تسجيل الخروج',
                icon: Icons.logout,
                color: Colors.red.shade700,
                onTap: () {
                  Get.dialog(
                    AlertDialog(
                      title: Text('تسجيل الخروج', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      content: Text('هل أنت متأكد أنك تريد تسجيل الخروج من الحساب؟', style: GoogleFonts.cairo()),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.textLight)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Get.back();
                            _controller.logout();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: Text('خروج', style: GoogleFonts.cairo(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showContactOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 0),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'تواصل معنا',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يسعدنا الرد على استفساراتكم في أي وقت',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 28),
            _contactCard(
              title: 'تواصل عبر الواتس اب',
              subtitle: '0989700800',
              icon: FontAwesomeIcons.whatsapp,
              iconColor: const Color(0xFF25D366),
              onTap: () async {
                final waUrl = Uri.parse('https://wa.me/963989700800');
                if (await canLaunchUrl(waUrl)) {
                  await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                } else {
                  final waUrlAlt = Uri.parse('whatsapp://send?phone=963989700800');
                  if (await canLaunchUrl(waUrlAlt)) {
                    await launchUrl(waUrlAlt, mode: LaunchMode.externalApplication);
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            _contactCard(
              title: 'تواصل عبر الايميل',
              subtitle: 'nnklot@gmail.com',
              icon: Icons.email_outlined,
              iconColor: AppColors.primary,
              onTap: () async {
                final emailUrl = Uri.parse('mailto:nnklot@gmail.com?subject=استفسار من تطبيق Inbody Coach');
                if (await canLaunchUrl(emailUrl)) {
                  await launchUrl(emailUrl, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _contactCard({
    required String title,
    required String subtitle,
    required dynamic icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Get.back();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: title.contains('واتس')
                  ? SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="#25D366" d="M17.472 14.382c-.301-.15-1.767-.872-2.036-.969-.269-.099-.465-.148-.659.15-.195.299-.754.949-.924 1.149-.17.199-.341.224-.642.074-.301-.15-1.27-.467-2.42-1.493-.894-.798-1.498-1.783-1.674-2.083-.176-.3-.019-.462.13-.611.135-.133.301-.35.451-.524.15-.174.199-.299.299-.499.099-.2.05-.375-.025-.524-.075-.15-.659-1.591-.902-2.177-.238-.57-.479-.493-.659-.503-.17-.008-.365-.01-.56-.01s-.513.073-.782.375c-.269.3-.1.745-.1 1.25s.365 2.148.513 2.348c.148.2 2.82 4.305 6.832 6.035 2.585 1.114 3.655 1.144 4.965.952 1.417-.208 2.306-.827 2.628-1.637.323-.811.323-1.505.226-1.637-.099-.133-.365-.211-.666-.362zM12.006 0C5.378 0 .004 5.374.004 12.001c0 2.112.547 4.16 1.587 5.978L.068 24l6.183-1.623c1.762.96 3.748 1.465 5.755 1.465 6.626 0 12.001-5.375 12.001-12.002C24.007 5.374 18.632 0 12.006 0z"/></svg>',
                      width: 22,
                      height: 22,
                    )
                  : (icon is IconData
                      ? Icon(icon, color: iconColor, size: 22)
                      : FaIcon(icon, color: iconColor, size: 22)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
    );
  }

  Widget _item({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color ?? AppColors.primary),
        title: Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.text,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color ?? AppColors.textLight),
      ),
    );
  }
}

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.controller.userData['name']?.toString() ?? '';
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedImage = file;
      _pickedImageBytes = bytes;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'تنبيه ⚠️',
        'يرجى إدخال اسم المستخدم',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    final done = await widget.controller.updateProfile(name: name, profileImage: _pickedImage);
    if (done) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentImageUrl = widget.controller.userData['profile_image_url']?.toString() ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: _pickedImageBytes != null
                    ? MemoryImage(_pickedImageBytes!)
                    : (currentImageUrl.isNotEmpty ? NetworkImage(currentImageUrl) : null) as ImageProvider?,
                child: _pickedImageBytes == null && currentImageUrl.isEmpty
                    ? const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 30)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: _pickImage, child: const Text('تغيير الصورة')),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'اسم المستخدم',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton(
                    onPressed: widget.controller.isSavingProfile.value ? null : _save,
                    child: widget.controller.isSavingProfile.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('حفظ التعديلات'),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountInfoView extends StatelessWidget {
  const AccountInfoView({super.key, required this.controller});

  final SettingsController controller;

  String _value(dynamic input) {
    if (input == null) return '-';
    final text = input.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  @override
  Widget build(BuildContext context) {
    final user = controller.userData;
    final profile = (user['profile'] is Map<String, dynamic>)
        ? user['profile'] as Map<String, dynamic>
        : <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(title: const Text('معلومات الحساب')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _readOnlyField('الاسم', _value(user['name'])),
          _readOnlyField('البريد الإلكتروني', _value(user['email'])),
          _readOnlyField('العمر', _value(user['age'])),
          _readOnlyField('الجنس', _value(user['gender'] == 'male' ? 'ذكر' : user['gender'] == 'female' ? 'أنثى' : null)),
          _readOnlyField('التصنيف', _value(user['category_label'])),
          _readOnlyField('الطول', _value(profile['height'])),
          _readOnlyField('الوزن', _value(profile['weight'])),
          _readOnlyField('نسبة العضلات', _value(profile['muscle_percentage'])),
          _readOnlyField('نسبة الدهون', _value(profile['fat_percentage'])),
          _readOnlyField('محيط الخصر', _value(profile['waist'])),
          _readOnlyField('ملاحظات', _value(profile['notes'])),
        ],
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(value, style: GoogleFonts.cairo(fontSize: 13)),
      ),
    );
  }
}

class SecurityMenuView extends StatelessWidget {
  const SecurityMenuView({super.key, required this.controller});
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأمان')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => Get.to(() => ChangePasswordView(controller: controller)),
              leading: const Icon(Icons.lock_reset, color: AppColors.primary),
              title: Text('تغيير كلمة المرور', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
            ),
          ),
          Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => Get.to(() => ChangeSecurityQuestionView(controller: controller)),
              leading: const Icon(Icons.security, color: AppColors.primary),
              title: Text('تغيير سؤال الأمان', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }
}

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _isOldPasswordVerified = false;
  bool _isLoadingVerify = false;
  bool _isNewPasswordValid = false;
  bool _isConfirmPasswordValid = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() {
      setState(() {
        _isNewPasswordValid = _newPasswordController.text.length >= 6;
        _isConfirmPasswordValid = _newPasswordController.text == _confirmPasswordController.text && _confirmPasswordController.text.isNotEmpty;
      });
    });
    _confirmPasswordController.addListener(() {
      setState(() {
        _isConfirmPasswordValid = _newPasswordController.text == _confirmPasswordController.text && _confirmPasswordController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyOldPassword() async {
    final current = _currentPasswordController.text;
    if (current.isEmpty) {
      _warn('يرجى إدخال كلمة المرور الحالية');
      return;
    }
    
    setState(() {
      _isLoadingVerify = true;
    });

    final isValid = await widget.controller.verifyCurrentPassword(current);
    
    setState(() {
      _isLoadingVerify = false;
      if (isValid) {
        _isOldPasswordVerified = true;
      }
    });
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final current = _currentPasswordController.text;
    final next = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    final done = await widget.controller.changePassword(
      currentPassword: current,
      newPassword: next,
      confirmPassword: confirm,
    );
    
    if (done) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _isOldPasswordVerified = false;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Get.back();
    }
  }

  void _warn(String msg) {
    Get.snackbar(
      'تنبيه ⚠️',
      msg,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    required bool hideText,
    required VoidCallback onToggleVisibility,
    bool readOnly = false,
    String? Function(String?)? validator,
    bool isValid = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: hideText,
      readOnly: readOnly,
      autovalidateMode: validator != null ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(hideText ? Icons.visibility_off : Icons.visibility),
              onPressed: onToggleVisibility,
            ),
            if (isValid) const Icon(Icons.check, color: Colors.green),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تغيير كلمة المرور')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildPasswordField(
                controller: _currentPasswordController,
                hint: 'كلمة المرور الحالية',
                prefixIcon: Icons.lock_outline,
                hideText: _hideCurrent,
                onToggleVisibility: () => setState(() => _hideCurrent = !_hideCurrent),
                readOnly: _isOldPasswordVerified,
                isValid: _isOldPasswordVerified,
              ),
              const SizedBox(height: 12),
              if (!_isOldPasswordVerified)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoadingVerify ? null : _verifyOldPassword,
                    child: _isLoadingVerify 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('تحقق'),
                  ),
                ),
              if (_isOldPasswordVerified) ...[
                _buildPasswordField(
                  controller: _newPasswordController,
                  hint: 'كلمة المرور الجديدة',
                  prefixIcon: Icons.lock_reset,
                  hideText: _hideNew,
                  onToggleVisibility: () => setState(() => _hideNew = !_hideNew),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return '⚠️ كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                  isValid: _isNewPasswordValid,
                ),
                const SizedBox(height: 12),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  hint: 'تأكيد كلمة المرور الجديدة',
                  prefixIcon: Icons.lock_person_outlined,
                  hideText: _hideConfirm,
                  onToggleVisibility: () => setState(() => _hideConfirm = !_hideConfirm),
                  validator: (val) {
                    if (val != _newPasswordController.text) {
                      return '⚠️ كلمات المرور غير متطابقة';
                    }
                    return null;
                  },
                  isValid: _isConfirmPasswordValid,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => ElevatedButton(
                        onPressed: widget.controller.isChangingPassword.value ? null : _changePassword,
                        child: widget.controller.isChangingPassword.value
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('تغيير كلمة المرور'),
                      )),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class ChangeSecurityQuestionView extends StatefulWidget {
  const ChangeSecurityQuestionView({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<ChangeSecurityQuestionView> createState() => _ChangeSecurityQuestionViewState();
}

class _ChangeSecurityQuestionViewState extends State<ChangeSecurityQuestionView> {
  final _formKey = GlobalKey<FormState>();
  final _currentAnswerController = TextEditingController();
  final _newAnswerController = TextEditingController();
  bool _isOldAnswerVerified = false;
  bool _isLoadingVerify = false;
  String? _selectedQuestion;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = Get.put(AuthController());
    _authController.loadSecurityQuestions();
  }

  @override
  void dispose() {
    _currentAnswerController.dispose();
    _newAnswerController.dispose();
    super.dispose();
  }

  Future<void> _verifyOldAnswer() async {
    final current = _currentAnswerController.text;
    if (current.isEmpty) {
      Get.snackbar('تنبيه ⚠️', 'يرجى إدخال الإجابة', backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      return;
    }
    
    setState(() {
      _isLoadingVerify = true;
    });

    final isValid = await widget.controller.verifySecurityAnswer(current);
    
    setState(() {
      _isLoadingVerify = false;
      if (isValid) {
        _isOldAnswerVerified = true;
      } else {
         _currentAnswerController.clear();
      }
    });
  }

  Future<void> _changeQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedQuestion == null) {
      Get.snackbar('تنبيه ⚠️', 'يرجى اختيار سؤال', backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      return;
    }

    final newAnswer = _newAnswerController.text;

    final done = await widget.controller.changeSecurityQuestion(
      newQuestion: _selectedQuestion!,
      newAnswer: newAnswer,
    );
    
    if (done) {
      _currentAnswerController.clear();
      _newAnswerController.clear();
      setState(() {
        _isOldAnswerVerified = false;
        _selectedQuestion = null;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.controller.userData['security_question']?.toString() ?? 'سؤال الأمان غير محدد';

    return Scaffold(
      appBar: AppBar(title: const Text('تغيير سؤال الأمان')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('سؤال الأمان الحالي:', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(currentQuestion, style: GoogleFonts.cairo(fontSize: 16, color: AppColors.primary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentAnswerController,
                readOnly: _isOldAnswerVerified,
                decoration: InputDecoration(
                  hintText: 'إجابة سؤال الأمان الحالي',
                  prefixIcon: const Icon(Icons.security),
                  suffixIcon: _isOldAnswerVerified ? const Icon(Icons.check, color: Colors.green) : null,
                ),
              ),
              const SizedBox(height: 12),
              if (!_isOldAnswerVerified)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoadingVerify ? null : _verifyOldAnswer,
                    child: _isLoadingVerify 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('تحقق من الإجابة'),
                  ),
                ),
              if (_isOldAnswerVerified) ...[
                const Divider(height: 32),
                Text('اختر سؤال أمان جديد:', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Obx(() => DropdownButtonFormField<String>(
                  value: _selectedQuestion,
                  hint: const Text('سؤال الأمان'),
                  items: _authController.securityQuestions.map((String q) {
                    return DropdownMenuItem<String>(
                      value: q,
                      child: Text(q, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (String? val) {
                    setState(() {
                      _selectedQuestion = val;
                    });
                  },
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return '⚠️ يرجى اختيار سؤال الأمان';
                    }
                    return null;
                  },
                )),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newAnswerController,
                  decoration: const InputDecoration(
                    hintText: 'الإجابة الجديدة',
                    prefixIcon: Icon(Icons.question_answer_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return '⚠️ يرجى إدخال الإجابة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => ElevatedButton(
                        onPressed: widget.controller.isChangingPassword.value ? null : _changeQuestion,
                        child: widget.controller.isChangingPassword.value
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('حفظ التغييرات'),
                      )),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class AssignedCoachView extends StatelessWidget {
  const AssignedCoachView({super.key, required this.coach, this.assignedAt});

  final Map<String, dynamic> coach;
  final dynamic assignedAt;

  @override
  Widget build(BuildContext context) {
    final profile = coach['coach_profile'] ?? {};
    final certificates = profile['certificates'] is List ? (profile['certificates'] as List) : [];
    final imageUrl = coach['profile_image_url']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('المدرب المخصص')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty
                  ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              coach['name'] ?? 'بدون اسم',
              style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
          ),
          const SizedBox(height: 30),
          
          _buildInfoRow(Icons.cake_outlined, 'العمر', '${coach['age'] ?? '-'} سنة'),
          const Divider(),
          _buildInfoRow(Icons.timeline, 'سنوات الخبرة', '${profile['experience_duration'] ?? '-'}'),
          const Divider(),
          
          const SizedBox(height: 16),
          if (assignedAt != null) ...[
            _buildInfoRow(Icons.calendar_month, 'تاريخ الاشتراك', assignedAt.toString().substring(0, 10)),
            const Divider(),
          ],
          
          const SizedBox(height: 16),
          Text('نبذة عن المدرب', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              (profile['bio'] ?? 'لا توجد نبذة.').toString().replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
              style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textLight, height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
          
          if (certificates.isNotEmpty) ...[
            Text('الشهادات والإنجازات', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: certificates.length,
                itemBuilder: (context, index) {
                  final certUrl = certificates[index];
                  final fullUrl = certUrl.toString().startsWith('http') 
                      ? certUrl 
                      : 'http://127.0.0.1:8000/api/image/$certUrl';

                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      image: DecorationImage(
                        image: NetworkImage(fullUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.cairo(fontSize: 15, color: AppColors.textLight)),
          const Spacer(),
          Text(value, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text)),
        ],
      ),
    );
  }
}
