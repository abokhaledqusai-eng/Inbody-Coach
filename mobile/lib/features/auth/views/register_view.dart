import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/app_colors.dart';
import '../controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  static const String _gymEmailSuffix = '@gym.com';
  int _currentStep = 0;
  final AuthController _authController = Get.put(AuthController());

  // ── Step 1 Controllers ────────────────────────────────
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  String? _selectedSecurityQuestion;
  final RxList<String> _securityQuestions = <String>[].obs;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _profileImage;
  Uint8List? _profileImageBytes;

  // ── Step 2 Controllers ────────────────────────────────
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String? _gender;
  bool _isPregnant = false;
  int _pregnancyMonth = 1;

  // ── Step 3 Controllers ────────────────────────────────
  final _muscleController = TextEditingController();
  final _fatController = TextEditingController();
  final _waistController = TextEditingController();
  final _notesController = TextEditingController();
  final _otherDiseaseController = TextEditingController();
  final _medicationNameController = TextEditingController();
  final _otherAllergyController = TextEditingController();
  final _inbodyWeightController = TextEditingController();

  int _inBodyMethod = 0; // 0: Manual, 1: File
  List<XFile> _inbodyFiles = [];
  List<Uint8List> _inbodyFilesBytes = [];
  int _stepThreePhase = 0; // 0: InBody, 1: Target Goals, 2: Health Report

  // Target Goals State
  final _targetWeightController = TextEditingController();
  String? _selectedBodyGoal;

  final List<String> _bodyGoalsList = [
    'خسارة الوزن والتنشيف',
    'بناء العضلات والتضخيم',
    'الحفاظ على اللياقة والوزن',
    'تحسين الصحة العامة',
  ];

  // Health Report State
  bool? _hasDiseases; // null, true, false
  final List<String> _selectedDiseases = [];
  bool _showOtherDiseaseInput = false;

  bool? _hasMedications;
  
  bool? _hasAllergies;
  final List<String> _selectedAllergies = [];
  bool _showOtherAllergyInput = false;

  // ── Password Visibility State ─────────────────────────
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  // ── Realtime validation state ──────────────────────────
  bool _passwordTooShort = false;
  bool _passwordMismatch = false;
  String? _emailError;
  String? _ageError;
  bool _isCheckingEmail = false;
  bool _isEmailAvailable = false;
  int _emailRequestNonce = 0;
  Timer? _emailDebounce;

  // ── Email validation ───────────────────────────────────
  Future<void> _onEmailChanged(String val) async {
    final value = val.trim();
    _emailDebounce?.cancel();
    setState(() {
      _isCheckingEmail = false;
      _isEmailAvailable = false;
      if (value.isEmpty) {
        _emailError = null;
      } else if (RegExp(r'[\u0600-\u06FF]').hasMatch(value)) {
        _emailError = 'لا يُسمح بإدخال أحرف عربية في البريد الإلكتروني ❌';
      } else if (value.contains('@')) {
        _emailError = 'اكتب اسم البريد فقط بدون @ لأن اللاحقة ثابتة ❌';
      } else if (!RegExp(r'^[a-zA-Z0-9._%+\-]+$').hasMatch(value)) {
        _emailError = 'اسم البريد غير صالح ❌';
      } else {
        _emailError = null;
      }
    });

    if (value.isEmpty || _emailError != null) {
      return;
    }

    final int requestNonce = ++_emailRequestNonce;
    setState(() {
      _isCheckingEmail = true;
    });

    _emailDebounce = Timer(const Duration(milliseconds: 450), () async {
      final available = await _authController.isEmailAvailable('$value$_gymEmailSuffix');
      if (!mounted || requestNonce != _emailRequestNonce) return;

      setState(() {
        _isCheckingEmail = false;
        if (available == null) {
          _emailError = 'تعذر التحقق من توفر اسم البريد حالياً';
          _isEmailAvailable = false;
        } else if (!available) {
          _emailError = 'اسم المستخدم مستخدم بالفعل، جرب اسمًا آخر ❌';
          _isEmailAvailable = false;
        } else {
          _emailError = null;
          _isEmailAvailable = true;
        }
      });
    });
  }

  // ── Password validation ────────────────────────────────
  void _onPasswordChanged(String val) {
    setState(() {
      _passwordTooShort = val.isNotEmpty && val.length < 6;
      _passwordMismatch = _confirmPasswordController.text.isNotEmpty &&
          val != _confirmPasswordController.text;
    });
  }

  void _onConfirmPasswordChanged(String val) {
    setState(() {
      _passwordMismatch = val.isNotEmpty && val != _passwordController.text;
    });
  }

  Future<void> _pickProfileImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _profileImage = picked;
      _profileImageBytes = bytes;
    });
  }

  // ── Age validation ─────────────────────────────────────
  void _onAgeChanged(String val) {
    setState(() {
      if (val.isEmpty) {
        _ageError = null;
      } else {
        final age = int.tryParse(val);
        if (age == null) {
          _ageError = 'يرجى إدخال رقم صحيح فقط ❌';
        } else if (age < 13) {
          _ageError = 'هذا العمر غير مسموح به ❌';
        } else {
          _ageError = null;
        }
        // Clear pregnancy if age is outside 13-55
        if (age == null || age < 13 || age > 55) {
          _isPregnant = false;
        }
      }
    });
  }

  // ── Step 1 Validation ──────────────────────────────────
  bool _validateStep1() {
    if (_usernameController.text.trim().isEmpty) {
      _snap('يرجى إدخال اسم المستخدم'); return false;
    }
    if (_emailController.text.trim().isEmpty) {
      _snap('يرجى إدخال البريد الإلكتروني'); return false;
    }
    if (_emailError != null) {
      _snap(_emailError!); return false;
    }
    if (_isCheckingEmail) {
      _snap('جاري التحقق من توفر اسم البريد...'); return false;
    }
    if (!_isEmailAvailable) {
      _snap('اسم المستخدم مستخدم بالفعل، جرب اسمًا آخر'); return false;
    }
    if (_passwordController.text.isEmpty) {
      _snap('يرجى إدخال كلمة المرور'); return false;
    }
    if (_passwordController.text.length < 6) {
      _snap('كلمة المرور يجب أن تكون 6 محارف على الأقل'); return false;
    }
    if (_confirmPasswordController.text.isEmpty) {
      _snap('يرجى تأكيد كلمة المرور'); return false;
    }
    if (_confirmPasswordController.text != _passwordController.text) {
      _snap('كلمة المرور وتأكيدها غير متطابقتين'); return false;
    }
    if (_selectedSecurityQuestion == null || _selectedSecurityQuestion!.isEmpty) {
      _snap('يرجى اختيار سؤال الأمان'); return false;
    }
    if (_securityAnswerController.text.trim().isEmpty) {
      _snap('يرجى إدخال إجابة سؤال الأمان'); return false;
    }
    return true;
  }

  // ── Step 2 Validation ──────────────────────────────────
  bool _validateStep2() {
    final ageText = _ageController.text.trim();
    if (ageText.isEmpty) {
      _snap('يرجى إدخال العمر'); return false;
    }
    final age = int.tryParse(ageText);
    if (age == null || age < 13) {
      _snap('هذا العمر غير مسموح به'); return false;
    }
    if (_gender == null) {
      _snap('يرجى اختيار الجنس'); return false;
    }
    if (_heightController.text.trim().isEmpty) {
      _snap('يرجى إدخال الطول'); return false;
    }
    if (double.tryParse(_heightController.text.trim()) == null) {
      _snap('يرجى إدخال قيمة صحيحة للطول'); return false;
    }
    if (_weightController.text.trim().isEmpty) {
      _snap('يرجى إدخال الوزن'); return false;
    }
    if (double.tryParse(_weightController.text.trim()) == null) {
      _snap('يرجى إدخال قيمة صحيحة للوزن'); return false;
    }
    return true;
  }

  void _snap(String msg) {
    Get.snackbar('تنبيه ⚠️', msg,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3));
  }

  // ── Navigation ────────────────────────────────────────
  void _nextStep() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;
    if (_currentStep == 2) {
      if (_stepThreePhase == 0) {
        setState(() => _stepThreePhase = 1);
        return;
      }
      if (_stepThreePhase == 1) {
        final tw = _targetWeightController.text.trim();
        if (tw.isEmpty) {
          _snap('يرجى إدخال هدف الوزن'); return;
        }
        final twParsed = double.tryParse(tw);
        if (twParsed == null || twParsed <= 0 || !RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(tw)) {
          _snap('هدف الوزن يجب أن يكون رقماً طبيعياً موجباً فقط'); return;
        }
        if (_selectedBodyGoal == null) {
          _snap('يرجى اختيار هدف الجسم'); return;
        }
        setState(() => _stepThreePhase = 2);
        return;
      }
      if (!_validateStep3Health()) return;

      _authController.register(
        name: _usernameController.text.trim(),
        email: '${_emailController.text.trim()}$_gymEmailSuffix',
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        profileImage: _profileImage,
        age: int.tryParse(_ageController.text),
        gender: _gender,
        pregnancyMonth: _isPregnant ? _pregnancyMonth : null,
        securityQuestion: _selectedSecurityQuestion!,
        securityAnswer: _securityAnswerController.text.trim(),
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_inbodyWeightController.text) ?? double.tryParse(_weightController.text),
        musclePercentage: double.tryParse(_muscleController.text),
        fatPercentage: double.tryParse(_fatController.text),
        waist: double.tryParse(_waistController.text),
        targetWeight: double.tryParse(_targetWeightController.text.trim()),
        bodyGoal: _selectedBodyGoal,
        notes: _notesController.text,
        inbodyFiles: _inbodyFiles,
        diseases: _selectedDiseases,
        otherDiseases: _showOtherDiseaseInput ? _otherDiseaseController.text.trim() : null,
        hasMedications: _hasMedications ?? false,
        medications: _hasMedications == true ? _medicationNameController.text.trim() : null,
        foodAllergies: _selectedAllergies,
        otherFoodAllergies: _showOtherAllergyInput ? _otherAllergyController.text.trim() : null,
      );
      return;
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep == 2) {
      if (_stepThreePhase == 2) {
        setState(() => _stepThreePhase = 1);
        return;
      } else if (_stepThreePhase == 1) {
        setState(() => _stepThreePhase = 0);
        return;
      }
    }
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  bool _validateStep3Health() {
    if (_hasDiseases == null) {
      _snap('يرجى تحديد إذا كنت تعاني من أمراض أم لا'); return false;
    }
    if (_hasDiseases == true && _selectedDiseases.isEmpty && !_showOtherDiseaseInput) {
      _snap('يرجى اختيار المرض أو كتابته'); return false;
    }
    if (_showOtherDiseaseInput && _otherDiseaseController.text.trim().isEmpty) {
      _snap('يرجى كتابة اسم المرض'); return false;
    }

    if (_hasMedications == null) {
      _snap('يرجى تحديد إذا كنت تتناول أدوية أم لا'); return false;
    }
    if (_hasMedications == true && _medicationNameController.text.trim().isEmpty) {
      _snap('يرجى إدخال اسم الدواء'); return false;
    }

    if (_hasAllergies == null) {
      _snap('يرجى تحديد إذا كنت تعاني من حساسية طعام أم لا'); return false;
    }
    if (_hasAllergies == true && _selectedAllergies.isEmpty && !_showOtherAllergyInput) {
      _snap('يرجى اختيار نوع الحساسية أو كتابتها'); return false;
    }
    if (_showOtherAllergyInput && _otherAllergyController.text.trim().isEmpty) {
      _snap('يرجى كتابة نوع الحساسية'); return false;
    }

    return true;
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // ── Immersive Background ──────────────────────────────
          _buildImmersiveBackground(),

          SafeArea(
            child: Column(
              children: [
                // ── Premium App Bar ─────────────────────────────
                _buildCustomAppBar(),
                
                // ── Modern Floating Stepper ────────────────────
                _buildModernStepper(),
                
                const SizedBox(height: 15),

                // ── Main Content Card ──────────────────────────
                Expanded(
                  child: Container(
                    width: double.infinity,
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
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      child: Obx(() => Stack(
                        children: [
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                            child: Column(
                              children: [
                                _buildCurrentStepContent(),
                                const SizedBox(height: 30),
                                _buildStepActions(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                          if (_authController.isLoading.value)
                            Container(
                              color: Colors.white.withValues(alpha: 0.8),
                              child: const Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            ),
                        ],
                      )),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImmersiveBackground() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 180, // Slightly more height for better balance
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: -10,
              child: Icon(Icons.fitness_center_rounded, size: 120, color: Colors.white.withValues(alpha: 0.04)),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Icon(Icons.bolt_rounded, size: 60, color: Colors.white.withValues(alpha: 0.03)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 32),
            ),
            const Spacer(),
            Text(
              'إنشاء حساب جديد',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStepper() {
    final steps = ['الحساب', 'البيانات', 'التحليل'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: List.generate(steps.length, (index) {
          bool isActive = _currentStep == index;
          bool isComplete = _currentStep > index;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isComplete || isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isActive ? [BoxShadow(color: Colors.white.withValues(alpha: 0.4), blurRadius: 8)] : [],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[index],
                        style: GoogleFonts.cairo(
                          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1) const SizedBox(width: 10),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0: return _stepOne();
      case 1: return _stepTwo();
      case 2: return _stepThree();
      default: return const SizedBox();
    }
  }

  Widget _buildStepActions() {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                'رجوع',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 15),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (_currentStep == 2 && _stepThreePhase == 2) ? 'إتمام التسجيل' : 'التالي',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Modern Field Helper ─────────────────────────────
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
    String? errorText,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
    int? maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: errorText != null ? Colors.red.withValues(alpha: 0.3) : Colors.blueGrey.shade100.withValues(alpha: 0.5)),
          ),
          child: Directionality(
            textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
            child: TextFormField(
              controller: controller,
              obscureText: isPassword && isPasswordHidden,
              textAlign: isLtr ? TextAlign.end : TextAlign.right,
              inputFormatters: inputFormatters,
              onChanged: onChanged,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.blueGrey.shade200, fontSize: 14),
                prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
                suffixText: suffixText,
                suffixStyle: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold),
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(isPasswordHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, 
                                   color: Colors.blueGrey.shade400, size: 20),
                        onPressed: onPasswordToggle,
                      )
                    : suffixIcon,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8, right: 8),
            child: Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }
  Widget _stepOne() {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blueGrey.shade50,
                    backgroundImage: _profileImageBytes != null ? MemoryImage(_profileImageBytes!) : null,
                    child: _profileImageBytes == null
                        ? const Icon(Icons.add_a_photo_rounded, size: 24, color: AppColors.primary)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        
        // Username
        _buildModernField(
          controller: _usernameController,
          label: 'اسم المستخدم',
          hint: '',
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 20),

        // Email
        _buildModernField(
          controller: _emailController,
          label: 'البريد الإلكتروني للصالات الرياضية',
          hint: 'email name',
          icon: Icons.alternate_email_rounded,
          isLtr: true,
          suffixText: _gymEmailSuffix,
          errorText: _emailError,
          onChanged: _onEmailChanged,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\u0600-\u06FF\s@]'))],
          suffixIcon: _emailController.text.isNotEmpty
              ? (_isCheckingEmail
                  ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)))
                  : Icon(_isEmailAvailable ? Icons.check_circle_rounded : Icons.close_rounded, 
                         color: _isEmailAvailable ? Colors.green : Colors.red, size: 20))
              : null,
        ),
        const SizedBox(height: 20),

        // Password
        _buildModernField(
          controller: _passwordController,
          label: 'كلمة المرور',
          hint: '',
          icon: Icons.lock_rounded,
          isPassword: true,
          isPasswordHidden: _isPasswordHidden,
          onPasswordToggle: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
          errorText: _passwordTooShort ? 'كلمة المرور قصيرة جداً' : null,
          onChanged: _onPasswordChanged,
          suffixIcon: (_passwordController.text.length >= 6)
              ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
              : null,
        ),
        const SizedBox(height: 20),

        // Confirm Password
        _buildModernField(
          controller: _confirmPasswordController,
          label: 'تأكيد كلمة المرور',
          hint: '',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isPasswordHidden: _isConfirmPasswordHidden,
          onPasswordToggle: () => setState(() => _isConfirmPasswordHidden = !_isConfirmPasswordHidden),
          errorText: _passwordMismatch ? 'كلمات المرور غير متطابقة' : null,
          onChanged: _onConfirmPasswordChanged,
          suffixIcon: (_confirmPasswordController.text.isNotEmpty && !_passwordMismatch)
              ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
              : null,
        ),
        const SizedBox(height: 20),

        // Security Question
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
              child: Text(
                'سؤال الأمان (للاستعادة)',
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.blueGrey.shade100.withValues(alpha: 0.5)),
              ),
              child: Obx(() {
                final items = _securityQuestions.toList();
                return DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSecurityQuestion,
                    hint: Text('اختر سؤال الأمان', style: GoogleFonts.cairo(color: Colors.blueGrey.shade300, fontSize: 14)),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    items: items.map((q) => DropdownMenuItem(value: q, child: Text(q, style: GoogleFonts.cairo(fontSize: 14)))).toList(),
                    onChanged: (val) => setState(() => _selectedSecurityQuestion = val),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Security Answer
        _buildModernField(
          controller: _securityAnswerController,
          label: 'إجابة سؤال الأمان',
          hint: '',
          icon: Icons.security_rounded,
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _authController.loadSecurityQuestions().then((_) {
      _securityQuestions.assignAll(_authController.securityQuestions);
    });
  }

  @override
  void dispose() {
    _emailDebounce?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════
  //  Step 2 – Personal Info
  // ══════════════════════════════════════
  Widget _stepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Age
        _buildModernField(
          controller: _ageController,
          label: 'العمر',
          hint: '',
          icon: Icons.calendar_today_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: _onAgeChanged,
          errorText: _ageError,
          suffixIcon: (_ageController.text.isNotEmpty && _ageError == null)
              ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
              : null,
        ),
        const SizedBox(height: 20),

        // Gender
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
              child: Text(
                'الجنس',
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.blueGrey.shade100.withValues(alpha: 0.5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _gender,
                  hint: Text('اختر الجنس', style: GoogleFonts.cairo(color: Colors.blueGrey.shade300, fontSize: 14)),
                  icon: const Icon(Icons.wc_rounded, color: AppColors.primary),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('ذكر')),
                    DropdownMenuItem(value: 'female', child: Text('أنثى')),
                  ],
                  onChanged: (val) => setState(() {
                    _gender = val;
                    if (val != 'female') _isPregnant = false;
                  }),
                ),
              ),
            ),
          ],
        ),
        
        // Pregnancy Section
        if (_gender == 'female' && int.tryParse(_ageController.text) != null && int.parse(_ageController.text) >= 13 && int.parse(_ageController.text) <= 55)
          Container(
            margin: const EdgeInsets.only(top: 15),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('هل أنتِ حامل؟', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                  value: _isPregnant,
                  onChanged: (val) => setState(() => _isPregnant = val),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                if (_isPregnant) ...[
                  const Divider(height: 1),
                  Row(
                    children: [
                      Text('في أي شهر؟', style: GoogleFonts.cairo(fontSize: 13)),
                      const Spacer(),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _pregnancyMonth,
                          items: List.generate(9, (i) => i + 1).map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
                          onChanged: (val) => setState(() => _pregnancyMonth = val ?? 1),
                          style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Height
        _buildModernField(
          controller: _heightController,
          label: 'الطول (سم)',
          hint: '',
          icon: Icons.height_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
        ),
        const SizedBox(height: 20),

        // Weight
        _buildModernField(
          controller: _weightController,
          label: 'الوزن الحالي (كجم)',
          hint: '',
          icon: Icons.monitor_weight_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  //  Step 3 – InBody Analysis (optional)
  // ══════════════════════════════════════
  // ══════════════════════════════════════
  //  Step 3 – Health Report (Two Phases)
  // ══════════════════════════════════════
  Widget _stepThree() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _stepThreePhase == 0 
          ? _inBodyPhase() 
          : (_stepThreePhase == 1 ? _targetGoalsPhase() : _healthReportPhase()),
    );
  }

  Widget _targetGoalsPhase() {
    return SingleChildScrollView(
      key: const ValueKey('target_goals_phase'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIllustrationHeader(
            icon: Icons.flag_circle_outlined,
            color: AppColors.primary,
            title: 'أهدافك وطموحك',
          ),
          const SizedBox(height: 24),
          Text('الوزن المستهدف (كجم)', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 10),
          _buildModernField(
            controller: _targetWeightController,
            label: 'هدف الوزن',
            hint: 'مثال: 70',
            icon: Icons.monitor_weight_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
          ),
          const SizedBox(height: 24),
          Text('الهدف البدني', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedBodyGoal,
              hint: const Text('اختر هدفك...'),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.fitness_center_rounded, color: AppColors.primary),
              ),
              items: _bodyGoalsList.map((goal) {
                return DropdownMenuItem<String>(
                  value: goal,
                  child: Text(goal, style: const TextStyle(fontWeight: FontWeight.w500)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedBodyGoal = val);
              },
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _inBodyPhase() {
    return SingleChildScrollView(
      key: const ValueKey('inbody_phase'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIllustrationHeader(
            icon: Icons.analytics_outlined,
            color: AppColors.primary,
            title: 'InBody Analysis',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'المرحلة الأولى: فحص الـ InBody',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        const SizedBox(height: 8),
        const Text(
          'يمكنك إدخال بيانات التحليل يدوياً أو رفع صورة للفحص.',
          style: TextStyle(color: AppColors.textLight, fontSize: 13),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _methodCard(
                icon: Icons.edit_note_rounded,
                label: 'إدخال يدوي',
                selected: _inBodyMethod == 0,
                onTap: () => setState(() => _inBodyMethod = 0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _methodCard(
                icon: Icons.upload_file_rounded,
                label: 'رفع ملف/صورة',
                selected: _inBodyMethod == 1,
                onTap: () => setState(() => _inBodyMethod = 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (_inBodyMethod == 0) ...[
          _buildManualInBodyFields(),
        ] else ...[
          _buildFileUploadSection(),
        ],
        const SizedBox(height: 20),
      ],
    ),
    );
  }

  Widget _methodCard({required IconData icon, required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.blueGrey.shade50.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Colors.blueGrey.shade100.withValues(alpha: 0.3)),
          boxShadow: selected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.2) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: selected ? Colors.white : AppColors.primary, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: selected ? Colors.white : const Color(0xFF334155),
                fontWeight: selected ? FontWeight.w900 : FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInBodyFields() {
    return Column(
      children: [
        _buildModernField(
          controller: _inbodyWeightController,
          label: 'وزن الجسم في الفحص (كجم)',
          hint: '',
          icon: Icons.monitor_weight_rounded,
        ),
        const SizedBox(height: 15),
        _buildModernField(
          controller: _muscleController,
          label: 'نسبة العضلات %',
          hint: '',
          icon: Icons.bolt_rounded,
        ),
        const SizedBox(height: 15),
        _buildModernField(
          controller: _fatController,
          label: 'نسبة الدهون %',
          hint: '',
          icon: Icons.percent_rounded,
        ),
        const SizedBox(height: 15),
        _buildModernField(
          controller: _waistController,
          label: 'محيط الخصر (سم)',
          hint: '',
          icon: Icons.straighten_rounded,
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = const TextInputType.numberWithOptions(decimal: true),
    bool isNumber = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))] : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_inbodyFiles.isEmpty)
          GestureDetector(
            onTap: _pickInBodyFiles,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), style: BorderStyle.solid, width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ارفع صور فحص الـ InBody',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يمكنك اختيار صورة واحدة أو أكثر من الاستوديو',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.blueGrey.shade400),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _inbodyFiles.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blueGrey.shade100, width: 1.5),
                        ),
                        child: Image.memory(
                          _inbodyFilesBytes[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _inbodyFiles.removeAt(index);
                          _inbodyFilesBytes.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickInBodyFiles,
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
              label: Text(
                'أضف المزيد من الصور',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickInBodyFiles() async {
    final picked = await _imagePicker.pickMultiImage(
      imageQuality: 85,
    );
    if (picked.isNotEmpty) {
      for (var file in picked) {
        final bytes = await file.readAsBytes();
        setState(() {
          _inbodyFiles.add(file);
          _inbodyFilesBytes.add(bytes);
        });
      }
    }
  }

  Widget _healthReportPhase() {
    return Column(
      key: const ValueKey('health_report_phase'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIllustrationHeader(
          icon: Icons.health_and_safety_rounded,
          color: Colors.redAccent,
          title: 'HEALTH PROFILE',
        ),
        const SizedBox(height: 30),

        // 1. Diseases
        _buildQuestionSection(
          question: 'هل تعاني من أي أمراض مزمنة؟',
          value: _hasDiseases,
          onChanged: (val) => setState(() {
            _hasDiseases = val;
            if (val == false) {
              _selectedDiseases.clear();
              _showOtherDiseaseInput = false;
            }
          }),
        ),
        if (_hasDiseases == true) ...[
          const SizedBox(height: 15),
          _buildMultiSelect(
            items: ['ربو', 'قلب', 'ديسك', 'ضغط دم', 'سكري', 'الغدة الدرقية'],
            selectedItems: _selectedDiseases,
            onOtherPressed: () => setState(() => _showOtherDiseaseInput = !_showOtherDiseaseInput),
          ),
          if (_showOtherDiseaseInput)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: _buildModernField(
                controller: _otherDiseaseController,
                label: 'اسم المرض الآخر',
                hint: '',
                icon: Icons.edit_note_rounded,
              ),
            ),
        ],

        const Divider(height: 40),

        // 2. Medications
        _buildQuestionSection(
          question: 'هل تتناول أي أدوية حالياً؟',
          value: _hasMedications,
          onChanged: (val) => setState(() {
            _hasMedications = val;
          }),
        ),
        if (_hasMedications == true) ...[
          const SizedBox(height: 15),
          _buildModernField(
            controller: _medicationNameController,
            label: 'اسم الأدوية',
            hint: '',
            icon: Icons.medication_rounded,
          ),
        ],

        const Divider(height: 40),

        // 3. Allergies
        _buildQuestionSection(
          question: 'هل تعاني من حساسية تجاه أطعمة معينة؟',
          value: _hasAllergies,
          onChanged: (val) => setState(() {
            _hasAllergies = val;
            if (val == false) {
              _selectedAllergies.clear();
              _showOtherAllergyInput = false;
            }
          }),
        ),
        if (_hasAllergies == true) ...[
          const SizedBox(height: 15),
          _buildMultiSelect(
            items: ['حليب ومشتقاته', 'القمح', 'البقوليات', 'البيض', 'المكسرات'],
            selectedItems: _selectedAllergies,
            onOtherPressed: () => setState(() => _showOtherAllergyInput = !_showOtherAllergyInput),
          ),
          if (_showOtherAllergyInput)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: _buildModernField(
                controller: _otherAllergyController,
                label: 'اسم الحساسية الأخرى',
                hint: '',
                icon: Icons.restaurant_rounded,
              ),
            ),
        ],

        const Divider(height: 40),

        // 4. Coach Notes
        _buildModernField(
          controller: _notesController,
          label: 'ملاحظات إضافية للمدرب',
          hint: '',
          icon: Icons.message_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildQuestionSection({required String question, required bool? value, required ValueChanged<bool> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildChoiceChip(label: 'نعم', selected: value == true, onTap: () => onChanged(true)),
            const SizedBox(width: 12),
            _buildChoiceChip(label: 'لا', selected: value == false, onTap: () => onChanged(false)),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceChip({required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.blueGrey.shade50.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: selected ? AppColors.primary : Colors.blueGrey.shade100.withValues(alpha: 0.5)),
          boxShadow: selected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            color: selected ? Colors.white : const Color(0xFF334155),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelect({required List<String> items, required List<String> selectedItems, required VoidCallback onOtherPressed}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...items.map((item) {
          final isSelected = selectedItems.contains(item);
          return ChoiceChip(
            label: Text(item),
            selected: isSelected,
            onSelected: (val) {
              setState(() {
                if (val) {
                  selectedItems.add(item);
                } else {
                  selectedItems.remove(item);
                }
              });
            },
          );
        }),
        ChoiceChip(
          label: const Text('غير ذلك...'),
          selected: false,
          onSelected: (_) => onOtherPressed(),
        ),
      ],
    );
  }

  Widget _buildIllustrationHeader({required IconData icon, required Color color, required String title}) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(icon, size: 100, color: color.withValues(alpha: 0.05)),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
