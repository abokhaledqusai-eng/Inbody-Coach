import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../../../core/app_colors.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../coaches/views/select_coach_view.dart';
import '../views/login_view.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  final RxList<String> securityQuestions = <String>[].obs;
  static const List<String> _defaultSecurityQuestions = [
    'اسم أول معلم لك؟',
    'ما هو اسم مدرستك الابتدائية؟',
    'ما هي مدينتك المفضلة؟',
    'اسم صديق الطفولة الأقرب؟',
    'ما هو لقب العائلة؟',
  ];

  String _extractErrorMessage(Object error, String fallback) {
    String normalizeKnownMessages(String message) {
      final lower = message.toLowerCase();
      if (lower.contains('email has already been taken')) {
        return 'اسم المستخدم مستخدم بالفعل، جرب اسمًا آخر';
      }
      return message;
    }

    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final errors = responseData['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            final first = firstError.first;
            if (first is String && first.isNotEmpty) {
              return normalizeKnownMessages(first);
            }
          }
          if (firstError is String && firstError.isNotEmpty) {
            return normalizeKnownMessages(firstError);
          }
        }
        final message = responseData['message'];
        if (message is String && message.isNotEmpty) {
          return normalizeKnownMessages(message);
        }
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return normalizeKnownMessages(error.message!);
      }
    }
    return fallback;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    int? age,
    String? gender,
    int? pregnancyMonth,
    String? securityQuestion,
    String? securityAnswer,
    double? height,
    double? weight,
    double? musclePercentage,
    double? fatPercentage,
    double? waist,
    double? targetWeight,
    String? bodyGoal,
    String? notes,
    XFile? profileImage,
    List<XFile>? inbodyFiles,
    List<String>? diseases,
    String? otherDiseases,
    bool hasMedications = false,
    String? medications,
    List<String>? foodAllergies,
    String? otherFoodAllergies,
  }) async {
    isLoading.value = true;

    try {
      final Map<String, dynamic> data = {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (pregnancyMonth != null) 'pregnancy_month': pregnancyMonth,
        if (securityQuestion != null) 'security_question': securityQuestion,
        if (securityAnswer != null) 'security_answer': securityAnswer,
        if (height != null) 'height': height,
        if (weight != null) 'weight': weight,
        if (musclePercentage != null) 'muscle_percentage': musclePercentage,
        if (fatPercentage != null) 'fat_percentage': fatPercentage,
        if (waist != null) 'waist': waist,
        if (targetWeight != null) 'target_weight': targetWeight,
        if (bodyGoal != null) 'body_goal': bodyGoal,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (diseases != null) 'diseases': diseases,
        if (otherDiseases != null) 'other_diseases': otherDiseases,
        'has_medications': hasMedications ? 1 : 0,
        if (medications != null) 'medications': medications,
        if (foodAllergies != null) 'food_allergies': foodAllergies,
        if (otherFoodAllergies != null) 'other_food_allergies': otherFoodAllergies,
      };

      bool hasFiles = profileImage != null || (inbodyFiles != null && inbodyFiles.isNotEmpty);
      dynamic requestBody;

      if (hasFiles) {
        final Map<String, dynamic> formDataMap = {};
        
        // Add non-array fields
        data.forEach((key, value) {
          if (value is! List) {
            formDataMap[key] = value;
          }
        });

        // Add array fields with [] suffix for Laravel
        if (diseases != null && diseases.isNotEmpty) {
          for (int i = 0; i < diseases.length; i++) {
            formDataMap['diseases[$i]'] = diseases[i];
          }
        }
        if (foodAllergies != null && foodAllergies.isNotEmpty) {
          for (int i = 0; i < foodAllergies.length; i++) {
            formDataMap['food_allergies[$i]'] = foodAllergies[i];
          }
        }

        if (profileImage != null) {
          final bytes = await profileImage.readAsBytes();
          formDataMap['profile_image'] = MultipartFile.fromBytes(
            bytes,
            filename: profileImage.name,
          );
        }

        if (inbodyFiles != null && inbodyFiles.isNotEmpty) {
          for (int i = 0; i < inbodyFiles.length; i++) {
            final file = inbodyFiles[i];
            final bytes = await file.readAsBytes();
            formDataMap['inbody_files[$i]'] = MultipartFile.fromBytes(
              bytes,
              filename: file.name,
            );
          }
        }

        requestBody = FormData.fromMap(formDataMap);
      } else {
        requestBody = data;
      }

      final response = await ApiService.post(
        '/register',
        requestBody,
        isMultipart: hasFiles,
      );

      if (response.statusCode == 201) {
        final token = response.data['data']['token'];
        await ApiService.saveToken(token);

        final user = response.data['data']['user'];
        // Save user info locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', user['name'] ?? '');
        await prefs.setBool('has_coach', user['coach_id'] != null);

        Get.snackbar(
          'نجاح ✅',
          'تم إنشاء الحساب بنجاح!',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );

        // Navigate to appropriate screen after short delay
        await Future.delayed(const Duration(seconds: 1));
        
        if (user['role'] == 'user' && user['coach_id'] == null) {
          Get.offAll(() => const SelectCoachView());
        } else {
          Get.offAll(() => const DashboardView());
        }
      }
    } catch (e) {
      final errorMessage = _extractErrorMessage(e, 'حدث خطأ أثناء إنشاء الحساب');
      Get.snackbar(
        'خطأ ❌',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadSecurityQuestions() async {
    try {
      final response = await ApiService.get('/security-questions');
      if (response.statusCode == 200) {
        final List<dynamic> list = response.data['data'] ?? [];
        final qs = list.map((e) => e.toString()).toList();
        if (qs.isNotEmpty) {
          securityQuestions.assignAll(qs);
        } else {
          securityQuestions.assignAll(_defaultSecurityQuestions);
        }
      }
    } catch (_) {
      securityQuestions.assignAll(_defaultSecurityQuestions);
    }
  }

  Future<bool?> isEmailAvailable(String email) async {
    try {
      final resp = await ApiService.get('/email-availability?email=$email');
      if (resp.statusCode == 200) {
        return resp.data['data']?['available'] == true;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> fetchSecurityQuestionByEmail(String email) async {
    if (email.isEmpty) return null;
    try {
      final resp = await ApiService.get('/security-question?email=$email');
      if (resp.statusCode == 200) {
        return resp.data['data']?['security_question'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> forgotPassword({
    required String email,
    required String securityAnswer,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (email.isEmpty || securityAnswer.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar('تنبيه ⚠️', 'يرجى تعبئة جميع الحقول',
          backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      return;
    }
    if (newPassword.length < 6) {
      Get.snackbar('تنبيه ⚠️', 'كلمة المرور يجب أن تكون 6 محارف على الأقل',
          backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      return;
    }
    if (newPassword != confirmPassword) {
      Get.snackbar('تنبيه ⚠️', 'كلمة المرور الجديدة وتأكيدها غير متطابقتين',
          backgroundColor: Colors.orange, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      return;
    }

    isLoading.value = true;
    try {
      final data = {
        'email': email,
        'security_answer': securityAnswer,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      };
      final response = await ApiService.post('/forgot-password', data);
      if (response.statusCode == 200) {
        Get.snackbar('نجاح ✅', 'تم تغيير كلمة المرور بنجاح',
            backgroundColor: AppColors.success,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 2));
        await Future.delayed(const Duration(seconds: 1));
        Get.offAll(() => LoginView());
      }
    } catch (e) {
      final errorMessage = _extractErrorMessage(e, 'تعذر تغيير كلمة المرور');
      Get.snackbar('خطأ ❌', errorMessage,
          backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.TOP);
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'تنبيه ⚠️',
        'يرجى إدخال البريد الإلكتروني وكلمة المرور',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    isLoading.value = true;

    try {
      final data = {
        'email': email,
        'password': password,
      };

      final response = await ApiService.post('/login', data);

      if (response.statusCode == 200) {
        final token = response.data['data']['token'];
        await ApiService.saveToken(token);

        final user = response.data['data']['user'];
        // Save user info locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', user['name'] ?? '');
        await prefs.setBool('has_coach', user['coach_id'] != null);

        Get.snackbar(
          'نجاح ✅',
          'تم تسجيل الدخول بنجاح!',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );

        await Future.delayed(const Duration(seconds: 1));
        
        if (user['role'] == 'user' && user['coach_id'] == null) {
          Get.offAll(() => const SelectCoachView());
        } else {
          Get.offAll(() => const DashboardView());
        }
      }
    } catch (e) {
      final errorMessage = _extractErrorMessage(e, 'حدث خطأ أثناء تسجيل الدخول');
      Get.snackbar(
        'خطأ ❌',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
