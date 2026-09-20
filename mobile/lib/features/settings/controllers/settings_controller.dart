import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import '../../../core/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../auth/views/login_view.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class SettingsController extends GetxController {
  final isLoading = false.obs;
  final isSavingProfile = false.obs;
  final isChangingPassword = false.obs;
  final userData = <String, dynamic>{}.obs;

  String _extractErrorMessage(Object error, String fallback) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
        final errors = responseData['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            final first = firstError.first;
            if (first is String && first.isNotEmpty) {
              return first;
            }
          }
          if (firstError is String && firstError.isNotEmpty) {
            return firstError;
          }
        }
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }
    return fallback;
  }

  Future<void> fetchMe() async {
    isLoading.value = true;
    try {
      final response = await ApiService.get('/me');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          userData.assignAll(data);
        }
      }
    } catch (e) {
      Get.snackbar(
        'خطأ ❌',
        _extractErrorMessage(e, 'تعذر جلب معلومات الحساب'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile({required String name, XFile? profileImage}) async {
    isSavingProfile.value = true;
    try {
      final Map<String, dynamic> data = {};
      if (name.trim().isNotEmpty) {
        data['name'] = name.trim();
      }

      dynamic requestBody = data;
      if (profileImage != null) {
        requestBody = FormData.fromMap({
          ...data,
          'profile_image': MultipartFile.fromBytes(
            await profileImage.readAsBytes(),
            filename: profileImage.name,
          ),
        });
      }

      final response = await ApiService.post(
        '/profile/update',
        requestBody,
        isMultipart: profileImage != null,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          userData.assignAll(data);
          if (Get.isRegistered<DashboardController>()) {
            final dashboard = Get.find<DashboardController>();
            dashboard.userName.value = data['name']?.toString() ?? dashboard.userName.value;
            dashboard.profileImageUrl.value = data['profile_image_url']?.toString() ?? '';
          }
        }
        Get.snackbar(
          'نجاح ✅',
          response.data['message']?.toString() ?? 'تم تحديث الملف الشخصي',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return true;
      }
    } catch (e) {
      Get.snackbar(
        'خطأ ❌',
        _extractErrorMessage(e, 'تعذر تحديث الملف الشخصي'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isSavingProfile.value = false;
    }
    return false;
  }

  Future<bool> verifyCurrentPassword(String currentPassword) async {
    isChangingPassword.value = true;
    try {
      final email = userData['email']?.toString() ?? '';
      if (email.isEmpty) {
        Get.snackbar(
          'خطأ ❌',
          'تعذر العثور على البريد الإلكتروني للتحقق',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }

      final response = await ApiService.post('/login', {
        'email': email,
        'password': currentPassword,
      });

      if (response.statusCode == 200) {
        // We can optionally save the new token if needed, or just ignore it
        // since we just want to verify the password is correct.
        return true;
      }
    } catch (e) {
      Get.snackbar(
        'خطأ ❌',
        'كلمة المرور الحالية غير صحيحة',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isChangingPassword.value = false;
    }
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    isChangingPassword.value = true;
    try {
      final response = await ApiService.post('/profile/change-password', {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      });

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        Get.snackbar(
          'نجاح ✅',
          'تم تغيير كلمة المرور بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        return true;
      }
    } catch (e) {
      Get.snackbar(
        'خطأ ❌',
        _extractErrorMessage(e, 'تعذر تغيير كلمة المرور'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isChangingPassword.value = false;
    }
    return false;
  }

  Future<bool> verifySecurityAnswer(String answer) async {
    isChangingPassword.value = true;
    try {
      final response = await ApiService.post('/profile/verify-security-answer', {
        'security_answer': answer,
      });

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return true;
      }
    } catch (e) {
      Get.snackbar(
        'خطأ ❌',
        _extractErrorMessage(e, 'إجابة الأمان غير صحيحة'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isChangingPassword.value = false;
    }
    return false;
  }

  Future<bool> changeSecurityQuestion({
    required String newQuestion,
    required String newAnswer,
  }) async {
    isChangingPassword.value = true;
    try {
      final response = await ApiService.post('/profile/change-security-question', {
        'security_question': newQuestion,
        'security_answer': newAnswer,
      });

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        Get.snackbar(
          'نجاح ✅',
          'تم تغيير سؤال الأمان بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        userData['security_question'] = newQuestion;
        return true;
      }
    } catch (e) {
      Get.snackbar(
        'خطأ ❌',
        _extractErrorMessage(e, 'تعذر تغيير سؤال الأمان'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isChangingPassword.value = false;
    }
    return false;
  }

  Future<void> logout() async {
    try {
      await ApiService.post('/logout', {});
    } catch (_) {}
    await ApiService.clearToken();
    Get.offAll(() => LoginView());
  }
}
