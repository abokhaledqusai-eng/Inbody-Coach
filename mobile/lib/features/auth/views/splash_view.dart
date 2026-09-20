import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'login_view.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../coaches/views/select_coach_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () => _checkAuthAndNavigate());
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    final token = await ApiService.getToken();

    // No token saved → go to login
    if (token == null || token.isEmpty) {
      Get.off(() => LoginView(), transition: Transition.fadeIn);
      return;
    }

    // Token exists → fetch user profile to determine correct destination
    try {
      final response = await ApiService.get('/me').timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final user = response.data['data'];
        final hasCoach = user['coach_id'] != null;

        // Save state locally for offline fallback
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_coach', hasCoach);
        await prefs.setString('user_name', user['name'] ?? '');

        if (user['role'] == 'user' && !hasCoach) {
          Get.offAll(() => const SelectCoachView());
        } else {
          Get.offAll(() => const DashboardView());
        }
      } else {
        // Token invalid/expired → clear it and go to login
        await ApiService.clearToken();
        Get.off(() => LoginView(), transition: Transition.fadeIn);
      }
    } catch (_) {
      // Network error or Timeout → use locally cached state to navigate correctly
      final prefs = await SharedPreferences.getInstance();
      final hasCoach = prefs.getBool('has_coach') ?? false;

      if (hasCoach) {
        Get.offAll(() => const DashboardView());
      } else {
        Get.offAll(() => const SelectCoachView());
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF0F172A)], // Blue to Deep Navy
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Text "INBODY" in white, "COACH" in black
              Column(
                children: [
                  Text(
                    'INBODY',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'COACH',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.black, // black as requested
                      height: 1.1,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Circle with dumbbell
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 100,
                    color: Color(0xFF1D4ED8), // Blue dumbbell
                  ),
                ),
              ),
              const Spacer(),
              
              // Bottom section: Loading text and beautiful wide animated bars
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LOADING...',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _AnimatedBars(),
                  const SizedBox(height: 60),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedBars extends StatefulWidget {
  const _AnimatedBars({Key? key}) : super(key: key);

  @override
  State<_AnimatedBars> createState() => _AnimatedBarsState();
}

class _AnimatedBarsState extends State<_AnimatedBars> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(15, (index) {
            // Create a wave effect using sin wave
            final wave = (math.sin((_controller.value * math.pi * 2) + (index * 0.5)) + 1) / 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 12, // Increased from 8 to 12 for wider appearance
              height: 15 + (wave * 35), // Height fluctuates between 15 and 50
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Slightly brighter for elegance
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}

