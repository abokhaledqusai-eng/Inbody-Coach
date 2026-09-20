import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_colors.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../controllers/workouts_controller.dart';
import 'workout_player_view.dart';

class WorkoutsView extends StatelessWidget {
  WorkoutsView({super.key});

  final WorkoutsController controller = Get.put(WorkoutsController());
  final DashboardController dashboardController = Get.find<DashboardController>();

  String _formatMinutes(double minutes) {
    if (minutes == minutes.toInt()) {
      return '${minutes.toInt()} دقيقة';
    }
    return '${minutes.toStringAsFixed(1)} دقيقة';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoadingPlan = controller.isLoadingPlan.value;
      final plan = controller.currentPlan.value;
      final error = controller.planErrorMessage.value;

      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTypeToggle(),
              Expanded(
                child: _buildStateContent(isLoadingPlan, plan, error),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _buildFAB(isLoadingPlan, plan, error, context),
      );
    });
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
            onPressed: () => controller.fetchPlan(),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'خطة التمرين اليومية',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              Text(
                'نظام عام .. جاري التخصيص',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
                  ? NetworkImage(dashboardController.profileImageUrl.value, headers: const {'Bypass-Tunnel-Reminder': 'true'})
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

  Widget _buildTypeToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Container(
        height: 55,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _ToggleItem(
                title: 'منزل',
                icon: Icons.home_rounded,
                isSelected: controller.selectedPlanType.value == 'home',
                onTap: () => controller.changePlanType('home'),
              ),
            ),
            Expanded(
              child: _ToggleItem(
                title: 'نادي',
                icon: Icons.fitness_center_rounded,
                isSelected: controller.selectedPlanType.value == 'gym',
                onTap: () => controller.changePlanType('gym'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateContent(bool isLoadingPlan, StandardWorkoutPlan? plan, String error) {
    if (isLoadingPlan) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    if (error.isNotEmpty) {
      return _buildErrorView(error);
    }

    if (plan == null) {
      return _buildErrorView('لا توجد خطة متاحة حالياً');
    }

    if (plan.isRestDay) {
      return _buildRestDayView();
    }

    return RefreshIndicator(
      onRefresh: () async => controller.fetchPlan(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 10),
          _buildStatsDashboard(plan),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${plan.exercises.length} تمارين',
                style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
              ),
              Text(
                'التمارين المجدولة',
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...plan.exercises.map((ex) => _ExerciseListItem(exercise: ex)).toList(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildStatsDashboard(StandardWorkoutPlan plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: Colors.blueAccent.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SmallInfoCard(
                icon: Icons.access_time_filled_rounded,
                label: 'المدة',
                value: _formatMinutes(plan.totalDurationMinutes),
                color: Colors.blue.shade400,
              ),
              _SmallInfoCard(
                icon: Icons.fitness_center_rounded,
                label: 'تمارين',
                value: '${plan.exerciseCount}',
                color: Colors.orange.shade400,
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'أنت تقترب من تحقيق هدفك اليومي!',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => controller.fetchPlan(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: Text('حاول مرة أخرى', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRestDayView() {
    return RefreshIndicator(
      onRefresh: () async => controller.fetchPlan(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Main Zen Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15)),
                  ],
                ),
                child: Column(
                  children: [
                    // Pulsing Zen Icon
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.03),
                          ),
                        ),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [Colors.blue.shade200.withOpacity(0.4), Colors.transparent],
                            ),
                          ),
                        ),
                        Icon(Icons.spa_rounded, size: 70, color: Colors.blue.shade400),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'يوم استشفاء ونمو',
                      style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.blue.shade900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'استرح جيداً اليوم، عضلاتك تنمو أثناء الراحة وليس فقط أثناء التمرين.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(fontSize: 15, color: Colors.blue.shade700, fontWeight: FontWeight.w600, height: 1.6),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Recovery Tips Section
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('نصائح للاستشفاء اليوم', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                  const SizedBox(width: 10),
                  const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                ],
              ),
              const SizedBox(height: 15),
              
              _buildRecoveryTip(
                'شرب الماء',
                'حافظ على ترطيب جسمك بشرب 3 لتر ماء على الأقل.',
                Icons.water_drop_rounded,
                Colors.blue,
              ),
              _buildRecoveryTip(
                'النوم العميق',
                'احرص على النوم لمدة 7-9 ساعات لضمان بناء العضلات.',
                Icons.bedtime_rounded,
                Colors.indigo,
              ),
              _buildRecoveryTip(
                'التمدد الخفيف',
                'قم بتمارين إطالة بسيطة لتنشيط الدورة الدموية.',
                Icons.accessibility_new_rounded,
                Colors.teal,
              ),
              
              const SizedBox(height: 40),
              
              // Motivation Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.blue.shade50),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.rocket_launch_rounded, color: Colors.orange, size: 24),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        'استعد جيداً، غداً ينتظرك تمرين جديد وممتع!',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade800, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecoveryTip(String title, String desc, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
                Text(desc, textAlign: TextAlign.right, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFAB(bool isLoading, StandardWorkoutPlan? plan, String error, BuildContext context) {
    if (isLoading || plan == null || plan.isRestDay || error.isNotEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(() => WorkoutPlayerView(plan: plan)),
          borderRadius: BorderRadius.circular(40),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                colors: [
                  Colors.blueAccent.shade400,
                  Colors.blueAccent.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 15),
                Text(
                  'ابدأ التمرين الآن',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleItem({required this.title, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SmallInfoCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
        Text(label, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ExerciseListItem extends StatelessWidget {
  final WorkoutExerciseItem exercise;

  const _ExerciseListItem({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 90,
              height: 90,
              child: _ExerciseThumbnail(mediaUrl: exercise.mediaUrl),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  exercise.name,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _InfoBadge(
                      label: '${exercise.sets.length} جولات',
                      color: Colors.blueAccent,
                      icon: Icons.layers_rounded,
                    ),
                    _InfoBadge(
                      label: exercise.sets.isNotEmpty 
                        ? (exercise.sets[0].unit == 'minutes' ? '${exercise.sets[0].repsOrMinutes} د' : '${exercise.sets[0].repsOrMinutes.toInt()} عدات')
                        : '0',
                      color: Colors.green.shade600,
                      icon: Icons.repeat_rounded,
                    ),
                    if (exercise.equipment != null && exercise.equipment!.isNotEmpty)
                      _InfoBadge(
                        label: exercise.equipment!,
                        color: Colors.blueGrey.shade600,
                        icon: Icons.fitness_center_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_left_rounded, color: Colors.grey),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _InfoBadge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(width: 4),
          Icon(icon, size: 12, color: color),
        ],
      ),
    );
  }
}

// Smart thumbnail: shows play icon for videos, Image.network for images
class _ExerciseThumbnail extends StatelessWidget {
  final String? mediaUrl;

  const _ExerciseThumbnail({this.mediaUrl});

  static const _videoExts = ['mp4', 'mov', 'avi', 'webm', 'mkv', 'm4v'];

  bool _isVideo(String url) {
    final lower = url.toLowerCase().split('?').first;
    return _videoExts.any((e) => lower.endsWith('.$e'));
  }

  @override
  Widget build(BuildContext context) {
    final url = mediaUrl;

    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.fitness_center_rounded, color: Colors.grey),
      );
    }

    if (_isVideo(url)) {
      // Show a dark thumbnail with play icon — no video loading for list items
      return Container(
        color: Colors.grey.shade800,
        child: const Center(
          child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 36),
        ),
      );
    }

    // Image / GIF
    return Image.network(
      url,
      headers: const {'Bypass-Tunnel-Reminder': 'true'},
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.fitness_center_rounded, color: Colors.grey),
      ),
    );
  }
}

