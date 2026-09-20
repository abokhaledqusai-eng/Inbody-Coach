import 'package:get/get.dart';
import '../../../core/services/api_service.dart';

class DashboardController extends GetxController {
  // Navigation
  var currentIndex = 0.obs;
  
  void changeTab(int index) {
    currentIndex.value = index;
  }

  // User profile
  var userName = ''.obs; // will be filled from /me endpoint
  var profileImageUrl = ''.obs;
  var isLoading = false.obs;

  // Real stats (weight, fat, muscle)
  var weight = '0.0'.obs;
  var weightChange = 0.0.obs;
  var fat = '0.0'.obs;
  var fatChange = 0.0.obs;
  var muscle = '0.0'.obs;
  var muscleChange = 0.0.obs;

  // Weight history for trend curve
  var weightHistory = <double>[].obs;

  // Today's workout preview (dynamic data from API)
  var todayTitle = ''.obs;
  var todayNotes = ''.obs;
  var todayDuration = ''.obs;
  var todayCalories = ''.obs;
  var todayProgress = 0.0.obs;

  // First exercise details for the new workout card
  var firstExerciseName = ''.obs;
  var firstExerciseTargetMuscles = ''.obs;
  var firstExerciseMediaUrl = ''.obs;
  var firstExerciseSetsCount = 0.obs;
  var firstExerciseReps = ''.obs;
  var firstExerciseCalories = 0.obs;
  var todayPlanName = ''.obs;
  var todayExerciseCount = 0.obs;
  var isTodayRestDay = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
    fetchTodayWorkout();
  }

  // ---------------------------------------------------------------------
  // Fetch user profile and latest body‑composition measurements
  // ---------------------------------------------------------------------
  Future<void> fetchUserData() async {
    isLoading.value = true;
    try {
      // 1️⃣ User profile
      final response = await ApiService.get('/me');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        userName.value = data['name'] ?? '';
        String img = data['profile_image_url']?.toString() ?? '';
        if (img.isNotEmpty && img.contains('127.0.0.1:8000/api')) {
          img = img.replaceAll('http://127.0.0.1:8000/api', ApiService.baseUrl);
        }
        profileImageUrl.value = img;
      }

      // 2️⃣ Latest two progress measurements for trend arrows
      final statsResponse = await ApiService.get('/progress/measurements');
      if (statsResponse.statusCode == 200) {
        final List stats = statsResponse.data['data'] ?? [];
        if (stats.isNotEmpty) {
          final current = stats[0];
          weight.value = current['weight']?.toString() ?? '0.0';
          fat.value = current['fat_percentage']?.toString() ?? '0.0';
          muscle.value = current['muscle_mass']?.toString() ?? '0.0';

          // Populate weight history list for chart (most recent first)
          weightHistory.value = stats.map<double>((s) => double.tryParse(s['weight']?.toString() ?? '0') ?? 0).toList();

          if (stats.length > 1) {
            final prev = stats[1];
            weightChange.value = (double.tryParse(weight.value) ?? 0) -
                (double.tryParse(prev['weight']?.toString() ?? '0') ?? 0);
            fatChange.value = (double.tryParse(fat.value) ?? 0) -
                (double.tryParse(prev['fat_percentage']?.toString() ?? '0') ?? 0);
            muscleChange.value = (double.tryParse(muscle.value) ?? 0) -
                (double.tryParse(prev['muscle_mass']?.toString() ?? '0') ?? 0);
          }
        }
      }
    } catch (_) {
      // Keep defaults on error
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------
  // Fetch today's workout (first exercise of the current day) for the card
  // ---------------------------------------------------------------------
  Future<void> fetchTodayWorkout() async {
    try {
      final dayNumber = DateTime.now().weekday;
      final response = await ApiService.get('/workouts/my-standard-plan?day_number=$dayNumber');
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['success'] == true) {
        final data = response.data['data'];

        // Plan-level info
        isTodayRestDay.value = data['is_rest_day'] == true;
        todayPlanName.value = data['name']?.toString() ?? '';

        final rawCategory = (data['category'] as Map?) ?? {};
        final catName = rawCategory['name']?.toString() ?? '';

        final List exercises = data['exercises'] ?? [];
        todayExerciseCount.value = exercises.length;

        if (!isTodayRestDay.value && exercises.isNotEmpty) {
          final first = exercises[0];

          // Fix media URL if needed
          String? mUrl = first['media_url']?.toString();
          if (mUrl != null && mUrl.contains('127.0.0.1:8000/api')) {
            mUrl = mUrl.replaceAll('http://127.0.0.1:8000/api', ApiService.baseUrl);
          }

          firstExerciseName.value = (first['name']?.toString() ?? '').trim();
          firstExerciseTargetMuscles.value = first['target_muscles']?.toString() ?? catName;
          firstExerciseMediaUrl.value = mUrl ?? '';
          firstExerciseCalories.value = (first['estimated_calories'] as num?)?.toInt() ?? 0;

          final sets = (first['sets'] as List?) ?? [];
          firstExerciseSetsCount.value = sets.length;
          if (sets.isNotEmpty) {
            firstExerciseReps.value = sets[0]['reps_or_minutes']?.toString() ?? '';
          }

          // Legacy fields
          todayTitle.value = firstExerciseName.value;
          todayNotes.value = first['trainer_notes']?.toString() ?? '';
        }
      }
    } catch (_) {
      // Silently ignore
    }
  }
}

