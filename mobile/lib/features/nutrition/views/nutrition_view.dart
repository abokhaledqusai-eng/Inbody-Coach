import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_colors.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../controllers/nutrition_controller.dart';
import '../models/meal.dart';

class NutritionView extends StatelessWidget {
  NutritionView({super.key});

  final NutritionController controller = Get.put(NutritionController());
  final DashboardController dashboardController = Get.find<DashboardController>();

  String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    
    String parsed = htmlString;
    // Handle newlines from common block tags
    parsed = parsed.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    parsed = parsed.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');
    parsed = parsed.replaceAll(RegExp(r'</div>', caseSensitive: false), '\n');
    
    // Handle list items by adding a bullet and a newline
    parsed = parsed.replaceAll(RegExp(r'<li>', caseSensitive: false), '• ');
    parsed = parsed.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');
    
    // Strip remaining HTML tags
    parsed = parsed.replaceAll(RegExp(r'<[^>]*>', multiLine: true), '');
    
    // Decode common entities
    parsed = parsed.replaceAll('&nbsp;', ' ')
                   .replaceAll('&amp;', '&')
                   .replaceAll('&lt;', '<')
                   .replaceAll('&gt;', '>')
                   .replaceAll('&quot;', '"');
                   
    // Clean up excessive newlines but preserve single ones for lists
    parsed = parsed.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    
    return parsed.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Column(
              children: [
            _buildAppBar(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (controller.errorMessage.isNotEmpty) {
                  return _buildErrorState(controller);
                }

                return RefreshIndicator(
          onRefresh: controller.fetchTodayPlan,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlanHeader(controller),
                const SizedBox(height: 25),
                
                _buildStatsCard(controller),
                const SizedBox(height: 30),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('وجبات اليوم',
                        style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text)),
                    Text('${controller.meals.where((m) => m.isLogged).length} من ${controller.meals.length}',
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Obx(() {
                    double progress = controller.meals.isEmpty 
                        ? 0 
                        : controller.meals.where((m) => m.isLogged).length / controller.meals.length;
                    return LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      color: AppColors.primary,
                    );
                  }),
                ),
                const SizedBox(height: 20),
                
                if (controller.meals.isEmpty)
                  _buildEmptyMealsMessage()
                else
                  _buildMealList(controller),
                  
                const SizedBox(height: 30),
                _buildWaterTracker(controller),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      })),
              ],
            ),
            ConfettiWidget(
              confettiController: controller.confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.blueAccent, size: 28),
            onPressed: () => controller.fetchTodayPlan(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'تغذيتي اليوم',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Obx(() => Text(
                  controller.isCustomPlan.value
                      ? 'خطة مخصصة من المدرب: ${controller.planName.value}'
                      : 'هذا نظام عام, جاري تخصيص نظام خاص لك بأسرع وقت',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: controller.isCustomPlan.value
                        ? Colors.green.shade600
                        : Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Obx(() => Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blueAccent, width: 2),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blueAccent,
              backgroundImage: dashboardController.profileImageUrl.value.isNotEmpty
                  ? NetworkImage(dashboardController.profileImageUrl.value)
                  : null,
              child: dashboardController.profileImageUrl.value.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPlanHeader(NutritionController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.85),
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.local_fire_department_rounded,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.planName.value.isEmpty ? "خطة التغذية" : controller.planName.value,
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2),
                ),
                Text(
                  'استمر في الالتزام لتحقيق هدفك!',
                  style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.9), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'اليوم ${controller.dayNumber.value}',
              style: GoogleFonts.cairo(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(NutritionController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMacroInfo('بروتين', controller.consumedProteins, controller.totalProteins, Colors.blue),
              _buildMainCalorieRing(controller),
              _buildMacroInfo('دهون', controller.consumedFats, controller.totalFats, Colors.orange),
            ],
          ),
          const SizedBox(height: 25),
          _buildHorizontalMacro('كربوهيدرات', controller.consumedCarbs, controller.totalCarbs, Colors.green),
        ],
      ),
    );
  }

  Widget _buildMainCalorieRing(NutritionController controller) {
    return Obx(() {
      final int remaining = (controller.totalCalories - controller.consumedCalories).clamp(0, 9999);
      final double progress = controller.calorieProgress;

      // Color transitions: blue → orange → red as calories are consumed
      final Color ringColor = progress < 0.6
          ? AppColors.primary
          : progress < 0.85
              ? Colors.orange
              : Colors.redAccent;

      return Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring (decorative)
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: animatedProgress,
                      strokeWidth: 4,
                      backgroundColor: Colors.transparent,
                      color: ringColor.withOpacity(0.2),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Main ring
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: CircularProgressIndicator(
                      value: animatedProgress,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade100,
                      color: ringColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Animated number inside
                  TweenAnimationBuilder<int>(
                    tween: IntTween(
                      begin: controller.totalCalories,
                      end: remaining,
                    ),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedRemaining, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('المتبقية',
                              style: GoogleFonts.cairo(
                                  fontSize: 13, color: AppColors.textLight)),
                          Text(
                            '$animatedRemaining',
                            style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: ringColor),
                          ),
                          Text('سعرة',
                              style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.bold)),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'الهدف: ${controller.totalCalories}',
              style: GoogleFonts.cairo(
                  fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight),
            ),
          ),
        ],
      );
    });
  }


  Widget _buildMacroInfo(String label, int current, int total, Color color) {
    double progress = total == 0 ? 0 : (current / total).clamp(0.0, 1.0);
    return Column(
      children: [
        Text('${total}g', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 10,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              width: 10,
              height: 80 * progress,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(label, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
        Text('${current}g',
            style: GoogleFonts.outfit(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHorizontalMacro(String label, int current, int total, Color color) {
    final double progress = total == 0 ? 0 : (current / total).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: current),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedCurrent, _) {
                    return Text(
                      '$animatedCurrent / ${total}g',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textLight),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: animatedProgress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade100,
                color: color,
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildMealList(NutritionController controller) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.meals.length,
      itemBuilder: (context, index) {
        final meal = controller.meals[index];
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOutQuart,
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _buildMealCard(context, meal, controller),
        );
      },
    );
  }

  Widget _buildMealCard(BuildContext context, Meal meal, NutritionController controller) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showMealDetails(context, meal, controller),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 1. Meal Image
              Hero(
                tag: 'meal_${meal.id}',
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: meal.isLogged ? 0.6 : 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: meal.imageUrl != null
                        ? Image.network(
                            meal.imageUrl!,
                            width: 85,
                            height: 85,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => _buildMealIconPlaceholder(),
                          )
                        : _buildMealIconPlaceholder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // 2. Meal Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge & Time
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            meal.typeLabel,
                            style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          ),
                        ),
                        if (meal.time != null && meal.time!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Text(meal.time!,
                                  style: GoogleFonts.outfit(
                                      fontSize: 12, color: AppColors.textLight)),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Name
                    Text(
                      meal.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                           fontSize: 15,
                           fontWeight: FontWeight.bold,
                           height: 1.2,
                           color: AppColors.text),
                    ),
                    const SizedBox(height: 6),
                    
                    // Calories & Recipe
                    Row(
                      children: [
                        Text(
                          '${meal.calories} سعرة',
                          style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => _showRecipeDetails(context, meal),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.receipt_long_rounded, color: Colors.orange, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'الوصفة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 3. Completion Checkmark
              const SizedBox(width: 8),
              InkWell(
                onTap: () => controller.toggleMealLog(meal.id),
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    meal.isLogged ? Icons.check_circle : Icons.circle_outlined,
                    color: meal.isLogged ? Colors.green : Colors.grey.shade300,
                    size: 34,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealIconPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade50,
      child: const Icon(Icons.restaurant_rounded, color: Colors.grey, size: 30),
    );
  }

  Widget _buildWaterTracker(NutritionController controller) {
    return Obx(() {
      double progress = controller.waterTarget.value == 0 
          ? 0 
          : (controller.waterCount.value / controller.waterTarget.value).clamp(0.0, 1.0);

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.water_drop_rounded, color: Colors.blueAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ترطيب الجسم',
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text('الهدف: ${controller.waterTarget.value} أكواب',
                            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${controller.waterCount.value}',
                        style: GoogleFonts.outfit(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.local_drink_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            
            // Modern progress visualization
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (controller.waterCount.value > 0) {
                      controller.updateWaterLog(controller.waterCount.value - 1);
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(Icons.remove_rounded, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Animated Progress Bar
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 20,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                height: 20,
                                width: constraints.maxWidth * progress,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.lightBlueAccent, Colors.blueAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        progress >= 1.0 
                            ? 'أحسنت! أكملت هدفك 🎉' 
                            : 'استمر للوصول لهدفك!',
                        style: GoogleFonts.cairo(
                            fontSize: 12, 
                            fontWeight: progress >= 1.0 ? FontWeight.bold : FontWeight.w600, 
                            color: progress >= 1.0 ? Colors.green : Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                     controller.updateWaterLog(controller.waterCount.value + 1);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                      ]
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _showMealDetails(BuildContext context, Meal meal, NutritionController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Meal Image
              if (meal.imageUrl != null)
                Hero(
                  tag: 'meal_${meal.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Image.network(
                          meal.imageUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.restaurant_rounded,
                                color: Colors.grey, size: 60),
                          ),
                        ),
                        // Gradient overlay at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Meal type badge on top of image
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              meal.typeLabel,
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Meal name + close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(meal.name,
                        style: GoogleFonts.cairo(
                            fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildNutritionSummary(meal),
              const SizedBox(height: 30),

              
              if (meal.ingredients != null && meal.ingredients!.isNotEmpty) ...[
                _buildRecipeSection(
                  title: 'المكونات',
                  content: meal.ingredients!,
                  icon: Icons.kitchen_rounded,
                  color: Colors.orange,
                ),
                const SizedBox(height: 25),
              ],
              
              if (meal.instructions != null && meal.instructions!.isNotEmpty) ...[
                _buildRecipeSection(
                  title: 'طريقة التحضير',
                  content: meal.instructions!,
                  icon: Icons.menu_book_rounded,
                  color: Colors.blue,
                ),
                const SizedBox(height: 30),
              ],

              Text('تحذير صحي',
                  style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
              const SizedBox(height: 12),
              _buildWarningSection(controller.healthStatus.value),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    controller.toggleMealLog(meal.id);
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: meal.isLogged ? Colors.red.shade50 : AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    meal.isLogged ? 'إلغاء تسجيل الوجبة' : 'تسجيل الوجبة الآن',
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: meal.isLogged ? Colors.red : Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showRecipeDetails(BuildContext context, Meal meal) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('تفاصيل ${meal.name}',
                        style: GoogleFonts.cairo(
                            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              
              if (meal.ingredients != null && meal.ingredients!.isNotEmpty) ...[
                _buildRecipeSection(
                  title: 'المكونات',
                  content: meal.ingredients!,
                  icon: Icons.kitchen_rounded,
                  color: Colors.orange,
                ),
                const SizedBox(height: 20),
              ],
              
              if (meal.instructions != null && meal.instructions!.isNotEmpty) ...[
                _buildRecipeSection(
                  title: 'طريقة التحضير',
                  content: meal.instructions!,
                  icon: Icons.menu_book_rounded,
                  color: Colors.blue,
                ),
                const SizedBox(height: 30),
              ],
              
              if ((meal.ingredients == null || meal.ingredients!.isEmpty) && 
                  (meal.instructions == null || meal.instructions!.isEmpty))
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.grey.shade300, size: 50),
                        const SizedBox(height: 10),
                        Text('لا توجد تفاصيل مضافة لهذه الوجبة', 
                            style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildRecipeSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(title, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _stripHtml(content),
            style: GoogleFonts.cairo(
                fontSize: 15, 
                height: 1.8, 
                color: Colors.black87.withOpacity(0.8),
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionSummary(Meal meal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNutrientItem('سعرات', '${meal.calories}', Colors.purple),
        _buildNutrientItem('بروتين', '${meal.proteins}g', Colors.blue),
        _buildNutrientItem('كربوهيدرات', '${meal.carbs}g', Colors.green),
        _buildNutrientItem('دهون', '${meal.fats}g', Colors.orange),
      ],
    );
  }

  Widget _buildNutrientItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: GoogleFonts.cairo(fontSize: 11, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildWarningSection(String status) {
    String warningText = 'هذه الوجبة متوافقة مع ملفك الصحي.';
    IconData icon = Icons.check_circle_rounded;
    Color color = Colors.green;

    if (status.contains('حامل')) {
      warningText = 'تحذير للحوامل: يرجى التأكد من طهي المكونات جيداً.';
      icon = Icons.warning_amber_rounded;
      color = Colors.pink;
    } else if (status.contains('مسن')) {
      warningText = 'تنبيه: هذه الوجبة قليلة الصوديوم لتناسب ضغط الدم.';
      icon = Icons.info_rounded;
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              warningText,
              style: GoogleFonts.cairo(fontSize: 13, color: color.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildEmptyMealsMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.restaurant_menu_rounded, size: 40, color: AppColors.primary.withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          Text(
            'لم يتم إضافة وجبات بعد',
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            'سيقوم المدرب بإضافة خطة الوجبات الخاصة بك قريباً. استعد لبدء رحلتك الصحية!',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(NutritionController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 70, color: Colors.red.shade300),
            const SizedBox(height: 20),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: controller.fetchTodayPlan,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
