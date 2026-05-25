import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:google_fonts/google_fonts.dart';

Future<void> showDayCompleteDialog(
  BuildContext context, {
  required int totalKcalBurned,
  required int totalExp,
}) async {
  HapticFeedback.heavyImpact();
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Day complete',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, _, _) => _CelebrationContent(
      totalKcalBurned: totalKcalBurned,
      totalExp: totalExp,
    ),
    transitionBuilder: (_, anim, _, child) {
      final scale = CurvedAnimation(
        parent: anim,
        curve: Curves.elasticOut,
      );
      return Transform.scale(
        scale: 0.6 + 0.4 * scale.value,
        child: Opacity(opacity: anim.value, child: child),
      );
    },
  );
}

class _CelebrationContent extends StatefulWidget {
  const _CelebrationContent({
    required this.totalKcalBurned,
    required this.totalExp,
  });

  final int totalKcalBurned;
  final int totalExp;

  @override
  State<_CelebrationContent> createState() => _CelebrationContentState();
}

class _CelebrationContentState extends State<_CelebrationContent>
    with TickerProviderStateMixin {
  late final AnimationController _sparkleCtrl;
  late final AnimationController _bobCtrl;

  @override
  void initState() {
    super.initState();
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sparkleCtrl.dispose();
    _bobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Day Complete!',
                  style: GoogleFonts.jersey20(
                    fontSize: 36,
                    color: const Color(0xFFF5A623),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'All workouts done. Streak continues.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _sparkleCtrl,
                        builder: (_, _) => CustomPaint(
                          size: const Size(200, 200),
                          painter: _SparklePainter(_sparkleCtrl.value),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _bobCtrl,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, -6 + _bobCtrl.value * 12),
                          child: child,
                        ),
                        child: Image.asset(
                          'assets/streak-continue.png',
                          width: 140,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stat(
                      icon: Icons.local_fire_department_rounded,
                      value: '${widget.totalKcalBurned}',
                      label: 'kcal burned',
                      color: const Color(0xFFF5A623),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.black12,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _stat(
                      icon: Icons.bolt_rounded,
                      value: '+${widget.totalExp}',
                      label: 'EXP earned',
                      color: const Color(0xFF2E7D32),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Nice!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.black45),
        ),
      ],
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t);
  final double t;

  static const _count = 14;
  static final _colors = [
    const Color(0xFFF5A623),
    const Color(0xFF5BA3D9),
    const Color(0xFF2E7D32),
    const Color(0xFFE91E63),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    for (int i = 0; i < _count; i++) {
      final phase = (t + i / _count) % 1.0;
      final angle = (i / _count) * 2 * math.pi;
      final r = maxR * phase;
      final pos = center +
          Offset(math.cos(angle) * r, math.sin(angle) * r);
      final paint = Paint()
        ..color = _colors[i % _colors.length]
            .withValues(alpha: (1 - phase).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 3 + phase * 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.t != t;
}
