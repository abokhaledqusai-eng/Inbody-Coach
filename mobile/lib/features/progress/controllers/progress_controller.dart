import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart' as dio_lib;
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';

class ProgressController extends GetxController {
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var measurements = <Map<String, dynamic>>[].obs;
  var selectedPeriod = 'weekly'.obs; // 'weekly', 'monthly', 'yearly'

  // Biometrics initial/target goals
  var targetWeight = 70.0.obs; 
  var currentWeight = 0.0.obs;
  var currentFat = 0.0.obs;
  var currentMuscle = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMeasurements();
    fetchTargetWeight();
  }

  Future<void> fetchTargetWeight() async {
    try {
      final response = await ApiService.get('/me');
      if (response.statusCode == 200) {
        final profile = response.data['data']['profile'];
        if (profile != null && profile['target_weight'] != null) {
          targetWeight.value = double.tryParse(profile['target_weight'].toString()) ?? 70.0;
        }
      }
    } catch (_) {}
  }

  Future<void> fetchMeasurements() async {
    isLoading.value = true;
    try {
      final response = await ApiService.get('/progress/measurements');
      if (response.data != null && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        measurements.value = List<Map<String, dynamic>>.from(data);

        // Update current stats from the latest report
        if (measurements.isNotEmpty) {
          final latest = measurements.first;
          currentWeight.value = double.tryParse(latest['weight']?.toString() ?? '0') ?? 0.0;
          currentFat.value = double.tryParse(latest['fat_percentage']?.toString() ?? '0') ?? 0.0;
          currentMuscle.value = double.tryParse(latest['muscle_mass']?.toString() ?? '0') ?? 0.0;
        }
      }
    } catch (e) {
      Get.log("Error fetching progress measurements: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addMeasurement({
    required DateTime date,
    double? weight,
    double? fat,
    double? muscle,
    double? bmi,
    double? chest,
    double? waist,
    double? arm,
    double? thigh,
    List<XFile>? inbodyFiles,
  }) async {
    isSubmitting.value = true;
    try {
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final Map<String, dynamic> fields = {
        'log_date': formattedDate,
        if (weight != null) 'weight': weight,
        if (fat != null) 'fat_percentage': fat,
        if (muscle != null) 'muscle_mass': muscle,
        if (bmi != null) 'bmi': bmi,
        if (chest != null) 'chest': chest,
        if (waist != null) 'waist': waist,
        if (arm != null) 'arm': arm,
        if (thigh != null) 'thigh': thigh,
      };

      dio_lib.FormData formData = dio_lib.FormData.fromMap(fields);

      if (inbodyFiles != null && inbodyFiles.isNotEmpty) {
        for (var file in inbodyFiles) {
          formData.files.add(
            MapEntry(
              'inbody_files[]',
              await dio_lib.MultipartFile.fromFile(
                file.path,
                filename: file.name,
              ),
            ),
          );
        }
      }

      final response = await ApiService.post(
        '/progress/measurements',
        formData,
        isMultipart: true,
      );

      if (response.data != null && response.data['success'] == true) {
        await fetchMeasurements();
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في إضافة سجل التطور. يرجى المحاولة لاحقاً',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // Filter measurements based on weekly, monthly, yearly
  List<Map<String, dynamic>> getFilteredMeasurements() {
    if (measurements.isEmpty) return [];
    
    // Sort ascending for chart rendering
    final sorted = List<Map<String, dynamic>>.from(measurements)
      ..sort((a, b) => (a['log_date'] ?? '').compareTo(b['log_date'] ?? ''));

    final now = DateTime.now();

    if (selectedPeriod.value == 'weekly') {
      // Filter for last 7 days or simply return last 7 entries for high visual clarity
      return sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
    } else if (selectedPeriod.value == 'monthly') {
      // Filter for last 30 days or last 12 entries
      return sorted.length > 12 ? sorted.sublist(sorted.length - 12) : sorted;
    } else {
      // Return all or last 30 entries
      return sorted.length > 30 ? sorted.sublist(sorted.length - 30) : sorted;
    }
  }
}
