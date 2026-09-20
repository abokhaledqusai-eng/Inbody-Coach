import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'workouts_controller.dart';

enum PlayerState { preparing, active, paused, resting }

class WorkoutPlayerController extends GetxController {
  final StandardWorkoutPlan plan;

  WorkoutPlayerController(this.plan);

  final playerState = PlayerState.preparing.obs;
  final currentExerciseIndex = 0.obs;
  final currentSetIndex = 0.obs;
  
  final cumulativeCalories = 0.0.obs;
  final restSecondsRemaining = 0.obs;
  final activeSecondsElapsed = 0.obs;
  
  // Tracking weights logged by the user
  final loggedWeights = <String, double>{}.obs; 
  
  // For the final summary
  final workoutStartTime = DateTime.now();
  late DateTime workoutEndTime;

  Timer? _restTimer;
  Timer? _activeTimer;
  
  final isRestingBetweenExercises = false.obs;

  WorkoutExerciseItem? get currentExercise {
    if (currentExerciseIndex.value >= plan.exercises.length) return null;
    return plan.exercises[currentExerciseIndex.value];
  }

  ExerciseSetItem? get currentSet {
    final exercise = currentExercise;
    if (exercise == null) return null;
    if (currentSetIndex.value >= exercise.sets.length) return null;
    return exercise.sets[currentSetIndex.value];
  }

  WorkoutExerciseItem? get nextExercise {
    if (currentExerciseIndex.value + 1 >= plan.exercises.length) return null;
    return plan.exercises[currentExerciseIndex.value + 1];
  }

  bool get isWorkoutFinished => currentExerciseIndex.value >= plan.exercises.length;
  
  double get progressPercentage {
    if (plan.exercises.isEmpty) return 0;
    return (currentExerciseIndex.value) / plan.exercises.length;
  }

  @override
  void onClose() {
    _restTimer?.cancel();
    _activeTimer?.cancel();
    super.onClose();
  }

  void startSet() {
    playerState.value = PlayerState.active;
    activeSecondsElapsed.value = 0;
    _activeTimer?.cancel();
    _activeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      activeSecondsElapsed.value++;
    });
  }

  void logWeight(double weight) {
    final exercise = currentExercise;
    if (exercise == null) return;
    final key = "${exercise.id}_${currentSetIndex.value}";
    loggedWeights[key] = weight;
  }

  void finishSet() {
    _activeTimer?.cancel();
    HapticFeedback.mediumImpact();
    
    final setItem = currentSet;
    final exercise = currentExercise;
    if (setItem == null || exercise == null) return;

    cumulativeCalories.value += exercise.estimatedCalories;

    bool isLastSet = currentSetIndex.value == exercise.sets.length - 1;
    
    if (isLastSet) {
      bool isLastExercise = currentExerciseIndex.value == plan.exercises.length - 1;
      
      if (isLastExercise) {
        workoutEndTime = DateTime.now();
        currentExerciseIndex.value++;
      } else {
        double restMinutes = exercise.restAfterExerciseMinutes;
        if (restMinutes > 0) {
          isRestingBetweenExercises.value = true;
          _startRestTimer(restMinutes);
        } else {
          _moveToNextExercise();
        }
      }
    } else {
      double restMinutes = setItem.restMinutes;
      if (restMinutes > 0) {
        isRestingBetweenExercises.value = false;
        _startRestTimer(restMinutes);
      } else {
        _moveToNextSet();
      }
    }
  }

  void _startRestTimer(double minutes) {
    playerState.value = PlayerState.resting;
    restSecondsRemaining.value = (minutes * 60).toInt();

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (restSecondsRemaining.value > 0) {
        restSecondsRemaining.value--;
        // Haptic feedback in the last 3 seconds
        if (restSecondsRemaining.value > 0 && restSecondsRemaining.value <= 3) {
          HapticFeedback.lightImpact();
        }
      } else {
        HapticFeedback.heavyImpact();
        skipRest();
      }
    });
  }

  void skipRest() {
    _restTimer?.cancel();
    
    final exercise = currentExercise;
    if (exercise == null) return;
    
    bool isLastSet = currentSetIndex.value == exercise.sets.length - 1;
    
    if (isLastSet) {
      _moveToNextExercise();
    } else {
      _moveToNextSet();
    }
  }

  void _moveToNextSet() {
    currentSetIndex.value++;
    playerState.value = PlayerState.preparing;
  }

  void _moveToNextExercise() {
    currentExerciseIndex.value++;
    currentSetIndex.value = 0;
    playerState.value = PlayerState.preparing;
  }

  void finishWorkoutEarly() {
    Get.back();
  }

  String get totalWorkoutDuration {
    final duration = workoutEndTime.difference(workoutStartTime);
    return "${duration.inMinutes} دقيقة";
  }
}
