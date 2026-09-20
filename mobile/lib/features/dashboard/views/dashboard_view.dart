import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/app_colors.dart';
import '../controllers/dashboard_controller.dart';
import '../../settings/views/settings_view.dart';
import '../../store/views/store_view.dart';
import '../../workouts/views/workouts_view.dart';
import '../../nutrition/views/nutrition_view.dart';
import '../../nutrition/controllers/nutrition_controller.dart';
import '../../progress/views/progress_view.dart';
import '../../progress/controllers/progress_controller.dart';
import 'package:video_player/video_player.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DashboardController _controller = Get.put(DashboardController());

  late final List<Widget> _pages = [
    HomeTab(controller: _controller),
    WorkoutsView(),
    const ProgressView(),
    StoreView(),
    NutritionView(),
    const SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() => _pages[_controller.currentIndex.value]),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        currentIndex: _controller.currentIndex.value,
        onTap: (index) => _controller.changeTab(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'التمارين'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'التقدم'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'المتجر'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'التغذية'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      )),
    );
  }
}

class HomeTab extends StatefulWidget {
  final DashboardController controller;
  const HomeTab({super.key, required this.controller});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _waterCups = 3;
  final int _maxWaterCups = 8;
  // Controllers — initialized safely in initState
  late final NutritionController nutritionController;
  late final ProgressController _progressController;

  @override
  void initState() {
    super.initState();
    // Safe registration: use existing instance or create new one
    nutritionController = Get.isRegistered<NutritionController>()
        ? Get.find<NutritionController>()
        : Get.put(NutritionController(), permanent: true);
    _progressController = Get.isRegistered<ProgressController>()
        ? Get.find<ProgressController>()
        : Get.put(ProgressController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sleek App Bar with Logo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                          ]
                        ),
                        child: const Icon(Icons.fitness_center, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'INBODY COACH',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: 1),
                      ),
                    ],
                  ),
                  Obx(() => CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: widget.controller.profileImageUrl.value.isNotEmpty
                        ? NetworkImage(widget.controller.profileImageUrl.value, headers: const {'Bypass-Tunnel-Reminder': 'true'})
                        : null,
                    child: widget.controller.profileImageUrl.value.isEmpty
                        ? const Icon(Icons.person, color: AppColors.primary, size: 20)
                        : null,
                  )),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 10),
                // Greeting
                Obx(() => Text(
                  'أهلاً، ${widget.controller.userName.value} 👋',
                  style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.text),
                )),
                Text(
                  'جاهز لتحدي اليوم وكسر أرقامك؟ 🔥',
                  style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textLight),
                ),
                const SizedBox(height: 20),

                // Weight Chart – right below greeting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('منحنى تغير الوزن', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => widget.controller.changeTab(2),
                      child: Row(
                        children: [
                          Text('التفاصيل', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.primary)),
                          const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDashboardWeightChart(),

                const SizedBox(height: 28),

                // Body Stats with Trend Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('جسمك اليوم', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBodyStatsRow(),

                const SizedBox(height: 28),

                // Nutrition Summary
                Text('ملخص تغذية اليوم', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildNutritionCard(),

                const SizedBox(height: 40),
              ]),

            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard() {
    return Obx(() {
      final c = widget.controller;

      // Rest day
      if (c.isTodayRestDay.value) {
        return _buildRestDayCard();
      }

      // Loading / empty state
      if (c.firstExerciseName.value.isEmpty) {
        return _buildWorkoutLoadingCard();
      }

      return _buildExercisePreviewCard(c);
    });
  }

  Widget _buildRestDayCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF0D1F17)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          const Text('🧘', style: TextStyle(fontSize: 48)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('يوم راحة', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text('جسمك يستحق الراحة اليوم 💪\nاستمتع بيومك وكن مستعداً للغد!',
                    style: GoogleFonts.cairo(fontSize: 13, color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutLoadingCard() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            const SizedBox(height: 12),
            Text('جاري تحميل تمرين اليوم...', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisePreviewCard(DashboardController c) {
    final hasVideo = c.firstExerciseMediaUrl.value.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header badge ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fitness_center, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text('أول تمرين اليوم', style: GoogleFonts.cairo(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                Obx(() => Text(
                  '${c.todayExerciseCount.value} تمارين',
                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70),
                )),
              ],
            ),
          ),

          // ── Body: video thumbnail + info ───────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video / placeholder thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 110,
                    height: 110,
                    color: const Color(0xFF0F172A),
                    child: hasVideo
                        ? _ExerciseVideoThumb(url: c.firstExerciseMediaUrl.value)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_circle_fill_rounded, color: Colors.white38, size: 40),
                              const SizedBox(height: 6),
                              Text('لا يوجد فيديو', style: GoogleFonts.cairo(fontSize: 9, color: Colors.white38)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise name
                      Obx(() => Text(
                        c.firstExerciseName.value,
                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )),
                      const SizedBox(height: 8),

                      // Target muscle chip
                      Obx(() {
                        final muscle = c.firstExerciseTargetMuscles.value;
                        if (muscle.isEmpty) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 13),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  muscle,
                                  style: GoogleFonts.cairo(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),

                      // Sets · Reps · Calories row
                      Obx(() => Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          if (c.firstExerciseSetsCount.value > 0)
                            _buildInfoChip(Icons.repeat_rounded, '${c.firstExerciseSetsCount.value} سيت', Colors.indigo),
                          if (c.firstExerciseReps.value.isNotEmpty)
                            _buildInfoChip(Icons.sports_gymnastics_rounded, '${c.firstExerciseReps.value} تكرار', Colors.teal),
                          if (c.firstExerciseCalories.value > 0)
                            _buildInfoChip(Icons.local_fire_department_rounded, '${c.firstExerciseCalories.value} سعرة', Colors.deepOrange),
                        ],
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.cairo(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }


  Widget _buildBodyStatsRow() {
    return Obx(() => Row(
      children: [
        Expanded(child: _buildStatBox('الوزن', widget.controller.weight.value, 'كجم', widget.controller.weightChange.value, true)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatBox('الدهون', widget.controller.fat.value, '%', widget.controller.fatChange.value, true)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatBox('العضلات', widget.controller.muscle.value, 'كجم', widget.controller.muscleChange.value, false)),
      ],
    ));
  }

  Widget _buildStatBox(String title, String value, String unit, double change, bool isDecreaseGood) {
    final isIncrease = change > 0;
    final isGood = isDecreaseGood ? !isIncrease : isIncrease;
    final color = change == 0.0 ? Colors.grey.shade400 : (isGood ? Colors.green : Colors.red);
    final icon = isIncrease ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
              const SizedBox(width: 2),
              Text(unit, style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (change != 0.0) ...[
                  Icon(icon, color: color, size: 12),
                  const SizedBox(width: 2),
                ],
                Text(change == 0.0 ? '-' : '${change.abs().toStringAsFixed(1)} $unit', style: TextStyle(color: change == 0.0 ? AppColors.textLight : color, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Circular Progress
          SizedBox(
            height: 100,
            width: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Obx(() => CircularProgressIndicator(
                  value: (nutritionController.consumedCalories) / (nutritionController.totalCalories == 0 ? 1 : nutritionController.totalCalories),
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeCap: StrokeCap.round,
                )),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                      Obx(() => Text(
                        '${nutritionController.consumedCalories}',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
                      )),
                      Obx(() => Text(
                        '/ ${nutritionController.totalCalories}',
                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textLight),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Macros Lines
          Expanded(
            child: Column(
              children: [
                Obx(() => _buildMacroLine('البروتين', nutritionController.consumedProteins, nutritionController.totalProteins, Colors.blue)),
                const SizedBox(height: 12),
                Obx(() => _buildMacroLine('الكارب', nutritionController.consumedCarbs, nutritionController.totalCarbs, Colors.orange)),
                const SizedBox(height: 12),
                Obx(() => _buildMacroLine('الدهون', nutritionController.consumedFats, nutritionController.totalFats, Colors.purple)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroLine(String label, int current, int total, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
            Text('$current / $total غ', style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textLight)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: current / total,
            minHeight: 6,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildWaterTracker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_waterCups / $_maxWaterCups أكواب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('${(_waterCups * 250)} مل', style: GoogleFonts.outfit(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_maxWaterCups, (index) {
              final isFilled = index < _waterCups;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (index == _waterCups - 1) {
                      _waterCups--; // allow toggle off
                    } else {
                      _waterCups = index + 1;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isFilled ? Colors.blue.withOpacity(0.15) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.water_drop,
                    color: isFilled ? Colors.blue : Colors.grey.shade300,
                    size: 20,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardWeightChart() {
    return Obx(() {
      final filtered = _progressController.getFilteredMeasurements();

      if (filtered.isEmpty) {
        return Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart_rounded, size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  'لا توجد بيانات بعد',
                  style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight),
                ),
                Text(
                  'أضف قياساتك من شاشة التقدم',
                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        );
      }

      List<FlSpot> spots = [];
      for (int i = 0; i < filtered.length; i++) {
        final w = double.tryParse(filtered[i]['weight']?.toString() ?? '0') ?? 0.0;
        if (w > 0) {
          spots.add(FlSpot(i.toDouble(), w));
        }
      }

      if (spots.isEmpty) {
        return const SizedBox.shrink();
      }

      final minY = spots.map((s) => s.y).reduce(math.min) - 2;
      final maxY = spots.map((s) => s.y).reduce(math.max) + 2;
      final latestWeight = spots.last.y;
      final firstWeight = spots.first.y;
      final diff = latestWeight - firstWeight;
      final isLoss = diff <= 0;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${latestWeight.toStringAsFixed(1)} كجم',
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text),
                    ),
                    Text(
                      'الوزن الحالي',
                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isLoss ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLoss ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                        color: isLoss ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${diff.abs().toStringAsFixed(1)} كجم',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isLoss ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Chart
            SizedBox(
              height: 130,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < filtered.length) {
                            final dateStr = filtered[idx]['log_date'] ?? '';
                            if (dateStr.isNotEmpty) {
                              final parsed = DateTime.tryParse(dateStr);
                              if (parsed != null) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    intl.DateFormat('MM/dd').format(parsed),
                                    style: GoogleFonts.cairo(fontSize: 8, color: AppColors.textLight),
                                  ),
                                );
                              }
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                        '${s.y.toStringAsFixed(1)} كجم',
                        GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      )).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppColors.primary,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.secondary.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── Exercise media thumbnail (video auto-play muted / image fallback) ─────────
class _ExerciseVideoThumb extends StatefulWidget {
  final String url;
  const _ExerciseVideoThumb({required this.url});
  @override
  State<_ExerciseVideoThumb> createState() => _ExerciseVideoThumbState();
}

class _ExerciseVideoThumbState extends State<_ExerciseVideoThumb> {
  VideoPlayerController? _vc;
  bool _ready = false;
  bool _isVideo = false;
  static const _vidExts = ['mp4', 'mov', 'avi', 'webm', 'mkv', 'm4v'];

  bool _isVid(String url) {
    final lower = url.toLowerCase().split('?').first;
    return _vidExts.any((e) => lower.endsWith('.$e'));
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final url = widget.url;
    if (url.isEmpty) return;
    if (!_isVid(url)) return; // it's an image — handled in build
    _isVideo = true;
    try {
      _vc = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {
          'Accept': 'video/mp4,video/*;q=0.9,*/*;q=0.8',
          'Bypass-Tunnel-Reminder': 'true',
        },
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await _vc!.initialize();
      _vc!.setLooping(true);
      _vc!.setVolume(0);
      _vc!.play();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      debugPrint('[DashboardVideoThumb] $e');
      if (mounted) setState(() => _isVideo = false);
    }
  }

  @override
  void dispose() {
    _vc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;

    // ── Image ──────────────────────────────────────────────────────────────
    if (!_isVideo) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        headers: const {'Bypass-Tunnel-Reminder': 'true'},
        loadingBuilder: (_, child, p) => p == null
            ? child
            : const Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                ),
              ),
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    // ── Video loading ───────────────────────────────────────────────────────
    if (!_ready) {
      return Container(
        color: const Color(0xFF0F172A),
        child: const Center(
          child: SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
          ),
        ),
      );
    }

    // ── Video ready ─────────────────────────────────────────────────────────
    final size = _vc!.value.size;
    return Container(
      color: Colors.black,
      child: Center(
        child: size.width > 0 && size.height > 0
            ? AspectRatio(
                aspectRatio: size.width / size.height,
                child: VideoPlayer(_vc!),
              )
            : VideoPlayer(_vc!),
      ),
    );
  }

  Widget _placeholder() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.play_circle_fill_rounded, color: Colors.white24, size: 36),
      const SizedBox(height: 6),
      Text('فيديو التمرين',
          style: GoogleFonts.cairo(fontSize: 9, color: Colors.white38)),
    ],
  );
}
