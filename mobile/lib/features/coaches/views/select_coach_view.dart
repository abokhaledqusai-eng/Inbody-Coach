import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_colors.dart';
import '../controllers/coaches_controller.dart';
import 'widgets/coach_card.dart';

class SelectCoachView extends StatefulWidget {
  const SelectCoachView({super.key});

  @override
  State<SelectCoachView> createState() => _SelectCoachViewState();
}

class _SelectCoachViewState extends State<SelectCoachView> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserNameAndShowDialog();
  }

  Future<void> _loadUserNameAndShowDialog() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? '';
    // Show dialog AFTER name is loaded
    if (mounted) {
      _showWelcomeDialog();
    }
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              // Simplified Title: مرحباً ❤️
              const Text(
                'مرحباً ❤️',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Message
              const Text(
                'سيظهر الآن المدربون المخصصون لك\nاختر المدرب المناسب لرحلتك',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.7,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'ابدأ الاختيار',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CoachesController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: true, // Standard safe area so status bar is protected and height is LTR locked
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Compact Native Header Banner - Sleek and narrow (AppBar style)
            Container(
              width: double.infinity,
              height: 75, // Sleek fixed height to occupy minimal space
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'INBODY',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'COACH',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A), // Dark elegant contrasting text matching logo style
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                          child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),



            // Title: اختر المدرب المناسب (Centered at top)
            Center(
              child: Text(
                'اختر المدرب المناسب',
                style: GoogleFonts.cairo(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // PageView / Scrollable Rows of coaches
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (controller.coaches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: AppColors.textLight.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'عذراً، لا يوجد مدربين متاحين حالياً',
                          style: TextStyle(color: AppColors.text, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: controller.fetchAvailableCoaches,
                          child: const Text('إعادة المحاولة', style: TextStyle(color: AppColors.primary)),
                        )
                      ],
                    ),
                  );
                }

                final maleCoaches = controller.coaches.where((c) => c.gender?.toLowerCase() == 'male').toList();
                final femaleCoaches = controller.coaches.where((c) => c.gender?.toLowerCase() == 'female').toList();

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        title: 'المدربون الذكور 🦾',
                        coaches: maleCoaches,
                      ),
                      const SizedBox(height: 10),
                      _buildSection(
                        title: 'المدربات الإناث 🎀',
                        coaches: femaleCoaches,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<dynamic> coaches,
  }) {
    if (coaches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            title,
            style: GoogleFonts.cairo(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 280, // Premium height for each card + shadows
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: coaches.length,
            itemBuilder: (context, index) {
              final coach = coaches[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                child: SizedBox(
                  width: 200, // Sleek fixed width for each horizontal card
                  child: CoachCard(coach: coach),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}



