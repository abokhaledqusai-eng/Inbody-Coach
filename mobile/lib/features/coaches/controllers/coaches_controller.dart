import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';
import '../../../core/app_colors.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../models/coach_model.dart';

class CoachesController extends GetxController {
  var isLoading = true.obs;
  var isSelecting = false.obs;
  var coaches = <CoachModel>[].obs;
  var selectedCoachId = RxnInt();

  @override
  void onInit() {
    super.onInit();
    fetchAvailableCoaches();
  }

  Future<void> fetchAvailableCoaches() async {
    try {
      isLoading(true);
      final response = await ApiService.get('/coaches/available');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          coaches.assignAll(data.map((json) => CoachModel.fromJson(json)).toList());
        } else {
          coaches.clear();
        }
      }
    } catch (e) {
      Get.snackbar(
        'خطأ ❌',
        'تعذر جلب قائمة المدربين: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 6),
        mainButton: TextButton(
          onPressed: fetchAvailableCoaches,
          child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> selectCoach(int coachId) async {
    try {
      isSelecting(true);
      final response = await ApiService.post('/user/select-coach', {'coach_id': coachId});
      
      if (response.statusCode == 200) {
        // Save locally so splash knows user has a coach (even if offline later)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_coach', true);

        Get.snackbar(
          'تهانينا! 🎉',
          response.data['message'] ?? 'تم اختيار المدرب بنجاح',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        
        // Wait a bit for the user to see the success message
        await Future.delayed(const Duration(seconds: 2));
        
        // Navigate to Dashboard and clear history so they can't go back to coach selection
        Get.offAll(() => const DashboardView());
      }
    } catch (e) {
      Get.snackbar(
        'خطأ ❌',
        'حدث خطأ أثناء محاولة ربطك بالمدرب. تأكد من اتصالك وجرب مرة أخرى.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isSelecting(false);
    }
  }
}
