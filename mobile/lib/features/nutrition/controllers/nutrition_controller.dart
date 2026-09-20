import 'dart:async';
import 'package:get/get.dart';
import 'package:confetti/confetti.dart';

import '../../../core/services/api_service.dart';
import '../models/meal.dart';

class NutritionController extends GetxController {


  var isLoading    = false.obs;
  var meals        = <Meal>[].obs;
  var waterCount   = 0.obs;
  var waterTarget  = 8.obs;
  var healthStatus = ''.obs;
  var planName     = ''.obs;
  var dayNumber    = 0.obs;
  var isRestDay    = false.obs;
  var isCustomPlan = false.obs;
  var errorMessage = ''.obs;

  late ConfettiController confettiController;

  @override
  void onInit() {
    super.onInit();
    confettiController = ConfettiController(duration: const Duration(seconds: 2));
    fetchTodayPlan();
  }

  @override
  void onClose() {
    confettiController.dispose();
    super.onClose();
  }

  Future<void> fetchTodayPlan() async {
    try {
      isLoading.value    = true;
      errorMessage.value = '';
      
      final response = await ApiService.get('/nutrition/my-meal-plan');

      if (response.statusCode == 200) {
        final result = response.data;
        if (result['success'] == true && result['data'] != null) {
          final data = result['data'] as Map<String, dynamic>;

          planName.value     = data['plan_name'] ?? '';
          dayNumber.value    = data['day_number'] ?? 0;
          isRestDay.value    = data['is_rest_day'] ?? false;
          isCustomPlan.value = data['is_custom_plan'] == true;
          healthStatus.value = data['health_status'] ?? '';

          final rawMeals = data['meals'] as List? ?? [];
          final parsedMeals = rawMeals
              .map((e) => Meal.fromJson(e as Map<String, dynamic>))
              .toList();
          meals.assignAll(parsedMeals);

          final water = data['water_intake'];
          waterCount.value  = (water?['current'] ?? 0).toInt();
          waterTarget.value = (water?['target'] ?? 8).toInt();
        } else {
          errorMessage.value = result['message'] ?? 'لم يتم العثور على خطة تغذية.';
          meals.clear();
        }
      } else {
        errorMessage.value = 'تعذّر الاتصال بالخادم (${response.statusCode}).';
        meals.clear();
      }
    } catch (e) {
      errorMessage.value = 'خطأ في الاتصال: تأكد من اتصالك بالإنترنت.';
      meals.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleMealLog(int mealId) async {
    final index = meals.indexWhere((m) => m.id == mealId);
    if (index == -1) return;

    final oldMeal = meals[index];
    final bool optimisticNewStatus = !oldMeal.isLogged;

    // 1. Optimistic Update (Instant UI reaction)
    _updateMealState(index, oldMeal, optimisticNewStatus);

    try {
      final response = await ApiService.post('/nutrition/meal-log/$mealId/toggle', {});

      if (response.statusCode == 200) {
        final result = response.data;
        if (result['success'] == true) {
          // Sync with server if the server returned a different status
          final serverStatus = result['is_logged'] == true;
          if (optimisticNewStatus != serverStatus) {
            _updateMealState(index, meals[index], serverStatus);
          }
          return;
        }
      }
      // Revert on API logic failure
      _updateMealState(index, meals[index], !optimisticNewStatus);
    } catch (_) {
      // Revert on network failure
      _updateMealState(index, meals[index], !optimisticNewStatus);
    }
  }

  void _updateMealState(int index, Meal oldMeal, bool newStatus) {
    meals[index] = Meal(
      id: oldMeal.id,
      name: oldMeal.name,
      calories: oldMeal.calories,
      proteins: oldMeal.proteins,
      carbs: oldMeal.carbs,
      fats: oldMeal.fats,
      imageUrl: oldMeal.imageUrl,
      time: oldMeal.time,
      ingredients: oldMeal.ingredients,
      instructions: oldMeal.instructions,
      isLogged: newStatus,
      typeLabel: oldMeal.typeLabel,
    );
    meals.refresh();
    _checkIfAllGoalsMet();
  }

  Timer? _waterDebouncer;

  void updateWaterLog(int count) {
    // Optimistic Update: Update UI instantly!
    final previousCount = waterCount.value;
    waterCount.value = count;
    _checkIfAllGoalsMet();

    // Debounce the API call to avoid spamming the server
    _waterDebouncer?.cancel();
    _waterDebouncer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final response = await ApiService.post('/nutrition/water-log', {'cups_count': waterCount.value});
        if (response.statusCode != 200 || response.data['success'] != true) {
          waterCount.value = previousCount; // Revert on failure
        } else {
          waterCount.value = (response.data['cups_count'] ?? count).toInt();
          _checkIfAllGoalsMet();
        }
      } catch (_) {
        waterCount.value = previousCount; // Revert on error
      }
    });
  }

  void _checkIfAllGoalsMet() {
    bool allMealsLogged = meals.isNotEmpty && meals.every((m) => m.isLogged);
    bool waterGoalMet = waterCount.value >= waterTarget.value && waterTarget.value > 0;
    
    if (allMealsLogged && waterGoalMet) {
      confettiController.play();
    }
  }

  // ── Computed getters ──────────────────────────────────────────────
  int get totalCalories => meals.fold(0, (s, m) => s + m.calories);
  int get consumedCalories => meals.where((m) => m.isLogged).fold(0, (s, m) => s + m.calories);

  int get totalProteins => meals.fold(0, (s, m) => s + m.proteins);
  int get consumedProteins => meals.where((m) => m.isLogged).fold(0, (s, m) => s + m.proteins);

  int get totalCarbs => meals.fold(0, (s, m) => s + m.carbs);
  int get consumedCarbs => meals.where((m) => m.isLogged).fold(0, (s, m) => s + m.carbs);

  int get totalFats => meals.fold(0, (s, m) => s + m.fats);
  int get consumedFats => meals.where((m) => m.isLogged).fold(0, (s, m) => s + m.fats);

  double get calorieProgress =>
      totalCalories == 0 ? 0.0 : (consumedCalories / totalCalories).clamp(0.0, 1.0);
}
