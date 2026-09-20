import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:video_player/video_player.dart';
import '../../../core/app_colors.dart';
import '../controllers/workout_player_controller.dart';
import '../controllers/workouts_controller.dart';

// ──────────────────────────────────────────────────────────────────────────────
class WorkoutPlayerView extends StatelessWidget {
  final StandardWorkoutPlan plan;
  late final WorkoutPlayerController _ctrl;

  WorkoutPlayerView({super.key, required this.plan}) {
    _ctrl = Get.put(WorkoutPlayerController(plan));
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Obx(() {
        if (_ctrl.isWorkoutFinished) return _FinishedView(ctrl: _ctrl);
        final ex = _ctrl.currentExercise!;
        final state = _ctrl.playerState.value;
        return Stack(
          children: [
            // ── Main layout ──────────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  _TopBar(plan: plan, ctrl: _ctrl, ex: ex),
                  // Video – bounded height so no layout errors
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.42,
                    child: _MediaArea(ex: ex),
                  ),
                  Expanded(
                    child: _BottomPanel(ctrl: _ctrl, ex: ex, state: state, fmt: _fmt),
                  ),
                ],
              ),
            ),
            // ── Rest overlay – covers full screen ────────────────────────────
            if (state == PlayerState.resting)
              Positioned.fill(
                child: _RestOverlay(ctrl: _ctrl, fmt: _fmt),
              ),
          ],
        );
      }),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final StandardWorkoutPlan plan;
  final WorkoutPlayerController ctrl;
  final WorkoutExerciseItem ex;
  const _TopBar({required this.plan, required this.ctrl, required this.ex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _IconBtn(icon: Icons.close_rounded, onTap: () => _exit(context)),
          const Spacer(),
          // Progress pills – fixed height, min size prevents overflow
          Obx(() => SizedBox(
            height: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(plan.exercises.length, (i) {
                final active = i == ctrl.currentExerciseIndex.value;
                final done   = i <  ctrl.currentExerciseIndex.value;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: done
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : active
                            ? AppColors.primary
                            : Colors.white24,
                  ),
                );
              }),
            ),
          )),
          const Spacer(),
          _IconBtn(
            icon: Icons.info_outline_rounded,
            onTap: () => _showInfo(context, ex),
          ),
        ],
      ),
    );
  }

  void _exit(BuildContext context) {
    HapticFeedback.mediumImpact();
    Get.dialog(Dialog(
      backgroundColor: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 44),
          const SizedBox(height: 14),
          Text('إنهاء التمرين؟',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('لن يتم حفظ تقدمك',
              style: GoogleFonts.cairo(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _ActionChip(label: 'إلغاء', onTap: () => Get.back(), outlined: true)),
            const SizedBox(width: 10),
            Expanded(child: _ActionChip(label: 'إنهاء', onTap: () { Get.back(); Get.back(); }, color: Colors.red.shade700)),
          ]),
        ]),
      ),
    ));
  }

  void _showInfo(BuildContext context, WorkoutExerciseItem ex) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(
            width: 38, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),
          Text(ex.name,
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          if (ex.targetMuscles != null) _InfoRow(icon: Icons.accessibility_new_rounded, label: 'العضلات', val: ex.targetMuscles!),
          if (ex.equipment != null && ex.equipment!.isNotEmpty) _InfoRow(icon: Icons.fitness_center_rounded, label: 'الآلة / المعدة', val: ex.equipment!),
          if (ex.description != null) _InfoRow(icon: Icons.description_rounded, label: 'الوصف', val: ex.description!),
          if (ex.trainerNotes != null || ex.coachNotes != null)
            _InfoRow(icon: Icons.psychology_rounded, label: 'نصيحة المدرب',
                val: ex.trainerNotes ?? ex.coachNotes!, iconColor: Colors.amber),
        ]),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
class _MediaArea extends StatelessWidget {
  final WorkoutExerciseItem ex;
  const _MediaArea({required this.ex});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _ExerciseMediaPlayer(
          key: ValueKey(ex.mediaUrl ?? ex.name),
          mediaUrl: ex.mediaUrl,
        ),
        // Bottom gradient for readability
        Positioned(
          bottom: 0, left: 0, right: 0, height: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, const Color(0xFF0D0D0D)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
class _BottomPanel extends StatelessWidget {
  final WorkoutPlayerController ctrl;
  final WorkoutExerciseItem ex;
  final PlayerState state;
  final String Function(int) fmt;
  const _BottomPanel({required this.ctrl, required this.ex, required this.state, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Exercise name + equipment chip
          Column(mainAxisSize: MainAxisSize.min, children: [
            Obx(() => Text(
              'التمرين ${ctrl.currentExerciseIndex.value + 1}',
              style: GoogleFonts.cairo(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700),
            )),
            const SizedBox(height: 4),
            Text(ex.name,
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (ex.equipment != null && ex.equipment!.isNotEmpty) ...[  
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fitness_center_rounded, color: Colors.white60, size: 14),
                    const SizedBox(width: 6),
                    Text(ex.equipment!,
                        style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ]),

          // Set dots
          Obx(() => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(ex.sets.length, (i) {
              final active = i == ctrl.currentSetIndex.value;
              final done   = i <  ctrl.currentSetIndex.value;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 12, height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? Colors.green.shade400 : active ? Colors.white : Colors.white24,
                  border: active ? Border.all(color: Colors.white, width: 2) : null,
                ),
                child: done
                    ? const Icon(Icons.check_rounded, size: 8, color: Colors.white)
                    : null,
              );
            }),
          )),

          // Big number
          Obx(() {
            final set = ctrl.currentSet;
            if (set == null) return const SizedBox.shrink();
            final isTime = set.unit == 'minutes';
            final display = (state == PlayerState.active && isTime)
                ? fmt(ctrl.activeSecondsElapsed.value)
                : '${set.repsOrMinutes.toInt()}';
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(display,
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontSize: 68, fontWeight: FontWeight.w900, height: 1)),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(isTime ? 'دقيقة' : 'عدة',
                      style: GoogleFonts.cairo(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }),

          // Action button
          Obx(() {
            final preparing = ctrl.playerState.value == PlayerState.preparing;
            return GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                preparing ? ctrl.startSet() : ctrl.finishSet();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity, height: 60,
                decoration: BoxDecoration(
                  color: preparing ? Colors.white : AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: (preparing ? Colors.white : AppColors.primary).withValues(alpha: 0.3),
                      blurRadius: 20, offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    preparing ? 'ابدأ الجولة' : 'أنهيت الجولة  ✓',
                    style: GoogleFonts.cairo(
                      color: preparing ? Colors.black : Colors.white,
                      fontSize: 18, fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
class _RestOverlay extends StatefulWidget {
  final WorkoutPlayerController ctrl;
  final String Function(int) fmt;
  const _RestOverlay({required this.ctrl, required this.fmt});
  @override State<_RestOverlay> createState() => _RestOverlayState();
}

class _RestOverlayState extends State<_RestOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.92),
      child: SafeArea(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('خذ نفساً عميقاً',
              style: GoogleFonts.cairo(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 40),
          // Breathing ring
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) {
              final scale = 0.85 + (_anim.value * 0.3);
              return Stack(alignment: Alignment.center, children: [
                Transform.scale(scale: scale,
                  child: Container(width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
                    ),
                  ),
                ),
                // Inner timer
                Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Center(
                    child: Obx(() => Text(
                      widget.fmt(widget.ctrl.restSecondsRemaining.value),
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                    )),
                  ),
                ),
              ]);
            },
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Text(_anim.value < 0.5 ? 'شهيق...' : 'زفير...',
                style: GoogleFonts.cairo(color: Colors.white30, fontSize: 13)),
          ),
          const SizedBox(height: 32),
          // Next exercise hint
          Obx(() {
            final next = widget.ctrl.nextExercise;
            if (next == null || !widget.ctrl.isRestingBetweenExercises.value) return const SizedBox.shrink();
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Text('التمرين التالي', style: GoogleFonts.cairo(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 4),
              Text(next.name, style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
            ]);
          }),
          TextButton(
            onPressed: () { HapticFeedback.lightImpact(); widget.ctrl.skipRest(); },
            child: Text('تخطي الراحة',
                style: GoogleFonts.cairo(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
class _FinishedView extends StatefulWidget {
  final WorkoutPlayerController ctrl;
  const _FinishedView({required this.ctrl});
  @override State<_FinishedView> createState() => _FinishedViewState();
}

class _FinishedViewState extends State<_FinishedView> {
  late ConfettiController _confetti;
  static const _msgs = [
    'أنت اليوم أقوى من الأمس 💪',
    'الانضباط يصنع الأبطال 🏆',
    'كل تمرين يقربك من هدفك 🎯',
    'الاستمرارية هي السر 🚀',
  ];

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confetti.play();
      HapticFeedback.heavyImpact();
    });
  }

  @override void dispose() { _confetti.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final msg = _msgs[Random().nextInt(_msgs.length)];
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(alignment: Alignment.topCenter, children: [
        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Spacer(),
              // Trophy
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Colors.amber.shade300, Colors.orange.shade700]),
                  boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 40, spreadRadius: 6)],
                ),
                child: const Icon(Icons.emoji_events_rounded, size: 58, color: Colors.white),
              ),
              const SizedBox(height: 28),
              Text('تم بنجاح!',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(msg,
                  style: GoogleFonts.cairo(color: Colors.white54, fontSize: 15),
                  textAlign: TextAlign.center),
              const SizedBox(height: 36),
              // Duration card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.timer_outlined, color: Colors.white38, size: 26),
                  const SizedBox(height: 8),
                  Text(widget.ctrl.totalWorkoutDuration,
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                  Text('مدة التمرين', style: GoogleFonts.cairo(color: Colors.white38, fontSize: 13)),
                ]),
              ),
              const Spacer(),
              // Back button
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: double.infinity, height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Center(child: Text('العودة للرئيسية',
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
        // Confetti
        ConfettiWidget(
          confettiController: _confetti,
          blastDirection: pi / 2,
          numberOfParticles: 30,
          gravity: 0.3,
          colors: const [Colors.amber, Colors.orange, Colors.white, Colors.blue, Colors.green],
        ),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shared small widgets
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  final Color? color;
  const _ActionChip({required this.label, required this.onTap, this.outlined = false, this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46,
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : (color ?? AppColors.primary),
        borderRadius: BorderRadius.circular(12),
        border: outlined ? Border.all(color: Colors.white24) : null,
      ),
      child: Center(child: Text(label,
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold))),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, val;
  final Color iconColor;
  const _InfoRow({required this.icon, required this.label, required this.val, this.iconColor = Colors.blueAccent});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: iconColor, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.cairo(color: Colors.white38, fontSize: 11)),
        Text(val, style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, height: 1.5)),
      ])),
    ]),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Media Player
class _ExerciseMediaPlayer extends StatefulWidget {
  final String? mediaUrl;
  const _ExerciseMediaPlayer({super.key, this.mediaUrl});
  @override State<_ExerciseMediaPlayer> createState() => _ExerciseMediaPlayerState();
}

class _ExerciseMediaPlayerState extends State<_ExerciseMediaPlayer> {
  VideoPlayerController? _vc;
  bool _ready = false, _isVideo = false;
  static const _vidExts = ['mp4', 'mov', 'avi', 'webm', 'mkv', 'm4v'];

  @override void initState() { super.initState(); _init(); }

  bool _isVid(String url) {
    final lower = url.toLowerCase().split('?').first;
    return _vidExts.any((e) => lower.endsWith('.$e'));
  }

  Future<void> _init() async {
    final url = widget.mediaUrl;
    if (url == null || url.isEmpty) return;
    if (!_isVid(url)) return;
    _isVideo = true;
    try {
      _vc = VideoPlayerController.networkUrl(Uri.parse(url),
          httpHeaders: const {
            'Accept': 'video/mp4,video/*;q=0.9,*/*;q=0.8',
            'Bypass-Tunnel-Reminder': 'true',
          },
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
      await _vc!.initialize();
      _vc!.setLooping(true);
      _vc!.setVolume(0);
      _vc!.play();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      debugPrint('[MediaPlayer] Error: $e');
      if (mounted) setState(() { _isVideo = false; });
    }
  }

  @override void dispose() { _vc?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final url = widget.mediaUrl;

    // No media
    if (url == null || url.isEmpty) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: Center(child: Icon(Icons.fitness_center_rounded, size: 64,
            color: Colors.white.withValues(alpha: 0.08))),
      );
    }

    // Video ready
    if (_isVideo && _ready && _vc != null) {
      final size = _vc!.value.size;
      if (size.width > 0 && size.height > 0) {
        return Container(
          color: Colors.black,
          child: Center(
            child: AspectRatio(
              aspectRatio: size.width / size.height,
              child: VideoPlayer(_vc!),
            ),
          ),
        );
      }
    }

    // Video loading
    if (_isVideo) {
      return Container(color: Colors.black,
          child: const Center(child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2)));
    }

    // Image
    return Image.network(url,
      headers: const {'Bypass-Tunnel-Reminder': 'true'},
      fit: BoxFit.cover, width: double.infinity, height: double.infinity,
      loadingBuilder: (_, child, p) => p == null ? child
          : Container(color: const Color(0xFF1A1A1A),
              child: const Center(child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2))),
      errorBuilder: (_, error, ___) => Container(
        color: const Color(0xFF1A1A1A),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_rounded, size: 48, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 12),
            const Text('تعذر تحميل الفيديو بسبب مشكلة في الشبكة', style: TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
