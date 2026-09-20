import 'package:get/get.dart';
import '../../../core/services/api_service.dart';

class ExerciseSetItem {
  final int setNumber;
  final double repsOrMinutes;
  final double restMinutes;
  final String unit;
  final double? suggestedWeight;

  ExerciseSetItem({
    required this.setNumber,
    required this.repsOrMinutes,
    required this.restMinutes,
    this.unit = 'reps',
    this.suggestedWeight,
  });

  factory ExerciseSetItem.fromJson(Map<String, dynamic> json) {
    return ExerciseSetItem(
      setNumber: (json['set_number'] as num?)?.toInt() ?? 1,
      repsOrMinutes: (json['reps_or_minutes'] as num?)?.toDouble() ?? 0.0,
      restMinutes: (json['rest_minutes'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString() ?? 'reps',
      suggestedWeight: (json['suggested_weight'] as num?)?.toDouble(),
    );
  }
}

class WorkoutExerciseItem {
  final int id;
  final int exerciseId;
  final String name;
  final String? description;
  final String? targetMuscles;
  final String? equipment;
  final int estimatedCalories;
  final String? coachNotes;
  final String exerciseType;
  final double restAfterExerciseMinutes;
  final String? trainerNotes;
  final String? mediaUrl;
  final int sortOrder;
  final List<ExerciseSetItem> sets;

  WorkoutExerciseItem({
    required this.id,
    required this.exerciseId,
    required this.name,
    this.description,
    this.targetMuscles,
    this.equipment,
    this.estimatedCalories = 0,
    this.coachNotes,
    required this.exerciseType,
    required this.restAfterExerciseMinutes,
    this.trainerNotes,
    this.mediaUrl,
    required this.sortOrder,
    required this.sets,
  });

  factory WorkoutExerciseItem.fromJson(Map<String, dynamic> json) {
    final rawSets = (json['sets'] as List?) ?? [];
    
    String? mUrl = json['media_url']?.toString();
    if (mUrl != null && mUrl.contains('127.0.0.1:8000/api')) {
      mUrl = mUrl.replaceAll('http://127.0.0.1:8000/api', ApiService.baseUrl);
    }

    return WorkoutExerciseItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      exerciseId: (json['exercise_id'] as num?)?.toInt() ?? 0,
      name: (json['name']?.toString() ?? '').trim(),
      description: json['description']?.toString(),
      targetMuscles: json['target_muscles']?.toString(),
      equipment: json['equipment']?.toString(),
      estimatedCalories: (json['estimated_calories'] as num?)?.toInt() ?? 0,
      coachNotes: json['coach_notes']?.toString(),
      exerciseType: (json['exercise_type']?.toString() ?? '').trim(),
      restAfterExerciseMinutes: (json['rest_after_exercise_minutes'] as num?)?.toDouble() ?? 0.0,
      trainerNotes: json['trainer_notes']?.toString(),
      mediaUrl: mUrl,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      sets: rawSets
          .whereType<Map>()
          .map((e) => ExerciseSetItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  double get totalDurationMinutes {
    double total = 0;
    for (var set in sets) {
      total += set.repsOrMinutes;
      total += set.restMinutes;
    }
    total += restAfterExerciseMinutes;
    return total;
  }
}

class StandardWorkoutPlan {
  final int id;
  final String name;
  final bool isRestDay;
  final String? message;
  final String categoryName;
  final String categorySlug;
  final String planType;
  final int dayNumber;
  final int exerciseCount;
  final List<WorkoutExerciseItem> exercises;

  StandardWorkoutPlan({
    required this.id,
    required this.name,
    required this.isRestDay,
    this.message,
    required this.categoryName,
    required this.categorySlug,
    required this.planType,
    required this.dayNumber,
    required this.exerciseCount,
    required this.exercises,
  });

  factory StandardWorkoutPlan.fromJson(Map<String, dynamic> json) {
    final rawExercises = (json['exercises'] as List?) ?? [];
    final rawCategory = Map<String, dynamic>.from((json['category'] as Map?) ?? {});
    return StandardWorkoutPlan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name']?.toString() ?? '').trim(),
      isRestDay: json['is_rest_day'] == true,
      message: json['message']?.toString(),
      categoryName: (rawCategory['name']?.toString() ?? '').trim(),
      categorySlug: (rawCategory['slug']?.toString() ?? '').trim(),
      planType: (json['plan_type']?.toString() ?? '').trim(),
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 1,
      exerciseCount: (json['exercise_count'] as num?)?.toInt() ?? 0,
      exercises: rawExercises
          .whereType<Map>()
          .map((e) => WorkoutExerciseItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  double get totalDurationMinutes {
    double total = 0;
    for (var ex in exercises) {
      total += ex.restAfterExerciseMinutes;
      for (var set in ex.sets) {
        total += set.repsOrMinutes; // Assuming repsOrMinutes is used as duration when applicable
        total += set.restMinutes;
      }
    }
    return total;
  }

  int get totalEstimatedCalories {
    int total = 0;
    for (var ex in exercises) {
      total += ex.estimatedCalories * ex.sets.length;
    }
    return total;
  }
}

class WorkoutsController extends GetxController {
  final isLoadingPlan = false.obs;
  final selectedPlanType = 'home'.obs;
  final selectedDayNumber = 1.obs;
  final currentPlan = Rxn<StandardWorkoutPlan>();
  final planErrorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPlan();
  }

  Future<void> fetchPlan() async {
    isLoadingPlan.value = true;
    planErrorMessage.value = '';
    try {
      final response = await ApiService.get(
        '/workouts/my-standard-plan?plan_type=${selectedPlanType.value}&day_number=${selectedDayNumber.value}',
      );

      if (response.data['success'] == true) {
        currentPlan.value = StandardWorkoutPlan.fromJson(response.data['data']);
      } else {
        planErrorMessage.value = response.data['message'] ?? 'فشل تحميل الخطة';
      }
    } catch (e) {
      planErrorMessage.value = 'تعذر تحميل الخطة حاليا, حاول بعد قليل الضغط على كبسة تحديث باعلى الصفحة';
    } finally {
      isLoadingPlan.value = false;
    }
  }

  void changePlanType(String type) {
    if (selectedPlanType.value == type) return;
    selectedPlanType.value = type;
    fetchPlan();
  }

  void changeDay(int day) {
    if (selectedDayNumber.value == day) return;
    selectedDayNumber.value = day;
    fetchPlan();
  }
}
